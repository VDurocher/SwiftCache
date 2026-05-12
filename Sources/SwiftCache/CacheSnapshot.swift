import Foundation

// Read-only point-in-time snapshot of a Cache's contents.
// Useful for persistence, debugging, and warm-up after restart.
public struct CacheSnapshot<Key: Hashable & Sendable, Value: Sendable>: Sendable {

    public struct Entry: Sendable {
        public let key: Key
        public let value: Value
        // nil when the entry has no expiry
        public let expiresAt: Date?
    }

    public let entries: [Entry]
    public let capturedAt: Date

    public var count: Int { entries.count }

    // Entries that have not yet expired relative to a reference date.
    public func validEntries(at date: Date = Date()) -> [Entry] {
        entries.filter { entry in
            guard let expiry = entry.expiresAt else { return true }
            return expiry > date
        }
    }
}
