#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI

  struct ToastCTAButton: View {
    static let minimumTargetSize: CGFloat = 44

    let label: ToastCTA.Label
    let font: Font
    let action: @MainActor () -> Void

    var body: some View {
      Button(action: action) {
        content
      }
      .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
      switch label {
      case .text(let title):
        Text(title)
          .font(font)
          .underline()
          .multilineTextAlignment(.trailing)
          .fixedSize(horizontal: false, vertical: true)
          .background {
            Color.clear
              .frame(
                minWidth: Self.minimumTargetSize,
                minHeight: Self.minimumTargetSize
              )
              .contentShape(Rectangle())
          }
      case .asset(let name, let bundleIdentifier, let renderingMode, let accessibilityLabel):
        if let image = ToastAssetResolver.image(
          named: name,
          bundleIdentifier: bundleIdentifier
        ) {
          Image(uiImage: image)
            .renderingMode(renderingMode == .template ? .template : .original)
            .frame(width: image.size.width, height: image.size.height)
            .frame(
              minWidth: Self.minimumTargetSize,
              minHeight: Self.minimumTargetSize
            )
            .contentShape(Rectangle())
            .accessibilityLabel(accessibilityLabel)
        }
      }
    }
  }
#endif
