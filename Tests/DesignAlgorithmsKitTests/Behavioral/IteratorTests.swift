import XCTest
@testable import DesignAlgorithmsKit

final class IteratorTests: XCTestCase {
    
    func testArrayIterator() {
        let items = [1, 2, 3]
        let iterator = ArrayIterator(items)
        
        XCTAssertTrue(iterator.hasNext())
        XCTAssertEqual(iterator.next(), 1)
        
        XCTAssertTrue(iterator.hasNext())
        XCTAssertEqual(iterator.next(), 2)
        
        XCTAssertTrue(iterator.hasNext())
        XCTAssertEqual(iterator.next(), 3)
        
        XCTAssertFalse(iterator.hasNext())
        XCTAssertNil(iterator.next())
    }
    
    func testTreeIterator() {
        // Tree structure:
        //      1
        //    /   \
        //   2     3
        //  / \
        // 4   5
        
        struct Node {
            let value: Int
            let children: [Node]
        }
        
        let node4 = Node(value: 4, children: [])
        let node5 = Node(value: 5, children: [])
        let node2 = Node(value: 2, children: [node4, node5])
        let node3 = Node(value: 3, children: [])
        let root = Node(value: 1, children: [node2, node3])
        
        // Depth-first traversal expected: 1, 2, 4, 5, 3
        let iterator = TreeIterator(root: root) { node in
            return node.children
        }
        
        var result: [Int] = []
        while let node = iterator.next() {
            result.append(node.value)
        }
        
        XCTAssertEqual(result, [1, 2, 4, 5, 3])
    }
}
