//
//  Merger.swift
//  DesignAlgorithmsKit
//
//  Merging/Upsert Pattern - Configurable merge strategies for conflict resolution
//

import Foundation

/// Protocol for types that can be merged
///
/// Types conforming to this protocol can be merged with conflict resolution strategies.
public protocol Mergeable: Sendable {
    /// Unique identifier for the item
    associatedtype ID: Hashable & Sendable
    /// Unique identifier for this item
    var id: ID { get }
}

/// Strategy for merging items when conflicts occur
public enum MergeStrategy: Sendable {
    /// Prefer existing values (keep existing, ignore new)
    case preferExisting
    /// Prefer new values (replace existing with new)
    case preferNew
    /// Combine values (merge dictionaries, arrays, etc.)
    case combine
    /// Custom merge function
    case custom(@Sendable (_ existing: any Mergeable, _ new: any Mergeable) -> any Mergeable)
}

/// Protocol for merging items with configurable strategies
///
/// Implementations of this protocol define how items are found and merged.
public protocol Merger: Sendable {
    /// Type of item being merged
    associatedtype Item: Mergeable
    /// Find an existing item by identifier
    /// - Parameter id: Identifier to search for
    /// - Returns: Existing item if found, nil otherwise
    func findExisting(by id: Item.ID) async -> Item?
    /// Merge existing item with new item using strategy
    /// - Parameters:
    ///   - existing: Existing item
    ///   - new: New item
    ///   - strategy: Merge strategy to use
    /// - Returns: Merged item
    func merge(existing: Item, with new: Item, strategy: MergeStrategy) -> Item
    /// Upsert an item (update if exists, insert if not)
    /// - Parameters:
    ///   - item: Item to upsert
    ///   - strategy: Merge strategy to use if item exists
    /// - Returns: Upserted item (may be merged with existing)
    func upsert(_ item: Item, strategy: MergeStrategy) async throws -> Item
}

/// Default merger implementation
///
/// Provides a base implementation of the merger protocol with default merge strategies.
/// Subclasses can override methods to customize behavior.
///
/// ## Usage
///
/// ```swift
/// struct MyItem: Mergeable {
///     let id: UUID
///     var name: String
///     var metadata: [String: String]
/// }
///
/// class MyMerger: DefaultMerger<MyItem> {
///     override func findExisting(by id: UUID) async -> MyItem? {
///         // Find in your storage
///         return storage.find(id: id)
///     }
///
///     override func upsert(_ item: MyItem, strategy: MergeStrategy) async throws -> MyItem {
///         if let existing = await findExisting(by: item.id) {
///             let merged = merge(existing: existing, with: item, strategy: strategy)
///             // Update in storage
///             return merged
///         } else {
///             // Insert in storage
///             return item
///         }
///     }
/// }
/// ```
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class DefaultMerger<Item: Mergeable>: @unchecked Sendable, Merger {
    public init() {}
    
    /// Find an existing item by identifier
    /// - Parameter id: Identifier to search for
    /// - Returns: Existing item if found, nil otherwise
    /// - Note: Subclasses must override this method
    open func findExisting(by id: Item.ID) async -> Item? {
        fatalError("Subclasses must override findExisting(by:)")
    }
    
    /// Merge existing item with new item using strategy
    /// - Parameters:
    ///   - existing: Existing item
    ///   - new: New item
    ///   - strategy: Merge strategy to use
    /// - Returns: Merged item
    /// - Note: Default implementation handles basic strategies. Subclasses can override for custom behavior.
    open func merge(existing: Item, with new: Item, strategy: MergeStrategy) -> Item {
        switch strategy {
        case .preferExisting:
            return existing
        case .preferNew:
            return new
        case .combine:
            // Default combine strategy: prefer existing, but this should be overridden
            // for types that can actually combine (e.g., dictionaries, arrays)
            return existing
        case .custom(let mergeFunction):
            return mergeFunction(existing, new) as! Item
        }
    }
    
    /// Upsert an item (update if exists, insert if not)
    /// - Parameters:
    ///   - item: Item to upsert
    ///   - strategy: Merge strategy to use if item exists
    /// - Returns: Upserted item (may be merged with existing)
    /// - Note: Subclasses must override this method
    open func upsert(_ item: Item, strategy: MergeStrategy) async throws -> Item {
        if let existing = await findExisting(by: item.id) {
            return merge(existing: existing, with: item, strategy: strategy)
        } else {
            return item
        }
    }
}

