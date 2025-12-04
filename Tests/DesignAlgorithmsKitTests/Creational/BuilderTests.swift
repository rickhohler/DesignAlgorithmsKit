//
//  BuilderTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Builder Pattern
//

import XCTest
@testable import DesignAlgorithmsKit

final class BuilderTests: XCTestCase {
    func testBuilderPattern() throws {
        // Given
        struct TestObject {
            let property1: String
            let property2: Int
        }
        
        class TestObjectBuilder: BaseBuilder<TestObject> {
            private var property1: String?
            private var property2: Int?
            
            func setProperty1(_ value: String) -> Self {
                self.property1 = value
                return self
            }
            
            func setProperty2(_ value: Int) -> Self {
                self.property2 = value
                return self
            }
            
            override func build() throws -> TestObject {
                guard let property1 = property1 else {
                    throw BuilderError.missingRequiredProperty("property1")
                }
                guard let property2 = property2 else {
                    throw BuilderError.missingRequiredProperty("property2")
                }
                return TestObject(property1: property1, property2: property2)
            }
        }
        
        // When
        let object = try TestObjectBuilder()
            .setProperty1("value1")
            .setProperty2(42)
            .build()
        
        // Then
        XCTAssertEqual(object.property1, "value1")
        XCTAssertEqual(object.property2, 42)
    }
    
    func testBuilderMissingProperty() {
        // Given
        struct TestObject {
            let property: String
        }
        
        class TestObjectBuilder: BaseBuilder<TestObject> {
            override func build() throws -> TestObject {
                throw BuilderError.missingRequiredProperty("property")
            }
        }
        
        // When/Then
        XCTAssertThrowsError(try TestObjectBuilder().build()) { error in
            if case BuilderError.missingRequiredProperty(let property) = error {
                XCTAssertEqual(property, "property")
            } else {
                XCTFail("Unexpected error type")
            }
        }
    }
    
    func testValidatingBuilder() throws {
        // Given
        struct TestObject {
            let value: Int
        }
        
        class ValidatingBuilder: BaseBuilder<TestObject>, ValidatingBuilderProtocol {
            private var value: Int?
            
            func setValue(_ value: Int) -> Self {
                self.value = value
                return self
            }
            
            func validate() throws {
                guard let value = value else {
                    throw BuilderError.missingRequiredProperty("value")
                }
                if value < 0 {
                    throw BuilderError.invalidValue("value", "must be non-negative")
                }
            }
            
            override func build() throws -> TestObject {
                try validate()
                return TestObject(value: value!)
            }
        }
        
        // When/Then - Valid value
        let object = try ValidatingBuilder()
            .setValue(42)
            .build()
        XCTAssertEqual(object.value, 42)
        
        // When/Then - Invalid value
        XCTAssertThrowsError(try ValidatingBuilder().setValue(-1).build())
    }
}

