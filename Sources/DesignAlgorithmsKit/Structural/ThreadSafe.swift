//
//  ThreadSafe.swift
//  DesignAlgorithmsKit
//
//  Thread-Safe Wrapper Pattern
//
//  A generic wrapper that provides thread check/locking around a value.
//

import Foundation

/// A thread-safe wrapper around a value.
/// Uses a lock to ensure atomic access to the wrapped value.
///
/// ## Usage
/// ```swift
/// // Thread-safe array
/// let safeArray = ThreadSafe<[String]>([])
///
/// // Thread-safe read
/// let value = safeArray.read { $0.first }
///
/// // Thread-safe write
/// safeArray.write { $0.append("New Item") }
/// ```
public final class ThreadSafe<Value>: @unchecked Sendable {
    private var value: Value
    
    #if !os(WASI) && !arch(wasm32)
    private let lock = NSRecursiveLock()
    #endif
    
    /// Initialize with a value
    /// - Parameter value: Initial value
    public init(_ value: Value) {
        self.value = value
    }
    
    /// Read the value safely
    /// - Parameter block: Closure to read the value
    /// - Returns: Result of closure
    public func read<Result>(_ block: (Value) throws -> Result) rethrows -> Result {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        return try block(value)
    }
    
    /// Mutate the value safely
    /// - Parameter block: Closure to mutate the value
    /// - Returns: Result of closure
    public func write<Result>(_ block: (inout Value) throws -> Result) rethrows -> Result {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        return try block(&value)
    }
    
    /// Get the raw value (copy). Only works for value types.
    /// Thread-safe.
    public var rawValue: Value {
        get {
            #if !os(WASI) && !arch(wasm32)
            lock.lock()
            defer { lock.unlock() }
            #endif
            return value
        }
        set {
            #if !os(WASI) && !arch(wasm32)
            lock.lock()
            defer { lock.unlock() }
            #endif
            value = newValue
        }
    }
}
