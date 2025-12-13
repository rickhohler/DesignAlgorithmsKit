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

/// Singleton errors
public enum SingletonError: Error {
    case createSharedNotImplemented(String)
    
    public var localizedDescription: String {
        switch self {
        case .createSharedNotImplemented(let typeName):
            return "Subclass '\(typeName)' must implement createShared()"
        }
    }
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
    #if !os(WASI) && !arch(wasm32)
    /// Lock for thread-safe initialization
    private static let lock = NSRecursiveLock()
    #endif
    
    /// Type-specific instance storage keyed by type identifier
    nonisolated(unsafe) private static var instances: [ObjectIdentifier: Any] = [:]
    
    /// Initialize singleton (must be called from subclass)
    public init() {
        // Base initialization
    }
    
    /// Create shared instance (must be implemented by subclass)
    /// - Returns: Shared singleton instance
    /// - Throws: SingletonError if not implemented by subclass
    open class func createShared() throws -> Self {
        let typeName = String(describing: Self.self)
        throw SingletonError.createSharedNotImplemented(typeName)
    }
    
    /// Shared singleton instance (lazy, thread-safe)
    /// - Note: This will call `fatalError()` if `createShared()` is not implemented,
    ///   as this indicates a programming error that should fail fast.
    public static var shared: Self {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        
        let typeID = ObjectIdentifier(Self.self)
        
        if let existing = instances[typeID] as? Self {
            return existing
        }
        
        do {
            let newInstance = try createShared()
            instances[typeID] = newInstance
            return newInstance
        } catch {
            // This is a programming error - fail fast
            // Note: This fatalError path cannot be tested in unit tests as it would crash the test suite.
            // The error path is testable via createShared() directly, but the fatalError here is intentional
            // for production code to fail fast on programming errors.
            fatalError(error.localizedDescription) // swiftlint:disable:this fatal_error_message
        }
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

