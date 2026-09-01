import Foundation
import iMagicRemoteCore

enum DevModeTV {
  static func fetchSessionToken() async -> String? {
    for device in loadTelevisions() {
      if let raw = await ssh(
        device,
        "cat /var/luna/preferences/devmode_enabled 2>/dev/null"
      ), let token = AresDeviceList.parseTokenFile(raw) {
        return token
      }
    }
    return nil
  }

  /// Same as pressing EXTEND in the Developer Mode app (updates the 50h UI).
  static func pressExtend() async {
    DevModeLog.line("tv: pressExtend (SSH luna launch palmdts.devmode)")
    let cmd =
      "luna-send-pub -n 1 luna://com.webos.applicationManager/launch " +
      "'{\"id\":\"com.palmdts.devmode\",\"params\":{\"extend\":true}}' " +
      "2>/dev/null || luna-send -n 1 luna://com.webos.applicationManager/launch " +
      "'{\"id\":\"com.palmdts.devmode\",\"params\":{\"extend\":true}}'"
    for device in loadTelevisions() {
      _ = await ssh(device, cmd)
    }
    await registerAsInput()
    _ = await ensureBootLaunch()
  }

  /// Append a launch to Developer Mode's boot script so the app starts with the TV.
  /// Needs Key Server on (SSH). Once written, later boots do not need SSH.
  static func ensureBootLaunch() async -> String {
    let remote = """
    for f in /media/cryptofs/apps/usr/palm/services/com.palmdts.devmode.service/start-devmode.sh /media/developer/apps/usr/palm/services/com.palmdts.devmode.service/start-devmode.sh; do
      [ -f "$f" ] || continue
      if grep -q imagicremote-autostart "$f" 2>/dev/null; then echo already; exit 0; fi
      if [ ! -w "$f" ]; then echo nowrite; continue; fi
      echo >> "$f"
      echo "# imagicremote-autostart" >> "$f"
      echo '(sleep 20; luna-send -n 1 -f luna://com.webos.applicationManager/launch '"'"'{"id":"com.gbuc.imagicremote"}'"'"') &' >> "$f"
      echo patched
      exit 0
    done
    echo fail
    exit 1
    """
    for device in loadTelevisions() {
      if let out = await ssh(device, remote) {
        let result = out.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.contains("patched") || result.contains("already") {
          return result.contains("already") ? "already" : "patched"
        }
      }
    }
    return "fail"
  }

  /// Register iMagicRemote as a TV input so webOS can resume it on power-on.
  static func registerAsInput() async {
    let cmd =
      "luna-send-pub -n 1 luna://com.webos.service.eim/addDevice " +
      "'{\"appId\":\"com.gbuc.imagicremote\",\"pigImage\":\"\",\"mvpdIcon\":\"\",\"type\":\"MVPD_IP\"}' " +
      "2>/dev/null || luna-send -n 1 luna://com.webos.service.eim/addDevice " +
      "'{\"appId\":\"com.gbuc.imagicremote\",\"pigImage\":\"\",\"mvpdIcon\":\"\",\"type\":\"MVPD_IP\"}'"
    for device in loadTelevisions() {
      _ = await ssh(device, cmd)
    }
  }

  private static func loadTelevisions() -> [AresDevice] {
    let url = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".webos/tv/novacom-devices.json")
    guard let data = try? Data(contentsOf: url) else { return [] }
    return AresDeviceList.televisions(in: AresDeviceList.parse(novacomJSON: data))
  }

  private static func ssh(_ device: AresDevice, _ command: String) async -> String? {
    let key = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".ssh")
      .appendingPathComponent(device.keyFileName)
    guard FileManager.default.isReadableFile(atPath: key.path) else { return nil }

    let askpass = FileManager.default.temporaryDirectory
      .appendingPathComponent("imagicremote-askpass-\(UUID().uuidString)")
    let script = "#!/bin/sh\nprintf '%s\\n' \"$IMAGICREMOTE_SSH_PASSPHRASE\"\n"
    do {
      try script.write(to: askpass, atomically: true, encoding: .utf8)
      try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: askpass.path)
    } catch {
      return nil
    }
    defer { try? FileManager.default.removeItem(at: askpass) }

    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
    proc.arguments = [
      "-i", key.path,
      "-o", "IdentitiesOnly=yes",
      "-o", "StrictHostKeyChecking=no",
      "-o", "UserKnownHostsFile=/dev/null",
      "-o", "GlobalKnownHostsFile=/dev/null",
      "-o", "ConnectTimeout=5",
      "-o", "PreferredAuthentications=publickey",
      "-p", String(device.port),
      "\(device.username)@\(device.host)",
      command,
    ]
    var env = ProcessInfo.processInfo.environment
    env["SSH_ASKPASS"] = askpass.path
    env["SSH_ASKPASS_REQUIRE"] = "force"
    env["DISPLAY"] = env["DISPLAY"] ?? ":0"
    env["SSH_AUTH_SOCK"] = ""
    env["IMAGICREMOTE_SSH_PASSPHRASE"] = device.passphrase ?? ""
    proc.environment = env
    let out = Pipe()
    let err = Pipe()
    proc.standardOutput = out
    proc.standardError = err
    proc.standardInput = FileHandle.nullDevice
    do {
      try proc.run()
    } catch {
      DevModeLog.line("ssh: failed to start \(error)")
      return nil
    }
    return await withCheckedContinuation { cont in
      proc.terminationHandler = { p in
        let data = out.fileHandleForReading.readDataToEndOfFile()
        let errData = err.fileHandleForReading.readDataToEndOfFile()
        let text = String(data: data, encoding: .utf8) ?? ""
        let errText = String(data: errData, encoding: .utf8) ?? ""
        let snippet = command.count > 80 ? String(command.prefix(80)) + "…" : command
        DevModeLog.line(
          "ssh \(device.host):\(device.port) status=\(p.terminationStatus) cmd=\(snippet) out=\(text.prefix(200)) err=\(errText.prefix(200))"
        )
        cont.resume(returning: p.terminationStatus == 0 ? text : nil)
      }
    }
  }
}
