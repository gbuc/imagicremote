import Foundation

public struct AresDevice: Equatable, Sendable {
  public var name: String
  public var host: String
  public var port: Int
  public var username: String
  public var keyFileName: String
  public var passphrase: String?

  public init(
    name: String,
    host: String,
    port: Int,
    username: String,
    keyFileName: String,
    passphrase: String? = nil
  ) {
    self.name = name
    self.host = host
    self.port = port
    self.username = username
    self.keyFileName = keyFileName
    self.passphrase = passphrase
  }

  public var isLoopback: Bool {
    host == "127.0.0.1" || host == "localhost" || host == "::1"
  }

  public var isTelevision: Bool {
    !isLoopback && username == "prisoner"
  }
}

public enum AresDeviceList {
  public static func parse(novacomJSON: Data) -> [AresDevice] {
    guard let raw = try? JSONSerialization.jsonObject(with: novacomJSON) else { return [] }
    let rows: [[String: Any]]
    if let arr = raw as? [[String: Any]] {
      rows = arr
    } else {
      return []
    }
    return rows.compactMap(parseRow)
  }

  public static func televisions(in devices: [AresDevice]) -> [AresDevice] {
    devices.filter(\.isTelevision)
  }

  public static func parseTokenFile(_ raw: String) -> String? {
    let token = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !token.isEmpty, !token.contains(where: { $0.isWhitespace }) else { return nil }
    return token
  }

  private static func parseRow(_ row: [String: Any]) -> AresDevice? {
    guard let host = row["host"] as? String, !host.isEmpty else { return nil }
    let port: Int
    if let n = row["port"] as? Int {
      port = n
    } else if let s = row["port"] as? String, let n = Int(s) {
      port = n
    } else {
      port = 9922
    }
    let user = (row["username"] as? String) ?? "prisoner"
    let key: String
    if let obj = row["privateKey"] as? [String: Any], let name = obj["openSsh"] as? String {
      key = name
    } else if let name = row["privateKey"] as? String {
      key = name
    } else if let name = row["privatekey"] as? String {
      key = name
    } else {
      return nil
    }
    return AresDevice(
      name: (row["name"] as? String) ?? host,
      host: host,
      port: port,
      username: user,
      keyFileName: key,
      passphrase: row["passphrase"] as? String
    )
  }
}
