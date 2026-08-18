#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI

  struct ToastInlineSubviewPlacement {
    let point: CGPoint
    let anchor: UnitPoint
  }

  func toastInlineCTAPlacement(
    in bounds: CGRect,
    layoutDirection: LayoutDirection
  ) -> ToastInlineSubviewPlacement {
    switch layoutDirection {
    case .leftToRight:
      ToastInlineSubviewPlacement(
        point: CGPoint(x: bounds.maxX, y: bounds.midY),
        anchor: .trailing
      )
    case .rightToLeft:
      ToastInlineSubviewPlacement(
        point: CGPoint(x: bounds.minX, y: bounds.midY),
        anchor: .leading
      )
    @unknown default:
      ToastInlineSubviewPlacement(
        point: CGPoint(x: bounds.maxX, y: bounds.midY),
        anchor: .trailing
      )
    }
  }

  func toastInlineMessagePlacement(
    in bounds: CGRect,
    layoutDirection: LayoutDirection
  ) -> ToastInlineSubviewPlacement {
    switch layoutDirection {
    case .leftToRight:
      ToastInlineSubviewPlacement(
        point: CGPoint(x: bounds.minX, y: bounds.midY),
        anchor: .leading
      )
    case .rightToLeft:
      ToastInlineSubviewPlacement(
        point: CGPoint(x: bounds.maxX, y: bounds.midY),
        anchor: .trailing
      )
    @unknown default:
      ToastInlineSubviewPlacement(
        point: CGPoint(x: bounds.minX, y: bounds.midY),
        anchor: .leading
      )
    }
  }

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
      let messagePlacement = toastInlineMessagePlacement(
        in: bounds,
        layoutDirection: layoutDirection
      )
      let ctaPlacement = toastInlineCTAPlacement(
        in: bounds,
        layoutDirection: layoutDirection
      )
      if layoutDirection == .leftToRight {
        subviews[0].place(
          at: messagePlacement.point,
          anchor: messagePlacement.anchor,
          proposal: .init(width: messageWidth, height: message.height)
        )
        subviews[1].place(
          at: ctaPlacement.point,
          anchor: ctaPlacement.anchor,
          proposal: .init(cta)
        )
      } else {
        subviews[0].place(
          at: messagePlacement.point,
          anchor: messagePlacement.anchor,
          proposal: .init(width: messageWidth, height: message.height)
        )
        subviews[1].place(
          at: ctaPlacement.point,
          anchor: ctaPlacement.anchor,
          proposal: .init(cta)
        )
      }
    }
  }
#endif
