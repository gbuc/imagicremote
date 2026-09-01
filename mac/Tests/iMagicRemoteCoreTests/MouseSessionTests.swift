import XCTest
import iMagicRemoteCore

final class MouseSessionTests: XCTestCase {
  let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

  func testMoveThenClick() {
    var session = MouseSession(target: screen, primary: screen)
    XCTAssertEqual(
      session.apply(.move(x: 0.5, y: 0.5)),
      [.move(CGPoint(x: 960, y: 540))]
    )
    XCTAssertEqual(session.apply(.down), [.leftDown(CGPoint(x: 960, y: 540))])
    XCTAssertEqual(session.apply(.up), [.leftUp(CGPoint(x: 960, y: 540))])
  }

  func testDownWithoutPointIsIgnored() {
    var session = MouseSession(target: screen, primary: screen)
    XCTAssertEqual(session.apply(.down), [])
    XCTAssertEqual(session.apply(.up), [])
  }

  func testMoveWhileDownIsDrag() {
    var session = MouseSession(target: screen, primary: screen)
    _ = session.apply(.move(x: 0, y: 0))
    _ = session.apply(.down)
    XCTAssertEqual(
      session.apply(.move(x: 1, y: 1)),
      [.drag(CGPoint(x: 1920, y: 1080))]
    )
  }

  func testDisconnectReleasesButton() {
    var session = MouseSession(target: screen, primary: screen)
    _ = session.apply(.move(x: 0.25, y: 0.25))
    _ = session.apply(.down)
    XCTAssertEqual(
      session.disconnected(),
      [.leftUp(CGPoint(x: 480, y: 270))]
    )
    XCTAssertFalse(session.isDown)
    XCTAssertEqual(session.disconnected(), [])
  }

  func testRightClickAndScroll() {
    var session = MouseSession(target: screen, primary: screen)
    _ = session.apply(.move(x: 0.5, y: 0.5))
    XCTAssertEqual(session.apply(.rdown), [.rightDown(CGPoint(x: 960, y: 540))])
    XCTAssertEqual(session.apply(.rup), [.rightUp(CGPoint(x: 960, y: 540))])
    XCTAssertEqual(session.apply(.scroll(dx: 0, dy: 2)), [.scroll(dx: 0, dy: 2)])
  }

  func testTextAndKeysDoNotNeedAPoint() {
    var session = MouseSession(target: screen, primary: screen)
    XCTAssertEqual(session.apply(.text("ok")), [.text("ok")])
    XCTAssertEqual(session.apply(.keyEnter), [.keyEnter])
    XCTAssertEqual(session.apply(.keyBackspace), [.keyBackspace])
  }

  func testDisconnectReleasesRightButton() {
    var session = MouseSession(target: screen, primary: screen)
    _ = session.apply(.move(x: 0.5, y: 0.5))
    _ = session.apply(.rdown)
    XCTAssertEqual(
      session.disconnected(),
      [.rightUp(CGPoint(x: 960, y: 540))]
    )
  }
}
