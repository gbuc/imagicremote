import Foundation
import iMagicRemoteCore

final class DevModeExtender: @unchecked Sendable {
  static let shared = DevModeExtender()

  private let lock = NSLock()
  private var inFlight = false
  private var remainingClock: String?
  private(set) var state: DevModeState

  /// e.g. "Dev Mode 999:58 left", or nil if unknown.
  var remainingMenuTitle: String? {
    lock.lock()
    let clock = remainingClock
    lock.unlock()
    guard let clock else { return nil }
    return "Dev Mode \(clock) left"
  }

  private init() {
    state = Self.load()
  }

  func isDue(now: Date = Date()) -> Bool {
    lock.lock()
    let snapshot = state
    lock.unlock()
    return DevModeSchedule.isDue(state: snapshot, now: now)
  }

  func extendIfDue(now: Date = Date()) async {
    lock.lock()
    let snapshot = state
    lock.unlock()
    guard DevModeSchedule.isDue(state: snapshot, now: now) else { return }
    _ = await extend(force: false)
  }

  func extend(force: Bool) async -> Bool {
    lock.lock()
    if inFlight {
      lock.unlock()
      return false
    }
    var snapshot = state
    if !force && !DevModeSchedule.isDue(state: snapshot, now: Date()) {
      lock.unlock()
      return false
    }
    inFlight = true
    lock.unlock()
    var token = snapshot.sessionToken ?? ""
    DevModeLog.line("extend: force=\(force) tokenLen=\(token.count)")
    if token.isEmpty {
      DevModeLog.line("extend: fetching token from TV via SSH")
      if let fetched = await DevModeTV.fetchSessionToken() {
        token = fetched
        DevModeLog.line("extend: got token len=\(token.count)")
        lock.lock()
        snapshot.sessionToken = fetched
        state = snapshot
        lock.unlock()
        Self.save(snapshot)
      } else {
        lock.lock()
        inFlight = false
        lock.unlock()
        DevModeLog.line("extend: FAIL missing session token")
        return false
      }
    }
    guard let url = DevModeAPI.resetURL(token: token) else {
      lock.lock()
      inFlight = false
      lock.unlock()
      DevModeLog.line("extend: FAIL bad reset URL")
      return false
    }
    defer {
      lock.lock()
      inFlight = false
      lock.unlock()
    }
    do {
      let (data, response) = try await URLSession.shared.data(from: url)
      let code = (response as? HTTPURLResponse)?.statusCode ?? -1
      let body = String(data: data, encoding: .utf8) ?? ""
      DevModeLog.line("extend: HTTPS reset status=\(code) body=\(body)")
      guard DevModeAPI.parseReset(data: data) else {
        DevModeLog.line("extend: FAIL reset JSON not success")
        return false
      }
      lock.lock()
      snapshot.lastExtend = Date()
      state = snapshot
      lock.unlock()
      Self.save(snapshot)
      await DevModeTV.pressExtend()
      await refreshRemaining()
      DevModeLog.line("extend: remaining=\(remainingMenuTitle ?? "nil")")
      return true
    } catch {
      DevModeLog.line("extend: FAIL network \(error)")
      return false
    }
  }

  func refreshRemaining() async {
    lock.lock()
    var token = state.sessionToken ?? ""
    lock.unlock()
    if token.isEmpty {
      if let fetched = await DevModeTV.fetchSessionToken() {
        token = fetched
        lock.lock()
        state.sessionToken = fetched
        let snapshot = state
        lock.unlock()
        Self.save(snapshot)
      } else {
        return
      }
    }
    guard let url = DevModeAPI.checkURL(token: token) else { return }
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      guard let clock = DevModeAPI.parseRemaining(data: data) else {
        let body = String(data: data, encoding: .utf8) ?? ""
        DevModeLog.line("check: could not parse remaining body=\(body)")
        return
      }
      lock.lock()
      remainingClock = clock
      lock.unlock()
    } catch {
      DevModeLog.line("check: FAIL \(error)")
    }
  }

  private static func supportDir() -> URL {
    let id = Bundle.main.bundleIdentifier ?? "com.gbuc.imagicremote.mac"
    let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent(id, isDirectory: true)
    try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    return root
  }

  private static func fileURL() -> URL {
    supportDir().appendingPathComponent("devmode.json")
  }

  private static func load() -> DevModeState {
    let dec = JSONDecoder()
    dec.dateDecodingStrategy = .iso8601
    func decode(_ url: URL) -> DevModeState? {
      guard let data = try? Data(contentsOf: url) else { return nil }
      return try? dec.decode(DevModeState.self, from: data)
    }
    return decode(fileURL()) ?? DevModeState()
  }

  private static func save(_ state: DevModeState) {
    let enc = JSONEncoder()
    enc.dateEncodingStrategy = .iso8601
    enc.outputFormatting = [.prettyPrinted]
    guard let data = try? enc.encode(state) else { return }
    let url = fileURL()
    try? data.write(to: url, options: .atomic)
    try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
  }
}
