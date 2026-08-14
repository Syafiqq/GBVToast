#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI

  @MainActor
  public struct GBVToastRootConfiguration {
    public struct ID: Hashable, Sendable, RawRepresentable {
      public let rawValue: String

      public init(rawValue: String) {
        precondition(rawValue.isEmpty == false, "A root configuration ID must not be empty.")
        self.rawValue = rawValue
      }

      public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
      }
    }

    public struct Preset {
      public let foregroundStyle: Color
      public let backgroundStyle: Color
      public let icon: Image?

      public init(foregroundStyle: Color, backgroundStyle: Color, icon: Image? = nil) {
        self.foregroundStyle = foregroundStyle
        self.backgroundStyle = backgroundStyle
        self.icon = icon
      }
    }

    public let id: ID
    public let normal: Preset
    public let info: Preset
    public let danger: Preset
    public let warning: Preset
    public let font: Font
    public let cornerRadius: CGFloat
    public let horizontalInset: CGFloat
    public let verticalInset: CGFloat

    public init(
      id: ID,
      normal: Preset,
      info: Preset,
      danger: Preset,
      warning: Preset,
      font: Font = .headline,
      cornerRadius: CGFloat = 16,
      horizontalInset: CGFloat = 24,
      verticalInset: CGFloat = 16
    ) {
      self.id = id
      self.normal = normal
      self.info = info
      self.danger = danger
      self.warning = warning
      self.font = font
      self.cornerRadius = cornerRadius
      self.horizontalInset = horizontalInset
      self.verticalInset = verticalInset
    }

    static let systemFallbackID = ID("com.geniebook.GBVToast.system-fallback.v1")

    public static let systemFallback = Self(
      id: systemFallbackID,
      normal: .init(foregroundStyle: .primary, backgroundStyle: Color(uiColor: .systemBackground)),
      info: .init(
        foregroundStyle: .white,
        backgroundStyle: .blue,
        icon: Image(systemName: "checkmark.circle.fill")
      ),
      danger: .init(
        foregroundStyle: .white,
        backgroundStyle: .red,
        icon: Image(systemName: "xmark.circle.fill")
      ),
      warning: .init(
        foregroundStyle: .primary,
        backgroundStyle: .yellow,
        icon: Image(systemName: "exclamationmark.triangle.fill")
      )
    )

    func preset(for style: ToastStyle) -> Preset {
      switch style {
      case .normal: normal
      case .info: info
      case .danger: danger
      case .warning: warning
      case .custom(let appearance):
        Preset(
          foregroundStyle: Color(appearance.foreground),
          backgroundStyle: Color(appearance.background)
        )
      }
    }
  }

  private extension Color {
    init(_ color: ToastColor) {
      self.init(
        red: color.red,
        green: color.green,
        blue: color.blue,
        opacity: color.alpha
      )
    }
  }

  public enum GBVToastConfigurationError: Error, Equatable {
    case alreadyStarted
  }

  @MainActor
  final class GBVToastConfigurationStore {
    private(set) var root: GBVToastRootConfiguration?
    private(set) var hasStarted = false

    func configure(_ root: GBVToastRootConfiguration) throws {
      if let active = self.root {
        guard active.id != root.id else { return }
        if hasStarted { throw GBVToastConfigurationError.alreadyStarted }
      }
      self.root = root
    }

    func start() -> GBVToastRootConfiguration {
      hasStarted = true
      if let root { return root }
      root = .systemFallback
      return .systemFallback
    }
  }
#endif
