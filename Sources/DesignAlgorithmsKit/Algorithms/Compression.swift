import Foundation
import Compression

/// A utility for GZIP compression and decompression using the native `Compression` framework.
public struct Gzip {
    
    /// Errors that can occur during compression or decompression.
    public enum Error: Swift.Error {
        case compressionFailed
        case decompressionFailed
        case invalidData
    }
    
    /// Compresses data using GZIP algorithm.
    /// - Parameter data: The input data to compress.
    /// - Returns: The compressed data.
    /// - Throws: `Gzip.Error.compressionFailed` if the operation fails.
    public static func compress(data: Data) throws -> Data {
        // GZIP Header (10 bytes)
        // Magic (2), Method (1), Flags (1), MTime (4), XFlags (1), OS (1)
        // GZIP Header (10 bytes)
        // Magic (2), Method (1), Flags (1), MTime (4), XFlags (1), OS (1)
        var result = Data([0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03])
        
        // 1. Compress with ZLIB algorithm (raw deflate) using low-level API
        let rawDeflated = try compressRawDeflate(data)

        // 2. Append to Header
        result.append(rawDeflated)
        
        // 3. Append CRC32 (4 bytes)
        let crc = Checksum.crc32(data: data)
        result.append(contentsOf: withUnsafeBytes(of: crc.littleEndian) { Array($0) })
        
        // 4. Append ISIZE (Input Size) modulo 2^32 (4 bytes)
        let isize = UInt32(data.count % 4294967296)
        result.append(contentsOf: withUnsafeBytes(of: isize.littleEndian) { Array($0) })
        
        return result
    }
    
    /// Decompresses GZIP compressed data.
    /// - Parameter data: The compressed data (including GZIP header).
    /// - Returns: The uncompressed data.
    /// - Throws: `Gzip.Error.decompressionFailed` or `invalidData`.
    public static func decompress(data: Data) throws -> Data {
        // GZIP Header Validation
        guard data.count >= 18 else { throw Error.invalidData }
        guard data[0] == 0x1f, data[1] == 0x8b else { throw Error.invalidData }
        guard data[2] == 0x08 else { throw Error.decompressionFailed } // Method must be DEFLATE
        
        // Parse Flags
        var parser = DataParser(data: data)
        _ = try parser.readByte() // Magic 1
        _ = try parser.readByte() // Magic 2
        _ = try parser.readByte() // Method
        let flags = try parser.readByte()
        _ = try parser.readBytes(count: 6) // MTime, XFlags, OS
        
        // FEXTRA (0x04)
        if (flags & 0x04) != 0 {
            let xlen = try parser.readUInt16()
            _ = try parser.readBytes(count: Int(xlen))
        }
        
        // FNAME (0x08)
        if (flags & 0x08) != 0 {
            while (try parser.readByte()) != 0 {}
        }
        
        // FCOMMENT (0x10)
        if (flags & 0x10) != 0 {
            while (try parser.readByte()) != 0 {}
        }
        
        // FHCRC (0x02)
        if (flags & 0x02) != 0 {
           _ = try parser.readBytes(count: 2)
        }
        
        let headerSize = parser.offset
        let footerSize = 8
        guard data.count > headerSize + footerSize else { throw Error.invalidData }
        
        let deflatePayload = data.subdata(in: headerSize..<(data.count - footerSize))
        
        return try decompressRawDeflate(deflatePayload)
    }

    // MARK: - Internal Helpers using ZlibProxy
    
    private static func compressRawDeflate(_ input: Data) throws -> Data {
        return try ZlibProxy.compressRawDeflate(data: input)
    }
    
    private static func decompressRawDeflate(_ input: Data) throws -> Data {
        return try ZlibProxy.decompressRawDeflate(data: input)
    }
}

// MARK: - Checksum Utility
struct Checksum {
    static func crc32(data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        var table = [UInt32](repeating: 0, count: 256)
        
        // Compute table
        for i in 0..<256 {
            var c = UInt32(i)
            for _ in 0..<8 {
                if (c & 1) != 0 {
                    c = 0xEDB88320 ^ (c >> 1)
                } else {
                    c = c >> 1
                }
            }
            table[i] = c
        }
        
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = table[index] ^ (crc >> 8)
        }
        
        return crc ^ 0xFFFFFFFF
    }
}

// MARK: - ZLib Proxy via @_silgen_name
// Bypasses 'import zlib' requirement by linking directly to system symbols
struct ZlibProxy {
    
    // Compression Bindings
    @_silgen_name("deflateInit2_")
    private static func deflateInit2_(_ strm: UnsafeMutableRawPointer, _ level: Int32, _ method: Int32, _ windowBits: Int32, _ memLevel: Int32, _ strategy: Int32, _ version: UnsafePointer<CChar>, _ stream_size: Int32) -> Int32
    
    @_silgen_name("deflate")
    private static func deflate(_ strm: UnsafeMutableRawPointer, _ flush: Int32) -> Int32
    
    @_silgen_name("deflateEnd")
    private static func deflateEnd(_ strm: UnsafeMutableRawPointer) -> Int32
    
    // Decompression Bindings
    @_silgen_name("inflateInit2_")
    private static func inflateInit2_(_ strm: UnsafeMutableRawPointer, _ windowBits: Int32, _ version: UnsafePointer<CChar>, _ stream_size: Int32) -> Int32
    
    @_silgen_name("inflate")
    private static func inflate(_ strm: UnsafeMutableRawPointer, _ flush: Int32) -> Int32
    
