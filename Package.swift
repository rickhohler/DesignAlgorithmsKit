// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DesignAlgorithmsKit",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "DesignAlgorithmsKit",
            targets: ["DesignAlgorithmsKit"]),
    ],
    dependencies: [
        // No dependencies - keep it simple for WASM compatibility
    ],
    targets: [
        .target(
            name: "DesignAlgorithmsKit",
            dependencies: [],
            path: "Sources/DesignAlgorithmsKit",
            exclude: [
                // Exclude hash/crypto types for WASM builds (they use NSLock)
                "Algorithms/DataStructures/BloomFilter.swift",
                "Algorithms/DataStructures/MerkleTree.swift",
                "Algorithms/WASMGuard.swift"
            ]
        ),
        .testTarget(
            name: "DesignAlgorithmsKitTests",
            dependencies: ["DesignAlgorithmsKit"],
            path: "Tests/DesignAlgorithmsKitTests"
        ),
    ]
)
