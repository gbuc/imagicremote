import Foundation

public struct DevModeState: Equatable, Codable, Sendable {
  public var lastExtend: Date?
  public var sessionToken: String?

  public init(lastExtend: Date? = nil, sessionToken: String? = nil) {
    self.lastExtend = lastExtend
    self.sessionToken = sessionToken
  }
}

public enum DevModeSchedule {
  public static let interval: TimeInterval = 30 * 24 * 60 * 60

  public static func isDue(state: DevModeState, now: Date) -> Bool {
    // No lastExtend: first connect. Fetch a token from the TV if needed, then reset.
    guard let last = state.lastExtend else { return true }
    guard let token = state.sessionToken, !token.isEmpty else { return false }
    return now.timeIntervalSince(last) >= interval
  }

  /// Keep lastExtend only from this app's store. A token found in an older
  /// path still counts as never-extended here, so the first TV connect
  /// hits LG's reset (remaining time becomes ~1000 hours).
  public static func merge(current: DevModeState?, legacy: [DevModeState]) -> DevModeState {
    if let current, let token = current.sessionToken, !token.isEmpty {
      return current
    }
    let token = legacy.compactMap(\.sessionToken).first { !$0.isEmpty }
    return DevModeState(lastExtend: nil, sessionToken: token)
  }
}

public enum DevModeAPI {
  public static func resetURL(token: String) -> URL? {
    var parts = URLComponents(string: "https://developer.lge.com/secure/ResetDevModeSession.dev")
    parts?.queryItems = [URLQueryItem(name: "sessionToken", value: token)]
    return parts?.url
  }

  public static func parseReset(data: Data) -> Bool {
    struct Payload: Decodable {
      var result: String?
      var errorCode: String?
    }
    guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return false }
    return payload.result == "success" || payload.errorCode == "200"
  }

  public static func checkURL(token: String) -> URL? {
    var parts = URLComponents(string: "https://developer.lge.com/secure/CheckDevModeSession.dev")
    parts?.queryItems = [URLQueryItem(name: "sessionToken", value: token)]
    return parts?.url
  }

  /// LG puts remaining time in errorMsg, e.g. "999:58:40".
  public static func parseRemaining(data: Data) -> String? {
    struct Payload: Decodable {
      var result: String?
      var errorCode: String?
      var errorMsg: String?
    }
    guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
    guard payload.result == "success" || payload.errorCode == "200" else { return nil }
    guard let raw = payload.errorMsg else { return nil }
    let parts = raw.split(separator: ":")
    guard parts.count >= 2, parts.allSatisfy({ Int($0) != nil }) else { return nil }
    return "\(parts[0]):\(parts[1])"
  }
}
