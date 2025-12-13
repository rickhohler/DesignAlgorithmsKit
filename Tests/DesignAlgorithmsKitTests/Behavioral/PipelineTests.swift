import XCTest
@testable import DesignAlgorithmsKit

final class PipelineTests: XCTestCase {
    
    // MARK: - Synchronous Pipeline
    
    func testSyncPipelineExecution() throws {
        let pipeline = DataPipeline<Int, String> { input in
            return String(input)
        }
        
        let result = try pipeline.execute(123)
        XCTAssertEqual(result, "123")
    }
    
    func testSyncPipelineChaining() throws {
        let pipeline = DataPipeline<Int, Int> { input in
            return input * 2
        }
        .appending { input in
            return input + 10
        }
        .appending { input in
            return String(input)
        }
        
        let result = try pipeline.execute(5)
        // (5 * 2) + 10 = 20 -> "20"
        XCTAssertEqual(result, "20")
    }
    
    struct IntToStringStage: DataPipelineStage {
        func process(_ input: Int) throws -> String {
            return String(input)
        }
    }
    
    func testSyncPipelineWithStageObject() throws {
        let pipeline = DataPipeline<Int, Int> { $0 * 2 }
            .appending(IntToStringStage())
        
        let result = try pipeline.execute(5)
        XCTAssertEqual(result, "10")
    }
    
    // MARK: - Asynchronous Pipeline
    
    func testAsyncPipelineExecution() async throws {
        let pipeline = AsyncDataPipeline<Int, String> { input in
            try await Task.sleep(nanoseconds: 1_000_000)
            return String(input)
        }
        
        let result = try await pipeline.execute(123)
        XCTAssertEqual(result, "123")
    }
    
    func testAsyncPipelineChaining() async throws {
        let pipeline = AsyncDataPipeline<Int, Int> { input in
            return input * 2
        }
        .appending { input in
            return input + 10
        }
        .appending { input in
            return String(input)
        }
        
        let result = try await pipeline.execute(5)
        XCTAssertEqual(result, "20")
    }
    
    struct IntToStringAsyncStage: AsyncDataPipelineStage {
        func process(_ input: Int) async throws -> String {
            return String(input)
        }
    }
    
    func testAsyncPipelineWithStageObject() async throws {
        let pipeline = AsyncDataPipeline<Int, Int> { $0 * 2 }
            .appending(IntToStringAsyncStage())
        
        let result = try await pipeline.execute(5)
        XCTAssertEqual(result, "10")
    }
}
