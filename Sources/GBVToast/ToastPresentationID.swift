import Foundation

public struct ToastPresentationID: Sendable, Hashable {
  private let rawValue: UUID

  public init() {
    rawValue = UUID()
  }
}
