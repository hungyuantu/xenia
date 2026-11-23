import AppKit
import ServiceManagement

@main
final class Xenia: NSObject, NSApplicationDelegate, NSMenuItemValidation {
  // Lazy: create the status item after NSApplication is up.
  private lazy var extra = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

  static func main() {
    let peers = NSRunningApplication.runningApplications(withBundleIdentifier: "dev.hytu.xenia")
    if peers.count > 1 { exit(0) }
    let xenia = Xenia()
    NSApplication.shared.delegate = xenia
    withExtendedLifetime(xenia) { NSApplication.shared.run() }
  }

  func applicationDidFinishLaunching(_ note: Notification) {
    _ = CGRequestPostEventAccess()
    Task { await Self.start() }
    let menu = NSMenu()
    menu.addItem(withTitle: "Open at Login", action: #selector(apply), target: self)
    menu.addItem(.separator())
    menu.addItem(withTitle: "Quit Xenia", action: #selector(NSApp.terminate), keyEquivalent: "q")
    extra.menu = menu
    extra.button?.image = NSImage(named: "Doors")
  }

  func validateMenuItem(_ item: NSMenuItem) -> Bool {
    item.state = SMAppService.mainApp.status == .enabled ? .on : .off
    return true
  }

  @objc func apply(_ item: NSMenuItem) {
    let app = SMAppService.mainApp
    try? item.state == .off ? app.register() : app.unregister()
    if app.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
  }
}

private extension Xenia {
  static var tap: CFMachPort?

  static func start() async {
    while !CGPreflightPostEventAccess() { try? await Task.sleep(for: .seconds(1)) }
    tap = CGEvent.makeTap(.scrollWheel) { _, type, event, _ in Xenia.route(type, event) }
    guard let tap else { return }
    CFRunLoopAddSource(CFRunLoopGetMain(), tap.makeSource(), .commonModes)
  }

  // Always on the main thread: start() adds the tap to the main run loop.
  nonisolated static func route(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
    switch type {
    case .scrollWheel: Mouse.scroll(event)
    case .tapDisabledByTimeout, .tapDisabledByUserInput: MainActor.assumeIsolated { rearm() }
    default: break
    }
    return .passUnretained(event)
  }

  static func rearm() {
    if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
  }
}

private extension NSMenu {
  func addItem(withTitle title: String, action: Selector, target: AnyObject) {
    addItem(withTitle: title, action: action, keyEquivalent: "").target = target
  }
}

private extension CFMachPort {
  func makeSource() -> CFRunLoopSource { CFMachPortCreateRunLoopSource(nil, self, 0) }
}

private extension CGEvent {
  static func makeTap(_ type: CGEventType, _ callback: CGEventTapCallBack) -> CFMachPort? {
    let mask = CGEventMask(1) << type.rawValue
    return tapCreate(
      tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
      eventsOfInterest: mask, callback: callback, userInfo: nil)
  }
}
