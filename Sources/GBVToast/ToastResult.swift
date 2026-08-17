public enum ToastResult: Sendable, Equatable {
  case cta
  case dismissed
  case notPresented(ToastNotPresentedReason)
}

public enum ToastNotPresentedReason: Error, Sendable, Equatable {
  case noEligibleWindow
  case ambiguousWindows
  case sceneUnavailable
  case duplicateKey
  case ctaAssetUnavailable
}
