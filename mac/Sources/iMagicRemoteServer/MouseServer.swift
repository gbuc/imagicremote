import FlyingFox
import Foundation
import iMagicRemoteCore

public final class MouseServer: @unchecked Sendable {
  private let host: String
  private let port: UInt16
  private let onMessage: @Sendable (WireMessage) -> Void
  private let onConnect: @Sendable () -> Void
  private let onDisconnect: @Sendable () -> Void
  private var server: HTTPServer?
  private var runTask: Task<Void, Error>?
  private let lock = NSLock()
  private var generation = 0
  private var dropCurrent: (@Sendable () -> Void)?
  private var sendCurrent: (@Sendable (String) -> Void)?

  public init(
    host: String = "0.0.0.0",
    port: UInt16 = Wire.port,
    onMessage: @escaping @Sendable (WireMessage) -> Void,
    onConnect: @escaping @Sendable () -> Void = {},
    onDisconnect: @escaping @Sendable () -> Void
  ) {
    self.host = host
    self.port = port
    self.onMessage = onMessage
    self.onConnect = onConnect
    self.onDisconnect = onDisconnect
  }

  public func start() async throws {
    // FlyingFox treats timeout 0 as an immediate handler timeout (handshake 500).
    let http = HTTPServer(address: try .inet(ip4: host, port: port))
    let handler = MouseWSHandler(
      onOpen: { [weak self] drop, send in
        self?.replaceClient(drop: drop, send: send) ?? 0
      },
      onText: { [weak self] gen, text in
        guard let self else { return }
        self.lock.lock()
        let current = self.generation
        self.lock.unlock()
        guard gen == current else { return }
        if let msg = Wire.parse(text: text) {
          self.onMessage(msg)
        }
      },
      onClose: { [weak self] gen in
        self?.handleClose(generation: gen)
      }
    )
    await http.appendRoute("GET /", to: .webSocket(handler))
    server = http
    try await http.run()
  }

  public func send(_ text: String) {
    lock.lock()
    let send = sendCurrent
    lock.unlock()
    send?(text)
  }

  public func stop() async {
    await server?.stop(timeout: 0)
    runTask?.cancel()
    server = nil
  }

  private func replaceClient(
    drop: @escaping @Sendable () -> Void,
    send: @escaping @Sendable (String) -> Void
  ) -> Int {
    lock.lock()
    let previous = dropCurrent
    dropCurrent = drop
    sendCurrent = send
    generation += 1
    let gen = generation
    let hadPrevious = previous != nil
    lock.unlock()
    previous?()
    if hadPrevious {
      onDisconnect()
    }
    onConnect()
    return gen
  }

  private func handleClose(generation gen: Int) {
    lock.lock()
    let isCurrent = gen == generation
    if isCurrent {
      dropCurrent = nil
      sendCurrent = nil
    }
    lock.unlock()
    if isCurrent {
      onDisconnect()
    }
  }
}

private struct MouseWSHandler: WSMessageHandler {
  let onOpen: @Sendable (
    @escaping @Sendable () -> Void,
    @escaping @Sendable (String) -> Void
  ) -> Int
  let onText: @Sendable (Int, String) -> Void
  let onClose: @Sendable (Int) -> Void

  func makeMessages(for client: AsyncStream<WSMessage>) async throws -> AsyncStream<WSMessage> {
    let (stream, continuation) = AsyncStream<WSMessage>.makeStream()
    let drop: @Sendable () -> Void = {
      continuation.yield(.close(.goingAway))
      continuation.finish()
    }
    let send: @Sendable (String) -> Void = { text in
      continuation.yield(.text(text))
    }
    let gen = onOpen(drop, send)
    Task {
      for await message in client {
        switch message {
        case .text(let text):
          onText(gen, text)
        case .data:
          break
        case .close:
          onClose(gen)
          continuation.yield(.close(.goingAway))
          continuation.finish()
          return
        }
      }
      onClose(gen)
      continuation.finish()
    }
    return stream
  }
}
