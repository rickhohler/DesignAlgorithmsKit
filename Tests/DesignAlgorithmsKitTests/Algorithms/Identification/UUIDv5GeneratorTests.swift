import XCTest
@testable import DesignAlgorithmsKit

final class UUIDv5GeneratorTests: XCTestCase {
    
    // Known Test Vectors from RFC 4122 Appendix B (if applicable) or online generators.
    // RFC 4122 uses DNS namespace for example, but we can verify determinism easily.
    
    func testDeterminism() {
        let namespace = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")! // DNS Namespace
        let name = "www.widgets.com"
        
        let uuid1 = UUIDv5Generator.generate(namespace: namespace, name: name)
        let uuid2 = UUIDv5Generator.generate(namespace: namespace, name: name)
        
        XCTAssertEqual(uuid1, uuid2, "UUIDv5 must be deterministic")
    }
    
    func testDifferentNamesProduceDifferentUUIDs() {
        let namespace = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
        
        let uuid1 = UUIDv5Generator.generate(namespace: namespace, name: "foo")
        let uuid2 = UUIDv5Generator.generate(namespace: namespace, name: "bar")
        
        XCTAssertNotEqual(uuid1, uuid2)
    }
    
    func testDifferentNamespacesProduceDifferentUUIDs() {
        let ns1 = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
        let ns2 = UUID(uuidString: "6ba7b811-9dad-11d1-80b4-00c04fd430c8")!
        let name = "foo"
        
        let uuid1 = UUIDv5Generator.generate(namespace: ns1, name: name)
        let uuid2 = UUIDv5Generator.generate(namespace: ns2, name: name)
        
        XCTAssertNotEqual(uuid1, uuid2)
    }
    
    func testKnownVector() {
        // Python: uuid.uuid5(uuid.NAMESPACE_DNS, 'python.org')
        // Output: 886313e1-3b8a-5372-9b90-0c9aee199e5d
        
        let dnsNamespace = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
        let name = "python.org"
        
        let generated = UUIDv5Generator.generate(namespace: dnsNamespace, name: name)
        
        XCTAssertEqual(generated.uuidString.lowercased(), "886313e1-3b8a-5372-9b90-0c9aee199e5d")
    }
    
    func testVersionAndVariant() {
        let namespace = UUID()
        let name = "test"
        let uuid = UUIDv5Generator.generate(namespace: namespace, name: name)
        
        // Check Version 5
        // UUID is 8-4-4-4-12 hex.
        // uuid.uuidString: XXXXXXXX-XXXX-MXXX-NXXX-XXXXXXXXXXXX
        // M should be 5.
        // N should be 8, 9, A, or B (Variant 1).
        
        let uuidStr = uuid.uuidString
        let chars = Array(uuidStr)
        
        // Version is 13th char (index 14 with dashes? no, specifically it's start of 3rd group)
        // 01234567-8901-2345-6789-012345678901
        // XXXXXXXX-XXXX-5XXX-....
        //              ^ index 14
        XCTAssertEqual(chars[14], "5", "UUID version should be 5")
        
        // Variant is 17th char (index 19)
        // XXXXXXXX-XXXX-XXXX-NXXX-....
        //                    ^ index 19
        let variantChar = chars[19]
        let validVariants: Set<Character> = ["8", "9", "A", "B"]
        XCTAssertTrue(validVariants.contains(variantChar), "UUID variant should be RFC 4122 (8, 9, A, or B), got \(variantChar)")
    }
}