    @_silgen_name("inflateEnd")
    private static func inflateEnd(_ strm: UnsafeMutableRawPointer) -> Int32
    
    // Internal z_stream structure layout (OS agnostic usually, but pointer size matters)
    private struct ZStream {
        var next_in: UnsafeMutableRawPointer? = nil
        var avail_in: UInt32 = 0
        var total_in: UInt = 0
        
        var next_out: UnsafeMutableRawPointer? = nil
        var avail_out: UInt32 = 0
        var total_out: UInt = 0
        
        var msg: UnsafePointer<CChar>? = nil
        var state: OpaquePointer? = nil
        
        var zalloc: OpaquePointer? = nil
        var zfree: OpaquePointer? = nil
        var opaque: OpaquePointer? = nil
        
        var data_type: Int32 = 0
        var adler: UInt = 0
        var reserved: UInt = 0
    }
    
    static func compressRawDeflate(data: Data) throws -> Data {
        // ZLIB constants
        let Z_DEFAULT_COMPRESSION: Int32 = -1
        let Z_DEFLATED: Int32 = 8
        let Z_DEFAULT_STRATEGY: Int32 = 0
        let Z_FINISH: Int32 = 4
        // let Z_OK: Int32 = 0
        let Z_STREAM_END: Int32 = 1
        
        let windowBits: Int32 = -15 // Raw Deflate
        let memLevel: Int32 = 8
        let version = "1.2.11"
        
        var stream = ZStream()
        
        return try data.withUnsafeBytes { inputPtr in
            var mutableStream = stream
            mutableStream.next_in = UnsafeMutableRawPointer(mutating: inputPtr.baseAddress) // can be nil
            mutableStream.avail_in = UInt32(inputPtr.count)
            
            let versionPtr = (version as NSString).utf8String!
            let res = deflateInit2_(&mutableStream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, windowBits, memLevel, Z_DEFAULT_STRATEGY, versionPtr, Int32(MemoryLayout<ZStream>.size))
            guard res == 0 else { throw Gzip.Error.compressionFailed }
            defer {
                var cleanupStream = mutableStream
                _ = deflateEnd(&cleanupStream)
            }
            
            var output = Data()
            let bufferSize = 65536
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            
            while true {
                let status = buffer.withUnsafeMutableBufferPointer { outputPtr -> Int32 in
                    mutableStream.next_out = UnsafeMutableRawPointer(outputPtr.baseAddress!)
                    mutableStream.avail_out = UInt32(bufferSize)
                    return deflate(&mutableStream, Z_FINISH)
                }
                
                let bytesWritten = bufferSize - Int(mutableStream.avail_out)
                if bytesWritten > 0 {
                    output.append(buffer, count: bytesWritten)
                }
                
                if status == Z_STREAM_END { break }
                if status != 0 && status != 1 { // Error (0 is OK, 1 is END)
                     throw Gzip.Error.compressionFailed
                }
            }
            return output
        }
    }
    
    static func decompressRawDeflate(data: Data) throws -> Data {
        var stream = ZStream()
        
        // windowBits = -15 for raw deflate
        let windowBits: Int32 = -15
        let version = "1.2.11" // Just needs to be compatible
        
        return try data.withUnsafeBytes { inputPtr in
            var mutableStream = stream
            mutableStream.next_in = UnsafeMutableRawPointer(mutating: inputPtr.baseAddress!)
            mutableStream.avail_in = UInt32(inputPtr.count)
            
            let versionPtr = (version as NSString).utf8String!
            
            let res = inflateInit2_(&mutableStream, windowBits, versionPtr, Int32(MemoryLayout<ZStream>.size))
            guard res == 0 else { throw Gzip.Error.decompressionFailed } // Z_OK = 0
            defer { 
                 var cleanupStream = mutableStream
                 _ = inflateEnd(&cleanupStream) 
            }
            
            var output = Data()
            let bufferSize = 65536
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            
            while true {
                let status = buffer.withUnsafeMutableBufferPointer { outputPtr -> Int32 in
                    mutableStream.next_out = UnsafeMutableRawPointer(outputPtr.baseAddress!)
                    mutableStream.avail_out = UInt32(bufferSize)
                    return inflate(&mutableStream, 0) // Z_NO_FLUSH
                }
                
                let bytesWritten = bufferSize - Int(mutableStream.avail_out)
                if bytesWritten > 0 {
                    output.append(buffer, count: bytesWritten)
                }
                
                if status == 1 { break } // Z_STREAM_END
                if status != 0 && status != 1 { // Error
                    // status -5 is Z_BUF_ERROR
                   throw Gzip.Error.decompressionFailed 
                }
            }
            return output
        }
    }
}

// Helper for parsing binary data
struct DataParser {
    let data: Data
    var offset = 0
    
    mutating func readByte() throws -> UInt8 {
        guard offset < data.count else { throw Gzip.Error.invalidData }
        let b = data[offset]
        offset += 1
        return b
    }
    
    mutating func readBytes(count: Int) throws -> Data {
        guard offset + count <= data.count else { throw Gzip.Error.invalidData }
        let chunk = data.subdata(in: offset..<(offset+count))
        offset += count
        return chunk
    }
    
    mutating func readUInt16() throws -> UInt16 {
        let bytes = try readBytes(count: 2)
        return bytes.withUnsafeBytes { $0.load(as: UInt16.self) }
    }
}
