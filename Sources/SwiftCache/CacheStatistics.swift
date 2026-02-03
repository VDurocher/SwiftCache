import Foundation

/// Hit/miss counters for a cache instance.
public struct CacheStatistics: Sendable {
    public private(set) var hits: Int = 0
    public private(set) var misses: Int = 0

    /// Total number of lookups performed.
    public var total: Int { hits + misses }

    /// Fraction of lookups that returned a cached value (0…1).
    public var hitRate: Double {
        guard total > 0 else { return 0 }
        return Double(hits) / Double(total)
    }

    mutating func recordHit() { hits += 1 }
    mutating func recordMiss() { misses += 1 }
}
