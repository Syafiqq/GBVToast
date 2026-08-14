public struct ToastCTA: Sendable, Equatable {
  public enum Layout: Sendable, Equatable {
    case dedicated
    case inline
  }

  public let title: String
  public let layout: Layout

  public init(title: String, layout: Layout = .dedicated) {
    self.title = title
    self.layout = layout
  }
}
