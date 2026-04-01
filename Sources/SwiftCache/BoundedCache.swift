import Foundation

/// A variant of `Cache` that enforces a hard byte-size limit in addition to entry count.
///
/// Useful when cached values have variable sizes (e.g. `Data` payloads)
/// and you want to cap total memory usage, not just entry count.
///
/// Size tracking relies on a caller-provided `sizer` closure rather than
/// conformance to a protocol, keeping `BoundedCache` generic over any `Value`.
///
/// ```swift
/// let imageCache = BoundedCache<String, Data>(
///     maxBytes: 50 * 1024 * 1024,  // 50 MB
///     sizer: { $0.count }
/// )
/// await imageCache.set("hero", value: heroImageData)
/// ```
public actor BoundedCache<Key: Hashable & Sendable, Value: Sendable> {

    private var storage: [Key: Entry] = [:]
    private var accessOrder: [Key] = []

    private let maxBytes: Int
    private let sizer: @Sendable (Value) -> Int
    private let defaultTTL: TimeInterval?

    private var usedBytes: Int = 0
    public private(set) var statistics = CacheStatistics()

    private struct Entry {
        let value: Value
        let byteSize: Int
        let expiresAt: Date?

        var isExpired: Bool {
            guard let expiresAt else { return false }
            return Date() >= expiresAt
        }
    }

    // MARK: - Init

    /// - Parameters:
    ///   - maxBytes: Maximum total byte size. New entries that would exceed this limit trigger LRU eviction.
    ///   - sizer: Returns the byte size of a given value.
    ///   - defaultTTL: Default time-to-live; `nil` means entries never expire.
    public init(
        maxBytes: Int,
        sizer: @escaping @Sendable (Value) -> Int,
        defaultTTL: TimeInterval? = nil
    ) {
        self.maxBytes = maxBytes
        self.sizer = sizer
        self.defaultTTL = defaultTTL
    }

    // MARK: - Read

    public func get(_ key: Key) -> Value? {
        guard let entry = storage[key] else {
            statistics.recordMiss()
            return nil
        }
        if entry.isExpired {
            removeEntry(for: key)
            statistics.recordMiss()
            return nil
        }
        touch(key)
        statistics.recordHit()
        return entry.value
    }

    // MARK: - Write

    public func set(_ key: Key, value: Value, ttl: TimeInterval? = nil) {
        let size = sizer(value)
        // Single entries larger than the total budget are silently dropped
        guard size <= maxBytes else { return }

        // Remove old entry if overwriting
        if let existing = storage[key] {
            usedBytes -= existing.byteSize
        }

        let effectiveTTL = ttl ?? defaultTTL
        let expiresAt = effectiveTTL.map { Date().addingTimeInterval($0) }
        storage[key] = Entry(value: value, byteSize: size, expiresAt: expiresAt)
        usedBytes += size
        touch(key)
        evictIfNeeded()
    }

    public func remove(_ key: Key) {
        removeEntry(for: key)
    }

    public func flush() {
        storage.removeAll()
        accessOrder.removeAll()
        usedBytes = 0
    }

    public var count: Int { storage.count }
    public var bytesUsed: Int { usedBytes }

    // MARK: - Private Helpers

    private func touch(_ key: Key) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }

    private func removeEntry(for key: Key) {
        if let entry = storage.removeValue(forKey: key) {
            usedBytes -= entry.byteSize
        }
        accessOrder.removeAll { $0 == key }
    }

    private func evictIfNeeded() {
        // First evict expired entries
        let expired = storage.filter { $0.value.isExpired }.map(\.key)
        for key in expired { removeEntry(for: key) }

        // Then evict LRU entries until under budget
        while usedBytes > maxBytes, let lruKey = accessOrder.first {
            removeEntry(for: lruKey)
        }
    }
}
