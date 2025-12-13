import XCTest
@testable import DesignAlgorithmsKit

final class CommandTests: XCTestCase {
    
    func testClosureCommand() {
        var value = 0
        let command = ClosureCommand(
            action: { value += 1 },
            undoAction: { value -= 1 }
        )
        
        command.execute()
        XCTAssertEqual(value, 1)
        
        command.undo()
        XCTAssertEqual(value, 0)
    }
    
    func testInvokerExecuteUndoRedo() {
        let invoker = CommandInvoker()
        var value = 0
        
        let incrementCommand = ClosureCommand(
            action: { value += 1 },
            undoAction: { value -= 1 }
        )
        
        // Execute
        invoker.execute(incrementCommand)
        XCTAssertEqual(value, 1)
        
        invoker.execute(incrementCommand)
        XCTAssertEqual(value, 2)
        
        // Undo
        invoker.undo()
        XCTAssertEqual(value, 1)
        
        invoker.undo()
        XCTAssertEqual(value, 0)
        
        // Redo
        invoker.redo()
        XCTAssertEqual(value, 1)
        
        invoker.redo()
        XCTAssertEqual(value, 2)
    }
    
    func testInvokerHistoryClearOnNewExecute() {
        let invoker = CommandInvoker()
        var value = 0
        
        let cmd1 = ClosureCommand(action: { value = 1 })
        let cmd2 = ClosureCommand(action: { value = 2 })
        
        invoker.execute(cmd1)
        invoker.undo()
        // Here undo stack has cmd1
        
        // New execution should clear redo stack
        invoker.execute(cmd2)
        XCTAssertEqual(value, 2)
        
        invoker.redo() // Should do nothing because redo stack was cleared
        XCTAssertEqual(value, 2)
    }
}
