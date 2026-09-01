import XCTest
import iMagicRemoteCore

final class AresDeviceTests: XCTestCase {
  func testParsesTelevisionAndSkipsEmulator() {
    let json = """
    [
      {"name":"emulator","host":"127.0.0.1","port":6622,"username":"developer","privateKey":{"openSsh":"webos_emul"}},
      {"name":"tv","host":"192.0.2.10","port":9922,"username":"prisoner","passphrase":"secret","privateKey":{"openSsh":"tv_webos"}}
    ]
    """.data(using: .utf8)!
    let all = AresDeviceList.parse(novacomJSON: json)
    let tvs = AresDeviceList.televisions(in: all)
    XCTAssertEqual(tvs.count, 1)
    XCTAssertEqual(tvs[0].host, "192.0.2.10")
    XCTAssertEqual(tvs[0].keyFileName, "tv_webos")
    XCTAssertEqual(tvs[0].passphrase, "secret")
  }

  func testParseTokenFile() {
    XCTAssertEqual(AresDeviceList.parseTokenFile("  abcDEF123 \n"), "abcDEF123")
    XCTAssertNil(AresDeviceList.parseTokenFile(""))
    XCTAssertNil(AresDeviceList.parseTokenFile("two words"))
  }
}
