import Foundation

enum DevModeLog {
  private static let maxBytes = 256 * 1024

  static let fileURL: URL = {
    let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("iMagicRemote.log")
  }()

  static func line(_ message: String) {
    let stamp = ISO8601DateFormatter().string(from: Date())
    let text = "\(stamp) \(message)\n"
    NSLog("iMagicRemote %@", message)
    guard let data = text.data(using: .utf8) else { return }
    if !FileManager.default.fileExists(atPath: fileURL.path) {
      FileManager.default.createFile(atPath: fileURL.path, contents: data)
      return
    }
    trimIfNeeded()
    guard let handle = try? FileHandle(forWritingTo: fileURL) else { return }
    defer { try? handle.close() }
    _ = try? handle.seekToEnd()
    try? handle.write(contentsOf: data)
  }

  private static func trimIfNeeded() {
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
          let size = attrs[.size] as? NSNumber,
          size.intValue > maxBytes,
          let raw = try? Data(contentsOf: fileURL)
    else { return }
    let keep = raw.suffix(maxBytes / 2)
    try? keep.write(to: fileURL, options: .atomic)
  }
}
