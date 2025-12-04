//
//  FactoryTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Factory Pattern
//

import XCTest
@testable import DesignAlgorithmsKit

final class FactoryTests: XCTestCase {
    var factory: ObjectFactory!
    
    override func setUp() {
        super.setUp()
        factory = ObjectFactory.shared
        factory.clear()
    }
    
    override func tearDown() {
        factory.clear()
        super.tearDown()
    }
    
    func testRegisterFactory() {
        // Given
        let type = "test"
        
        // When
        factory.register(type: type) { config in
            return "created"
        }
        
        // Then
        XCTAssertTrue(factory.isRegistered(type: type))
    }
    
    func testCreateObject() throws {
        // Given
        factory.register(type: "test") { config in
            return "created"
        }
        
        // When
        let result = try factory.create(type: "test", configuration: [:])
        
        // Then
        XCTAssertEqual(result as? String, "created")
    }
    
    func testCreateWithConfiguration() throws {
        // Given
        factory.register(type: "test") { config in
            return config["value"] as? String ?? "default"
        }
        
        // When
        let result = try factory.create(type: "test", configuration: ["value": "custom"])
        
        // Then
        XCTAssertEqual(result as? String, "custom")
    }
    
    func testCreateNonExistentType() {
        // When/Then
        XCTAssertThrowsError(try factory.create(type: "nonexistent", configuration: [:])) { error in
            if case FactoryError.typeNotRegistered(let type) = error {
                XCTAssertEqual(type, "nonexistent")
            } else {
                XCTFail("Unexpected error type")
            }
        }
    }
    
    func testRegisterFactoryProduct() throws {
        // Given
        struct TestProduct: FactoryProduct {
            let value: String
            
            init(configuration: [String: Any]) throws {
                self.value = configuration["value"] as? String ?? "default"
            }
        }
        
        // When
        factory.register(TestProduct.self, key: "test")
        
        // Then
        let result = try factory.create(type: "test", configuration: ["value": "custom"])
        XCTAssertTrue(result is TestProduct)
        XCTAssertEqual((result as? TestProduct)?.value, "custom")
    }
    
    func testRegisterFactoryProductWithoutKey() throws {
        // Given
        struct TestProduct: FactoryProduct {
            let value: String
            
            init(configuration: [String: Any]) throws {
                self.value = configuration["value"] as? String ?? "default"
            }
        }
        
        // When - Register without explicit key (uses type name)
        factory.register(TestProduct.self)
        
        // Then - Should be registered with type name
        let typeName = String(describing: TestProduct.self)
        XCTAssertTrue(factory.isRegistered(type: typeName))
        
        // And should be able to create
        let result = try factory.create(type: typeName, configuration: ["value": "test"])
        XCTAssertTrue(result is TestProduct)
        XCTAssertEqual((result as? TestProduct)?.value, "test")
    }
    
    func testFactoryErrorLocalizedDescription() {
        // Test typeNotRegistered
        let notRegistered = FactoryError.typeNotRegistered("testType")
        XCTAssertEqual(notRegistered.localizedDescription, "Factory type 'testType' is not registered")
        
        // Test creationFailed
        let creationError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let creationFailed = FactoryError.creationFailed("testType", creationError)
        XCTAssertTrue(creationFailed.localizedDescription.contains("Failed to create 'testType'"))
        XCTAssertTrue(creationFailed.localizedDescription.contains("Test error"))
    }
    
    func testFactoryCreationFailed() {
        // Given
        struct FailingProduct: FactoryProduct {
            init(configuration: [String: Any]) throws {
                throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Creation failed"])
            }
        }
        
        factory.register(FailingProduct.self, key: "failing")
        
        // When/Then
        XCTAssertThrowsError(try factory.create(type: "failing", configuration: [:])) { error in
            // The error should be the underlying error, not FactoryError.creationFailed
            // because the factory doesn't wrap errors
            XCTAssertNotNil(error)
        }
    }
    
    func testFactoryIsRegistered() {
        // Given
        XCTAssertFalse(factory.isRegistered(type: "nonexistent"))
        
        // When
        factory.register(type: "test") { _ in "test" }
        
        // Then
        XCTAssertTrue(factory.isRegistered(type: "test"))
        XCTAssertFalse(factory.isRegistered(type: "nonexistent"))
    }
    
    func testFactoryClear() {
        // Given
        factory.register(type: "test1") { _ in "test1" }
        factory.register(type: "test2") { _ in "test2" }
        XCTAssertTrue(factory.isRegistered(type: "test1"))
        XCTAssertTrue(factory.isRegistered(type: "test2"))
        
        // When
        factory.clear()
        
        // Then
        XCTAssertFalse(factory.isRegistered(type: "test1"))
        XCTAssertFalse(factory.isRegistered(type: "test2"))
    }
    
    func testFactoryThreadSafety() {
        // Given
        let expectation = expectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        // When - Register from multiple threads
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.factory.register(type: "type\(i)") { _ in "value\(i)" }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
        
        // Then - All should be registered
        for i in 0..<10 {
            XCTAssertTrue(factory.isRegistered(type: "type\(i)"))
        }
    }
}

