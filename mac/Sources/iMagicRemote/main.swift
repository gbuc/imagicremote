import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let menuController = MainActor.assumeIsolated { () -> StatusMenuController in
  let menu = StatusMenuController()
  AppState.shared.start()
  return menu
}
withExtendedLifetime(menuController) {
  app.run()
}
