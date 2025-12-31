//
//  GraphTests.swift
//  DesignAlgorithmsKitTests
//
//  Tests for Graph Data Structures and Algorithms
//

import XCTest
@testable import DesignAlgorithmsKit

final class GraphTests: XCTestCase {
    
    func testGraphConstruction() {
        let graph = Graph<String>()
        graph.addNode("A")
        graph.addEdge(from: "A", to: "B")
        
        XCTAssertEqual(graph.allNodes.count, 2)
        XCTAssertTrue(graph.neighbors(of: "A").contains("B"))
        XCTAssertTrue(graph.neighbors(of: "B").isEmpty)
    }
    
    func testReachabilitySimple() {
        let graph = Graph<String>()
        graph.addEdge(from: "A", to: "B")
        graph.addEdge(from: "B", to: "C")
        
        let reachable = graph.reachability(from: ["A"])
        
        XCTAssertTrue(reachable.contains("A"))
        XCTAssertTrue(reachable.contains("B"))
        XCTAssertTrue(reachable.contains("C"))
        XCTAssertEqual(reachable.count, 3)
    }
    
    func testReachabilityCycle() {
        let graph = Graph<String>()
        graph.addEdge(from: "A", to: "B")
        graph.addEdge(from: "B", to: "A") // Cycle
        
        let reachable = graph.reachability(from: ["A"])
        
        XCTAssertTrue(reachable.contains("A"))
        XCTAssertTrue(reachable.contains("B"))
        XCTAssertEqual(reachable.count, 2)
    }
    
    func testTreeShaking() {
        let graph = Graph<String>()
        // Reachable Component
        graph.addEdge(from: "Root", to: "A")
        graph.addEdge(from: "A", to: "B")
        
        // Unreachable Component (Dead Code)
        graph.addEdge(from: "Dead", to: "MoreDead")
        
        let unreachable = graph.findUnreachable(from: ["Root"])
        
        XCTAssertTrue(unreachable.contains("Dead"))
        XCTAssertTrue(unreachable.contains("MoreDead"))
        XCTAssertFalse(unreachable.contains("Root"))
        XCTAssertFalse(unreachable.contains("A"))
    }
    
    func testDisconnectedNodes() {
        let graph = Graph<Int>()
        graph.addNode(1)
        graph.addNode(2)
        
        let reachable = graph.reachability(from: [1])
        XCTAssertTrue(reachable.contains(1))
        XCTAssertFalse(reachable.contains(2))
    }
}
