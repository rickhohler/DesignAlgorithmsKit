import XCTest
@testable import DesignAlgorithmsKit

final class CompositeTests: XCTestCase {
    
    class TestLeaf: Leaf {
        let name: String
        var operationCalled = false
        
        init(name: String) {
            self.name = name
        }
        
        override func operation() {
            operationCalled = true
        }
    }
    
    class TestComposite: Composite {
        let name: String
        
        init(name: String) {
            self.name = name
        }
    }
    
    func testTreeStructure() {
        let root = TestComposite(name: "root")
        let branch = TestComposite(name: "branch")
        let leaf1 = TestLeaf(name: "leaf1")
        let leaf2 = TestLeaf(name: "leaf2")
        
        root.add(branch)
        root.add(leaf1)
        branch.add(leaf2)
        
        // Check hierarchy
        XCTAssertTrue(branch.parent === root)
        XCTAssertTrue(leaf1.parent === root)
        XCTAssertTrue(leaf2.parent === branch)
        
        XCTAssertEqual(root.getChildren().count, 2)
        XCTAssertEqual(branch.getChildren().count, 1)
        
        // Check retrieval
        XCTAssertTrue(root.getChild(at: 0) === branch)
        XCTAssertTrue(root.getChild(at: 1) === leaf1)
    }
    
    func testOperationPropagation() {
        let root = TestComposite(name: "root")
        let leaf1 = TestLeaf(name: "leaf1")
        let leaf2 = TestLeaf(name: "leaf2")
        
        root.add(leaf1)
        root.add(leaf2)
        
        root.operation()
        
        XCTAssertTrue(leaf1.operationCalled)
        XCTAssertTrue(leaf2.operationCalled)
    }
    
    func testRemove() {
        let root = TestComposite(name: "root")
        let leaf = TestLeaf(name: "leaf")
        
        root.add(leaf)
        XCTAssertEqual(root.getChildren().count, 1)
        XCTAssertNotNil(leaf.parent)
        
        root.remove(leaf)
        XCTAssertEqual(root.getChildren().count, 0)
        XCTAssertNil(leaf.parent)
    }
}
