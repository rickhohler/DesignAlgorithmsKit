//
//  Singleton.swift
//  DesignAlgorithmsKit
//
//  Singleton Pattern - Ensure a class has only one instance and provide global access
//

import Foundation

/// Protocol for singleton types
public protocol Singleton {
    /// Shared singleton instance
    static var shared: Self { get }
}

/// Thread-safe singleton base class
///
/// Provides a base implementation for singleton pattern with thread-safe
/// lazy initialization. Prevents static initialization order issues.
///
/// ## Usage
///
/// ```swift
/// class MySingleton: ThreadSafeSingleton {
///     private init() {
///         super.init()
///         // Initialize singleton
///     }
///
///     func doSomething() {
///         // Singleton functionality
///     }
/// }
///
/// // Usage
/// MySingleton.shared.doSomething()
/// ```
open class ThreadSafeSingleton {
    /// Lock for thread-safe initialization
    private static let lock = NSLock()
    
    /// Type-specific instance storage keyed by type identifier
    private static var instances: [ObjectIdentifier: Any] = [:]
    
    /// Initialize singleton (must be called from subclass)
    public init() {
        // Base initialization
    }
    
    /// Create shared instance (must be implemented by subclass)
    /// - Returns: Shared singleton instance
    open class func createShared() -> Self {
        fatalError("Subclass must implement createShared()")
    }
    
    /// Shared singleton instance (lazy, thread-safe)
    public static var shared: Self {
        lock.lock()
        defer { lock.unlock() }
        
        let typeID = ObjectIdentifier(Self.self)
        
        if let existing = instances[typeID] as? Self {
            return existing
        }
        
        let newInstance = createShared()
        instances[typeID] = newInstance
        return newInstance
    }
}

/// Actor-based singleton for Swift concurrency
///
/// Provides a singleton pattern using Swift actors for concurrency safety.
/// Use this for singletons that need to work with async/await.
///
/// ## Usage
///
/// ```swift
/// actor MyActorSingleton: ActorSingleton {
///     private init() {
///         // Initialize actor singleton
///     }
///
///     func doSomething() async {
///         // Actor functionality
///     }
/// }
///
/// // Usage
/// await MyActorSingleton.shared.doSomething()
/// ```
public protocol ActorSingleton {
    /// Shared singleton instance
    static var shared: Self { get }
}

