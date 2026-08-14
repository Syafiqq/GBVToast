#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI

  public struct ToastContentView: View {
    private let configuration: ToastConfiguration
    private let palette: SwiftUIToastPalette
    private let onDismiss: @MainActor () -> Void
    private let onCTA: @MainActor () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.layoutDirection) private var layoutDirection

    @MainActor
    public init(
      configuration: ToastConfiguration,
      root: GBVToastRootConfiguration = .systemFallback,
      onDismiss: @MainActor @escaping () -> Void,
      onCTA: @MainActor @escaping () -> Void = {}
    ) {
      self.configuration = configuration
      palette = SwiftUIToastPalette(root: root, style: configuration.style)
      self.onDismiss = onDismiss
      self.onCTA = onCTA
    }

    public var body: some View {
      content
        .padding(.horizontal, palette.horizontalInset)
        .padding(.vertical, palette.verticalInset)
        .foregroundStyle(palette.foregroundStyle)
        .background(palette.backgroundStyle, in: .rect(cornerRadius: palette.cornerRadius))
        .contentShape(.rect(cornerRadius: palette.cornerRadius))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(configuration.message)
        .modifier(ToastDismissModifier(
          isEnabled: configuration.dismissOnTap,
          action: handleDismiss
        ))
    }

    @ViewBuilder
    private var content: some View {
      HStack(alignment: .top, spacing: 16) {
        if configuration.icon != .hidden {
          ToastIconView(
            icon: configuration.icon,
            size: configuration.iconSize,
            defaultImage: palette.icon,
            tint: palette.foregroundStyle
          )
        }
        responsiveMessageAndCTA
      }
    }

    @ViewBuilder
    private var responsiveMessageAndCTA: some View {
      if let cta = configuration.cta {
        if dynamicTypeSize.isAccessibilitySize {
          verticalLayout(cta)
        } else if #available(iOS 16, *) {
          requestedLayout(cta)
        } else {
          ToastLegacyResponsiveLayout(
            message: configuration.message,
            cta: cta,
            font: palette.font,
            foregroundStyle: palette.foregroundStyle,
            onCTA: onCTA
          )
        }
      } else {
        message
      }
    }

    @available(iOS 16, *)
    @ViewBuilder
    private func requestedLayout(_ cta: ToastCTA) -> some View {
      switch cta.layout {
      case .inline:
        ToastInlineLayout(spacing: 12, layoutDirection: layoutDirection) {
          message
          ctaButton(cta)
        }
      case .dedicated:
        ToastDedicatedLayout(spacing: 8, layoutDirection: layoutDirection) {
          message
          ctaButton(cta)
        }
      }
    }

    private func verticalLayout(_ cta: ToastCTA) -> some View {
      VStack(alignment: .leading, spacing: 8) {
        message
        ctaButton(cta)
          .frame(maxWidth: .infinity, alignment: .trailing)
      }
    }

    private var message: some View {
      Text(configuration.message)
        .font(palette.font)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityHidden(true)
    }

    private func ctaButton(_ cta: ToastCTA) -> some View {
      Button(action: handleCTA) {
        Text(cta.title)
          .font(palette.font)
          .underline()
          .multilineTextAlignment(.trailing)
          .fixedSize(horizontal: false, vertical: true)
          .background {
            Color.clear
              .frame(minWidth: 44, minHeight: 44)
              .contentShape(Rectangle())
          }
      }
        .buttonStyle(.plain)
    }

    func handleDismiss() {
      guard configuration.dismissOnTap else { return }
      onDismiss()
    }

    func handleCTA() {
      onCTA()
    }
  }

#endif
