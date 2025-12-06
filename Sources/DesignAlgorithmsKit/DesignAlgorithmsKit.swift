//
//  DesignAlgorithmsKit.swift
//  DesignAlgorithmsKit
//
//  A comprehensive collection of design patterns and algorithms in Swift
//

import Foundation

// MARK: - Main Module

/// DesignAlgorithmsKit provides a comprehensive collection of design patterns
/// and algorithms implemented in Swift.
///
/// ## Features
///
/// - **Design Patterns**: Creational, Structural, and Behavioral patterns
/// - **Data Structures**: Specialized data structures for various use cases
/// - **Algorithms**: Common algorithms and utilities
///
/// ## Modules
///
/// ### Creational Patterns
/// - Factory Pattern
/// - Builder Pattern  
/// - Singleton Pattern
///
/// ### Structural Patterns
/// - Adapter Pattern
/// - Facade Pattern
///
/// ### Behavioral Patterns
/// - Observer Pattern
/// - Strategy Pattern
/// - Queue Processing Pattern
/// - Merger Pattern
///
/// ### Data Structures (not available in WASM builds)
/// - Bloom Filter (requires NSLock)
/// - Merkle Tree (requires NSLock)
///
/// ### Core Utilities
/// - Type Registry
///
/// ## Platform Support
///
/// - macOS 12.0+
/// - iOS 15.0+
/// - tvOS 15.0+
/// - watchOS 8.0+
/// - WASM (limited - excludes hash/crypto types that require NSLock)
public struct DesignAlgorithmsKit {
    /// Library version
    public static let version = "1.2.0"
}

// Re-export all modules
@_exported import struct Foundation.Data
@_exported import struct Foundation.URL

/// TypeRegistry.shared.register(MyType.self)
///
/// // Use Factory Pattern
/// let object = try ObjectFactory.shared.create(type: "myType", configuration: [:])
///
/// // Use Builder Pattern
/// let object = try MyObjectBuilder()
///     .setProperty("value")
///     .build()
///
/// // Use Merkle Tree
/// let tree = MerkleTree.build(from: dataBlocks)
/// let rootHash = tree.rootHash
/// ```
public enum DesignAlgorithmsKit {
    /// DesignAlgorithmsKit version
    public static let version = "1.1.0"
}
