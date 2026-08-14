public struct ToastAppearance: Sendable, Equatable {
  public let foreground: ToastColor
  public let background: ToastColor

  public init(foreground: ToastColor, background: ToastColor) {
    self.foreground = foreground
    self.background = background
  }
}
