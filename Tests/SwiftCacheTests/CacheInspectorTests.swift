import XCTest
@testable import SwiftCache

final class CacheInspectorTests: XCTestCase {

    func testEntryCountMatchesInserted() async {
        let cache = Cache<String, Int>()
        await cache.set(1, forKey: "a", ttl: 60)
        await cache.set(2, forKey: "b", ttl: 60)
        let inspector = CacheInspector(cache: cache)
        let count = await inspector.entryCount()
        XCTAssertEqual(count, 2)
    }

    func testReportCountsValidEntries() async {
        let cache = Cache<String, Int>()
        await cache.set(1, forKey: "valid", ttl: 60)
        let inspector = CacheInspector(cache: cache)
        let report = await inspector.generateReport()
        XCTAssertGreaterThanOrEqual(report.validEntries, 1)
        XCTAssertFalse(report.summary.isEmpty)
    }

    func testExpiredKeysDetected() async throws {
        let cache = Cache<String, Int>()
        await cache.set(1, forKey: "short", ttl: 0.01)  // 10ms TTL
        await cache.set(2, forKey: "long", ttl: 60)
        try await Task.sleep(nanoseconds: 50_000_000)   // wait 50ms
        let inspector = CacheInspector(cache: cache)
        let expired = await inspector.expiredKeys()
        XCTAssertTrue(expired.contains("short"))
        XCTAssertFalse(expired.contains("long"))
    }

    func testKeysExpiringWithinWindow() async {
        let cache = Cache<String, Int>()
        await cache.set(1, forKey: "soon", ttl: 5)      // expires in 5s
        await cache.set(2, forKey: "later", ttl: 3600)  // expires in 1hr
        let inspector = CacheInspector(cache: cache)
        let keys = await inspector.keysExpiringWithin(seconds: 10)
        XCTAssertTrue(keys.contains("soon"))
        XCTAssertFalse(keys.contains("later"))
    }

    func testReportSummaryContainsCounts() async {
        let cache = Cache<String, String>()
        await cache.set("hello", forKey: "key", ttl: 60)
        let inspector = CacheInspector(cache: cache)
        let report = await inspector.generateReport()
        XCTAssertTrue(report.summary.contains("valid"))
        XCTAssertTrue(report.summary.contains("expired"))
    }
}
