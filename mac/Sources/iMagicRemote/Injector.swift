import ApplicationServices
import CoreGraphics
import Foundation
import iMagicRemoteCore

enum CGEventInjector {
  static func post(_ commands: [InjectCommand]) {
    guard AXIsProcessTrusted() else { return }
    for command in commands {
      switch command {
      case .scroll(let dx, let dy):
        // Wire dy > 0 is DOM scroll-down; Quartz wheel1 > 0 is scroll-up.
        guard let event = CGEvent(
          scrollWheelEvent2Source: nil,
          units: .line,
          wheelCount: 2,
          wheel1: -dy,
          wheel2: dx,
          wheel3: 0
        ) else { continue }
        event.post(tap: .cghidEventTap)
      case .move(let p):
        postMouse(.mouseMoved, p, .left)
      case .drag(let p):
        postMouse(.leftMouseDragged, p, .left)
      case .leftDown(let p):
        postMouse(.leftMouseDown, p, .left)
      case .leftUp(let p):
        postMouse(.leftMouseUp, p, .left)
      case .rightDown(let p):
        postMouse(.rightMouseDown, p, .right)
      case .rightUp(let p):
        postMouse(.rightMouseUp, p, .right)
      case .text(let s):
        postUnicode(s)
      case .keyEnter:
        postKey(0x24)
      case .keyBackspace:
        postKey(0x33)
      }
    }
  }

  private static func postKey(_ code: CGKeyCode) {
    guard let down = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true),
          let up = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false)
    else { return }
    down.flags = []
    up.flags = []
    down.post(tap: .cghidEventTap)
    up.post(tap: .cghidEventTap)
  }

  private static func postUnicode(_ string: String) {
    guard !string.isEmpty else { return }
    let chars = Array(string.utf16)
    guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
          let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
    else { return }
    chars.withUnsafeBufferPointer { buf in
      down.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: buf.baseAddress)
      up.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: buf.baseAddress)
    }
    down.flags = []
    up.flags = []
    down.post(tap: .cghidEventTap)
    up.post(tap: .cghidEventTap)
  }

  private static func postMouse(_ type: CGEventType, _ point: CGPoint, _ button: CGMouseButton) {
    guard let event = CGEvent(
      mouseEventSource: nil,
      mouseType: type,
      mouseCursorPosition: point,
      mouseButton: button
    ) else { return }
    event.post(tap: .cghidEventTap)
  }
}
