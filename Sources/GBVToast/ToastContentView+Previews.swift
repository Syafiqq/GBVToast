#if DEBUG && canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI

  #Preview("Presets") {
    VStack(spacing: 16) {
      ToastContentView(configuration: .init(message: "Normal", style: .normal), onDismiss: {})
      ToastContentView(configuration: .init(message: "Information", style: .info), onDismiss: {})
      ToastContentView(configuration: .init(message: "Danger", style: .danger), onDismiss: {})
      ToastContentView(configuration: .init(message: "Warning", style: .warning), onDismiss: {})
    }
    .padding()
  }

  #Preview("CTA layouts and long content") {
    VStack(spacing: 16) {
      ToastContentView(
        configuration: .init(
          message: "Inline CTA keeps the icon top-aligned and the action bottom-trailing.",
          style: .info,
          cta: .init(title: "Review", layout: .inline)
        ),
        onDismiss: {}
      )
      ToastContentView(
        configuration: .init(
          message: "A long action falls back vertically without clipping or truncating content.",
          style: .danger,
          cta: .init(
            title: "Review your worksheet answers and submit the entire worksheet again",
            layout: .dedicated
          )
        ),
        onDismiss: {}
      )
    }
    .padding()
  }

  #Preview("Accessibility XXXL and Reduce Motion") {
    ToastHostView(
      content: ToastContentView(
        configuration: .init(
          message: "Worksheet ready.",
          style: .warning,
          cta: .init(title: "Review", layout: .inline)
        ),
        onDismiss: {}
      ),
      edge: .top,
      isAnimated: true,
      reduceMotionOverride: true
    )
    .environment(\.dynamicTypeSize, .accessibility3)
    .padding()
  }

  #Preview("Right to left") {
    ToastContentView(
      configuration: .init(
        message: "تم حفظ ورقة العمل",
        style: .info,
        cta: .init(title: "تراجع", layout: .dedicated)
      ),
      onDismiss: {}
    )
    .environment(\.layoutDirection, .rightToLeft)
    .padding()
  }
#endif
