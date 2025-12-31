//
//  Visitor.swift
//  DesignAlgorithmsKit
//
//  Visitor Pattern - Separate algorithms from object structure
//

import Foundation

/// A generic visitor interface.
/// Allows for separation of algorithms from the object structure they operate on.
///
/// - Result: The type of result produced by the visit.
public protocol Visitor {
    associatedtype Result
    
    /// Visits a visitable element.
    /// In a concrete implementation, this would likely dispatch to specific methods based on type.
    /// However, since Swift doesn't support double dispatch natively without manual casting or overloading
    /// in the `accept` method of the element, strict type safety often requires the Element to call a specific method on the Visitor.
    ///
    /// For a generic protocol, we define the entry point.
    func visit(_ element: Visitable) -> Result
}

/// An interface for elements that can be visited.
public protocol Visitable {
    /// Accepts a visitor.
    /// - Parameter visitor: The visitor instance.
    /// - Returns: The result of the visit.
    func accept<V: Visitor>(_ visitor: V) -> V.Result
}
