public enum ToastIcon: Sendable, Equatable {
  public enum RenderingMode: Sendable, Equatable {
    case template
    case original
  }

  case `default`
  case hidden
  case asset(
    name: String,
    bundleIdentifier: String? = nil,
    renderingMode: RenderingMode = .template,
    accessibilityLabel: String? = nil
  )
}
