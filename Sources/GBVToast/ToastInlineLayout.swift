#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI

  @available(iOS 16, *)
  struct ToastInlineLayout: Layout {
    let spacing: CGFloat
    let layoutDirection: LayoutDirection

    func sizeThatFits(
      proposal: ProposedViewSize,
      subviews: Subviews,
      cache: inout ()
    ) -> CGSize {
      guard subviews.count == 2 else { return .zero }
      let availableWidth = proposal.width ?? 0
      let intrinsicCTA = subviews[1].sizeThatFits(.unspecified)
      let ctaWidth = min(intrinsicCTA.width, max(44, availableWidth * 0.45))
      let cta = subviews[1].sizeThatFits(.init(width: ctaWidth, height: nil))
      let messageWidth = max(0, availableWidth - ctaWidth - spacing)
      let message = subviews[0].sizeThatFits(.init(width: messageWidth, height: nil))
      return CGSize(width: availableWidth, height: max(message.height, cta.height))
    }

    func placeSubviews(
      in bounds: CGRect,
      proposal: ProposedViewSize,
      subviews: Subviews,
      cache: inout ()
    ) {
      guard subviews.count == 2 else { return }
      let intrinsicCTA = subviews[1].sizeThatFits(.unspecified)
      let ctaWidth = min(intrinsicCTA.width, max(44, bounds.width * 0.45))
      let cta = subviews[1].sizeThatFits(.init(width: ctaWidth, height: nil))
      let messageWidth = max(0, bounds.width - ctaWidth - spacing)
      let message = subviews[0].sizeThatFits(.init(width: messageWidth, height: nil))
      if layoutDirection == .leftToRight {
        subviews[0].place(
          at: CGPoint(x: bounds.minX, y: bounds.minY),
          proposal: .init(width: messageWidth, height: message.height)
        )
        subviews[1].place(
          at: CGPoint(x: bounds.maxX, y: bounds.maxY),
          anchor: .bottomTrailing,
          proposal: .init(cta)
        )
      } else {
        subviews[0].place(
          at: CGPoint(x: bounds.maxX, y: bounds.minY),
          anchor: .topTrailing,
          proposal: .init(width: messageWidth, height: message.height)
        )
        subviews[1].place(
          at: CGPoint(x: bounds.minX, y: bounds.maxY),
          anchor: .bottomLeading,
          proposal: .init(cta)
        )
      }
    }
  }
#endif
