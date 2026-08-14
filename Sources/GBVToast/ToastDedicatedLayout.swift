#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI

  @available(iOS 16, *)
  struct ToastDedicatedLayout: Layout {
    let spacing: CGFloat
    let layoutDirection: LayoutDirection

    func sizeThatFits(
      proposal: ProposedViewSize,
      subviews: Subviews,
      cache: inout ()
    ) -> CGSize {
      guard subviews.count == 2 else { return .zero }
      let availableWidth = proposal.width ?? 0
      let message = subviews[0].sizeThatFits(.init(width: availableWidth, height: nil))
      let cta = subviews[1].sizeThatFits(.init(width: availableWidth, height: nil))
      return CGSize(
        width: availableWidth,
        height: message.height + spacing + cta.height
      )
    }

    func placeSubviews(
      in bounds: CGRect,
      proposal: ProposedViewSize,
      subviews: Subviews,
      cache: inout ()
    ) {
      guard subviews.count == 2 else { return }
      let message = subviews[0].sizeThatFits(.init(width: bounds.width, height: nil))
      let cta = subviews[1].sizeThatFits(.init(width: bounds.width, height: nil))
      subviews[0].place(
        at: CGPoint(x: bounds.minX, y: bounds.minY),
        proposal: .init(width: bounds.width, height: message.height)
      )
      if layoutDirection == .leftToRight {
        subviews[1].place(
          at: CGPoint(x: bounds.maxX, y: bounds.maxY),
          anchor: .bottomTrailing,
          proposal: .init(cta)
        )
      } else {
        subviews[1].place(
          at: CGPoint(x: bounds.minX, y: bounds.maxY),
          anchor: .bottomLeading,
          proposal: .init(cta)
        )
      }
    }
  }
#endif
