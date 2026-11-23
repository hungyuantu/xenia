import CoreGraphics

/// Tuned for SANWA SUPPLY GMAERGWBT22BK
nonisolated enum Mouse {
  private static let step: Int64 = 3
  private static let unit: Int64 = 10

  static func scroll(_ event: CGEvent) {
    guard event[.scrollWheelEventIsContinuous] as Int64 == 0 else { return }
    let delta = -event[.scrollWheelEventDeltaAxis1].signum() * step
    event[.scrollWheelEventDeltaAxis1] = delta
    event[.scrollWheelEventFixedPtDeltaAxis1] = Double(delta)
    event[.scrollWheelEventPointDeltaAxis1] = delta * unit
  }
}

private nonisolated extension CGEvent {
  subscript(field: CGEventField) -> Int64 {
    get { getIntegerValueField(field) }
    set { setIntegerValueField(field, value: newValue) }
  }
  subscript(field: CGEventField) -> Double {
    get { getDoubleValueField(field) }
    set { setDoubleValueField(field, value: newValue) }
  }
}
