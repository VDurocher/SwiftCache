import XCTest
@testable import SwiftCache

final class CachePreloaderTests: XCTestCase {

    private func makeCache() -> Cache<String, Int> {
        Cache<String, Int>()
    }

    func testLoadEntriesIntoEmptyCache() async {
        let cache = makeCache()
        let preloader = CachePreloader(cache: cache, ttl: 60)
        let entries = [
            CachePreloader.Entry(key: "a", value: 1),
            CachePreloader.Entry(key: "b", value: 2),
        ]
        let result = await preloader.load(entries)
        XCTAssertEqual(result.loaded, 2)
        XCTAssertEqual(result.skipped, 0)
        let a = await cache.value(forKey: "a")
        let b = await cache.value(forKey: "b")
        XCTAssertEqual(a, 1)
        XCTAssertEqual(b, 2)
    }

    func testSkipsExistingEntriesByDefault() async {
        let cache = makeCache()
        await cache.set(99, forKey: "a", ttl: 60)
        let preloader = CachePreloader(cache: cache, ttl: 60)
        let result = await preloader.load([CachePreloader.Entry(key: "a", value: 1)])
        XCTAssertEqual(result.loaded, 0)
        XCTAssertEqual(result.skipped, 1)
        let value = await cache.value(forKey: "a")
        XCTAssertEqual(value, 99)
    }

    func testOverwriteExistingWhenEnabled() async {
        let cache = makeCache()
        await cache.set(99, forKey: "a", ttl: 60)
        let preloader = CachePreloader(cache: cache, ttl: 60, overwriteExisting: true)
        let result = await preloader.load([CachePreloader.Entry(key: "a", value: 1)])
        XCTAssertEqual(result.loaded, 1)
        XCTAssertEqual(result.skipped, 0)
        let value = await cache.value(forKey: "a")
        XCTAssertEqual(value, 1)
    }

    func testLoadDictionary() async {
        let cache = makeCache()
        let preloader = CachePreloader(cache: cache, ttl: 60)
        let result = await preloader.load(["x": 10, "y": 20, "z": 30])
        XCTAssertEqual(result.loaded, 3)
        XCTAssertEqual(result.skipped, 0)
    }

    func testPerEntryTTLOverridesDefault() async {
        let cache = makeCache()
        let preloader = CachePreloader(cache: cache, ttl: 3600)
        // Entry with very short TTL (10ms)
        let entry = CachePreloader.Entry(key: "short", value: 42, ttl: 0.01)
        await preloader.load([entry])
        // Immediately present
        let before = await cache.value(forKey: "short")
        XCTAssertEqual(before, 42)
        // After expiry, should be nil
        try? await Task.sleep(nanoseconds: 50_000_000)
        let after = await cache.value(forKey: "short")
        XCTAssertNil(after)
    }
}
