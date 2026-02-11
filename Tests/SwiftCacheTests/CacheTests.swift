import XCTest
@testable import SwiftCache

final class CacheTests: XCTestCase {

    // MARK: - Basic get/set

    func testSetAndGet() async {
        let cache = Cache<String, Int>(capacity: 10)
        await cache.set("key", value: 42)
        let result = await cache.get("key")
        XCTAssertEqual(result, 42)
    }

    func testMissingKeyReturnsNil() async {
        let cache = Cache<String, Int>(capacity: 10)
        let result = await cache.get("missing")
        XCTAssertNil(result)
    }

    func testOverwriteExistingKey() async {
        let cache = Cache<String, Int>(capacity: 10)
        await cache.set("key", value: 1)
        await cache.set("key", value: 2)
        let result = await cache.get("key")
        XCTAssertEqual(result, 2)
    }

    func testRemove() async {
        let cache = Cache<String, Int>(capacity: 10)
        await cache.set("key", value: 99)
        await cache.remove("key")
        let result = await cache.get("key")
        XCTAssertNil(result)
    }

    func testFlush() async {
        let cache = Cache<String, Int>(capacity: 10)
        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        await cache.flush()
        let count = await cache.count
        XCTAssertEqual(count, 0)
    }

    // MARK: - TTL

    func testEntryExpiresAfterTTL() async throws {
        let cache = Cache<String, Int>(capacity: 10, defaultTTL: 0.05)
        await cache.set("key", value: 1)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        let result = await cache.get("key")
        XCTAssertNil(result, "Entry should have expired")
    }

    func testEntryWithNoTTLDoesNotExpire() async throws {
        let cache = Cache<String, Int>(capacity: 10, defaultTTL: nil)
        await cache.set("key", value: 7)
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        let result = await cache.get("key")
        XCTAssertEqual(result, 7)
    }

    func testPerEntryTTLOverridesDefault() async throws {
        let cache = Cache<String, Int>(capacity: 10, defaultTTL: 60)
        // Override with a very short TTL for this specific entry
        await cache.set("short", value: 1, ttl: 0.05)
        await cache.set("long", value: 2)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        XCTAssertNil(await cache.get("short"))
        XCTAssertEqual(await cache.get("long"), 2)
    }

    func testPurgeExpired() async throws {
        let cache = Cache<String, Int>(capacity: 10)
        await cache.set("short", value: 1, ttl: 0.05)
        await cache.set("long", value: 2, ttl: 60)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        await cache.purgeExpired()
        let count = await cache.count
        XCTAssertEqual(count, 1)
    }

    // MARK: - LRU eviction

    func testLRUEviction() async {
        let cache = Cache<Int, Int>(capacity: 3)
        await cache.set(1, value: 1)
        await cache.set(2, value: 2)
        await cache.set(3, value: 3)
        // Access key 1 to make it recently used
        _ = await cache.get(1)
        // Adding key 4 should evict key 2 (LRU)
        await cache.set(4, value: 4)
        XCTAssertNil(await cache.get(2), "Key 2 should have been evicted")
        XCTAssertNotNil(await cache.get(1))
        XCTAssertNotNil(await cache.get(3))
        XCTAssertNotNil(await cache.get(4))
    }

    func testCountDoesNotExceedCapacity() async {
        let cache = Cache<Int, Int>(capacity: 5)
        for i in 0..<20 { await cache.set(i, value: i) }
        let count = await cache.count
        XCTAssertLessThanOrEqual(count, 5)
    }

    // MARK: - Statistics

    func testHitAndMissTracking() async {
        let cache = Cache<String, Int>(capacity: 10)
        await cache.set("x", value: 1)
        _ = await cache.get("x")      // hit
        _ = await cache.get("x")      // hit
        _ = await cache.get("missing") // miss
        let stats = await cache.statistics
        XCTAssertEqual(stats.hits, 2)
        XCTAssertEqual(stats.misses, 1)
        XCTAssertEqual(stats.hitRate, 2.0 / 3.0, accuracy: 0.001)
    }

    // MARK: - getOrInsert

    func testGetOrInsertComputesOnMiss() async throws {
        let cache = Cache<String, Int>(capacity: 10)
        var computeCalled = 0
        let result = try await cache.getOrInsert("key") {
            computeCalled += 1
            return 99
        }
        XCTAssertEqual(result, 99)
        XCTAssertEqual(computeCalled, 1)
    }

    func testGetOrInsertDoesNotRecomputeOnHit() async throws {
        let cache = Cache<String, Int>(capacity: 10)
        await cache.set("key", value: 42)
        var computeCalled = 0
        let result = try await cache.getOrInsert("key") {
            computeCalled += 1
            return 99
        }
        XCTAssertEqual(result, 42)
        XCTAssertEqual(computeCalled, 0)
    }
}
