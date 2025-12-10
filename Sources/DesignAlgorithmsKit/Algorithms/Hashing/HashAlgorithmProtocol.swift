//
//  HashAlgorithmProtocol.swift
//  DesignAlgorithmsKit
//
//  Hash Algorithm Protocol - Base protocol for hash algorithms
//

import Foundation

#if canImport(CryptoKit)
import CryptoKit
#endif

/// Protocol for hash algorithms
public protocol HashAlgorithmProtocol {
    /// Algorithm name
    static var name: String { get }
    
    /// Hash data using this algorithm
    /// - Parameter data: Data to hash
    /// - Returns: Hash value as Data
    static func hash(data: Data) -> Data
    
    /// Hash a string using this algorithm
    /// - Parameter string: String to hash
    /// - Returns: Hash value as Data
    static func hash(string: String) -> Data
}

public extension HashAlgorithmProtocol {
    /// Default implementation for string hashing
    /// - Parameter string: String to hash
    /// - Returns: Hash value as Data, or empty Data if UTF-8 conversion fails
    /// - Note: UTF-8 conversion failure returns empty Data, which will hash to a valid hash value.
    ///   This path is testable by creating strings that fail UTF-8 conversion (rare but possible).
    public static func hash(string: String) -> Data {
        guard let data = string.data(using: .utf8) else {
            // UTF-8 conversion failed - return hash of empty data
            // This is a valid fallback that ensures we always return a hash
            return hash(data: Data())
        }
        return hash(data: data)
    }
}

/// SHA-256 hash algorithm
public enum SHA256: HashAlgorithmProtocol {
    public static let name = "SHA-256"
    
    public static func hash(data: Data) -> Data {
        #if canImport(CryptoKit)
        let digest = CryptoKit.SHA256.hash(data: data)
        return Data(digest)
        #else
        // Fallback implementation
        // In production, use CommonCrypto or another crypto library
        return fallbackHash(data: data)
        #endif
    }
    
    #if !canImport(CryptoKit)
    /// Fallback hash implementation (simple, not cryptographically secure)
    /// For production use, import CryptoKit or CommonCrypto
    /// - Note: This path is conditionally compiled and only available when CryptoKit is not available.
    ///   It cannot be tested in environments where CryptoKit is available (like macOS/iOS test environments).
    ///   The fallback implementation is intentionally simple and not cryptographically secure.
    private static func fallbackHash(data: Data) -> Data {
        var hash = Data(count: 32)
        data.withUnsafeBytes { dataBytes in
            hash.withUnsafeMutableBytes { hashBytes in
                // Simple hash (NOT cryptographically secure)
                // This is a placeholder - use CryptoKit in production
                for i in 0..<32 {
                    var value: UInt8 = 0
                    for j in 0..<dataBytes.count {
                        value ^= dataBytes[j] &+ UInt8(i)
                    }
                    hashBytes[i] = value
                }
            }
        }
        return hash
    }
    #endif
}
