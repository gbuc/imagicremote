import XCTest
import iMagicRemoteCore

final class WireTests: XCTestCase {
  func testParseMoveClamps() {
    let msg = Wire.parse(text: #"{"t":"move","x":1.5,"y":-0.2}"#)
    XCTAssertEqual(msg, .move(x: 1.0, y: 0.0))
  }

  func testParseDownUp() {
    XCTAssertEqual(Wire.parse(text: #"{"t":"down"}"#), .down)
    XCTAssertEqual(Wire.parse(text: #"{"t":"up"}"#), .up)
  }

  func testParseDownIgnoresExtraFields() {
    XCTAssertEqual(Wire.parse(text: #"{"t":"down","foo":1}"#), .down)
  }

  func testParseRightAndScroll() {
    XCTAssertEqual(Wire.parse(text: #"{"t":"rdown"}"#), .rdown)
    XCTAssertEqual(Wire.parse(text: #"{"t":"rup"}"#), .rup)
    XCTAssertEqual(
      Wire.parse(text: #"{"t":"scroll","dx":0,"dy":3}"#),
      .scroll(dx: 0, dy: 3)
    )
    XCTAssertEqual(
      Wire.parse(text: #"{"t":"scroll","dy":-1}"#),
      .scroll(dx: 0, dy: -1)
    )
  }

  func testScrollClampsAndIgnoresEmpty() {
    XCTAssertEqual(
      Wire.parse(text: #"{"t":"scroll","dx":99,"dy":-99}"#),
      .scroll(dx: 20, dy: -20)
    )
    XCTAssertNil(Wire.parse(text: #"{"t":"scroll"}"#))
  }

  func testParseTextAndKeys() {
    XCTAssertEqual(Wire.parse(text: #"{"t":"text","s":"Hi"}"#), .text("Hi"))
    XCTAssertEqual(Wire.parse(text: #"{"t":"key","k":"enter"}"#), .keyEnter)
    XCTAssertEqual(Wire.parse(text: #"{"t":"key","k":"backspace"}"#), .keyBackspace)
    XCTAssertNil(Wire.parse(text: #"{"t":"text","s":""}"#))
    XCTAssertNil(Wire.parse(text: #"{"t":"key","k":"tab"}"#))
  }

  func testUnknownTypeAndInvalidJSONAreNil() {
    XCTAssertNil(Wire.parse(text: #"{"t":"nope"}"#))
    XCTAssertNil(Wire.parse(text: #"{"t":"move"}"#))
    XCTAssertNil(Wire.parse(text: "not-json"))
  }
}
