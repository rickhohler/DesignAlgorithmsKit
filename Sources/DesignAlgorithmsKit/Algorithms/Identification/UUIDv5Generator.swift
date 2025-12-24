import Foundation
import CryptoKit

/// Generator for UUID v5 (SHA-1 based name-based UUIDs).
/// Reference: RFC 4122
public enum UUIDv5Generator: Sendable {
    
    /// Generates a UUID v5 for the given namespace and name.
    /// - Parameters:
    ///   - namespace: The namespace UUID.
    ///   - name: The name string.
    /// - Returns: A deterministic UUID v5.
    public static func generate(namespace: UUID, name: String) -> UUID {
        // 1. Convert Namespace UUID to bytes (Network Byte Order / Big Endian)
        let namespaceBytes = withUnsafeBytes(of: namespace.uuid) { Data($0) }
        
        // 2. Concatenate Namespace + Name
        var data = Data()
        data.append(namespaceBytes)
        data.append(Data(name.utf8))
        
        // 3. SHA-1 Hash
        let digest = Insecure.SHA1.hash(data: data)
        // SHA-1 is 20 bytes
        var hashBytes = Array(digest)
        
        // 4. Truncate to 16 bytes
        guard hashBytes.count >= 16 else { return UUID() }
        
        // 5. Set Version (5) and Variant (RFC 4122)
        // Version: bits 4-7 of octet 6 = 5 (0101)
        hashBytes[6] = (hashBytes[6] & 0x0F) | 0x50
        // Variant: bits 6-7 of octet 8 = 10 (10xx)
        hashBytes[8] = (hashBytes[8] & 0x3F) | 0x80
        
        // 6. Create UUID from bytes
        return UUID(uuid: (
            hashBytes[0], hashBytes[1], hashBytes[2], hashBytes[3],
            hashBytes[4], hashBytes[5], hashBytes[6], hashBytes[7],
            hashBytes[8], hashBytes[9], hashBytes[10], hashBytes[11],
            hashBytes[12], hashBytes[13], hashBytes[14], hashBytes[15]
        ))
    }
}
