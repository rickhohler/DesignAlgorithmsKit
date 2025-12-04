//
//  SingletonTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Singleton Pattern
//

import XCTest
@testable import DesignAlgorithmsKit

final class SingletonTests: XCTestCase {
    
    // MARK: - ThreadSafeSingleton Tests
    
    func testThreadSafeSingletonSingleInstance() {
        // Given - Using a unique class name to avoid static storage conflicts
        // Each test method needs a completely unique singleton class
        // The base class uses shared Static storage, so we need to ensure
        // each test class is truly isolated
        class IsolatedSingletonTest1: ThreadSafeSingleton {
            var value: String = "initial"
            
            private override init() {
                super.init()
            }
            
            override class func createShared() -> Self {
                // Use class-specific static storage that's truly isolated
                // This struct is unique to this specific class type
                struct IsolatedStorage {
                    static var instance: IsolatedSingletonTest1?
                }
                if IsolatedStorage.instance == nil {
                    IsolatedStorage.instance = IsolatedSingletonTest1()
                }
                return IsolatedStorage.instance! as! Self
            }
        }
        
        // When - Access shared instance multiple times
        let instance1 = IsolatedSingletonTest1.shared
        let instance2 = IsolatedSingletonTest1.shared
        
        // Then - Should return the same instance
        XCTAssertTrue(instance1 === instance2, "Should return the same instance")
        XCTAssertEqual(instance1.value, "initial")
        
        // Verify it's the same object identity
        instance1.value = "modified"
        XCTAssertEqual(instance2.value, "modified", "Both references should point to same instance")
    }
    
    func testThreadSafeSingletonThreadSafety() {
        // Given - Use unique class name to avoid conflicts
        class ThreadSafetyTestSingleton: ThreadSafeSingleton {
            var counter: Int = 0
            
            private override init() {
                super.init()
            }
            
            override class func createShared() -> Self {
                struct StaticStorage {
                    static var instance: ThreadSafetyTestSingleton?
                }
                if StaticStorage.instance == nil {
                    StaticStorage.instance = ThreadSafetyTestSingleton()
                }
                return StaticStorage.instance! as! Self
            }
            
            func increment() {
                counter += 1
            }
        }
        
        // When - Access from multiple threads
        let expectation = expectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        for _ in 0..<10 {
            DispatchQueue.global().async {
                let instance = ThreadSafetyTestSingleton.shared
                instance.increment()
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
        
        // Then - Should still be the same instance
        let instance1 = ThreadSafetyTestSingleton.shared
        let instance2 = ThreadSafetyTestSingleton.shared
        XCTAssertTrue(instance1 === instance2, "Should return the same instance across threads")
    }
    
    func testThreadSafeSingletonState() {
        // Given - Use unique class name to avoid conflicts
        class StateTestSingleton: ThreadSafeSingleton {
            var state: String = "initial"
            
            private override init() {
                super.init()
            }
            
            override class func createShared() -> Self {
                struct StaticStorage {
                    static var instance: StateTestSingleton?
                }
                if StaticStorage.instance == nil {
                    StaticStorage.instance = StateTestSingleton()
                }
                return StaticStorage.instance! as! Self
            }
        }
        
        // When
        let instance = StateTestSingleton.shared
        instance.state = "modified"
        
        // Then
        let instance2 = StateTestSingleton.shared
        XCTAssertEqual(instance2.state, "modified", "State should persist across accesses")
    }
    
    func testThreadSafeSingletonSubclass() {
        // Given - Use unique class names to avoid conflicts
        class SubclassTestBaseSingleton: ThreadSafeSingleton {
            var baseValue: String = "base"
            
            private override init() {
                super.init()
            }
            
            override class func createShared() -> Self {
                struct StaticStorage {
                    static var instance: SubclassTestBaseSingleton?
                }
                if StaticStorage.instance == nil {
                    StaticStorage.instance = SubclassTestBaseSingleton()
                }
                return StaticStorage.instance! as! Self
            }
        }
        
        class SubclassTestDerivedSingleton: ThreadSafeSingleton {
            var derivedValue: String = "derived"
            
            private override init() {
                super.init()
            }
            
            override class func createShared() -> Self {
                struct StaticStorage {
                    static var instance: SubclassTestDerivedSingleton?
                }
                if StaticStorage.instance == nil {
                    StaticStorage.instance = SubclassTestDerivedSingleton()
                }
                return StaticStorage.instance! as! Self
            }
        }
        
        // When
        let base = SubclassTestBaseSingleton.shared
        let derived = SubclassTestDerivedSingleton.shared
        
        // Then
        XCTAssertNotNil(base)
        XCTAssertNotNil(derived)
        XCTAssertTrue(type(of: base) == SubclassTestBaseSingleton.self)
        XCTAssertTrue(type(of: derived) == SubclassTestDerivedSingleton.self)
    }
    
    // MARK: - Singleton Protocol Tests
    
    func testSingletonProtocol() {
        // Given - Use unique class name to avoid conflicts
        class ProtocolTestSingleton: ThreadSafeSingleton, Singleton {
            private override init() {
                super.init()
            }
            
            override class func createShared() -> Self {
                struct StaticStorage {
                    static var instance: ProtocolTestSingleton?
                }
                if StaticStorage.instance == nil {
                    StaticStorage.instance = ProtocolTestSingleton()
                }
                return StaticStorage.instance! as! Self
            }
        }
        
        // When
        let instance1 = ProtocolTestSingleton.shared
        let instance2 = ProtocolTestSingleton.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "Should conform to Singleton protocol")
    }
    
    // MARK: - ActorSingleton Protocol Tests
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testActorSingletonProtocol() {
        // Given
        actor TestActorSingleton: ActorSingleton {
            static let shared = TestActorSingleton()
            
            private init() {}
            
            var value: String = "initial"
            
            func setValue(_ newValue: String) {
                value = newValue
            }
            
            func getValue() -> String {
                return value
            }
        }
        
        // When/Then
        let expectation = expectation(description: "Actor singleton test")
        
        Task {
            let instance1 = TestActorSingleton.shared
            let instance2 = TestActorSingleton.shared
            
            await instance1.setValue("modified")
            let value1 = await instance1.getValue()
            let value2 = await instance2.getValue()
            
            XCTAssertEqual(value1, "modified")
            XCTAssertEqual(value2, "modified", "Actor singleton should share state")
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
}

