import AppKit
import iMagicRemoteCore

@MainActor
final class StatusMenuController: NSObject {
  private let item: NSStatusItem
  private let menu = NSMenu()

  override init() {
    item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    super.init()
    item.button?.title = "iMR"
    item.menu = menu
    AppState.shared.onChange = { [weak self] in
      self?.rebuild()
    }
    rebuild()
  }

  func rebuild() {
    menu.removeAllItems()
    let state = AppState.shared
    let statusTitle: String
    switch state.status {
    case .listening: statusTitle = "listening"
    case .connected: statusTitle = "connected"
    case .needsAccessibility: statusTitle = "needs Accessibility"
    case .noDisplay: statusTitle = "no display"
    }
    item.button?.toolTip = "\(statusTitle) · \(state.lanIP):\(Wire.port)"

    let copyIP = NSMenuItem(
      title: "Copy Mac IP \(state.lanIP)",
      action: #selector(copyLanIP),
      keyEquivalent: ""
    )
    copyIP.target = self
    menu.addItem(copyIP)
    menu.addItem(.separator())

    let displays = NSMenuItem(title: "Display", action: nil, keyEquivalent: "")
    let displayMenu = NSMenu()
    for screen in state.screens {
      let entry = NSMenuItem(
        title: screen.name,
        action: #selector(selectScreen(_:)),
        keyEquivalent: ""
      )
      entry.target = self
      entry.representedObject = screen
      entry.state = state.selectedScreen == screen ? .on : .off
      displayMenu.addItem(entry)
    }
    displays.submenu = displayMenu
    menu.addItem(displays)

    let hide = NSMenuItem(title: "Hide Mac cursor", action: #selector(toggleCursor), keyEquivalent: "")
    hide.target = self
    hide.state = state.hideCursor ? .on : .off
    menu.addItem(hide)

    if state.canOpenAtLogin {
      let login = NSMenuItem(title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")
      login.target = self
      login.state = state.openAtLogin ? .on : .off
      menu.addItem(login)
    }

    menu.addItem(.separator())
    if let remaining = state.devModeRemaining {
      let clock = NSMenuItem(title: remaining, action: nil, keyEquivalent: "")
      clock.isEnabled = false
      menu.addItem(clock)
    }
    let extend = NSMenuItem(
      title: "Extend Developer Mode",
      action: #selector(extendDevMode),
      keyEquivalent: ""
    )
    extend.target = self
    menu.addItem(extend)
    let boot = NSMenuItem(
      title: "Install TV Start at Power-On",
      action: #selector(installTVBoot),
      keyEquivalent: ""
    )
    boot.target = self
    menu.addItem(boot)

    let ax = NSMenuItem(
      title: "Open Accessibility Settings",
      action: #selector(openAX),
      keyEquivalent: ""
    )
    ax.target = self
    menu.addItem(ax)
    menu.addItem(.separator())
    let quit = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    menu.addItem(quit)
  }

  @objc private func selectScreen(_ sender: NSMenuItem) {
    guard let pick = sender.representedObject as? ScreenPick else { return }
    AppState.shared.chooseScreen(pick)
  }

  @objc private func copyLanIP() {
    let ip = AppState.shared.lanIP
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(ip, forType: .string)
  }

  @objc private func toggleCursor() {
    AppState.shared.hideCursor.toggle()
    rebuild()
  }

  @objc private func toggleLogin() {
    AppState.shared.openAtLogin.toggle()
    rebuild()
  }

  @objc private func openAX() {
    AppState.shared.openAccessibilitySettings()
  }

  @objc private func extendDevMode() {
    AppState.shared.extendDevMode()
  }

  @objc private func installTVBoot() {
    AppState.shared.installTVBootLaunch()
  }
}
