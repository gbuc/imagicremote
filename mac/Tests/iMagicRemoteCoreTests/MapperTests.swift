import XCTest
import iMagicRemoteCore

final class MapperTests: XCTestCase {
  let hd1080 = CGRect(x: 0, y: 0, width: 1920, height: 1080)

  func testOriginAndFarCornerOnSingleScreen() {
    let tl = Mapper.quartzPoint(x: 0, y: 0, target: hd1080, primary: hd1080)
    XCTAssertEqual(tl, CGPoint(x: 0, y: 0))
    let br = Mapper.quartzPoint(x: 1, y: 1, target: hd1080, primary: hd1080)
    XCTAssertEqual(br, CGPoint(x: 1920, y: 1080))
    let mid = Mapper.quartzPoint(x: 0.5, y: 0.5, target: hd1080, primary: hd1080)
    XCTAssertEqual(mid, CGPoint(x: 960, y: 540))
  }

  func testFourK() {
    let uhd = CGRect(x: 0, y: 0, width: 3840, height: 2160)
    let mid = Mapper.quartzPoint(x: 0.5, y: 0.5, target: uhd, primary: uhd)
    XCTAssertEqual(mid, CGPoint(x: 1920, y: 1080))
  }

  func testTargetToTheRightOfPrimary() {
    let primary = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let target = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
    let p = Mapper.quartzPoint(x: 0, y: 0, target: target, primary: primary)
    XCTAssertEqual(p, CGPoint(x: 1920, y: 0))
  }

  func testTargetAbovePrimaryUsesNegativeQuartzY() {
    let primary = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let target = CGRect(x: 0, y: 1080, width: 1920, height: 1080)
    let p = Mapper.quartzPoint(x: 0.5, y: 0, target: target, primary: primary)
    XCTAssertEqual(p, CGPoint(x: 960, y: -1080))
  }
}
