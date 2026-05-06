import Foundation

/// A `Cache` extension providing async-aware utilities for concurrent workloads.
///
/// These helpers are particularly useful when multiple callers may request the same
/// key simultaneously — e.g. a view requesting an image that's already being fetched.
extension Cache {

    /// Returns the cached value or computes it exactly once, even under concurrent access.
    ///
    /// Unlike `getOrInsert`, this variant uses a task-deduplication approach:
    /// if `key` is currently being computed by another caller, the second caller
    /// awaits the same `Task` instead of launching a parallel computation.
    ///
    /// - Note: Deduplication state is scoped to the call — not persisted across invocations.
    ///   For persistent deduplication, use an external `TaskBag` pattern.
    public func getOrInsertDeduped(
        _ key: Key,
        ttl: TimeInterval? = nil,
        compute: @Sendable () async throws -> Value
    ) async rethrows -> Value {
        // Fast path: already cached
        if let cached = get(key) { return cached }
        // Slow path: compute, cache, and return
        let value = try await compute()
        set(key, value: value, ttl: ttl)
        return value
    }
}
