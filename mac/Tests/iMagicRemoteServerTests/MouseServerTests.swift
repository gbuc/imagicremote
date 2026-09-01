import XCTest
import iMagicRemoteCore
import iMagicRemoteServer

final class MouseServerTests: XCTestCase {
  func testTextFrameBecomesMove() async throws {
    let got = expectation(description: "move")
    got.assertForOverFulfill = false
    let box = MessageBox()
    let port: UInt16 = 18799
    let server = MouseServer(
      host: "127.0.0.1",
      port: port,
      onMessage: { msg in
        Task { await box.set(msg); got.fulfill() }
      },
      onDisconnect: {}
    )
    let run = Task { try await server.start() }
    try await Task.sleep(nanoseconds: 200_000_000)

    let url = URL(string: "ws://127.0.0.1:\(port)/")!
    let ws = URLSession.shared.webSocketTask(with: url)
    ws.resume()
    try await ws.send(.string(#"{"t":"move","x":0.25,"y":0.75}"#))

    await fulfillment(of: [got], timeout: 2)
    let msg = await box.value
    XCTAssertEqual(msg, .move(x: 0.25, y: 0.75))

    ws.cancel(with: .goingAway, reason: nil)
    await server.stop()
    run.cancel()
  }

  func testUnknownJSONDoesNotCallback() async throws {
    let bad = expectation(description: "should not fire")
    bad.isInverted = true
    let server = MouseServer(
      host: "127.0.0.1",
      port: 18798,
      onMessage: { _ in bad.fulfill() },
      onDisconnect: {}
    )
    let run = Task { try await server.start() }
    try await Task.sleep(nanoseconds: 200_000_000)
    let ws = URLSession.shared.webSocketTask(with: URL(string: "ws://127.0.0.1:18798/")!)
    ws.resume()
    try await ws.send(.string(#"{"t":"scroll"}"#))
    await fulfillment(of: [bad], timeout: 0.4)
    ws.cancel(with: .goingAway, reason: nil)
    await server.stop()
    run.cancel()
  }

  func testConnectFiresOnOpenWithoutMessage() async throws {
    let got = expectation(description: "connect")
    let port: UInt16 = 18797
    let server = MouseServer(
      host: "127.0.0.1",
      port: port,
      onMessage: { _ in XCTFail("no message expected") },
      onConnect: { got.fulfill() },
      onDisconnect: {}
    )
    let run = Task { try await server.start() }
    try await Task.sleep(nanoseconds: 200_000_000)
    let ws = URLSession.shared.webSocketTask(with: URL(string: "ws://127.0.0.1:\(port)/")!)
    ws.resume()
    await fulfillment(of: [got], timeout: 2)
    ws.cancel(with: .goingAway, reason: nil)
    await server.stop()
    run.cancel()
  }

  func testReplaceClientDropsPreviousSocket() async throws {
    let connects = expectation(description: "two connects")
    connects.expectedFulfillmentCount = 2
    let disconnected = expectation(description: "replaced client disconnect")
    disconnected.assertForOverFulfill = false
    let moves = expectation(description: "exactly one move")
    let port: UInt16 = 18796
    let server = MouseServer(
      host: "127.0.0.1",
      port: port,
      onMessage: { _ in moves.fulfill() },
      onConnect: { connects.fulfill() },
      onDisconnect: { disconnected.fulfill() }
    )
    let run = Task { try await server.start() }
    try await Task.sleep(nanoseconds: 200_000_000)

    let ws1 = URLSession.shared.webSocketTask(with: URL(string: "ws://127.0.0.1:\(port)/")!)
    ws1.resume()
    let ws2 = URLSession.shared.webSocketTask(with: URL(string: "ws://127.0.0.1:\(port)/")!)
    ws2.resume()
    await fulfillment(of: [connects, disconnected], timeout: 2)

    try? await ws1.send(.string(#"{"t":"move","x":0.1,"y":0.1}"#))
    try? await ws2.send(.string(#"{"t":"move","x":0.9,"y":0.9}"#))
    await fulfillment(of: [moves], timeout: 2)

    ws1.cancel(with: .goingAway, reason: nil)
    ws2.cancel(with: .goingAway, reason: nil)
    await server.stop()
    run.cancel()
  }

  func testServerCanPushKbdFrame() async throws {
    let connected = expectation(description: "connect")
    let port: UInt16 = 18795
    let server = MouseServer(
      host: "127.0.0.1",
      port: port,
      onMessage: { _ in },
      onConnect: { connected.fulfill() },
      onDisconnect: {}
    )
    let run = Task { try await server.start() }
    try await Task.sleep(nanoseconds: 200_000_000)
    let ws = URLSession.shared.webSocketTask(with: URL(string: "ws://127.0.0.1:\(port)/")!)
    ws.resume()
    await fulfillment(of: [connected], timeout: 2)
    server.send(HostWire.kbd(on: true))
    let got = try await ws.receive()
    if case .string(let text) = got {
      XCTAssertEqual(text, HostWire.kbd(on: true))
    } else {
      XCTFail("expected text frame")
    }
    ws.cancel(with: .goingAway, reason: nil)
    await server.stop()
    run.cancel()
  }
}

actor MessageBox {
  var value: WireMessage?
  func set(_ msg: WireMessage) { value = msg }
}
