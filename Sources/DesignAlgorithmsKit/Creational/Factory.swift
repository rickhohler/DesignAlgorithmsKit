//
//  Factory.swift
//  DesignAlgorithmsKit
//
//  Factory Pattern - Create objects without specifying their concrete classes
//

import Foundation

/// Protocol for factory-created objects
public protocol FactoryProduct {
    /// Initialize product with configuration
    init(configuration: [String: Any]) throws
}

/// Factory for creating objects without specifying concrete classes
///
/// The factory pattern provides a way to create objects without exposing
/// the instantiation logic to the client. This promotes loose coupling
/// and makes code more maintainable.
///
/// ## Usage
///
/// ```swift
/// // Register a factory method
/// ObjectFactory.register(type: "myType") { config in
///     return MyType(configuration: config)
/// }
///
/// // Create object via factory
/// let object = try ObjectFactory.create(type: "myType", configuration: [:])
/// ```
public final class ObjectFactory: @unchecked Sendable {
    /// Shared singleton instance (lazy initialization)
    #if !os(WASI) && !arch(wasm32)
    nonisolated(unsafe) private static var _shared: ObjectFactory?
    nonisolated private static let lock = NSLock()
    #else
    private static var _shared: ObjectFactory?
    #endif
    
    /// Shared singleton instance
    public static var shared: ObjectFactory {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        if _shared == nil {
            _shared = ObjectFactory()
        }
        return _shared!
    }
    
    #if !os(WASI) && !arch(wasm32)
    /// Lock for thread-safe access
    private let lock = NSLock()
    #endif
    
    /// Factory methods (type -> factory closure)
    private var factories: [String: (([String: Any]) throws -> Any)] = [:]
    
    private init() {
        // Private initializer for singleton
    }
    
    /// Register a factory method for a type
    /// - Parameters:
    ///   - type: Type identifier
    ///   - factory: Factory closure that creates the object
    /// Thread-safe: Can be called concurrently
    public func register(type: String, factory: @escaping ([String: Any]) throws -> Any) {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        factories[type] = factory
    }
    
    /// Register a factory method for a FactoryProduct type
    /// - Parameter type: The FactoryProduct type
    /// Thread-safe: Can be called concurrently
    public func register<T: FactoryProduct>(_ type: T.Type, key: String? = nil) {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        let typeKey = key ?? String(describing: type)
        factories[typeKey] = { config in
            try T(configuration: config)
        }
    }
    
    /// Create an object using registered factory
    /// - Parameters:
    ///   - type: Type identifier
    ///   - configuration: Configuration dictionary
    /// - Returns: Created object
    /// - Throws: Error if factory not found or creation fails
    /// Thread-safe: Can be called concurrently
    public func create(type: String, configuration: [String: Any] = [:]) throws -> Any {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        let factory = factories[type]
        lock.unlock()
        #else
        let factory = factories[type]
        #endif
        
        guard let factory = factory else {
            throw FactoryError.typeNotRegistered(type)
        }
        
        return try factory(configuration)
    }
    
    /// Check if a factory is registered
    /// - Parameter type: Type identifier
    /// - Returns: true if factory is registered
    /// Thread-safe: Can be called concurrently
    public func isRegistered(type: String) -> Bool {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        return factories[type] != nil
    }
    
    /// Clear all registered factories (primarily for testing)
    /// Thread-safe: Can be called concurrently
    public func clear() {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        factories.removeAll()
    }
}

/// Factory errors
public enum FactoryError: Error {
    case typeNotRegistered(String)
    case creationFailed(String, Error)
    
    public var localizedDescription: String {
        switch self {
        case .typeNotRegistered(let type):
            return "Factory type '\(type)' is not registered"
        case .creationFailed(let type, let error):
            return "Failed to create '\(type)': \(error.localizedDescription)"
        }
    }
}

