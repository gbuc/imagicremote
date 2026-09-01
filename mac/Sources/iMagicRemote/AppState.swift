import AppKit
import ApplicationServices
import Foundation
import iMagicRemoteCore
import iMagicRemoteServer
import ServiceManagement

@MainActor
final class AppState {
  static let shared = AppState()

  enum Status: Equatable {
    case listening
    case connected
    case needsAccessibility
    case noDisplay
  }

  private let defaults = UserDefaults.standard
  private var session = MouseSession(target: .zero, primary: .zero)
  private var server: MouseServer?
  private var serverTask: Task<Void, Never>?
  private var cursorHidden = false
  private var clientConnected = false
  private var screenObserver: NSObjectProtocol?
  private var kbdProbe = 0
  private(set) var status: Status = .listening
  var onChange: (() -> Void)?

  var hideCursor: Bool {
    get { defaults.object(forKey: "hideCursor") as? Bool ?? true }
    set {
      defaults.set(newValue, forKey: "hideCursor")
      syncCursor()
    }
  }

  var lanIP: String { LANAddress.ipv4() ?? "unknown" }

  var screens: [ScreenPick] {
    NSScreen.screens.map { ScreenPick(name: $0.localizedName, frame: $0.frame) }
  }

  var selectedScreen: ScreenPick? {
    let saved = loadSavedScreen()
    return ScreenSelection.resolve(saved: saved, screens: screens)
  }

  /// SMAppService only works inside a packaged .app; `swift run` has no bundle.
  var canOpenAtLogin: Bool {
    (Bundle.main.bundlePath as NSString).pathExtension.lowercased() == "app"
  }

  var devModeRemaining: String? { DevModeExtender.shared.remainingMenuTitle }
  private var remainingTimer: Timer?

  var tvBootLaunchStatus: String {
    defaults.string(forKey: "tvBootLaunch") ?? "TV start at power-on: not installed"
  }

  var openAtLogin: Bool {
    get { SMAppService.mainApp.status == .enabled }
    set {
      guard canOpenAtLogin else { return }
      do {
        if newValue {
          try SMAppService.mainApp.register()
        } else {
          try SMAppService.mainApp.unregister()
        }
      } catch {
        NSLog("SMAppService: \(error)")
      }
    }
  }

  func start() {
    promptAccessibility()
    applySelectedScreen()
    observeScreens()
    pollDevModeRemaining()
    let server = MouseServer(
      onMessage: { message in
        Task { @MainActor in
          AppState.shared.handle(message)
        }
      },
      onConnect: {
        Task { @MainActor in
          AppState.shared.handleConnect()
        }
      },
      onDisconnect: {
        Task { @MainActor in
          AppState.shared.handleDisconnect()
        }
      }
    )
    self.server = server
    serverTask = Task {
      do {
        try await server.start()
      } catch {
        NSLog("MouseServer failed: \(error)")
      }
    }
    refreshStatus()
  }

  func chooseScreen(_ pick: ScreenPick) {
    defaults.set(
      ["name": pick.name, "width": Double(pick.frame.width), "height": Double(pick.frame.height)],
      forKey: "savedScreen"
    )
    applySelectedScreen()
    refreshStatus()
  }

  func openAccessibilitySettings() {
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    NSWorkspace.shared.open(url)
  }

  private func handle(_ message: WireMessage) {
    switch message {
    case .text, .keyEnter, .keyBackspace:
      break
    default:
      applySelectedScreen()
      guard selectedScreen != nil else {
        refreshStatus()
        return
      }
    }
    let commands = session.apply(message)
    if AXIsProcessTrusted() {
      CGEventInjector.post(commands)
    } else {
      refreshStatus()
    }
    switch message {
    case .up:
      if commands.contains(where: { if case .leftUp = $0 { return true }; return false }) {
        scheduleKbdProbe()
      }
    case .rdown, .down:
      cancelKbdProbe()
    default:
      break
    }
  }

