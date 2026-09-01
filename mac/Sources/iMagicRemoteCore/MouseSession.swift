import Foundation

public enum InjectCommand: Equatable, Sendable {
  case move(CGPoint)
  case drag(CGPoint)
  case leftDown(CGPoint)
  case leftUp(CGPoint)
  case rightDown(CGPoint)
  case rightUp(CGPoint)
  case scroll(dx: Int32, dy: Int32)
  case text(String)
  case keyEnter
  case keyBackspace
}

public struct MouseSession {
  public var target: CGRect
  public var primary: CGRect
  public private(set) var lastPoint: CGPoint?
  public private(set) var isDown = false
  public private(set) var isRightDown = false

  public init(target: CGRect, primary: CGRect) {
    self.target = target
    self.primary = primary
  }

  public mutating func apply(_ message: WireMessage) -> [InjectCommand] {
    switch message {
    case .move(let x, let y):
      let point = Mapper.quartzPoint(x: x, y: y, target: target, primary: primary)
      lastPoint = point
      return [isDown ? .drag(point) : .move(point)]
    case .down:
      guard let point = lastPoint, !isDown else { return [] }
      isDown = true
      return [.leftDown(point)]
    case .up:
      guard let point = lastPoint, isDown else { return [] }
      isDown = false
      return [.leftUp(point)]
    case .rdown:
      guard let point = lastPoint, !isRightDown else { return [] }
      isRightDown = true
      return [.rightDown(point)]
    case .rup:
      guard let point = lastPoint, isRightDown else { return [] }
      isRightDown = false
      return [.rightUp(point)]
    case .scroll(let dx, let dy):
      return [.scroll(dx: dx, dy: dy)]
    case .text(let s):
      return s.isEmpty ? [] : [.text(s)]
    case .keyEnter:
      return [.keyEnter]
    case .keyBackspace:
      return [.keyBackspace]
    }
  }

  public mutating func disconnected() -> [InjectCommand] {
    guard let point = lastPoint else { return [] }
    var commands: [InjectCommand] = []
    if isDown {
      isDown = false
      commands.append(.leftUp(point))
    }
    if isRightDown {
      isRightDown = false
      commands.append(.rightUp(point))
    }
    return commands
  }
}
