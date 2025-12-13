import XCTest
@testable import DesignAlgorithmsKit

final class ChainOfResponsibilityTests: XCTestCase {
    
    // MARK: - Untyped Handler Tests
    
    class ConcreteHandlerA: BaseHandler {
        override func handle(_ request: Any) -> Any? {
            if let str = request as? String, str == "A" {
                return "Handled by A"
            }
            return super.handle(request)
        }
    }
    
    class ConcreteHandlerB: BaseHandler {
        override func handle(_ request: Any) -> Any? {
            if let str = request as? String, str == "B" {
                return "Handled by B"
            }
            return super.handle(request)
        }
    }
    
    func testUntypedChain() {
        let handlerA = ConcreteHandlerA()
        let handlerB = ConcreteHandlerB()
        
        handlerA.setNext(handlerB)
        
        XCTAssertEqual(handlerA.handle("A") as? String, "Handled by A")
        XCTAssertEqual(handlerA.handle("B") as? String, "Handled by B")
        XCTAssertNil(handlerA.handle("C"))
    }
    
    // MARK: - Typed Handler Tests
    
    class TypedHandlerA: BaseTypedHandler<String, String> {
        override func handle(_ request: String) -> String? {
            if request == "A" {
                return "Handled by A"
            }
            return super.handle(request)
        }
    }
    
    class TypedHandlerB: BaseTypedHandler<String, String> {
        override func handle(_ request: String) -> String? {
            if request == "B" {
                return "Handled by B"
            }
            return super.handle(request)
        }
    }
    
    func testTypedChain() {
        let handlerA = TypedHandlerA()
        let handlerB = TypedHandlerB()
        
        handlerA.setNext(handlerB)
        
        XCTAssertEqual(handlerA.handle("A"), "Handled by A")
        XCTAssertEqual(handlerA.handle("B"), "Handled by B")
        XCTAssertNil(handlerA.handle("C"))
    }
}
