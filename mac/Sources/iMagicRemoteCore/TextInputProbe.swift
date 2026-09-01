import Foundation

public enum TextInputProbe {
  public static let delayNs: UInt64 = 80_000_000

  public static func isEditable(role: String?, subrole: String?, valueSettable: Bool) -> Bool {
    let r = role ?? ""
    let s = subrole ?? ""
    let named: Set<String> = [
      "AXTextField",
      "AXTextArea",
      "AXComboBox",
      "AXSearchField",
      "AXSecureTextField",
    ]
    if named.contains(r) || named.contains(s) { return true }
    if r.hasSuffix("TextField") || r.hasSuffix("TextArea") { return true }
    if valueSettable && (r.contains("Text") || s.contains("Text") || r.contains("Edit")) {
      return r != "AXStaticText"
    }
    return false
  }
}

public enum HostWire {
  public static func kbd(on: Bool) -> String {
    on ? #"{"t":"kbd","on":true}"# : #"{"t":"kbd","on":false}"#
  }

  public static let devExtend = #"{"t":"devextend"}"#
}
