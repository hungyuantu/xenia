import CoreGraphics

enum Event {
  static func start() async {
    _ = CGRequestPostEventAccess()
    while !CGPreflightPostEventAccess() { try? await Task.sleep(for: .seconds(1)) }
    tap = CGEvent.makeTap(.scrollWheel) { _, type, event, _ in Event.route(type, event) }
    guard let tap else { return }
    CFRunLoopAddSource(CFRunLoopGetMain(), tap.makeSource(), .commonModes)
  }
}

private extension Event {
  static var tap: CFMachPort?

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
