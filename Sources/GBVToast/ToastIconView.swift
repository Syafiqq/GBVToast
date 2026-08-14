#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI

  struct ToastIconView: View {
    let icon: ToastIcon
    let size: CGFloat
    let defaultImage: Image?
    let tint: Color

    var body: some View {
      resolvedImage
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var resolvedImage: some View {
      switch icon {
      case .hidden:
        EmptyView()
      case .default:
        defaultImage?
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .foregroundStyle(tint)
          .accessibilityHidden(true)
      case .asset(let name, let bundleIdentifier, let renderingMode, let label):
        configuredAsset(
          Image(name, bundle: bundleIdentifier.flatMap(Bundle.init(identifier:)) ?? .main),
          renderingMode: renderingMode,
          label: label
        )
      }
    }

    @ViewBuilder
    private func configuredAsset(
      _ image: Image,
      renderingMode: ToastIcon.RenderingMode,
      label: String?
    ) -> some View {
      let rendered = image
        .renderingMode(renderingMode == .template ? .template : .original)
        .resizable()
        .scaledToFit()

      if let label {
        rendered
          .foregroundStyle(tint)
          .accessibilityLabel(label)
      } else {
        rendered
          .foregroundStyle(tint)
          .accessibilityHidden(true)
      }
    }
  }
#endif
