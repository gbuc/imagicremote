import XCTest
import iMagicRemoteCore

final class TextInputProbeTests: XCTestCase {
  func testNamedEditableRoles() {
    XCTAssertTrue(TextInputProbe.isEditable(role: "AXTextField", subrole: nil, valueSettable: false))
    XCTAssertTrue(TextInputProbe.isEditable(role: "AXTextArea", subrole: nil, valueSettable: false))
    XCTAssertTrue(TextInputProbe.isEditable(role: "AXComboBox", subrole: nil, valueSettable: false))
    XCTAssertTrue(TextInputProbe.isEditable(role: "AXSearchField", subrole: nil, valueSettable: false))
    XCTAssertTrue(TextInputProbe.isEditable(role: "AXSecureTextField", subrole: nil, valueSettable: false))
    XCTAssertTrue(TextInputProbe.isEditable(role: "AXGroup", subrole: "AXSearchField", valueSettable: false))
  }

  func testButtonsAndStaticTextAreNotEditable() {
    XCTAssertFalse(TextInputProbe.isEditable(role: "AXButton", subrole: nil, valueSettable: false))
    XCTAssertFalse(TextInputProbe.isEditable(role: "AXWebArea", subrole: nil, valueSettable: false))
    XCTAssertFalse(TextInputProbe.isEditable(role: "AXStaticText", subrole: nil, valueSettable: true))
  }

  func testSettableTextishRoles() {
    XCTAssertTrue(TextInputProbe.isEditable(role: "AXText", subrole: nil, valueSettable: true))
    XCTAssertFalse(TextInputProbe.isEditable(role: "AXGroup", subrole: nil, valueSettable: true))
  }

  func testKbdWire() {
    XCTAssertEqual(HostWire.kbd(on: true), #"{"t":"kbd","on":true}"#)
    XCTAssertEqual(HostWire.kbd(on: false), #"{"t":"kbd","on":false}"#)
    XCTAssertEqual(HostWire.devExtend, #"{"t":"devextend"}"#)
  }
}
