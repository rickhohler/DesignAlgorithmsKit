// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DesignAlgorithmsKit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "DesignAlgorithmsKit",
            targets: ["DesignAlgorithmsKit"]),
    ],
    dependencies: [
        // Swift DocC Plugin for documentation generation
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "DesignAlgorithmsKit",
            dependencies: [],
            path: "Sources/DesignAlgorithmsKit"
        ),
        .testTarget(
            name: "DesignAlgorithmsKitTests",
            dependencies: ["DesignAlgorithmsKit"],
            path: "Tests/DesignAlgorithmsKitTests"
        ),
    ]
)
