import XCTest
import iMagicRemoteCore

final class DevModeScheduleTests: XCTestCase {
  func testDueWhenNeverExtended() {
    let state = DevModeState(lastExtend: nil, sessionToken: "abc")
    XCTAssertTrue(DevModeSchedule.isDue(state: state, now: Date()))
  }

  func testFirstConnectDueWithoutToken() {
    let state = DevModeState(lastExtend: nil, sessionToken: nil)
    XCTAssertTrue(DevModeSchedule.isDue(state: state, now: Date()))
  }

  func testDueAfterThirtyDays() {
    let last = Date(timeIntervalSince1970: 0)
    let state = DevModeState(lastExtend: last, sessionToken: "abc")
    let day29 = last.addingTimeInterval(29 * 24 * 60 * 60)
    let day30 = last.addingTimeInterval(30 * 24 * 60 * 60)
    XCTAssertFalse(DevModeSchedule.isDue(state: state, now: day29))
    XCTAssertTrue(DevModeSchedule.isDue(state: state, now: day30))
  }

  func testFirstConnectIsDueAfterTokenMigration() {
    let old = DevModeState(lastExtend: Date(), sessionToken: "abc")
    let merged = DevModeSchedule.merge(current: nil, legacy: [old])
    XCTAssertEqual(merged.sessionToken, "abc")
    XCTAssertNil(merged.lastExtend)
    XCTAssertTrue(DevModeSchedule.isDue(state: merged, now: Date()))
  }

  func testCurrentStoreWins() {
    let current = DevModeState(lastExtend: Date(timeIntervalSince1970: 1), sessionToken: "new")
    let old = DevModeState(lastExtend: Date(timeIntervalSince1970: 2), sessionToken: "old")
    let merged = DevModeSchedule.merge(current: current, legacy: [old])
    XCTAssertEqual(merged, current)
  }

  func testParseResetJSON() {
    let ok = Data(#"{"result":"success","errorCode":"200","errorMsg":"GNL"}"#.utf8)
    XCTAssertTrue(DevModeAPI.parseReset(data: ok))
    let bad = Data(#"{"result":"fail"}"#.utf8)
    XCTAssertFalse(DevModeAPI.parseReset(data: bad))
  }

  func testParseRemaining() {
    let ok = Data(#"{"result":"success","errorCode":"200","errorMsg":"999:58:40"}"#.utf8)
    XCTAssertEqual(DevModeAPI.parseRemaining(data: ok), "999:58")
    let fail = Data(#"{"result":"fail","errorMsg":"expired"}"#.utf8)
    XCTAssertNil(DevModeAPI.parseRemaining(data: fail))
    let gn = Data(#"{"result":"success","errorCode":"200","errorMsg":"GNL"}"#.utf8)
    XCTAssertNil(DevModeAPI.parseRemaining(data: gn))
  }
}
