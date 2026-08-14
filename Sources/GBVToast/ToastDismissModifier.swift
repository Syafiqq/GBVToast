#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI

  struct ToastDismissModifier: ViewModifier {
    let isEnabled: Bool
    let action: @MainActor () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
      if isEnabled {
        content
          .onTapGesture(perform: action)
          .accessibilityAddTraits(.isButton)
          .accessibilityAction(named: "Dismiss", action)
      } else {
        content
      }
    }
  }
#endif
