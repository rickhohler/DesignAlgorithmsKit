import XCTest
@testable import DesignAlgorithmsKit

final class CompressionTests: XCTestCase {
    
    func testRoundTrip() throws {
        let originalText = "Hello, GZIP World! " + String(repeating: "Repeating content ", count: 100)
        let originalData = originalText.data(using: .utf8)!
        
        let compressed = try Gzip.compress(data: originalData)
        XCTAssertTrue(compressed.count < originalData.count, "Compressed data should be smaller for redundant text")
        
        // Verify GZIP header magic numbers (0x1f 0x8b)
        XCTAssertEqual(compressed[0], 0x1f)
        XCTAssertEqual(compressed[1], 0x8b)
        
        let decompressed = try Gzip.decompress(data: compressed)
        let decompressedText = String(data: decompressed, encoding: .utf8)
        
        XCTAssertEqual(originalText, decompressedText)
    }
    
    func testDecompressInvalidData() {
        let badData = "Not GZIP Data".data(using: .utf8)!
        XCTAssertThrowsError(try Gzip.decompress(data: badData)) { error in
            guard let gzipError = error as? Gzip.Error else {
                XCTFail("Wrong error type")
                return
            }
            XCTAssertTrue(gzipError == .invalidData || gzipError == .decompressionFailed)
        }
    }
    
    func testDecompressEmptyData() throws {
        let empty = Data()
        // Empty data lacks GZIP header, so it should throw invalidData
        XCTAssertThrowsError(try Gzip.decompress(data: empty)) { error in
            XCTAssertEqual(error as? Gzip.Error, .invalidData)
        }
    }
    
    func testCompressEmptyData() throws {
        // Compressing empty data should still produce a valid GZIP header + footer
        let emptyInfo = Data()
        let compressed = try Gzip.compress(data: emptyInfo)
        XCTAssertTrue(compressed.count > 0) 
        
        let decompressed = try Gzip.decompress(data: compressed)
        XCTAssertTrue(decompressed.isEmpty)
    }
}
