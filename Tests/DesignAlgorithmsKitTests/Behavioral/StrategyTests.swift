//
//  StrategyTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Strategy Pattern
//

import XCTest
@testable import DesignAlgorithmsKit

final class StrategyTests: XCTestCase {
    func testStrategyPattern() {
        // Given
        struct AdditionStrategy: Strategy {
            let strategyID = "addition"
            
            func execute(_ a: Int, _ b: Int) -> Int {
                return a + b
            }
        }
        
        struct MultiplicationStrategy: Strategy {
            let strategyID = "multiplication"
            
            func execute(_ a: Int, _ b: Int) -> Int {
                return a * b
            }
        }
        
        // When
        let context1 = StrategyContext(strategy: AdditionStrategy())
        let result1 = context1.getStrategy().execute(5, 3)
        
        let context2 = StrategyContext(strategy: MultiplicationStrategy())
        let result2 = context2.getStrategy().execute(5, 3)
        
        // Then
        XCTAssertEqual(result1, 8)
        XCTAssertEqual(result2, 15)
    }
    
    func testStrategyContext() {
        // Given
        struct TestStrategy: Strategy {
            let strategyID = "test"
        }
        
        // When
        let context = StrategyContext(strategy: TestStrategy())
        
        // Then
        XCTAssertEqual(context.getStrategy().strategyID, "test")
    }
    
    func testStrategyContextSetStrategy() {
        // Given
        struct TestStrategy: Strategy {
            let strategyID: String
        }
        
        // When
        let context = StrategyContext(strategy: TestStrategy(strategyID: "strategy1"))
        XCTAssertEqual(context.getStrategy().strategyID, "strategy1")
        
        context.setStrategy(TestStrategy(strategyID: "strategy2"))
        
        // Then
        XCTAssertEqual(context.getStrategy().strategyID, "strategy2")
    }
    
    func testBaseStrategy() {
        // Given
        let baseStrategy = BaseStrategy(strategyID: "base-test")
        
        // Then
        XCTAssertEqual(baseStrategy.strategyID, "base-test")
    }
    
    func testBaseStrategyInheritance() {
        // Given
        class CustomStrategy: BaseStrategy {
            init() {
                super.init(strategyID: "custom")
            }
        }
        
        // When
        let strategy = CustomStrategy()
        
        // Then
        XCTAssertEqual(strategy.strategyID, "custom")
    }
    
    func testStrategyContextGetStrategy() {
        // Given
        struct TestStrategy: Strategy {
            let strategyID = "test"
        }
        
        let context = StrategyContext(strategy: TestStrategy())
        
        // When
        let retrievedStrategy = context.getStrategy()
        
        // Then
        XCTAssertEqual(retrievedStrategy.strategyID, "test")
    }
    
    func testStrategyContextMultipleStrategies() {
        // Given
        struct TestStrategy: Strategy {
            let strategyID: String
        }
        
        // When
        let context = StrategyContext(strategy: TestStrategy(strategyID: "strategy1"))
        context.setStrategy(TestStrategy(strategyID: "strategy2"))
        
        // Then
        XCTAssertEqual(context.getStrategy().strategyID, "strategy2")
    }
}

// Extension to make strategies executable for testing
extension Strategy {
    func execute(_ a: Int, _ b: Int) -> Int {
        return 0 // Default implementation
    }
}

