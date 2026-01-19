import Foundation

// MARK: - CacheInspector

/// Provides diagnostic and introspection tools for a `Cache` instance.
///
/// Use in debug builds to understand cache state, identify hot or stale keys,
/// and surface metrics for logging or analytics dashboards.
///
/// ```swift
/// let inspector = CacheInspector(cache: myCache)
/// let report = await inspector.generateReport()
/// print(report.summary)
/// ```
public actor CacheInspector<Key: Hashable & Sendable, Value: Sendable> {

    // MARK: - Report

    /// A point-in-time diagnostic snapshot of a cache.
    public struct Report: Sendable {
        public let totalEntries: Int
        public let expiredEntries: Int
        public let validEntries: Int
        public let capturedAt: Date

        /// A human-readable single-line summary.
        public var summary: String {
            "Cache at \(capturedAt): \(validEntries) valid, \(expiredEntries) expired (\(totalEntries) total)"
        }
    }

    // MARK: - Properties

    private let cache: Cache<Key, Value>

    // MARK: - Init

    public init(cache: Cache<Key, Value>) {
        self.cache = cache
    }

    // MARK: - API

    /// Returns the total number of entries (including expired ones not yet evicted).
    public func entryCount() async -> Int {
        await cache.count
    }

    /// Generates a diagnostic report from a `CacheSnapshot`.
    public func generateReport() async -> Report {
        let snapshot = await cache.snapshot()
        let now = Date()
        let expired = snapshot.entries.values.filter { $0.expiresAt <= now }.count
        let total = snapshot.entries.count
        return Report(
            totalEntries: total,
            expiredEntries: expired,
            validEntries: total - expired,
            capturedAt: now
        )
    }

    /// Returns all keys that have already expired (but not yet evicted).
    public func expiredKeys() async -> [Key] {
        let snapshot = await cache.snapshot()
        let now = Date()
        return snapshot.entries.compactMap { key, entry in
            entry.expiresAt <= now ? key : nil
        }
    }

    /// Returns keys whose TTL will expire within the next `seconds`.
    public func keysExpiringWithin(seconds: TimeInterval) async -> [Key] {
        let snapshot = await cache.snapshot()
        let deadline = Date().addingTimeInterval(seconds)
        return snapshot.entries.compactMap { key, entry in
            entry.expiresAt > Date() && entry.expiresAt <= deadline ? key : nil
        }
    }
}
