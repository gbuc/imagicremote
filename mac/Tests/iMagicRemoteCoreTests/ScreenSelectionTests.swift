import XCTest
import iMagicRemoteCore

final class ScreenSelectionTests: XCTestCase {
  func testSingleScreenIsDefault() {
    let only = ScreenPick(name: "LG", frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
    XCTAssertEqual(ScreenSelection.pickDefault([only]), only)
  }

  func testTwoScreensRequirePick() {
    let a = ScreenPick(name: "A", frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
    let b = ScreenPick(name: "B", frame: CGRect(x: 1920, y: 0, width: 3840, height: 2160))
    XCTAssertNil(ScreenSelection.pickDefault([a, b]))
  }

  func testResolveUsesSavedNameAndSize() {
    let a = ScreenPick(name: "A", frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
    let b = ScreenPick(name: "OLED", frame: CGRect(x: 1920, y: 0, width: 3840, height: 2160))
    let saved = SavedScreen(name: "OLED", width: 3840, height: 2160)
    XCTAssertEqual(ScreenSelection.resolve(saved: saved, screens: [a, b]), b)
  }

  func testResolveFallsBackWhenSavedGone() {
    let only = ScreenPick(name: "Now", frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
    let saved = SavedScreen(name: "OLED", width: 3840, height: 2160)
    XCTAssertEqual(ScreenSelection.resolve(saved: saved, screens: [only]), only)
  }

  func testResolveNilWhenSavedGoneAndMultiple() {
    let a = ScreenPick(name: "A", frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
    let b = ScreenPick(name: "B", frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080))
    let saved = SavedScreen(name: "OLED", width: 3840, height: 2160)
    XCTAssertNil(ScreenSelection.resolve(saved: saved, screens: [a, b]))
  }
}
