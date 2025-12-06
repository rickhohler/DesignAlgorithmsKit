//
//  Observer.swift
//  DesignAlgorithmsKit
//
//  Observer Pattern - Define a one-to-many dependency between objects
//

import Foundation

/// Protocol for observable subjects
///
/// Subjects maintain a list of observers and notify them of state changes.
public protocol Observable {
    /// Add an observer
    /// - Parameter observer: Observer to add
    func addObserver(_ observer: any Observer)
    
    /// Remove an observer
    /// - Parameter observer: Observer to remove
    func removeObserver(_ observer: any Observer)
    
    /// Notify all observers of an event
    /// - Parameter event: Event to notify
    func notifyObservers(event: Any)
}

/// Protocol for observers
///
/// Observers are notified when subjects they observe change state.
public protocol Observer: AnyObject {
    /// Handle notification from observable
    /// - Parameters:
    ///   - observable: Observable that sent notification
    ///   - event: Event data
    func didReceiveNotification(from observable: any Observable, event: Any)
}

/// Base observable implementation
///
/// Provides a thread-safe implementation of the observer pattern.
///
/// ## Usage
///
/// ```swift
/// class MyObservable: BaseObservable {
///     func doSomething() {
///         // Perform operation
///         notifyObservers(event: "somethingHappened")
///     }
/// }
///
/// class MyObserver: Observer {
///     func didReceiveNotification(from observable: any Observable, event: Any) {
///         print("Received event: \(event)")
///     }
/// }
///
/// // Usage
/// let observable = MyObservable()
/// let observer = MyObserver()
/// observable.addObserver(observer)
/// observable.doSomething()
/// ```
open class BaseObservable: Observable {
    #if !os(WASI) && !arch(wasm32)
    /// Lock for thread-safe access
    private let lock = NSLock()
    #endif
    
    /// Weak references to observers
    private var observers: [WeakObserver] = []
    
    public init() {}
    
    public func addObserver(_ observer: any Observer) {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        
        // Remove any nil weak references
        observers = observers.filter { $0.observer != nil }
        
        // Add observer if not already present
        if !observers.contains(where: { $0.observer === observer }) {
            observers.append(WeakObserver(observer: observer))
        }
    }
    
    public func removeObserver(_ observer: any Observer) {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        defer { lock.unlock() }
        #endif
        observers.removeAll { $0.observer === observer }
    }
    
    public func notifyObservers(event: Any) {
        #if !os(WASI) && !arch(wasm32)
        lock.lock()
        let currentObservers = observers.compactMap { $0.observer }
        lock.unlock()
        #else
        let currentObservers = observers.compactMap { $0.observer }
        #endif
        
        for observer in currentObservers {
            observer.didReceiveNotification(from: self, event: event)
        }
    }
}

/// Weak reference wrapper for observers
private struct WeakObserver {
    weak var observer: (any Observer)?
}

