public enum ToastStyle: Sendable, Equatable {
  case normal
  case info
  case danger
  case warning
  case custom(ToastAppearance)

  public static let builtInCases: [Self] = [.normal, .info, .danger, .warning]
}
