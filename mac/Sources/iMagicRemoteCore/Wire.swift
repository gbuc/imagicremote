import Foundation

public enum WireMessage: Equatable, Sendable {
  case move(x: Double, y: Double)
  case down
  case up
  case rdown
  case rup
  case scroll(dx: Int32, dy: Int32)
  case text(String)
  case keyEnter
  case keyBackspace
}

public enum Wire {
  public static let port: UInt16 = 18734

  public static func parse(text: String) -> WireMessage? {
    parse(Data(text.utf8))
  }

  public static func parse(_ data: Data) -> WireMessage? {
    struct Payload: Decodable {
      var t: String
      var x: Double?
      var y: Double?
      var dx: Double?
      var dy: Double?
      var s: String?
      var k: String?
    }
    guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
      return nil
    }
    switch payload.t {
    case "move":
      guard let x = payload.x, let y = payload.y else { return nil }
      return .move(x: clamp01(x), y: clamp01(y))
    case "down":
      return .down
    case "up":
      return .up
    case "rdown":
      return .rdown
    case "rup":
      return .rup
    case "scroll":
      let dx = Int32((payload.dx ?? 0).rounded())
      let dy = Int32((payload.dy ?? 0).rounded())
      if dx == 0 && dy == 0 { return nil }
      return .scroll(dx: clampScroll(dx), dy: clampScroll(dy))
    case "text":
      guard let s = payload.s, !s.isEmpty else { return nil }
      return .text(String(s.prefix(256)))
    case "key":
      switch payload.k {
      case "enter": return .keyEnter
      case "backspace": return .keyBackspace
      default: return nil
      }
    default:
      return nil
    }
  }

  private static func clamp01(_ value: Double) -> Double {
    min(1, max(0, value))
  }

  private static func clampScroll(_ value: Int32) -> Int32 {
    min(20, max(-20, value))
  }
}
