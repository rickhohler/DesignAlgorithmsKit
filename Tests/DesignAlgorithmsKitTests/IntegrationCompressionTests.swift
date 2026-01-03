import XCTest
@testable import DesignAlgorithmsKit

final class IntegrationCompressionTests: XCTestCase {
    
    let fileManager = FileManager.default
    var tempDir: URL!
    
    override func setUp() {
        super.setUp()
        tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? fileManager.removeItem(at: tempDir)
        super.tearDown()
    }
    
    func testSwiftCompressGunzipDecompress() throws {
        // 1. Create a file
        let originalContent = "Hello from Swift GZIP Integration Test! " + String(repeating: "Repeat ", count: 50)
        let originalData = originalContent.data(using: .utf8)!
        let originalFile = tempDir.appendingPathComponent("test.txt")
        try originalData.write(to: originalFile)
        
        // 2. Compress using Swift
        let compressedData = try Gzip.compress(data: originalData)
        let compressedFile = tempDir.appendingPathComponent("test.txt.gz")
        try compressedData.write(to: compressedFile)
        
        // 3. Decompress using system `gunzip`
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/gunzip")
        process.arguments = ["-f", "-k", compressedFile.path] // -f force overwrite, -k keep original
        try process.run()
        process.waitUntilExit()
        
        XCTAssertEqual(process.terminationStatus, 0, "gunzip failed")
        
        // 4. Verify content
        // gunzip should produce test.txt (overwriting original? no, we wrote to test.txt.gz, gunzip produces test.txt)
        // Since original test.txt exists, gunzip might prompt or fail.
        // Let's delete original first.
        try fileManager.removeItem(at: originalFile)
        
        let gunzipProcess = Process()
        gunzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/gunzip")
        gunzipProcess.arguments = [compressedFile.path]
        try gunzipProcess.run()
        gunzipProcess.waitUntilExit()
        
        XCTAssertEqual(gunzipProcess.terminationStatus, 0)
        
        let restoredData = try Data(contentsOf: originalFile)
        XCTAssertEqual(restoredData, originalData)
    }
    
    func testGzipCompressSwiftDecompress() throws {
        // 1. Create a file
        let originalContent = "Hello from GZIP CLI Integration Test! " + String(repeating: "CliRepeat ", count: 50)
        let originalData = originalContent.data(using: .utf8)!
        let originalFile = tempDir.appendingPathComponent("cli_test.txt")
        try originalData.write(to: originalFile)
        
        // 2. Compress using system `gzip`
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/gzip")
        process.arguments = [originalFile.path] // Replaces file with .gz
        try process.run()
        process.waitUntilExit()
        
        XCTAssertEqual(process.terminationStatus, 0)
        
        let gzFile = tempDir.appendingPathComponent("cli_test.txt.gz")
        XCTAssertTrue(fileManager.fileExists(atPath: gzFile.path))
        
        // 3. Read and Decompress using Swift
        let gzData = try Data(contentsOf: gzFile)
        let decompressedData = try Gzip.decompress(data: gzData)
        
        // 4. Verify
        XCTAssertEqual(decompressedData, originalData)
    }
}
