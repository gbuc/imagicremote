import CoreGraphics
import Foundation

public struct ScreenPick: Equatable, Sendable {
  public var name: String
  public var frame: CGRect
  public init(name: String, frame: CGRect) {
    self.name = name
    self.frame = frame
  }
}

public struct SavedScreen: Equatable, Sendable, Codable {
  public var name: String
  public var width: Double
  public var height: Double
  public init(name: String, width: Double, height: Double) {
    self.name = name
    self.width = width
    self.height = height
  }
}

public enum ScreenSelection {
  public static func pickDefault(_ screens: [ScreenPick]) -> ScreenPick? {
    screens.count == 1 ? screens[0] : nil
  }

  public static func resolve(saved: SavedScreen?, screens: [ScreenPick]) -> ScreenPick? {
    if let saved,
       let match = screens.first(where: {
         $0.name == saved.name
           && Double($0.frame.width) == saved.width
           && Double($0.frame.height) == saved.height
       })
    {
      return match
    }
    return pickDefault(screens)
  }
}
