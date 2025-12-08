//
//  HashComputationTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for HashComputation.
//

import XCTest
@testable import DesignAlgorithmsKit

final class HashComputationTests: XCTestCase {
    
    // MARK: - SHA256 Tests
    
    func testSHA256_EmptyData() throws {
        let data = Data()
        let hash = try HashComputation.computeHashHex(data: data, algorithm: .sha256)
        
        // SHA256 of empty data
        XCTAssertEqual(hash, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }
    
    func testSHA256_HelloWorld() throws {
        let data = "Hello, World!".data(using: .utf8)!
        let hash = try HashComputation.computeHashHex(data: data, algorithm: .sha256)
        
        // Known SHA256 of "Hello, World!"
        XCTAssertEqual(hash, "dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f")
    }
    
    func testSHA256_DataExtension() {
        let data = "Test".data(using: .utf8)!
        let hash1 = data.sha256Hex
        let hash2 = try! HashComputation.computeHashHex(data: data, algorithm: .sha256)
        
        XCTAssertEqual(hash1, hash2)
        XCTAssertFalse(hash1.isEmpty)
    }
    
    // MARK: - SHA1 Tests
    
    func testSHA1_EmptyData() throws {
        let data = Data()
        let hash = try HashComputation.computeHashHex(data: data, algorithm: .sha1)
        
        // SHA1 of empty data
        XCTAssertEqual(hash, "da39a3ee5e6b4b0d3255bfef95601890afd80709")
    }
    
    func testSHA1_HelloWorld() throws {
        let data = "Hello, World!".data(using: .utf8)!
        let hash = try HashComputation.computeHashHex(data: data, algorithm: .sha1)
        
        // Known SHA1 of "Hello, World!"
        XCTAssertEqual(hash, "0a0a9f2a6772942557ab5355d76af442f8f65e01")
    }
    
    // MARK: - MD5 Tests
    
    func testMD5_EmptyData() throws {
        let data = Data()
        let hash = try HashComputation.computeHashHex(data: data, algorithm: .md5)
        
        // MD5 of empty data
        XCTAssertEqual(hash, "d41d8cd98f00b204e9800998ecf8427e")
    }
    
    func testMD5_HelloWorld() throws {
        let data = "Hello, World!".data(using: .utf8)!
        let hash = try HashComputation.computeHashHex(data: data, algorithm: .md5)
        
        // Known MD5 of "Hello, World!"
        XCTAssertEqual(hash, "65a8e27d8879283831b664bd8b7f0ad4")
    }
    
    // MARK: - CRC32 Tests
    
    func testCRC32_EmptyData() {
        let data = Data()
        let crc = HashComputation.computeCRC32(data: data)
        
        // CRC32 of empty data is 0x00000000
        XCTAssertEqual(crc.count, 4)
        XCTAssertEqual(crc, Data([0x00, 0x00, 0x00, 0x00]))
    }
    
    func testCRC32_HelloWorld() {
        let data = "Hello, World!".data(using: .utf8)!
        let crc = HashComputation.computeCRC32(data: data)
        
        XCTAssertEqual(crc.count, 4)
        // CRC32 is deterministic
        XCTAssertFalse(crc.isEmpty)
    }
    
    func testCRC32_AsHex() throws {
        let data = "Test".data(using: .utf8)!
        let hex = try HashComputation.computeHashHex(data: data, algorithm: .crc32)
        
        // Should be 8 hex characters (4 bytes)
        XCTAssertEqual(hex.count, 8)
    }
    
    // MARK: - String Algorithm Tests
    
    func testStringAlgorithm_SHA256() throws {
        let data = "Test".data(using: .utf8)!
        let hash1 = try HashComputation.computeHashHex(data: data, algorithm: .sha256)
        let hash2 = try HashComputation.computeHashHex(data: data, algorithm: "sha256")
        
        XCTAssertEqual(hash1, hash2)
    }
    
    func testStringAlgorithm_CaseInsensitive() throws {
        let data = "Test".data(using: .utf8)!
        let hash1 = try HashComputation.computeHashHex(data: data, algorithm: "SHA256")
        let hash2 = try HashComputation.computeHashHex(data: data, algorithm: "sha256")
        
        XCTAssertEqual(hash1, hash2)
    }
    
    func testStringAlgorithm_InvalidAlgorithm() {
        let data = "Test".data(using: .utf8)!
        
        XCTAssertThrowsError(try HashComputation.computeHashHex(data: data, algorithm: "invalid")) { error in
            guard case HashComputationError.algorithmNotSupported(let alg) = error else {
                XCTFail("Expected algorithmNotSupported error")
                return
            }
            XCTAssertEqual(alg, "invalid")
        }
    }
    
    // MARK: - Data Return Tests
    
    func testComputeHash_ReturnsData() throws {
        let data = "Test".data(using: .utf8)!
        let hash = try HashComputation.computeHash(data: data, algorithm: .sha256)
        
        // SHA256 produces 32 bytes
        XCTAssertEqual(hash.count, 32)
    }
    
    func testSHA1_Returns20Bytes() throws {
        let data = "Test".data(using: .utf8)!
        let hash = try HashComputation.computeHash(data: data, algorithm: .sha1)
        
        // SHA1 produces 20 bytes
        XCTAssertEqual(hash.count, 20)
    }
    
    func testMD5_Returns16Bytes() throws {
        let data = "Test".data(using: .utf8)!
        let hash = try HashComputation.computeHash(data: data, algorithm: .md5)
        
        // MD5 produces 16 bytes
        XCTAssertEqual(hash.count, 16)
    }
    
    // MARK: - Consistency Tests
    
    func testConsistency_SameInputSameOutput() throws {
        let data = "Consistency Test".data(using: .utf8)!
        
        let hash1 = try HashComputation.computeHashHex(data: data, algorithm: .sha256)
        let hash2 = try HashComputation.computeHashHex(data: data, algorithm: .sha256)
        
        XCTAssertEqual(hash1, hash2)
    }
    
    func testConsistency_DifferentInputDifferentOutput() throws {
        let data1 = "Test1".data(using: .utf8)!
        let data2 = "Test2".data(using: .utf8)!
        
        let hash1 = try HashComputation.computeHashHex(data: data1, algorithm: .sha256)
        let hash2 = try HashComputation.computeHashHex(data: data2, algorithm: .sha256)
        
        XCTAssertNotEqual(hash1, hash2)
    }
    
    // MARK: - Algorithm Enum Tests
    
    func testHashAlgorithm_AllCases() {
        let algorithms = HashAlgorithm.allCases
        
        XCTAssertEqual(algorithms.count, 4)
        XCTAssertTrue(algorithms.contains(.sha256))
        XCTAssertTrue(algorithms.contains(.sha1))
        XCTAssertTrue(algorithms.contains(.md5))
        XCTAssertTrue(algorithms.contains(.crc32))
    }
    
    func testHashAlgorithm_RawValues() {
        XCTAssertEqual(HashAlgorithm.sha256.rawValue, "sha256")
        XCTAssertEqual(HashAlgorithm.sha1.rawValue, "sha1")
        XCTAssertEqual(HashAlgorithm.md5.rawValue, "md5")
        XCTAssertEqual(HashAlgorithm.crc32.rawValue, "crc32")
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_SHA256() {
        let data = Data(repeating: 0x42, count: 1024 * 1024) // 1MB
        
        measure {
            _ = try! HashComputation.computeHash(data: data, algorithm: .sha256)
        }
    }
}
