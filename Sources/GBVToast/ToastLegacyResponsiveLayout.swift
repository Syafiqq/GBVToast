#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI

  struct ToastLegacyResponsiveLayout: View {
    let message: String
    let cta: ToastCTA
    let font: Font
    let foregroundStyle: Color
    let onCTA: @MainActor () -> Void

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        Text(message)
          .font(font)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityHidden(true)
        Button(action: onCTA) {
          Text(cta.title)
            .font(font)
            .underline()
            .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
      }
      .foregroundStyle(foregroundStyle)
    }
  }
#endif
