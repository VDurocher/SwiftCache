import Foundation

/// Namespace for pre-built cache key strategies.
public enum CacheKey {

    /// Combines a base prefix with a unique identifier — useful for namespacing entries by type.
    ///
    /// ```swift
    /// let key = CacheKey.namespaced("user", id: 42)  // "user:42"
    /// ```
    public static func namespaced(_ prefix: String, id: some CustomStringConvertible) -> String {
        "\(prefix):\(id)"
    }

    /// Builds a composite key from multiple components joined by "/".
    ///
    /// ```swift
    /// let key = CacheKey.composite("v2", "products", "featured")  // "v2/products/featured"
    /// ```
    public static func composite(_ components: String...) -> String {
        components.joined(separator: "/")
    }
}
