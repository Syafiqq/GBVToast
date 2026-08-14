import Foundation

public enum ToastWidth: Sendable, Equatable {
  case compact
  case full

  static let fullMaximum: CGFloat = 400
  static let horizontalMargin: CGFloat = 16
}
