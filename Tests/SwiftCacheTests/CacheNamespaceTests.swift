import XCTest
@testable import SwiftCache

final class CacheNamespaceTests: XCTestCase {

    func testResolvedKeyIncludesPrefix() async {
        let cache = Cache<String, Int>()
        let ns = CacheNamespace(cache: cache, prefix: "user")
        XCTAssertEqual(ns.resolvedKey(for: "id"), "user:id")
    }

    func testCustomSeparator() async {
        let cache = Cache<String, Int>()
        let ns = CacheNamespace(cache: cache, prefix: "img", separator: ".")
        XCTAssertEqual(ns.resolvedKey(for: "avatar"), "img.avatar")
    }

    func testSetAndRetrieve() async {
        let cache = Cache<String, String>()
        let ns = CacheNamespace(cache: cache, prefix: "session")
        await ns.set("token123", forKey: "token", ttl: 60)
        let value = await ns.value(forKey: "token")
        XCTAssertEqual(value, "token123")
    }

    func testNamespacesDoNotCollide() async {
        let cache = Cache<String, String>()
        let nsA = CacheNamespace(cache: cache, prefix: "a")
        let nsB = CacheNamespace(cache: cache, prefix: "b")
        await nsA.set("alpha", forKey: "key", ttl: 60)
        await nsB.set("beta", forKey: "key", ttl: 60)
        let a = await nsA.value(forKey: "key")
        let b = await nsB.value(forKey: "key")
        XCTAssertEqual(a, "alpha")
        XCTAssertEqual(b, "beta")
    }

    func testRemoveOnlyAffectsNamespace() async {
        let cache = Cache<String, String>()
        let nsA = CacheNamespace(cache: cache, prefix: "a")
        let nsB = CacheNamespace(cache: cache, prefix: "b")
        await nsA.set("alpha", forKey: "key", ttl: 60)
        await nsB.set("beta", forKey: "key", ttl: 60)
        await nsA.remove(forKey: "key")
        let a = await nsA.value(forKey: "key")
        let b = await nsB.value(forKey: "key")
        XCTAssertNil(a)
        XCTAssertEqual(b, "beta")
    }

    func testMissingKeyReturnsNil() async {
        let cache = Cache<String, Int>()
        let ns = CacheNamespace(cache: cache, prefix: "x")
        let value = await ns.value(forKey: "nonexistent")
        XCTAssertNil(value)
    }
}
