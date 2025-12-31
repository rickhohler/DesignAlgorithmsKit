//
//  VisitorTests.swift
//  DesignAlgorithmsKitTests
//
//  Tests for Visitor Pattern
//

import XCTest
@testable import DesignAlgorithmsKit

final class VisitorTests: XCTestCase {
    
    // Mocks
    struct ConcreteElement: Visitable {
        let name: String
        func accept<V: Visitor>(_ visitor: V) -> V.Result {
            return visitor.visit(self)
        }
    }
    
    struct NameVisitor: Visitor {
        typealias Result = String
        
        func visit(_ element: Visitable) -> String {
            if let ce = element as? ConcreteElement {
                return "Visited: \(ce.name)"
            }
            return "Unknown"
        }
    }
    
    func testVisitorTraverse() {
        let element = ConcreteElement(name: "TestNode")
        let visitor = NameVisitor()
        
        let result = element.accept(visitor)
        XCTAssertEqual(result, "Visited: TestNode")
    }
    
    func testVisitorUnknownType() {
        struct UnknownElement: Visitable {
            func accept<V: Visitor>(_ visitor: V) -> V.Result {
                return visitor.visit(self)
            }
        }
        
        let element = UnknownElement()
        let visitor = NameVisitor()
        let result = element.accept(visitor)
        XCTAssertEqual(result, "Unknown")
    }
}
