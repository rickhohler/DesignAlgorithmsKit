//
//  Queue.swift
//  DesignAlgorithmsKit
//
//  Queue Processing Pattern - Concurrent queue management with status tracking, progress, and retry
//

import Foundation

/// Status of a queue item
public enum QueueItemStatus: Sendable {
    /// Item is pending processing
    case pending
    /// Item is currently being processed
    case processing
    /// Item completed successfully
    case completed
    /// Item failed processing
    case failed
}

/// Protocol for items that can be processed in a queue
///
/// Queue items must have a unique identifier and track their status and progress.
public protocol QueueItem: Sendable {
    /// Unique identifier for the item
    associatedtype ID: Hashable & Sendable
    /// Unique identifier for this item
    var id: ID { get }
    /// Current status of the item
    var status: QueueItemStatus { get set }
    /// Progress of processing (0.0 to 1.0)
    var progress: Double { get set }
}

/// Protocol for processing queue items
///
/// Implementations of this protocol define how items are processed.
public protocol QueueProcessor: Sendable {
    /// Type of item being processed
    associatedtype Item: QueueItem
    /// Process a single item
    /// - Parameter item: Item to process
    /// - Throws: Error if processing fails
    func process(_ item: Item) async throws
}

/// Concurrent processing queue with status tracking, progress monitoring, and retry support
///
/// The queue processing pattern provides a sophisticated queue management system for
/// processing items concurrently with configurable limits, status tracking, progress
/// monitoring, pause/resume functionality, and retry mechanisms.
///
/// ## Features
///
/// - **Concurrent Processing**: Process multiple items concurrently with configurable limit
/// - **Status Tracking**: Track pending, processing, completed, and failed items
/// - **Progress Monitoring**: Track progress (0.0 to 1.0) for each item
/// - **Retry Support**: Retry failed items automatically or manually
/// - **Pause/Resume**: Pause and resume queue processing
/// - **Cancellation**: Cancel individual items or all processing
/// - **Deduplication**: Prevent duplicate items by identifier
///
/// ## Usage
///
/// ```swift
/// // Define your item type
/// struct MyItem: QueueItem {
///     let id: UUID
///     var status: QueueItemStatus = .pending
///     var progress: Double = 0.0
///     let data: Data
/// }
///
/// // Define your processor
/// struct MyProcessor: QueueProcessor {
///     typealias Item = MyItem
///     
///     func process(_ item: MyItem) async throws {
///         // Process the item
///         // Update progress if needed
///     }
/// }
///
/// // Create and use the queue
/// let queue = ProcessingQueue<MyItem, MyProcessor>(
///     processor: MyProcessor(),
///     maxConcurrent: 3
/// )
///
/// // Add items
/// let items = [MyItem(id: UUID(), data: data1), MyItem(id: UUID(), data: data2)]
/// await queue.add(items)
///
/// // Monitor progress
/// let pending = await queue.pendingItems
/// let processing = await queue.processingItems
/// let completed = await queue.completedItems
/// let failed = await queue.failedItems
///
/// // Retry failed items
/// if let failedItem = await queue.failedItems.first {
///     await queue.retry(id: failedItem.id)
/// }
///
/// // Pause/resume
/// await queue.pause()
/// await queue.resume()
/// ```
///
/// ## Thread Safety
///
/// All operations are thread-safe using an actor for synchronization.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public actor ProcessingQueue<Item: QueueItem, Processor: QueueProcessor> where Processor.Item == Item {
    /// Maximum number of concurrent processing tasks
    public var maxConcurrent: Int {
        didSet {
            // Ensure maxConcurrent is at least 1
            if maxConcurrent < 1 {
                maxConcurrent = 1
            }
        }
    }
    
    /// All items in the queue
    public private(set) var items: [Item] = []
    
    /// Processor for handling items
    private let processor: Processor
    
    /// Whether processing is paused
    public private(set) var isPaused: Bool = false
    
    /// Active processing tasks (item ID -> task)
    private var processingTasks: [Item.ID: Task<Void, Never>] = [:]
    
    /// Create a new processing queue
    /// - Parameters:
    ///   - processor: Processor for handling items
    ///   - maxConcurrent: Maximum number of concurrent processing tasks (default: 3)
    public init(processor: Processor, maxConcurrent: Int = 3) {
        self.processor = processor
        self.maxConcurrent = max(maxConcurrent, 1)
    }
    
    /// Pending items (status == .pending)
    public var pendingItems: [Item] {
        items.filter { $0.status == .pending }
    }
    
    /// Currently processing items (status == .processing)
    public var processingItems: [Item] {
        items.filter { $0.status == .processing }
    }
    
    /// Completed items (status == .completed)
    public var completedItems: [Item] {
        items.filter { $0.status == .completed }
    }
    
    /// Failed items (status == .failed)
    public var failedItems: [Item] {
        items.filter { $0.status == .failed }
    }
    
    /// Add items to the queue
    /// - Parameter newItems: Items to add
    /// - Note: Duplicate items (by ID) are automatically filtered out
    public func add(_ newItems: [Item]) {
        let existingIDs = Set(items.map { $0.id })
        let uniqueItems = newItems.filter { !existingIDs.contains($0.id) }
        items.append(contentsOf: uniqueItems)
        
        // Start processing if not paused
        if !isPaused {
            Task {
                await processQueue()
            }
        }
    }
    
    /// Remove an item from the queue
    /// - Parameter id: ID of the item to remove
    public func remove(id: Item.ID) {
        // Cancel task if processing
        if let task = processingTasks[id] {
            task.cancel()
            processingTasks.removeValue(forKey: id)
        }
        
        items.removeAll { $0.id == id }
    }
    
    /// Remove all completed items
    public func clearCompleted() {
        items.removeAll { $0.status == .completed }
    }
    
    /// Remove all failed items
    public func clearFailed() {
        items.removeAll { $0.status == .failed }
    }
    
    /// Remove all items from the queue
    public func clearAll() {
        // Cancel all processing tasks
        for task in processingTasks.values {
            task.cancel()
        }
        processingTasks.removeAll()
        items.removeAll()
    }
    
    /// Pause queue processing
    public func pause() {
        isPaused = true
    }
    
    /// Resume queue processing
    public func resume() {
        isPaused = false
        Task {
            await processQueue()
        }
    }
    
    /// Retry a failed item
    /// - Parameter id: ID of the failed item to retry
    public func retry(id: Item.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              items[index].status == .failed else {
            return
        }
        
        items[index].status = .pending
        items[index].progress = 0.0
        
        if !isPaused {
            Task {
                await processQueue()
            }
        }
    }
    
    /// Update item status and progress
    /// - Parameters:
    ///   - id: Item ID
    ///   - status: New status (optional)
    ///   - progress: New progress (0.0 to 1.0, optional)
    public func updateItem(
        id: Item.ID,
        status: QueueItemStatus? = nil,
        progress: Double? = nil
    ) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        if let status = status {
            items[index].status = status
        }
        
        if let progress = progress {
            items[index].progress = max(0.0, min(1.0, progress))
        }
    }
    
    /// Process the queue (internal method)
    private func processQueue() async {
        guard !isPaused else { return }
        
        let pending = items.filter { $0.status == .pending }
        let processing = items.filter { $0.status == .processing }
        let availableSlots = maxConcurrent - processing.count
        
        guard availableSlots > 0 else {
            return
        }
        
        let toProcess = Array(pending.prefix(availableSlots))
        
        for item in toProcess {
            processItem(item)
        }
    }
    
    /// Process a single item (internal method)
    private func processItem(_ item: Item) {
        let itemID = item.id
        let task = Task { [weak self] in
            guard let self = self else { return }
            do {
                // Update status to processing
                // Note: await is required for actor isolation, even though updateItem is synchronous
                // swiftlint:disable:next no_async_await_expression
                await self.updateItem(id: itemID, status: .processing, progress: 0.0)
                
                // Get current item (may have been updated)
                // Note: await is required for actor isolation when accessing actor-isolated property
                // swiftlint:disable:next no_async_await_expression
                let currentItem = await self.items.first(where: { $0.id == itemID })
                guard let itemToProcess = currentItem else {
                    // Item was removed
                    return
                }
                
                // Process the item
                try await processor.process(itemToProcess)
                
                // Mark as completed
                // swiftlint:disable:next no_async_await_expression
                await self.updateItem(id: itemID, status: .completed, progress: 1.0)
                
                // Continue processing queue
                await self.processQueue()
                
            } catch {
                // Mark as failed
                // swiftlint:disable:next no_async_await_expression
                await self.updateItem(id: itemID, status: .failed, progress: 0.0)
                
                // Continue processing queue
                await self.processQueue()
            }
        }
        
        processingTasks[item.id] = task
    }
}

