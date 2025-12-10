// DesignAlgorithmsKit
// SHA-1 Hash Strategy

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Strategy for SHA-1 hashing
/// Note: SHA-1 is insecure and should only be used for legacy compatibility
public struct SHA1Strategy: HashStrategy {
    public static let algorithm: HashAlgorithm = .sha1
    
    public init() {}
    
    public func compute(data: Data) -> Data {
        #if canImport(CryptoKit)
        let digest = Insecure.SHA1.hash(data: data)
        return Data(digest)
        #else
        fatalError("CryptoKit not available for SHA1")
        #endif
    }
}
