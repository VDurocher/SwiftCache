# SwiftCache

> Actor-based in-memory cache with TTL and LRU eviction for Swift 6.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-blue.svg)](https://developer.apple.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**SwiftCache** is a lightweight, thread-safe key-value cache built with Swift 6 strict concurrency. No external dependencies — just `Foundation`.

---

## Features

- **Actor-isolated** — all reads and writes are `async`, safe to call from any concurrency domain
- **TTL support** — per-entry or global time-to-live; expired entries are evicted lazily
- **LRU eviction** — least-recently-used entries are dropped when capacity is exceeded
- **`getOrInsert`** — compute-and-cache in a single call, no double-checked locking needed
- **Statistics** — track hit/miss counts and hit rate
- **`CacheKey` helpers** — namespaced and composite key builders

---

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/VDurocher/SwiftCache.git", from: "1.0.0")
]
```

---

## Quick Start

```swift
import SwiftCache

// Create a cache with a 5-minute TTL and max 256 entries
let cache = Cache<String, Data>(capacity: 256, defaultTTL: 300)

// Store
await cache.set("avatar-42", value: imageData)

// Retrieve
let data = await cache.get("avatar-42")  // Data? — nil if missing or expired

// Compute-and-cache
let profile = try await cache.getOrInsert("profile-7") {
    try await api.fetchProfile(id: 7)
}

// Namespaced keys
let key = CacheKey.namespaced("user", id: 42)  // "user:42"
```

---

## API

```swift
// Read
func get(_ key: Key) -> Value?

// Write
func set(_ key: Key, value: Value, ttl: TimeInterval? = nil)

// Compute-and-cache
func getOrInsert(_ key: Key, ttl: TimeInterval? = nil,
                 compute: @Sendable () async throws -> Value) async rethrows -> Value

// Removal
func remove(_ key: Key)
func purgeExpired()
func flush()

// Metadata
var count: Int
var statistics: CacheStatistics  // hits, misses, hitRate
```

---

## License

MIT — [@VDurocher](https://github.com/VDurocher)
