#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI

  public struct SwiftUIToastPalette {
    public let foregroundStyle: Color
    public let backgroundStyle: Color
    public let icon: Image?
    public let font: Font
    public let cornerRadius: CGFloat
    public let horizontalInset: CGFloat
    public let verticalInset: CGFloat

    @MainActor
    public init(
      root: GBVToastRootConfiguration,
      style: ToastStyle
    ) {
      let preset = root.preset(for: style)
      foregroundStyle = preset.foregroundStyle
      backgroundStyle = preset.backgroundStyle
      icon = preset.icon
      font = root.font
      cornerRadius = root.cornerRadius
      horizontalInset = root.horizontalInset
      verticalInset = root.verticalInset
    }
  }
#endif
