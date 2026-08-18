#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI
  import Testing

  @testable import GBVToast

  struct ToastInlineLayoutTests {
    @Test(
      "Inline CTA is centered at semantic trailing",
      arguments: [
        (LayoutDirection.leftToRight, CGFloat(24), CGFloat(72)),
        (LayoutDirection.leftToRight, CGFloat(72), CGFloat(24)),
        (LayoutDirection.rightToLeft, CGFloat(24), CGFloat(72)),
        (LayoutDirection.rightToLeft, CGFloat(72), CGFloat(24)),
      ]
    )
    func ctaIsCenteredAtSemanticTrailing(
      layoutDirection: LayoutDirection,
      messageHeight: CGFloat,
      ctaHeight: CGFloat
    ) {
      let bounds = CGRect(
        x: 17,
        y: 29,
        width: 240,
        height: max(messageHeight, ctaHeight)
      )
      let placement = toastInlineCTAPlacement(
        in: bounds,
        layoutDirection: layoutDirection
      )
      let ctaFrame = CGRect(
        x: placement.point.x - placement.anchor.x * 64,
        y: placement.point.y - placement.anchor.y * ctaHeight,
        width: 64,
        height: ctaHeight
      )

      #expect(ctaFrame.midY == bounds.midY)
      if layoutDirection == .leftToRight {
        #expect(ctaFrame.maxX == bounds.maxX)
        #expect(placement.anchor == .trailing)
      } else {
        #expect(ctaFrame.minX == bounds.minX)
        #expect(placement.anchor == .leading)
      }
    }
  }
#endif
