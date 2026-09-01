import ApplicationServices
import Foundation
import iMagicRemoteCore

enum FocusedTextInput {
  static func isEditable() -> Bool {
    let system = AXUIElementCreateSystemWide()
    var focused: CFTypeRef?
    guard AXUIElementCopyAttributeValue(
      system,
      kAXFocusedUIElementAttribute as CFString,
      &focused
    ) == .success, let focused else { return false }
    let el = focused as! AXUIElement
    var roleRef: CFTypeRef?
    AXUIElementCopyAttributeValue(el, kAXRoleAttribute as CFString, &roleRef)
    var subRef: CFTypeRef?
    AXUIElementCopyAttributeValue(el, kAXSubroleAttribute as CFString, &subRef)
    var settable = DarwinBoolean(false)
    AXUIElementIsAttributeSettable(el, kAXValueAttribute as CFString, &settable)
    return TextInputProbe.isEditable(
      role: roleRef as? String,
      subrole: subRef as? String,
      valueSettable: settable.boolValue
    )
  }
}
