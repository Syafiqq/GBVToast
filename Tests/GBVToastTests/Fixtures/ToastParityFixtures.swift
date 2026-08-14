import Foundation
import SwiftUI

@testable import GBVToast

struct ToastParityFixture: Sendable {
  enum Device: Sendable, Equatable {
    case phone
    case pad

    var name: String {
      switch self {
      case .phone: "iPhone 14"
      case .pad: "iPad (10th generation)"
      }
    }

    var size: CGSize {
      switch self {
      case .phone: CGSize(width: 390, height: 844)
      case .pad: CGSize(width: 820, height: 1_180)
      }
    }

    var safeAreaTop: CGFloat {
      switch self {
      case .phone: 47
      case .pad: 24
      }
    }

    var safeAreaBottom: CGFloat {
      switch self {
      case .phone: 34
      case .pad: 20
      }
    }
  }

  let name: String
  let device: Device
  let configuration: ToastConfiguration
  var dynamicTypeSize: DynamicTypeSize = .large
  var layoutDirection: LayoutDirection = .leftToRight
}

enum ToastParityFixtures {
  static let all: [ToastParityFixture] = [
    .init(name: "default-title-only", device: .phone, configuration: .init(
      message: "Your changes have been saved", style: .normal, icon: .hidden,
      autoDismissDuration: nil)),
    .init(name: "success-icon-title", device: .phone, configuration: .init(
      message: "Worksheet submitted successfully", style: .info,
      autoDismissDuration: nil)),
    .init(name: "error-hidden-icon-multiline", device: .phone, configuration: .init(
      message: "Unable to load your worksheet. Please check your connection and try again.",
      style: .danger, icon: .hidden, autoDismissDuration: nil)),
    .init(name: "warning-icon-title", device: .phone, configuration: .init(
      message: "10 minutes remaining", style: .warning, autoDismissDuration: nil)),
    .init(name: "custom-colors-title", device: .phone, configuration: .init(
      message: "Custom Geniebook announcement",
      style: .custom(.init(
        foreground: .init(red: 0.08, green: 0.12, blue: 0.25),
        background: .init(red: 0.63, green: 0.82, blue: 1)
      )), icon: .hidden, autoDismissDuration: nil)),
    .init(name: "inline-cta-with-icon", device: .phone, configuration: .init(
      message: "Switching GenieAsk mode", style: .info,
      cta: .init(title: "Close", layout: .inline), autoDismissDuration: nil)),
    .init(name: "inline-cta-without-icon", device: .phone, configuration: .init(
      message: "Draft restored", icon: .hidden,
      cta: .init(title: "Review", layout: .inline), autoDismissDuration: nil)),
    .init(name: "dedicated-cta-with-icon", device: .phone, configuration: .init(
      message: "Reminder removed", style: .info,
      cta: .init(title: "Undo", layout: .dedicated), autoDismissDuration: nil)),
    .init(name: "dedicated-cta-without-icon", device: .phone, configuration: .init(
      message: "Session expired", style: .danger, icon: .hidden,
      cta: .init(title: "Sign in", layout: .dedicated), autoDismissDuration: nil)),
    .init(name: "ipad-inline-cta-centered", device: .pad, configuration: .init(
      message: "Switching GenieAsk mode", style: .info,
      cta: .init(title: "Close", layout: .inline), autoDismissDuration: nil,
      maximumPadWidth: 480)),
    .init(name: "ipad-dedicated-cta-bottom", device: .pad, configuration: .init(
      message: "10 minutes remaining", style: .warning,
      cta: .init(title: "Dismiss", layout: .dedicated), autoDismissDuration: nil,
      maximumPadWidth: 480)),
    .init(name: "bottom-custom-spacing", device: .phone, configuration: .init(
      message: "Saved", style: .info, edge: .bottom, autoDismissDuration: nil,
      safeAreaSpacing: 24, maximumPhoneWidth: 320)),
    .init(name: "stress-large-icon", device: .phone, configuration: .init(
      message: "A deliberately oversized status icon must not overlap the title or CTA.",
      style: .warning, iconSize: 64,
      cta: .init(title: "Dismiss", layout: .inline), autoDismissDuration: nil)),
    .init(name: "stress-long-title", device: .phone, configuration: .init(
      message: "This is an intentionally very long Geniebook toast title used to verify that multiple lines wrap cleanly, remain readable at the supported phone width, preserve the icon alignment, and never escape the rounded toast container even when the message contains substantially more content than a production notification normally would.",
      style: .danger, cta: .init(title: "Try again", layout: .dedicated),
      autoDismissDuration: nil)),
    .init(name: "stress-long-cta", device: .phone, configuration: .init(
      message: "Your worksheet could not be submitted.", style: .danger,
      cta: .init(
        title: "Review your worksheet answers and submit the entire worksheet again",
        layout: .inline
      ), autoDismissDuration: nil)),
    .init(name: "custom-asset-icon", device: .phone, configuration: .init(
      message: "Custom informative asset",
      style: .info,
      icon: .asset(
        name: "ToastTestIcon",
        bundleIdentifier: Bundle.module.bundleIdentifier,
        renderingMode: .original,
        accessibilityLabel: "Geniebook"
      ),
      autoDismissDuration: nil)),
    .init(name: "accessibility-extra-extra-extra-large", device: .phone, configuration: .init(
      message: "Worksheet ready.",
      style: .warning,
      cta: .init(title: "Review", layout: .inline),
      autoDismissDuration: nil), dynamicTypeSize: .accessibility3),
    .init(name: "right-to-left-layout", device: .phone, configuration: .init(
      message: "تم حفظ ورقة العمل",
      style: .info,
      cta: .init(title: "تراجع", layout: .dedicated),
      autoDismissDuration: nil), layoutDirection: .rightToLeft),
  ]
}
