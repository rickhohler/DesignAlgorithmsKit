//
//  HashComputation.swift
//  DesignAlgorithmsKit
//
//  Cryptographic hash computation utilities.
//  Supports SHA256, SHA1, MD5, and CRC32 algorithms.
//

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(CommonCrypto)
import CommonCrypto
#endif

/// Supported hash algorithms
public enum HashAlgorithm: String, Sendable, CaseIterable {
    case sha256 = "sha256"
    case sha1 = "sha1"
    case md5 = "md5"
    case crc32 = "crc32"
}

/// Hash computation error
public enum HashComputationError: Error, LocalizedError {
    case algorithmNotSupported(String)
    case computationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .algorithmNotSupported(let algorithm):
            return "Hash algorithm '\(algorithm)' is not supported on this platform"
        case .computationFailed(let message):
            return "Hash computation failed: \(message)"
        }
    }
}

/// Cryptographic hash computation utilities
///
/// Provides unified hash computation across platforms using CryptoKit when available,
/// falling back to CommonCrypto on older platforms.
///
/// **Example**:
/// ```swift
/// let data = "Hello, World!".data(using: .utf8)!
/// let hash = try HashComputation.computeHash(data: data, algorithm: .sha256)
/// let hex = try HashComputation.computeHashHex(data: data, algorithm: .sha256)
/// ```
public enum HashComputation {
    
    /// Compute hash and return as Data
    /// - Parameters:
    ///   - data: Data to hash
    ///   - algorithm: Hash algorithm to use
    /// - Returns: Hash as Data
    /// - Throws: HashComputationError if hashing fails or algorithm is unsupported
    public static func computeHash(data: Data, algorithm: HashAlgorithm) throws -> Data {
        #if canImport(CryptoKit)
        let digest: any Digest
        switch algorithm {
        case .sha256:
            digest = SHA256.hash(data: data)
        case .sha1:
            digest = Insecure.SHA1.hash(data: data)
        case .md5:
            digest = Insecure.MD5.hash(data: data)
        case .crc32:
            // CRC32 not in CryptoKit, use custom implementation
            return computeCRC32(data: data)
        }
        return Data(digest)
        #elseif canImport(CommonCrypto)
        switch algorithm {
        case .sha256:
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            data.withUnsafeBytes { bytes in
                _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
            }
            return Data(digest)
        case .sha1:
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
            data.withUnsafeBytes { bytes in
                _ = CC_SHA1(bytes.baseAddress, CC_LONG(data.count), &digest)
            }
            return Data(digest)
        case .md5:
            // MD5 kept for legacy compatibility (companion files, existing checksums)
            var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            data.withUnsafeBytes { bytes in
                digest.withUnsafeMutableBytes { digestBytes in
                    _ = CC_MD5(bytes.baseAddress, CC_LONG(data.count), digestBytes.baseAddress)
                }
            }
            return Data(digest)
        case .crc32:
            return computeCRC32(data: data)
        }
        #else
        throw HashComputationError.algorithmNotSupported(algorithm.rawValue)
        #endif
    }
    
    /// Compute hash and return as hex string (lowercase)
    /// - Parameters:
    ///   - data: Data to hash
    ///   - algorithm: Hash algorithm to use
    /// - Returns: Hash as hex string (lowercase, no separators)
    /// - Throws: HashComputationError if hashing fails or algorithm is unsupported
    public static func computeHashHex(data: Data, algorithm: HashAlgorithm) throws -> String {
        let hashData = try computeHash(data: data, algorithm: algorithm)
        return hashData.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Compute hash and return as hex string (lowercase) from algorithm name string
    /// - Parameters:
    ///   - data: Data to hash
    ///   - algorithm: Hash algorithm name (e.g., "sha256", "sha1", "md5")
    /// - Returns: Hash as hex string (lowercase, no separators)
    /// - Throws: HashComputationError if hashing fails or algorithm is unsupported
    public static func computeHashHex(data: Data, algorithm: String) throws -> String {
        guard let hashAlgorithm = HashAlgorithm(rawValue: algorithm.lowercased()) else {
            throw HashComputationError.algorithmNotSupported(algorithm)
        }
        return try computeHashHex(data: data, algorithm: hashAlgorithm)
    }
    
    /// Compute CRC32 checksum
    /// - Parameter data: Data to checksum
    /// - Returns: CRC32 as Data (4 bytes, big-endian)
    public static func computeCRC32(data: Data) -> Data {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc = crc32Table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        crc = crc ^ 0xFFFFFFFF
        return withUnsafeBytes(of: crc.bigEndian) { Data($0) }
    }
    
    // MARK: - Private Helpers
    
    /// CRC32 lookup table
    private static let crc32Table: [UInt32] = {
        var table: [UInt32] = []
        for i in 0..<256 {
            var crc = UInt32(i)
            for _ in 0..<8 {
                crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1
            }
            table.append(crc)
        }
        return table
    }()
}

// MARK: - Convenience Extensions

extension Data {
    /// Compute SHA256 hash of this data
    public var sha256: Data {
        (try? HashComputation.computeHash(data: self, algorithm: .sha256)) ?? Data()
    }
    
    /// Compute SHA256 hash and return as hex string
    public var sha256Hex: String {
        (try? HashComputation.computeHashHex(data: self, algorithm: .sha256)) ?? ""
    }
}