  func extendDevMode() {
    DevModeLog.line("menu: Extend Developer Mode clicked, tvSocket=\(clientConnected)")
    server?.send(HostWire.devExtend)
    Task {
      let ok = await DevModeExtender.shared.extend(force: true)
      DevModeLog.line("menu: extend finished ok=\(ok)")
      await MainActor.run { refreshStatus() }
    }
  }

  private func pollDevModeRemaining() {
    remainingTimer?.invalidate()
    remainingTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
      Task { @MainActor in
        await DevModeExtender.shared.refreshRemaining()
        AppState.shared.onChange?()
      }
    }
    remainingTimer?.tolerance = 15
    Task {
      await DevModeExtender.shared.refreshRemaining()
      await MainActor.run { onChange?() }
    }
  }

  func installTVBootLaunch() {
    Task {
      let result = await DevModeTV.ensureBootLaunch()
      await MainActor.run {
        switch result {
        case "patched", "already":
          defaults.set("TV start at power-on: installed", forKey: "tvBootLaunch")
        default:
          defaults.set("TV start at power-on: turn Key Server on and retry", forKey: "tvBootLaunch")
        }
        onChange?()
      }
    }
  }

  private var devModeKickoff = false
  private func maybeExtendDevMode() {
    guard DevModeExtender.shared.isDue() else { return }
    if devModeKickoff { return }
    devModeKickoff = true
    Task {
      await DevModeExtender.shared.extendIfDue()
      await MainActor.run {
        devModeKickoff = false
        onChange?()
      }
    }
  }

  private func handleConnect() {
    clientConnected = true
    applySelectedScreen()
    refreshStatus()
    maybeExtendDevMode()
    if defaults.string(forKey: "tvBootLaunch") != "TV start at power-on: installed" {
      installTVBootLaunch()
    }
  }

  private func handleDisconnect() {
    clientConnected = false
    cancelKbdProbe()
    CGEventInjector.post(session.disconnected())
    refreshStatus()
  }

  private func cancelKbdProbe() {
    kbdProbe += 1
  }

  private func scheduleKbdProbe() {
    kbdProbe += 1
    let token = kbdProbe
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: TextInputProbe.delayNs)
      guard token == kbdProbe, clientConnected, AXIsProcessTrusted() else { return }
      guard FocusedTextInput.isEditable() else { return }
      server?.send(HostWire.kbd(on: true))
    }
  }

  private func applySelectedScreen() {
    let primary = NSScreen.screens.first?.frame ?? .zero
    if let pick = selectedScreen {
      session.target = pick.frame
      session.primary = primary
    }
  }

  private func observeScreens() {
    guard screenObserver == nil else { return }
    screenObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil,
      queue: .main
    ) { _ in
      Task { @MainActor in
        AppState.shared.applySelectedScreen()
        AppState.shared.refreshStatus()
      }
    }
  }

  private func refreshStatus() {
    if !AXIsProcessTrusted() {
      status = .needsAccessibility
    } else if selectedScreen == nil {
      status = .noDisplay
    } else if clientConnected {
      status = .connected
    } else {
      status = .listening
    }
    syncCursor()
    onChange?()
  }

  private func promptAccessibility() {
    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(opts)
  }

  private func syncCursor() {
    let shouldHide = hideCursor && status == .connected
    if shouldHide && !cursorHidden {
      NSCursor.hide()
      cursorHidden = true
    } else if !shouldHide && cursorHidden {
      NSCursor.unhide()
      cursorHidden = false
    }
  }

  private func loadSavedScreen() -> SavedScreen? {
    guard let dict = defaults.dictionary(forKey: "savedScreen"),
          let name = dict["name"] as? String,
          let width = dict["width"] as? Double,
          let height = dict["height"] as? Double
    else { return nil }
    return SavedScreen(name: name, width: width, height: height)
  }
}
