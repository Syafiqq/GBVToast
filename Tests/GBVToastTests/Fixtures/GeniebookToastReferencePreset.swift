#if canImport(CoreText) && canImport(SwiftUI) && canImport(UIKit)
  import CoreText
  import SwiftUI

  @testable import GBVToast

  /// Test/example-only appearance copied from Geniebook's production VToastViewV2.
  @MainActor
  enum GeniebookToastReferencePreset {
    static let configuration: GBVToastRootConfiguration = {
      registerOpenSansBold()

      return GBVToastRootConfiguration(
        id: .init("tests.geniebook-production-reference.v1"),
        normal: .init(
          foregroundStyle: .white,
          backgroundStyle: color(red: 0x82, green: 0x7E, blue: 0x7E)
        ),
        info: .init(
          foregroundStyle: .white,
          backgroundStyle: color(red: 0x48, green: 0xA0, blue: 0x74),
          icon: Image("GeniebookToastSuccess", bundle: .module)
        ),
        danger: .init(
          foregroundStyle: .white,
          backgroundStyle: color(red: 0xF7, green: 0x77, blue: 0x67),
          icon: Image("GeniebookToastDanger", bundle: .module)
        ),
        warning: .init(
          foregroundStyle: color(red: 0x33, green: 0x33, blue: 0x33),
          backgroundStyle: color(red: 0xFE, green: 0xD0, blue: 0x0B),
          icon: Image("GeniebookToastWarning", bundle: .module)
        ),
        font: .custom("OpenSans-Bold", size: 16, relativeTo: .body),
        cornerRadius: 16,
        horizontalInset: 24,
        verticalInset: 16
      )
    }()

    private static func color(red: Int, green: Int, blue: Int) -> Color {
      Color(
        red: Double(red) / 255,
        green: Double(green) / 255,
        blue: Double(blue) / 255
      )
    }

    private static func registerOpenSansBold() {
      guard let fontURL = Bundle.module.url(
        forResource: "OpenSans-Bold",
        withExtension: "ttf"
      ) else {
        preconditionFailure("Missing copied Geniebook OpenSans-Bold.ttf fixture")
      }

      var registrationError: Unmanaged<CFError>?
      let registered = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &registrationError)
      if registered == false,
         let error = registrationError?.takeRetainedValue(),
         CFErrorGetCode(error) != CTFontManagerError.alreadyRegistered.rawValue
      {
        preconditionFailure("Could not register OpenSans-Bold.ttf: \(error)")
      }
    }
  }
#endif
