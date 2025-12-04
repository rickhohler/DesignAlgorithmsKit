//
//  DesignAlgorithmsKit.swift
//  DesignAlgorithmsKit
//
//  Main entry point for DesignAlgorithmsKit
//

import Foundation

// Re-export all modules
@_exported import struct Foundation.Data
@_exported import struct Foundation.URL

/// DesignAlgorithmsKit - Common design patterns and algorithms for Swift
///
/// This package provides implementations of classic design patterns (Gang of Four)
/// and modern patterns commonly used in Swift development, as well as common algorithms
/// and data structures.
///
/// ## Modules
///
/// - **Core**: Base protocols and types (Registry)
/// - **Creational**: Creational design patterns (Singleton, Factory, Builder)
/// - **Structural**: Structural design patterns (Facade, Adapter)
/// - **Behavioral**: Behavioral design patterns (Strategy, Observer)
/// - **Algorithms**: Algorithms and data structures (Merkle Tree, Hashing)
/// - **Modern**: Modern patterns and extensions
///
/// ## Quick Start
///
/// ```swift
/// import DesignAlgorithmsKit
///
/// // Use Registry Pattern
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
