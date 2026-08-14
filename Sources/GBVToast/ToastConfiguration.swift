import Foundation

public struct ToastConfiguration: Sendable, Equatable {
  public let message: String
  public let style: ToastStyle
  public let edge: ToastEdge
  public let icon: ToastIcon
  public let iconSize: CGFloat
  public let cta: ToastCTA?
  public let autoDismissDuration: TimeInterval?
  public let dismissOnTap: Bool
  public let removesOnDismiss: Bool
  public let isAnimated: Bool
  public let safeAreaSpacing: CGFloat
  public let maximumPhoneWidth: CGFloat?
  public let maximumPadWidth: CGFloat?
  public let deduplicationKey: String?

  public init(
    message: String,
    style: ToastStyle = .normal,
    edge: ToastEdge = .top,
    icon: ToastIcon = .default,
    iconSize: CGFloat = 20,
    cta: ToastCTA? = nil,
    autoDismissDuration: TimeInterval? = 3,
    dismissOnTap: Bool = true,
    removesOnDismiss: Bool = true,
    isAnimated: Bool = true,
    safeAreaSpacing: CGFloat = 16,
    maximumPhoneWidth: CGFloat? = nil,
    maximumPadWidth: CGFloat? = nil,
    deduplicationKey: String? = nil
  ) {
    self.message = message
    self.style = style
    self.edge = edge
    self.icon = icon
    self.iconSize = iconSize
    self.cta = cta
    self.autoDismissDuration = autoDismissDuration
    self.dismissOnTap = dismissOnTap
    self.removesOnDismiss = removesOnDismiss
    self.isAnimated = isAnimated
    self.safeAreaSpacing = safeAreaSpacing
    self.maximumPhoneWidth = maximumPhoneWidth
    self.maximumPadWidth = maximumPadWidth
    self.deduplicationKey = deduplicationKey
  }
}
