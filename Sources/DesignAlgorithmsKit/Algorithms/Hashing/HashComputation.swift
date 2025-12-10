// DesignAlgorithmsKit
// HashComputation
//
// This file provides a static helper for computing hashes using the Strategy Pattern.

import Foundation

/// Utility for computing hashes of data
/// Delegates actual computation to registered HashStrategy implementations
public struct HashComputation {
    
    // Register default strategies on load
    // Note: In Swift, static initialization is lazy. Usage of any static member triggers it.
    private static let _setup: Void = {
        HashStrategyRegistry.register(SHA256Strategy.self)
        HashStrategyRegistry.register(SHA1Strategy.self)
        HashStrategyRegistry.register(MD5Strategy.self)
        HashStrategyRegistry.register(CRC32Strategy.self)
    }()
    
    /// Compute hash for data using the specified algorithm
    /// - Parameters:
    ///   - data: Data to hash
    ///   - algorithm: Hash algorithm to use
    /// - Returns: Hash as Data
    /// - Throws: Error if algorithm is not implemented/registered
    public static func computeHash(data: Data, algorithm: HashAlgorithm) throws -> Data {
        // Ensure registration is done
        _ = _setup
        
        guard let strategy = HashStrategyRegistry.strategy(for: algorithm) else {
            // Using logic similar to FS error but generic
            throw HashError.algorithmNotImplemented(algorithm.rawValue)
        }
        
        return strategy.compute(data: data)
    }
    
    /// Compute hash and return as hex string (lowercase) from algorithm name string
    /// Convenience method for code that uses string-based algorithm names
    /// - Parameters:
    ///   - data: Data to hash
    ///   - algorithm: Hash algorithm name (e.g., "sha256", "sha1", "md5")
    /// - Returns: Hash as hex string (lowercase, no separators)
    /// - Throws: Error if hashing fails or algorithm is unsupported
    public static func computeHashHex(data: Data, algorithm: String) throws -> String {
        guard let hashAlgorithm = HashAlgorithm(rawValue: algorithm.lowercased()) else {
             throw HashError.algorithmNotImplemented(algorithm)
        }
        return try computeHashHex(data: data, algorithm: hashAlgorithm)
    }
    
    /// Compute CRC32 checksum
    /// - Parameter data: Data to checksum
    /// - Returns: CRC32 as Data (4 bytes, big-endian)
    public static func computeCRC32(data: Data) -> Data {
        let strategy = CRC32Strategy()
        return strategy.compute(data: data)
    }
    
    /// Compute hash and return as lowercase hex string
    /// - Parameters:
    ///   - data: Data to hash
    ///   - algorithm: Hash algorithm
    /// - Returns: Hex string of the hash
    /// - Throws: Error if algorithm is not implemented
    public static func computeHashHex(data: Data, algorithm: HashAlgorithm) throws -> String {
        let hashData = try computeHash(data: data, algorithm: algorithm)
        return hashData.map { String(format: "%02x", $0) }.joined()
    }
}

/// Generic error for hashing failures
public enum HashError: Error {
    case algorithmNotImplemented(String)
}
