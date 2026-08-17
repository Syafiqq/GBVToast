public struct ToastCTA: Sendable, Equatable {
  public enum Label: Sendable, Equatable {
    case text(String)
    case asset(
      name: String,
      bundleIdentifier: String? = nil,
      renderingMode: ToastIcon.RenderingMode = .original,
      accessibilityLabel: String
    )
  }

  public enum Layout: Sendable, Equatable {
    case dedicated
    case inline
  }

  public let label: Label
  public let layout: Layout

  public init(label: Label, layout: Layout = .dedicated) {
    self.label = label
    self.layout = layout
  }

  public init(title: String, layout: Layout = .dedicated) {
    self.init(label: .text(title), layout: layout)
  }

}
