import XCTest
@testable import DesignAlgorithmsKit

final class DecoratorTests: XCTestCase {
    
    // Component Interface
    protocol TextComponent {
        func render() -> String
    }
    
    // Concrete Component
    class SimpleText: TextComponent {
        func render() -> String {
            return "Text"
        }
    }
    
    // Decorator
    class BoldDecorator: BaseDecorator<TextComponent>, TextComponent {
        func render() -> String {
            return "<b>" + component.render() + "</b>"
        }
    }
    
    class ItalicDecorator: BaseDecorator<TextComponent>, TextComponent {
        func render() -> String {
            return "<i>" + component.render() + "</i>"
        }
    }
    
    func testDecoratorChain() {
        let simple = SimpleText()
        XCTAssertEqual(simple.render(), "Text")
        
        let bold = BoldDecorator(simple)
        XCTAssertEqual(bold.render(), "<b>Text</b>")
        
        let boldItalic = ItalicDecorator(bold)
        XCTAssertEqual(boldItalic.render(), "<i><b>Text</b></i>")
    }
    
    func testBaseDecoratorProperties() {
        let simple = SimpleText()
        let decorator = BaseDecorator(simple)
        
        // Check access to underlying component
        XCTAssertTrue(decorator.component === simple)
    }
}
