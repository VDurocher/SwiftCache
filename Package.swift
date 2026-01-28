// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftCache",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(name: "SwiftCache", targets: ["SwiftCache"])
    ],
    targets: [
        .target(
            name: "SwiftCache",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SwiftCacheTests",
            dependencies: ["SwiftCache"]
        )
    ],
    swiftLanguageVersions: [.v6]
)
