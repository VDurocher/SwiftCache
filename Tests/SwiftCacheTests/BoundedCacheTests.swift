import XCTest
@testable import SwiftCache

final class BoundedCacheTests: XCTestCase {

    private func makeCache(maxBytes: Int = 100) -> BoundedCache<String, Data> {
        BoundedCache(maxBytes: maxBytes, sizer: { $0.count })
    }

    func testSetAndGet() async {
        let cache = makeCache()
        let data = Data(repeating: 0xAB, count: 10)
        await cache.set("key", value: data)
        let result = await cache.get("key")
        XCTAssertEqual(result, data)
    }

    func testBytesUsedTracking() async {
        let cache = makeCache(maxBytes: 200)
        await cache.set("a", value: Data(count: 30))
        await cache.set("b", value: Data(count: 40))
        let used = await cache.bytesUsed
        XCTAssertEqual(used, 70)
    }

    func testEntriesLargerThanBudgetAreDropped() async {
        let cache = makeCache(maxBytes: 50)
        await cache.set("big", value: Data(count: 60))
        let result = await cache.get("big")
        XCTAssertNil(result, "Entry exceeding maxBytes should be silently dropped")
    }

    func testLRUEvictionWhenOverBudget() async {
        let cache = makeCache(maxBytes: 60)
        let payload = Data(count: 25)
        await cache.set("a", value: payload)
        await cache.set("b", value: payload)
        // Access 'a' to make 'b' the LRU
        _ = await cache.get("a")
        // Adding 'c' should evict 'b' (25 + 25 + 25 = 75 > 60)
        await cache.set("c", value: payload)
        XCTAssertNil(await cache.get("b"), "LRU entry should have been evicted")
        XCTAssertNotNil(await cache.get("a"))
        XCTAssertNotNil(await cache.get("c"))
    }

    func testFlushResetsBytes() async {
        let cache = makeCache()
        await cache.set("a", value: Data(count: 20))
        await cache.flush()
        let used = await cache.bytesUsed
        XCTAssertEqual(used, 0)
    }
}
