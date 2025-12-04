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
    
    func testBaseBuilderNotImplemented() {
        // Given
        struct TestObject {
            let value: String
        }
        
        class TestBuilder: BaseBuilder<TestObject> {
            // Doesn't override build()
        }
        
        // When/Then
        XCTAssertThrowsError(try TestBuilder().build()) { error in
            if case BuilderError.notImplemented = error {
                // Expected error
            } else {
                XCTFail("Expected BuilderError.notImplemented, got \(error)")
            }
        }
    }
    
    func testBuilderErrorLocalizedDescription() {
        // Test notImplemented
        let notImplemented = BuilderError.notImplemented
        XCTAssertEqual(notImplemented.localizedDescription, "Builder build() method not implemented")
        
        // Test missingRequiredProperty
        let missing = BuilderError.missingRequiredProperty("testProperty")
        XCTAssertEqual(missing.localizedDescription, "Required property 'testProperty' is missing")
        
        // Test invalidValue
        let invalid = BuilderError.invalidValue("testProperty", "must be positive")
        XCTAssertEqual(invalid.localizedDescription, "Invalid value for 'testProperty': must be positive")
    }
    
    func testBuilderFluentAPI() throws {
        // Given
        struct ComplexObject {
            let name: String
            let age: Int
            let email: String?
            let tags: [String]
        }
        
        class ComplexObjectBuilder: BaseBuilder<ComplexObject> {
            private var name: String?
            private var age: Int?
            private var email: String?
            private var tags: [String] = []
            
            func setName(_ name: String) -> Self {
                self.name = name
                return self
            }
            
            func setAge(_ age: Int) -> Self {
                self.age = age
                return self
            }
            
            func setEmail(_ email: String?) -> Self {
                self.email = email
                return self
            }
            
            func addTag(_ tag: String) -> Self {
                self.tags.append(tag)
                return self
            }
            
            override func build() throws -> ComplexObject {
                guard let name = name else {
                    throw BuilderError.missingRequiredProperty("name")
                }
                guard let age = age else {
                    throw BuilderError.missingRequiredProperty("age")
                }
                return ComplexObject(name: name, age: age, email: email, tags: tags)
            }
        }
        
        // When - Test fluent API chaining
        let object = try ComplexObjectBuilder()
            .setName("John Doe")
            .setAge(30)
            .setEmail("john@example.com")
            .addTag("developer")
            .addTag("swift")
            .build()
        
        // Then
        XCTAssertEqual(object.name, "John Doe")
        XCTAssertEqual(object.age, 30)
        XCTAssertEqual(object.email, "john@example.com")
        XCTAssertEqual(object.tags, ["developer", "swift"])
    }
    
    func testBuilderWithOptionalProperties() throws {
        // Given
        struct OptionalObject {
            let required: String
            let optional: String?
        }
        
        class OptionalObjectBuilder: BaseBuilder<OptionalObject> {
            private var required: String?
            private var optional: String?
            
            func setRequired(_ value: String) -> Self {
                self.required = value
                return self
            }
            
            func setOptional(_ value: String?) -> Self {
                self.optional = value
                return self
            }
            
            override func build() throws -> OptionalObject {
                guard let required = required else {
                    throw BuilderError.missingRequiredProperty("required")
                }
                return OptionalObject(required: required, optional: optional)
            }
        }
        
        // When/Then - With optional value
        let object1 = try OptionalObjectBuilder()
            .setRequired("required")
            .setOptional("optional")
            .build()
        XCTAssertEqual(object1.required, "required")
        XCTAssertEqual(object1.optional, "optional")
        
        // When/Then - Without optional value
        let object2 = try OptionalObjectBuilder()
            .setRequired("required")
            .setOptional(nil)
            .build()
        XCTAssertEqual(object2.required, "required")
        XCTAssertNil(object2.optional)
    }
    
    func testBuilderMultipleInstances() throws {
        // Given
        struct SimpleObject {
            let value: String
        }
        
        class SimpleBuilder: BaseBuilder<SimpleObject> {
            private var value: String?
            
            func setValue(_ value: String) -> Self {
                self.value = value
                return self
            }
            
            override func build() throws -> SimpleObject {
                guard let value = value else {
                    throw BuilderError.missingRequiredProperty("value")
                }
                return SimpleObject(value: value)
            }
        }
        
        // When - Create multiple instances
        let builder1 = SimpleBuilder()
        let builder2 = SimpleBuilder()
        
        let object1 = try builder1.setValue("value1").build()
        let object2 = try builder2.setValue("value2").build()
        
        // Then - Each builder should be independent
        XCTAssertEqual(object1.value, "value1")
        XCTAssertEqual(object2.value, "value2")
    }
    
    func testValidatingBuilderProtocolDefault() throws {
        // Given
        struct TestObject {
            let value: Int
        }
        
        class DefaultValidatingBuilder: BaseBuilder<TestObject>, ValidatingBuilderProtocol {
            private var value: Int?
            
            func setValue(_ value: Int) -> Self {
                self.value = value
                return self
            }
            
            override func build() throws -> TestObject {
                guard let value = value else {
                    throw BuilderError.missingRequiredProperty("value")
                }
                return TestObject(value: value)
            }
        }
        
        // When/Then - Default validation should not throw
        let object = try DefaultValidatingBuilder()
            .setValue(42)
            .build()
        XCTAssertEqual(object.value, 42)
    }
    
    func testValidatingBuilderWithCustomValidation() throws {
        // Given
        struct User {
            let username: String
            let age: Int
        }
        
        class UserBuilder: BaseBuilder<User>, ValidatingBuilderProtocol {
            private var username: String?
            private var age: Int?
            
            func setUsername(_ username: String) -> Self {
                self.username = username
                return self
            }
            
            func setAge(_ age: Int) -> Self {
                self.age = age
                return self
            }
            
            func validate() throws {
                guard let username = username else {
                    throw BuilderError.missingRequiredProperty("username")
                }
                if username.count < 3 {
                    throw BuilderError.invalidValue("username", "must be at least 3 characters")
                }
                
                guard let age = age else {
                    throw BuilderError.missingRequiredProperty("age")
                }
                if age < 0 {
                    throw BuilderError.invalidValue("age", "must be non-negative")
                }
                if age > 150 {
                    throw BuilderError.invalidValue("age", "must be less than 150")
                }
            }
            
            override func build() throws -> User {
                try validate()
                return User(username: username!, age: age!)
            }
        }
        
        // When/Then - Valid user
        let validUser = try UserBuilder()
            .setUsername("johndoe")
            .setAge(30)
            .build()
        XCTAssertEqual(validUser.username, "johndoe")
        XCTAssertEqual(validUser.age, 30)
        
        // When/Then - Invalid username (too short)
        XCTAssertThrowsError(try UserBuilder().setUsername("ab").setAge(30).build()) { error in
            if case BuilderError.invalidValue(let property, _) = error {
                XCTAssertEqual(property, "username")
            } else {
                XCTFail("Expected invalidValue error for username")
            }
        }
        
        // When/Then - Invalid age (negative)
        XCTAssertThrowsError(try UserBuilder().setUsername("johndoe").setAge(-1).build()) { error in
            if case BuilderError.invalidValue(let property, _) = error {
                XCTAssertEqual(property, "age")
            } else {
                XCTFail("Expected invalidValue error for age")
            }
        }
        
        // When/Then - Invalid age (too high)
        XCTAssertThrowsError(try UserBuilder().setUsername("johndoe").setAge(200).build()) { error in
            if case BuilderError.invalidValue(let property, _) = error {
                XCTAssertEqual(property, "age")
            } else {
                XCTFail("Expected invalidValue error for age")
            }
        }
    }
    
    func testBuilderErrorEquality() {
        // Test that error cases can be matched
        let error1 = BuilderError.missingRequiredProperty("test")
        let error2 = BuilderError.missingRequiredProperty("test")
        
        // Use pattern matching to verify
        if case BuilderError.missingRequiredProperty(let prop1) = error1,
           case BuilderError.missingRequiredProperty(let prop2) = error2 {
            XCTAssertEqual(prop1, prop2)
        } else {
            XCTFail("Error pattern matching failed")
        }
    }
    
    func testBuilderReuse() throws {
        // Given
        struct Config {
            let host: String
            let port: Int
        }
        
        class ConfigBuilder: BaseBuilder<Config> {
            private var host: String?
            private var port: Int?
            
            func setHost(_ host: String) -> Self {
                self.host = host
                return self
            }
            
            func setPort(_ port: Int) -> Self {
                self.port = port
                return self
            }
            
            override func build() throws -> Config {
                guard let host = host else {
                    throw BuilderError.missingRequiredProperty("host")
                }
                guard let port = port else {
                    throw BuilderError.missingRequiredProperty("port")
                }
                return Config(host: host, port: port)
            }
        }
        
        // When - Reuse builder instance
        let builder = ConfigBuilder()
        
        let config1 = try builder
            .setHost("localhost")
            .setPort(8080)
            .build()
        
        // Reset and build again
        let config2 = try builder
            .setHost("example.com")
            .setPort(443)
            .build()
        
        // Then - Last values should be used
        XCTAssertEqual(config1.host, "localhost")
        XCTAssertEqual(config1.port, 8080)
        XCTAssertEqual(config2.host, "example.com")
        XCTAssertEqual(config2.port, 443)
    }
}

