import Foundation

/// Thread-safe in-memory cache with TTL support and LRU eviction.
///
/// Built on Swift 6 strict concurrency — every read and write requires `await`.
/// The cache evicts the least-recently-used entry when `capacity` is reached.
///
/// ```swift
/// let cache = Cache<String, Data>(capacity: 512, defaultTTL: 300)
///
/// await cache.set("avatar-42", value: imageData)
/// let data = await cache.get("avatar-42")
///
/// // Compute-and-cache in one call
/// let profile = await cache.getOrInsert("profile-7") {
///     try await api.fetchProfile(id: 7)
/// }
/// ```
public actor Cache<Key: Hashable & Sendable, Value: Sendable> {

    private var storage: [Key: CacheEntry<Value>] = [:]
    /// Keys ordered from least- to most-recently used.
    private var accessOrder: [Key] = []

    private let capacity: Int
    private let defaultTTL: TimeInterval?

    public private(set) var statistics = CacheStatistics()

    // MARK: - Init

    /// - Parameters:
    ///   - capacity: Maximum number of entries before LRU eviction kicks in. Default: 256.
    ///   - defaultTTL: Time-to-live applied to entries that do not specify their own TTL. `nil` means entries never expire.
    public init(capacity: Int = 256, defaultTTL: TimeInterval? = nil) {
        self.capacity = capacity
        self.defaultTTL = defaultTTL
    }

    // MARK: - Read

    /// Returns the cached value for `key`, or `nil` if absent or expired.
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

    /// Stores `value` under `key`, overwriting any existing entry.
    /// - Parameters:
    ///   - key: Cache key.
    ///   - value: Value to store.
    ///   - ttl: Time-to-live in seconds. Overrides `defaultTTL` when provided.
    public func set(_ key: Key, value: Value, ttl: TimeInterval? = nil) {
        let effectiveTTL = ttl ?? defaultTTL
        storage[key] = CacheEntry(value: value, ttl: effectiveTTL)
        touch(key)
        evictIfNeeded()
    }

    /// Returns the cached value for `key` if present; otherwise calls `compute`,
    /// stores the result, and returns it.
    public func getOrInsert(
        _ key: Key,
        ttl: TimeInterval? = nil,
        compute: @Sendable () async throws -> Value
    ) async rethrows -> Value {
        if let cached = get(key) { return cached }
        let value = try await compute()
        set(key, value: value, ttl: ttl)
        return value
    }

    // MARK: - Removal

    /// Removes the entry for `key`, if it exists.
    public func remove(_ key: Key) {
        removeEntry(for: key)
    }

    /// Removes all expired entries without clearing valid ones.
    public func purgeExpired() {
        let expiredKeys = storage.filter { $0.value.isExpired }.map(\.key)
        for key in expiredKeys { removeEntry(for: key) }
    }

    /// Removes all entries from the cache.
    public func flush() {
        storage.removeAll()
        accessOrder.removeAll()
    }

    // MARK: - Metadata

    /// Number of non-expired entries currently in the cache.
    public var count: Int { storage.count }

    // MARK: - Private Helpers

    private func touch(_ key: Key) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }

    private func removeEntry(for key: Key) {
        storage.removeValue(forKey: key)
        accessOrder.removeAll { $0 == key }
    }

    private func evictIfNeeded() {
        while storage.count > capacity, let lruKey = accessOrder.first {
            removeEntry(for: lruKey)
        }
    }
}
