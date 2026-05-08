import Foundation

// Defines eviction strategy and TTL behaviour for a Cache instance.
public struct CachePolicy: Sendable, Equatable {

    // Maximum number of entries before LRU eviction kicks in.
    // nil = unbounded.
    public let maxCount: Int?

    // Default TTL applied when no per-entry TTL is given.
    // nil = entries never expire by default.
    public let defaultTTL: TimeInterval?

    // When true, accessing a cache hit resets that entry's TTL.
    public let refreshOnAccess: Bool

    public init(
        maxCount: Int? = nil,
        defaultTTL: TimeInterval? = nil,
        refreshOnAccess: Bool = false
    ) {
        self.maxCount = maxCount
        self.defaultTTL = defaultTTL
        self.refreshOnAccess = refreshOnAccess
    }
}

public extension CachePolicy {

    // Conservative: small cache, short TTL, no refresh.
    static let conservative = CachePolicy(maxCount: 50, defaultTTL: 60)

    // Moderate: medium cache, 5-minute TTL.
    static let moderate = CachePolicy(maxCount: 200, defaultTTL: 300)

    // Aggressive: large cache, 1-hour TTL, TTL resets on access.
    static let aggressive = CachePolicy(maxCount: 1000, defaultTTL: 3600, refreshOnAccess: true)
}
