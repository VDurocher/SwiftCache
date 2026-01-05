import Foundation

// MARK: - CachePreloader

/// Populates a `Cache` with a set of known entries at startup,
/// useful for warming caches from bundled assets or server-seeded data.
///
/// ```swift
/// let preloader = CachePreloader(cache: cache, ttl: 3600)
/// try await preloader.load([
///     CachePreloader.Entry(key: "config", value: appConfig),
///     CachePreloader.Entry(key: "defaults", value: defaults),
/// ])
/// ```
public actor CachePreloader<Key: Hashable & Sendable, Value: Sendable> {

    // MARK: - Entry

    /// A single preload item — a key/value pair with an optional custom TTL.
    public struct Entry: Sendable {
        public let key: Key
        public let value: Value
        /// Override the preloader's default TTL for this entry. `nil` uses the default.
        public let ttl: TimeInterval?

        public init(key: Key, value: Value, ttl: TimeInterval? = nil) {
            self.key = key
            self.value = value
            self.ttl = ttl
        }
    }

    // MARK: - Result

    public struct LoadResult: Sendable {
        public let loaded: Int
        public let skipped: Int
    }

    // MARK: - Properties

    private let cache: Cache<Key, Value>
    private let defaultTTL: TimeInterval
    private let overwriteExisting: Bool

    // MARK: - Init

    /// - Parameters:
    ///   - cache: The cache to populate.
    ///   - ttl: Default time-to-live for preloaded entries.
    ///   - overwriteExisting: When `false`, existing cache entries are skipped. Default `false`.
    public init(cache: Cache<Key, Value>, ttl: TimeInterval, overwriteExisting: Bool = false) {
        self.cache = cache
        self.defaultTTL = ttl
        self.overwriteExisting = overwriteExisting
    }

    // MARK: - API

    /// Loads the given entries into the cache.
    /// - Returns: A summary of how many entries were loaded vs skipped.
    @discardableResult
    public func load(_ entries: [Entry]) async -> LoadResult {
        var loaded = 0
        var skipped = 0

        for entry in entries {
            if !overwriteExisting, await cache.value(forKey: entry.key) != nil {
                skipped += 1
                continue
            }
            let ttl = entry.ttl ?? defaultTTL
            await cache.set(entry.value, forKey: entry.key, ttl: ttl)
            loaded += 1
        }

        return LoadResult(loaded: loaded, skipped: skipped)
    }

    /// Convenience for loading a dictionary of key/value pairs with the default TTL.
    @discardableResult
    public func load(_ dictionary: [Key: Value]) async -> LoadResult {
        let entries = dictionary.map { Entry(key: $0.key, value: $0.value) }
        return await load(entries)
    }
}
