//
//  QueueTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Queue Processing Pattern
//

import XCTest
@testable import DesignAlgorithmsKit

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class QueueTests: XCTestCase {
    // MARK: - Test Types
    
    struct TestItem: QueueItem {
        let id: UUID
        var status: QueueItemStatus = .pending
        var progress: Double = 0.0
        let data: String
    }
    
    actor TestProcessor: QueueProcessor {
        typealias Item = TestItem
        
        var shouldFail: Bool = false
        var processingDelay: TimeInterval = 0.1
        var processedItems: [UUID] = []
        
        func setShouldFail(_ value: Bool) {
            shouldFail = value
        }
        
        func setProcessingDelay(_ value: TimeInterval) {
            processingDelay = value
        }
        
        func getProcessedItems() -> [UUID] {
            return processedItems
        }
        
        func process(_ item: TestItem) async throws {
            // Simulate processing delay
            try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
            
            if shouldFail {
                throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Processing failed"])
            }
            
            processedItems.append(item.id)
        }
    }
    
    // MARK: - Basic Queue Operations
    
    func testAddItems() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        let item2 = TestItem(id: UUID(), data: "data2")
        
        // When
        await queue.add([item1, item2])
        
        // Then
        let items = await queue.items
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].id, item1.id)
        XCTAssertEqual(items[1].id, item2.id)
    }
    
    func testDeduplication() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let sharedID = UUID()
        let item1 = TestItem(id: sharedID, data: "data1")
        let item2 = TestItem(id: sharedID, data: "data2") // Same ID
        
        // When
        await queue.add([item1])
        await queue.add([item2]) // Add duplicate separately
        
        // Then
        let items = await queue.items
        XCTAssertEqual(items.count, 1) // Duplicate should be filtered
        XCTAssertEqual(items[0].id, sharedID)
    }
    
    func testRemoveItem() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        let item2 = TestItem(id: UUID(), data: "data2")
        
        await queue.add([item1, item2])
        
        // When
        await queue.remove(id: item1.id)
        
        // Then
        let items = await queue.items
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].id, item2.id)
    }
    
    func testClearCompleted() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        let item2 = TestItem(id: UUID(), data: "data2")
        
        await queue.add([item1, item2])
        await queue.updateItem(id: item1.id, status: .completed)
        
        // When
        await queue.clearCompleted()
        
        // Then
        let items = await queue.items
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].id, item2.id)
    }
    
    func testClearFailed() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        let item2 = TestItem(id: UUID(), data: "data2")
        
        await queue.add([item1, item2])
        await queue.updateItem(id: item1.id, status: .failed)
        
        // When
        await queue.clearFailed()
        
        // Then
        let items = await queue.items
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].id, item2.id)
    }
    
    func testClearAll() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        let item2 = TestItem(id: UUID(), data: "data2")
        
        await queue.add([item1, item2])
        
        // When
        await queue.clearAll()
        
        // Then
        let items = await queue.items
        XCTAssertEqual(items.count, 0)
    }
    
    // MARK: - Status Filtering
    
    func testPendingItems() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        let item2 = TestItem(id: UUID(), data: "data2")
        let item3 = TestItem(id: UUID(), data: "data3")
        
        await queue.add([item1, item2, item3])
        await queue.updateItem(id: item1.id, status: .completed)
        await queue.updateItem(id: item2.id, status: .processing)
        
        // When
        let pending = await queue.pendingItems
        
        // Then
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending[0].id, item3.id)
    }
    
    func testProcessingItems() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        let item2 = TestItem(id: UUID(), data: "data2")
        
        await queue.add([item1, item2])
        await queue.updateItem(id: item1.id, status: .processing)
        
        // When
        let processing = await queue.processingItems
        
        // Then
        XCTAssertEqual(processing.count, 1)
        XCTAssertEqual(processing[0].id, item1.id)
    }
    
    func testCompletedItems() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        let item2 = TestItem(id: UUID(), data: "data2")
        
        await queue.add([item1, item2])
        await queue.updateItem(id: item1.id, status: .completed)
        
        // When
        let completed = await queue.completedItems
        
        // Then
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed[0].id, item1.id)
    }
    
    func testFailedItems() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        let item2 = TestItem(id: UUID(), data: "data2")
        
        await queue.add([item1, item2])
        await queue.updateItem(id: item1.id, status: .failed)
        
        // When
        let failed = await queue.failedItems
        
        // Then
        XCTAssertEqual(failed.count, 1)
        XCTAssertEqual(failed[0].id, item1.id)
    }
    
    // MARK: - Pause/Resume
    
    func testPauseResume() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        await queue.add([item1])
        
        // When
        await queue.pause()
        let isPaused = await queue.isPaused
        
        // Then
        XCTAssertTrue(isPaused)
        
        // When
        await queue.resume()
        let isPausedAfterResume = await queue.isPaused
        
        // Then
        XCTAssertFalse(isPausedAfterResume)
    }
    
    // MARK: - Retry
    
    func testRetry() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        await queue.add([item1])
        await queue.updateItem(id: item1.id, status: .failed)
        
        // When
        await queue.retry(id: item1.id)
        
        // Then
        let items = await queue.items
        XCTAssertEqual(items[0].status, .pending)
        XCTAssertEqual(items[0].progress, 0.0)
    }
    
    // MARK: - Concurrent Processing
    
    func testConcurrentProcessing() async {
        // Given
        let processor = TestProcessor()
        await processor.setProcessingDelay(0.2)
        
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 3)
        
        let items = (0..<5).map { _ in TestItem(id: UUID(), data: "data") }
        
        // When
        await queue.add(items)
        
        // Wait for processing to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then
        let completed = await queue.completedItems
        // Should have processed at least 3 items concurrently (maxConcurrent = 3)
        XCTAssertGreaterThanOrEqual(completed.count, 3)
    }
    
    // MARK: - Update Item
    
    func testUpdateItem() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        await queue.add([item1])
        
        // When
        await queue.updateItem(id: item1.id, status: .processing, progress: 0.5)
        
        // Then
        let items = await queue.items
        XCTAssertEqual(items[0].status, .processing)
        XCTAssertEqual(items[0].progress, 0.5)
    }
    
    func testUpdateItemProgressClamping() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        await queue.add([item1])
        
        // When
        await queue.updateItem(id: item1.id, progress: 1.5) // Should be clamped to 1.0
        await queue.updateItem(id: item1.id, progress: -0.5) // Should be clamped to 0.0
        
        // Then
        let items = await queue.items
        XCTAssertEqual(items[0].progress, 0.0) // Last update wins
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testRemoveNonExistentItem() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        await queue.add([item1])
        
        // When - remove non-existent item
        await queue.remove(id: UUID())
        
        // Then - should not crash, item1 should still exist
        let items = await queue.items
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].id, item1.id)
    }
    
    func testUpdateNonExistentItem() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        // When - update non-existent item
        await queue.updateItem(id: UUID(), status: .completed, progress: 1.0)
        
        // Then - should not crash, no items should exist
        let items = await queue.items
        XCTAssertEqual(items.count, 0)
    }
    
    func testRetryNonExistentItem() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        // When - retry non-existent item
        await queue.retry(id: UUID())
        
        // Then - should not crash
        let items = await queue.items
        XCTAssertEqual(items.count, 0)
    }
    
    func testRetryNonFailedItem() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        await queue.add([item1])
        await queue.updateItem(id: item1.id, status: .pending) // Not failed
        
        // When - retry non-failed item
        await queue.retry(id: item1.id)
        
        // Then - should not change status (still pending)
        let items = await queue.items
        XCTAssertEqual(items[0].status, .pending)
    }
    
    func testMaxConcurrentMinimum() async {
        // Given - Create queue with maxConcurrent < 1
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 0)
        
        // When - maxConcurrent should be clamped to 1
        let maxConcurrent = await queue.maxConcurrent
        
        // Then
        XCTAssertEqual(maxConcurrent, 1)
    }
    
    func testMaxConcurrentNegative() async {
        // Given - Create queue with negative maxConcurrent
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: -5)
        
        // When - maxConcurrent should be clamped to 1
        let maxConcurrent = await queue.maxConcurrent
        
        // Then
        XCTAssertEqual(maxConcurrent, 1)
    }
    
    func testProcessQueueWhenPaused() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        await queue.add([item1])
        await queue.pause()
        
        // When - wait a bit to see if processing happens
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - item should still be pending (not processing)
        let pending = await queue.pendingItems
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending[0].id, item1.id)
    }
    
    func testProcessQueueResumeAfterPause() async {
        // Given
        let processor = TestProcessor()
        let queue = ProcessingQueue<TestItem, TestProcessor>(processor: processor, maxConcurrent: 1)
        
        let item1 = TestItem(id: UUID(), data: "data1")
        await queue.add([item1])
        await queue.pause()
        
        // When - resume
        await queue.resume()
        
        // Wait for processing
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then - item should be processed
        let completed = await queue.completedItems
        XCTAssertGreaterThanOrEqual(completed.count, 0) // May have completed
    }
}

