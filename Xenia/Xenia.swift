import AppKit
import ServiceManagement

@main
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

  static func main() {
    // Create the app before the delegate, whose status item needs it.
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    withExtendedLifetime(delegate) { app.run() }
  }

  func applicationDidFinishLaunching(_: Notification) {
    Task { await Event.start() }
    let menu = NSMenu()
    menu.addItem(withTitle: "Open at Login", action: #selector(toggle), keyEquivalent: "")
    menu.addItem(.separator())
    menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate), keyEquivalent: "q")
    statusItem.menu = menu
    statusItem.button?.image = NSImage(named: "Doors")
  }

  func validateMenuItem(_ item: NSMenuItem) -> Bool {
    if item.action == #selector(toggle) {
      item.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }
    return true
  }

  @objc func toggle() {
    let service = SMAppService.mainApp
    try? service.status == .enabled ? service.unregister() : service.register()
    if service.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
  }
}
