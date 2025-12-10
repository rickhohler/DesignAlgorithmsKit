// DesignAlgorithmsKit
// SHA-256 Hash Strategy

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Strategy for SHA-256 hashing
public struct SHA256Strategy: HashStrategy {
    public static let algorithm: HashAlgorithm = .sha256
    
    public init() {}
    
    public func compute(data: Data) -> Data {
        #if canImport(CryptoKit)
        let digest = CryptoKit.SHA256.hash(data: data)
        return Data(digest)
        #else
        // Uses the existing SHA256 implementation in DesignAlgorithmsKit (from HashAlgorithmProtocol)
        // Since we are INSIDE DAK, we can access SHA256 enum directly.
        return SHA256.hash(data: data)
        #endif
    }
}
