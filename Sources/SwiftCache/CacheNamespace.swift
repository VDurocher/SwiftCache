import Foundation

// MARK: - CacheNamespace

/// A logical partition over an existing `Cache`, scoping all keys under a prefix.
///
/// Use to share a single cache instance across modules while preventing key
/// collisions without managing prefixes manually.
///
/// ```swift
/// let cache = Cache<String, Data>()
/// let userCache = CacheNamespace(cache: cache, prefix: "user")
/// let imageCache = CacheNamespace(cache: cache, prefix: "image")
///
/// await userCache.set(data, forKey: "avatar")   // stored as "user:avatar"
/// await imageCache.set(img, forKey: "avatar")   // stored as "image:avatar"
/// ```
public actor CacheNamespace<Value: Sendable> {

    // MARK: - Properties

    private let cache: Cache<String, Value>
    private let prefix: String
    private let separator: String

    // MARK: - Init

    /// - Parameters:
    ///   - cache: The backing cache. All operations are delegated to it.
    ///   - prefix: The namespace prefix applied to every key.
    ///   - separator: Character(s) between prefix and key. Defaults to `":"`.
    public init(cache: Cache<String, Value>, prefix: String, separator: String = ":") {
        precondition(!prefix.isEmpty, "Namespace prefix must not be empty")
        self.cache = cache
        self.prefix = prefix
        self.separator = separator
    }

    // MARK: - Key namespacing

    private func namespacedKey(_ key: String) -> String {
        "\(prefix)\(separator)\(key)"
    }

    // MARK: - API

    /// Returns the cached value for `key`, or `nil` if absent or expired.
    public func value(forKey key: String) async -> Value? {
        await cache.value(forKey: namespacedKey(key))
    }

    /// Stores `value` for `key` with the given TTL.
    public func set(_ value: Value, forKey key: String, ttl: TimeInterval) async {
        await cache.set(value, forKey: namespacedKey(key), ttl: ttl)
    }

    /// Removes the entry for `key`.
    public func remove(forKey key: String) async {
        await cache.remove(forKey: namespacedKey(key))
    }

    /// Returns the namespaced key string (useful for debugging).
    public func resolvedKey(for key: String) -> String {
        namespacedKey(key)
    }
}
