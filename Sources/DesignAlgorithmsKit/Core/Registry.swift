//
//  Registry.swift
//  DesignAlgorithmsKit
//
//  Registry Pattern - Centralized registration and discovery of extensible types
//

import Foundation

/// Protocol for types that can be registered in a registry
public protocol Registrable {
    /// Unique key for registration
    static var registrationKey: String { get }
}

/// Thread-safe registry for type registration and discovery
///
/// The registry pattern provides a centralized way to register and discover types
/// at runtime. This enables extensibility and plugin-like architectures.
///
/// ## Usage
///
/// ```swift
/// // Register a type
/// TypeRegistry.shared.register(MyType.self, key: "myType")
///
/// // Find registered type
/// if let type = TypeRegistry.shared.find(for: "myType") {
///     // Use type
/// }
/// ```
///
/// ## Thread Safety
///
/// All operations are thread-safe using NSLock for synchronization.
public final class TypeRegistry: @unchecked Sendable {
    /// Shared singleton instance (lazy initialization to avoid static initialization order issues)
    #if !os(WASI) && !arch(wasm32)
    // Protected by lock, so marked as nonisolated(unsafe) for concurrency safety
    nonisolated(unsafe) private static var _shared: TypeRegistry?
    nonisolated private static let lock = NSLock()
    #else
    // WASM: Single-threaded, no locking needed
    nonisolated(unsafe) private static var _shared: TypeRegistry?
    #endif
    
    /// Shared singleton instance (lazy)
    public static var shared: TypeRegistry {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        if _shared == nil {
            _shared = TypeRegistry()
        }
        return _shared!
    }
    
    #if !os(WASI) && !arch(wasm32)
    /// Lock for thread-safe access
    private let lock = NSLock()
    #endif
    
    /// Registered types (key -> type)
    private var registeredTypes: [String: Any.Type] = [:]
    
    private init() {
        // Private initializer for singleton
    }
    
    /// Register a type
    /// - Parameter type: The type to register
    /// - Parameter key: Optional custom key (defaults to type name)
    /// Thread-safe: Can be called concurrently
    public func register(_ type: Any.Type, key: String? = nil) {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        
        let registrationKey = key ?? String(describing: type)
        registeredTypes[registrationKey] = type
    }
    
    /// Register a type conforming to Registrable protocol
    /// - Parameter type: The registrable type
    /// Thread-safe: Can be called concurrently
    public func register<T: Registrable>(_ type: T.Type) {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        let key = T.registrationKey
        registeredTypes[key] = type
    }
    
    /// Find a registered type
    /// - Parameter key: Key to look up
    /// - Returns: Registered type, or nil if not found
    /// Thread-safe: Can be called concurrently
    public func find(for key: String) -> Any.Type? {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        return registeredTypes[key]
    }
    
    /// Get all registered types
    /// - Returns: Dictionary of all registered types
    /// Thread-safe: Can be called concurrently
    public func allTypes() -> [String: Any.Type] {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        return registeredTypes
    }
    
    /// Check if a type is registered
    /// - Parameter key: Key to check
    /// - Returns: true if type is registered
    /// Thread-safe: Can be called concurrently
    public func isRegistered(key: String) -> Bool {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        return registeredTypes[key] != nil
    }
    
    /// Clear all registered types (primarily for testing)
    /// Thread-safe: Can be called concurrently
    public func clear() {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        registeredTypes.removeAll()
    }
}

/// A thread-safe generic registry for storing values by key.
///
/// This class provides a base implementation for the Registry pattern using `ThreadSafe` storage.
/// It is suitable for managing collections of objects, strategies, or specifications.
///
/// ## Usage
/// ```swift
/// class MyRegistry: Registry<String, MyObject> { ... }
/// ```
open class Registry<Key: Hashable, Value>: @unchecked Sendable {
    /// Thread-safe storage
    private let storage: ThreadSafe<[Key: Value]>
    
    /// Initialize registry
    public init() {
        self.storage = ThreadSafe([:])
    }
    
    /// Register a value
    /// - Parameters:
    ///   - value: Value to register
    ///   - key: Key to register under
    open func register(_ value: Value, for key: Key) {
        storage.write { $0[key] = value }
    }
    
    /// Retrieve a value
    /// - Parameter key: Key to lookup
    /// - Returns: Value if found, nil otherwise
    open func get(_ key: Key) -> Value? {
        storage.read { $0[key] }
    }
    
    /// Unregister a key
    /// - Parameter key: Key to remove
    open func unregister(_ key: Key) {
        storage.write { $0.removeValue(forKey: key) }
    }
    
    /// Get all values
    /// - Returns: Array of all registered values
    open func all() -> [Value] {
        storage.read { Array($0.values) }
    }
    
    /// Clear all registrations
    open func removeAll() {
        storage.write { $0.removeAll() }
    }
    
    /// Lookup value (subscript support)
    public subscript(key: Key) -> Value? {
        get { get(key) }
        set {
            if let value = newValue {
                register(value, for: key)
            } else {
                unregister(key)
            }
        }
    }
}

