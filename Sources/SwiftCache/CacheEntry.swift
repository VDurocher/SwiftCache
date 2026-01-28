import Foundation

/// A single cached value with optional expiration.
struct CacheEntry<Value: Sendable>: Sendable {
    let value: Value
    /// Absolute expiration date — nil means the entry never expires.
    let expiresAt: Date?

    init(value: Value, ttl: TimeInterval?) {
        self.value = value
        self.expiresAt = ttl.map { Date().addingTimeInterval($0) }
    }

    /// Returns true if the entry has passed its expiration date.
    var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() >= expiresAt
    }
}
