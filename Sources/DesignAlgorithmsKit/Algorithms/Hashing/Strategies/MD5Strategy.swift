// DesignAlgorithmsKit
// MD5 Hash Strategy

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Strategy for MD5 hashing
/// Note: MD5 is insecure and should only be used for legacy compatibility
public struct MD5Strategy: HashStrategy {
    public static let algorithm: HashAlgorithm = .md5
    
    public init() {}
    
    public func compute(data: Data) -> Data {
        #if canImport(CryptoKit)
        let digest = Insecure.MD5.hash(data: data)
        return Data(digest)
        #else
        fatalError("CryptoKit not available for MD5")
        #endif
    }
}
