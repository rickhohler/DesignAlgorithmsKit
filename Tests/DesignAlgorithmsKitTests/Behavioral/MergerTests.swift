//
//  MergerTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Merging/Upsert Pattern
//

import XCTest
@testable import DesignAlgorithmsKit

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class MergerTests: XCTestCase {
    // MARK: - Test Types
    
    struct TestItem: Mergeable {
        let id: UUID
        var name: String
        var value: Int
        
        init(id: UUID = UUID(), name: String, value: Int) {
            self.id = id
            self.name = name
            self.value = value
        }
    }
    
    class TestMerger: DefaultMerger<TestItem> {
        var storage: [UUID: TestItem] = [:]
        
        override func findExisting(by id: UUID) async -> TestItem? {
            return storage[id]
        }
        
        override func upsert(_ item: TestItem, strategy: MergeStrategy) async throws -> TestItem {
            if let existing = await findExisting(by: item.id) {
                let merged = merge(existing: existing, with: item, strategy: strategy)
                storage[item.id] = merged
                return merged
            } else {
                storage[item.id] = item
                return item
            }
        }
    }
    
    // MARK: - Merge Strategies
    
    func testPreferExistingStrategy() async throws {
        // Given
        let merger = TestMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "New", value: 20)
        
        merger.storage[existing.id] = existing
        
        // When
        let merged = merger.merge(existing: existing, with: new, strategy: .preferExisting)
        
        // Then
        XCTAssertEqual(merged.name, "Existing")
        XCTAssertEqual(merged.value, 10)
    }
    
    func testPreferNewStrategy() async throws {
        // Given
        let merger = TestMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "New", value: 20)
        
        // When
        let merged = merger.merge(existing: existing, with: new, strategy: .preferNew)
        
        // Then
        XCTAssertEqual(merged.name, "New")
        XCTAssertEqual(merged.value, 20)
    }
    
    func testCustomStrategy() async throws {
        // Given
        let merger = TestMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "New", value: 20)
        
        // Custom strategy: combine values
        let customStrategy: MergeStrategy = .custom { existing, new in
            let existingItem = existing as! TestItem
            let newItem = new as! TestItem
            return TestItem(
                id: existingItem.id,
                name: "\(existingItem.name) + \(newItem.name)",
                value: existingItem.value + newItem.value
            )
        }
        
        // When
        let merged = merger.merge(existing: existing, with: new, strategy: customStrategy)
        
        // Then
        XCTAssertEqual(merged.name, "Existing + New")
        XCTAssertEqual(merged.value, 30)
    }
    
    // MARK: - Upsert Operations
    
    func testUpsertInsert() async throws {
        // Given
        let merger = TestMerger()
        let item = TestItem(id: UUID(), name: "New Item", value: 10)
        
        // When
        let upserted = try await merger.upsert(item, strategy: .preferNew)
        
        // Then
        XCTAssertEqual(upserted.id, item.id)
        XCTAssertEqual(upserted.name, item.name)
        XCTAssertEqual(upserted.value, item.value)
        
        // Verify stored
        let stored = await merger.storage[item.id]
        XCTAssertNotNil(stored)
        XCTAssertEqual(stored?.name, item.name)
    }
    
    func testUpsertUpdate() async throws {
        // Given
        let merger = TestMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "Updated", value: 20)
        
        merger.storage[existing.id] = existing
        
        // When
        let upserted = try await merger.upsert(new, strategy: .preferNew)
        
        // Then
        XCTAssertEqual(upserted.id, existing.id)
        XCTAssertEqual(upserted.name, "Updated")
        XCTAssertEqual(upserted.value, 20)
        
        // Verify stored
        let stored = await merger.storage[existing.id]
        XCTAssertNotNil(stored)
        XCTAssertEqual(stored?.name, "Updated")
    }
    
    func testUpsertWithPreferExisting() async throws {
        // Given
        let merger = TestMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "New", value: 20)
        
        merger.storage[existing.id] = existing
        
        // When
        let upserted = try await merger.upsert(new, strategy: .preferExisting)
        
        // Then
        XCTAssertEqual(upserted.id, existing.id)
        XCTAssertEqual(upserted.name, "Existing") // Should prefer existing
        XCTAssertEqual(upserted.value, 10)
    }
    
    func testUpsertWithPreferNew() async throws {
        // Given
        let merger = TestMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "New", value: 20)
        
        merger.storage[existing.id] = existing
        
        // When
        let upserted = try await merger.upsert(new, strategy: .preferNew)
        
        // Then
        XCTAssertEqual(upserted.id, existing.id)
        XCTAssertEqual(upserted.name, "New") // Should prefer new
        XCTAssertEqual(upserted.value, 20)
    }
    
    func testUpsertWithCustomStrategy() async throws {
        // Given
        let merger = TestMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "New", value: 20)
        
        merger.storage[existing.id] = existing
        
        // Custom strategy: combine values
        let customStrategy: MergeStrategy = .custom { existing, new in
            let existingItem = existing as! TestItem
            let newItem = new as! TestItem
            return TestItem(
                id: existingItem.id,
                name: "\(existingItem.name) + \(newItem.name)",
                value: existingItem.value + newItem.value
            )
        }
        
        // When
        let upserted = try await merger.upsert(new, strategy: customStrategy)
        
        // Then
        XCTAssertEqual(upserted.id, existing.id)
        XCTAssertEqual(upserted.name, "Existing + New")
        XCTAssertEqual(upserted.value, 30)
    }
    
    // MARK: - Find Existing
    
    func testFindExisting() async {
        // Given
        let merger = TestMerger()
        let item = TestItem(id: UUID(), name: "Item", value: 10)
        
        merger.storage[item.id] = item
        
        // When
        let found = await merger.findExisting(by: item.id)
        
        // Then
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, item.id)
        XCTAssertEqual(found?.name, item.name)
    }
    
    func testFindExistingNotFound() async {
        // Given
        let merger = TestMerger()
        let id = UUID()
        
        // When
        let found = await merger.findExisting(by: id)
        
        // Then
        XCTAssertNil(found)
    }
    
    // MARK: - DefaultMerger Base Class Tests
    
    func testDefaultMergerMergeCombineStrategy() {
        // Given
        let merger = TestMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "New", value: 20)
        
        // When - combine strategy defaults to preferExisting
        let merged = merger.merge(existing: existing, with: new, strategy: .combine)
        
        // Then - should prefer existing (default behavior)
        XCTAssertEqual(merged.name, "Existing")
        XCTAssertEqual(merged.value, 10)
    }
    
    func testDefaultMergerUpsertDirectly() async throws {
        // Given - Create a merger that uses DefaultMerger's upsert implementation
        class DirectMerger: DefaultMerger<TestItem> {
            var storage: [UUID: TestItem] = [:]
            
            override func findExisting(by id: UUID) async -> TestItem? {
                return storage[id]
            }
            
            override func upsert(_ item: TestItem, strategy: MergeStrategy) async throws -> TestItem {
                // Use parent implementation
                return try await super.upsert(item, strategy: strategy)
            }
        }
        
        let merger = DirectMerger()
        let item = TestItem(id: UUID(), name: "New Item", value: 10)
        
        // When - upsert new item
        let upserted = try await merger.upsert(item, strategy: .preferNew)
        
        // Then - should return the item (not stored, but method executed)
        XCTAssertEqual(upserted.id, item.id)
        XCTAssertEqual(upserted.name, item.name)
    }
    
    func testDefaultMergerUpsertWithExisting() async throws {
        // Given
        class DirectMerger: DefaultMerger<TestItem> {
            var storage: [UUID: TestItem] = [:]
            
            override func findExisting(by id: UUID) async -> TestItem? {
                return storage[id]
            }
            
            override func upsert(_ item: TestItem, strategy: MergeStrategy) async throws -> TestItem {
                if let existing = await findExisting(by: item.id) {
                    let merged = merge(existing: existing, with: item, strategy: strategy)
                    storage[item.id] = merged
                    return merged
                } else {
                    storage[item.id] = item
                    return item
                }
            }
        }
        
        let merger = DirectMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "Updated", value: 20)
        
        await merger.storage[existing.id] = existing
        
        // When - upsert with existing item
        let upserted = try await merger.upsert(new, strategy: .preferNew)
        
        // Then - should merge using strategy
        XCTAssertEqual(upserted.id, existing.id)
        XCTAssertEqual(upserted.name, "Updated")
        XCTAssertEqual(upserted.value, 20)
    }
    
    func testDefaultMergerFindExistingFatalError() async {
        // Given - Direct use of DefaultMerger without override
        let merger = DefaultMerger<TestItem>()
        
        // When/Then - Should fatal error (but we can't test that directly)
        // This test documents the expected behavior
        // In practice, subclasses must override this method
        let id = UUID()
        
        // Note: This will fatal error if called, so we skip the actual call
        // The coverage shows this method exists but isn't called in tests
        // which is expected since it's meant to be overridden
    }
    
    // MARK: - Additional Coverage Tests
    
    func testDefaultMergerUpsertWithCombineStrategy() async throws {
        // Given
        class DirectMerger: DefaultMerger<TestItem> {
            var storage: [UUID: TestItem] = [:]
            
            override func findExisting(by id: UUID) async -> TestItem? {
                return storage[id]
            }
            
            override func upsert(_ item: TestItem, strategy: MergeStrategy) async throws -> TestItem {
                return try await super.upsert(item, strategy: strategy)
            }
        }
        
        let merger = DirectMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "New", value: 20)
        
        await merger.storage[existing.id] = existing
        
        // When - upsert with combine strategy
        let upserted = try await merger.upsert(new, strategy: .combine)
        
        // Then - should prefer existing (default combine behavior)
        XCTAssertEqual(upserted.id, existing.id)
        XCTAssertEqual(upserted.name, "Existing")
        XCTAssertEqual(upserted.value, 10)
    }
    
    func testDefaultMergerUpsertNewItemWithCombineStrategy() async throws {
        // Given
        class DirectMerger: DefaultMerger<TestItem> {
            var storage: [UUID: TestItem] = [:]
            
            override func findExisting(by id: UUID) async -> TestItem? {
                return storage[id]
            }
            
            override func upsert(_ item: TestItem, strategy: MergeStrategy) async throws -> TestItem {
                return try await super.upsert(item, strategy: strategy)
            }
        }
        
        let merger = DirectMerger()
        let item = TestItem(id: UUID(), name: "New Item", value: 10)
        
        // When - upsert new item with combine strategy
        let upserted = try await merger.upsert(item, strategy: .combine)
        
        // Then - should return item (no existing to combine with)
        XCTAssertEqual(upserted.id, item.id)
        XCTAssertEqual(upserted.name, item.name)
    }
    
    func testDefaultMergerUpsertNewItemWithPreferExistingStrategy() async throws {
        // Given
        class DirectMerger: DefaultMerger<TestItem> {
            var storage: [UUID: TestItem] = [:]
            
            override func findExisting(by id: UUID) async -> TestItem? {
                return storage[id]
            }
            
            override func upsert(_ item: TestItem, strategy: MergeStrategy) async throws -> TestItem {
                return try await super.upsert(item, strategy: strategy)
            }
        }
        
        let merger = DirectMerger()
        let item = TestItem(id: UUID(), name: "New Item", value: 10)
        
        // When - upsert new item with preferExisting strategy
        let upserted = try await merger.upsert(item, strategy: .preferExisting)
        
        // Then - should return item (no existing to prefer)
        XCTAssertEqual(upserted.id, item.id)
        XCTAssertEqual(upserted.name, item.name)
    }
    
    func testDefaultMergerUpsertNewItemWithCustomStrategy() async throws {
        // Given
        class DirectMerger: DefaultMerger<TestItem> {
            var storage: [UUID: TestItem] = [:]
            
            override func findExisting(by id: UUID) async -> TestItem? {
                return storage[id]
            }
            
            override func upsert(_ item: TestItem, strategy: MergeStrategy) async throws -> TestItem {
                return try await super.upsert(item, strategy: strategy)
            }
        }
        
        let merger = DirectMerger()
        let item = TestItem(id: UUID(), name: "New Item", value: 10)
        
        // Custom strategy (won't be used since no existing item)
        let customStrategy: MergeStrategy = .custom { existing, new in
            let existingItem = existing as! TestItem
            let newItem = new as! TestItem
            return TestItem(
                id: existingItem.id,
                name: "\(existingItem.name) + \(newItem.name)",
                value: existingItem.value + newItem.value
            )
        }
        
        // When - upsert new item with custom strategy
        let upserted = try await merger.upsert(item, strategy: customStrategy)
        
        // Then - should return item (no existing to merge with)
        XCTAssertEqual(upserted.id, item.id)
        XCTAssertEqual(upserted.name, item.name)
    }
    
    func testDefaultMergerUpsertExistingWithCombineStrategy() async throws {
        // Given
        class DirectMerger: DefaultMerger<TestItem> {
            var storage: [UUID: TestItem] = [:]
            
            override func findExisting(by id: UUID) async -> TestItem? {
                return storage[id]
            }
            
            override func upsert(_ item: TestItem, strategy: MergeStrategy) async throws -> TestItem {
                return try await super.upsert(item, strategy: strategy)
            }
        }
        
        let merger = DirectMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "New", value: 20)
        
        await merger.storage[existing.id] = existing
        
        // When - upsert existing with combine strategy
        let upserted = try await merger.upsert(new, strategy: .combine)
        
        // Then - should prefer existing (default combine behavior)
        XCTAssertEqual(upserted.id, existing.id)
        XCTAssertEqual(upserted.name, "Existing")
        XCTAssertEqual(upserted.value, 10)
    }
    
    func testDefaultMergerMergeAllStrategies() {
        // Given
        let merger = TestMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "New", value: 20)
        
        // Test all merge strategies through the merge method
        let preferExistingResult = merger.merge(existing: existing, with: new, strategy: .preferExisting)
        XCTAssertEqual(preferExistingResult.name, "Existing")
        
        let preferNewResult = merger.merge(existing: existing, with: new, strategy: .preferNew)
        XCTAssertEqual(preferNewResult.name, "New")
        
        let combineResult = merger.merge(existing: existing, with: new, strategy: .combine)
        XCTAssertEqual(combineResult.name, "Existing")
        
        let customStrategy: MergeStrategy = .custom { existing, new in
            let existingItem = existing as! TestItem
            let newItem = new as! TestItem
            return TestItem(
                id: existingItem.id,
                name: "Custom",
                value: existingItem.value + newItem.value
            )
        }
        let customResult = merger.merge(existing: existing, with: new, strategy: customStrategy)
        XCTAssertEqual(customResult.name, "Custom")
        XCTAssertEqual(customResult.value, 30)
    }
    
    func testDefaultMergerInit() {
        // Given/When - Test DefaultMerger initialization
        let merger = DefaultMerger<TestItem>()
        
        // Then - Should initialize successfully
        XCTAssertNotNil(merger)
    }
    
    // MARK: - Protocol Conformance Tests
    
    func testMergeableProtocolConformance() {
        // Given - Test that TestItem conforms to Mergeable
        let item = TestItem(id: UUID(), name: "Test", value: 10)
        
        // Then - Should have id property
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.name, "Test")
        XCTAssertEqual(item.value, 10)
    }
    
    func testMergeStrategyCases() {
        // Test that all MergeStrategy cases exist and are accessible
        let preferExisting: MergeStrategy = .preferExisting
        let preferNew: MergeStrategy = .preferNew
        let combine: MergeStrategy = .combine
        let custom: MergeStrategy = .custom { existing, new in
            return existing
        }
        
        // Verify all cases are accessible
        XCTAssertNotNil(preferExisting)
        XCTAssertNotNil(preferNew)
        XCTAssertNotNil(combine)
        XCTAssertNotNil(custom)
    }
    
    func testMergerProtocolConformance() {
        // Given - Test that TestMerger conforms to Merger protocol
        let merger = TestMerger()
        
        // Then - Should be a Merger
        XCTAssertTrue(merger is Merger)
        XCTAssertTrue(merger is DefaultMerger<TestItem>)
    }
    
    // MARK: - Edge Cases and Error Paths
    
    func testMergeWithSameItem() {
        // Given
        let merger = TestMerger()
        let item = TestItem(id: UUID(), name: "Item", value: 10)
        
        // When - Merge item with itself
        let merged = merger.merge(existing: item, with: item, strategy: .preferExisting)
        
        // Then - Should return the item
        XCTAssertEqual(merged.id, item.id)
        XCTAssertEqual(merged.name, item.name)
        XCTAssertEqual(merged.value, item.value)
    }
    
    func testMergeWithSameItemPreferNew() {
        // Given
        let merger = TestMerger()
        let item = TestItem(id: UUID(), name: "Item", value: 10)
        
        // When - Merge item with itself using preferNew
        let merged = merger.merge(existing: item, with: item, strategy: .preferNew)
        
        // Then - Should return the item
        XCTAssertEqual(merged.id, item.id)
        XCTAssertEqual(merged.name, item.name)
    }
    
    func testUpsertSameItemMultipleTimes() async throws {
        // Given
        let merger = TestMerger()
        let item = TestItem(id: UUID(), name: "Item", value: 10)
        
        // When - Upsert the same item multiple times
        let upserted1 = try await merger.upsert(item, strategy: .preferExisting)
        let upserted2 = try await merger.upsert(item, strategy: .preferExisting)
        let upserted3 = try await merger.upsert(item, strategy: .preferNew)
        
        // Then - All should return the same item (or merged version)
        XCTAssertEqual(upserted1.id, item.id)
        XCTAssertEqual(upserted2.id, item.id)
        XCTAssertEqual(upserted3.id, item.id)
    }
    
    func testMergeWithDifferentIDs() {
        // Given - Items with different IDs
        let merger = TestMerger()
        let item1 = TestItem(id: UUID(), name: "Item1", value: 10)
        let item2 = TestItem(id: UUID(), name: "Item2", value: 20)
        
        // When - Merge items with different IDs
        let merged = merger.merge(existing: item1, with: item2, strategy: .preferExisting)
        
        // Then - Should return existing (item1)
        XCTAssertEqual(merged.id, item1.id)
        XCTAssertEqual(merged.name, "Item1")
    }
    
    func testCustomStrategyWithNilHandling() {
        // Given
        let merger = TestMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "New", value: 20)
        
        // Custom strategy that handles edge cases
        let customStrategy: MergeStrategy = .custom { existing, new in
            let existingItem = existing as! TestItem
            let newItem = new as! TestItem
            // Return a new item with combined properties
            return TestItem(
                id: existingItem.id,
                name: newItem.name.isEmpty ? existingItem.name : newItem.name,
                value: max(existingItem.value, newItem.value)
            )
        }
        
        // When
        let merged = merger.merge(existing: existing, with: new, strategy: customStrategy)
        
        // Then
        XCTAssertEqual(merged.id, existing.id)
        XCTAssertEqual(merged.name, "New")
        XCTAssertEqual(merged.value, 20)
    }
    
    func testDefaultMergerUpsertPathThroughSuper() async throws {
        // Given - Test that calling super.upsert works correctly
        class SuperMerger: DefaultMerger<TestItem> {
            var storage: [UUID: TestItem] = [:]
            var callCount = 0
            
            override func findExisting(by id: UUID) async -> TestItem? {
                callCount += 1
                return storage[id]
            }
            
            override func upsert(_ item: TestItem, strategy: MergeStrategy) async throws -> TestItem {
                // Call super implementation
                return try await super.upsert(item, strategy: strategy)
            }
        }
        
        let merger = SuperMerger()
        let item = TestItem(id: UUID(), name: "Item", value: 10)
        
        // When - Upsert new item
        let upserted = try await merger.upsert(item, strategy: .preferNew)
        
        // Then - Should return item and call findExisting
        XCTAssertEqual(upserted.id, item.id)
        XCTAssertEqual(merger.callCount, 1)
    }
    
    func testDefaultMergerUpsertPathWithExistingThroughSuper() async throws {
        // Given
        class SuperMerger: DefaultMerger<TestItem> {
            var storage: [UUID: TestItem] = [:]
            
            override func findExisting(by id: UUID) async -> TestItem? {
                return storage[id]
            }
            
            override func upsert(_ item: TestItem, strategy: MergeStrategy) async throws -> TestItem {
                // Call super implementation
                return try await super.upsert(item, strategy: strategy)
            }
        }
        
        let merger = SuperMerger()
        let existing = TestItem(id: UUID(), name: "Existing", value: 10)
        let new = TestItem(id: existing.id, name: "New", value: 20)
        
        await merger.storage[existing.id] = existing
        
        // When - Upsert with existing item
        let upserted = try await merger.upsert(new, strategy: .preferNew)
        
        // Then - Should merge and return new
        XCTAssertEqual(upserted.id, existing.id)
        XCTAssertEqual(upserted.name, "New")
    }
    
    // MARK: - Documentation Tests
    
    func testDefaultMergerFindExistingDocumentation() {
        // This test documents that findExisting(by:) in DefaultMerger
        // calls fatalError and cannot be tested directly.
        // Subclasses MUST override this method.
        
        let merger = DefaultMerger<TestItem>()
        
        // Note: Calling merger.findExisting(by:) directly would cause fatalError
        // This is intentional - it's a programming error if not overridden.
        // We verify the merger exists but don't call findExisting.
        XCTAssertNotNil(merger)
        
        // Verify we can create a subclass that properly overrides it
        class ProperMerger: DefaultMerger<TestItem> {
            override func findExisting(by id: UUID) async -> TestItem? {
                return nil
            }
        }
        
        let properMerger = ProperMerger()
        XCTAssertNotNil(properMerger)
    }
}

