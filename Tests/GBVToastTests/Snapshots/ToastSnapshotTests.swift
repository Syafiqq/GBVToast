#if canImport(SwiftUI) && canImport(UIKit)
  import SnapshotTesting
  import SwiftUI
  import UIKit
  import XCTest
  @testable import GBVToast

  @MainActor
  final class ToastSnapshotTests: XCTestCase {
    private let fixtures: [(name: String, value: ToastConfiguration)] = [
      ("mode-switch-inline-cta", GeniebookToastFixtures.modeSwitch),
      ("mode-switch-dedicated-cta", GeniebookToastFixtures.modeSwitchDedicated),
      ("ten-minute-warning-cta", GeniebookToastFixtures.tenMinuteReminder),
      ("reminder-undo", GeniebookToastFixtures.reminderUndo),
      ("hidden-icon-error", GeniebookToastFixtures.hiddenIcon),
      ("bottom-synthetic", GeniebookToastFixtures.syntheticBottom),
      ("update-version-image-cta", GeniebookToastFixtures.updateVersionImageCTA),
    ]

    func testSwiftUIRealFixturesFullPage() {
      for fixture in fixtures {
        assertSnapshot(
          of: ToastSnapshotSupport.swiftUI(fixture.value),
          as: .image(precision: 0.98),
          named: fixture.name
        )
      }
    }

    func testCTAContractMatrix() {
      for fixture in ToastParityFixtures.all where fixture.configuration.cta != nil {
        assertSnapshot(
          of: ToastSnapshotSupport.swiftUIToast(
            fixture.configuration,
            device: fixture.device,
            dynamicTypeSize: fixture.dynamicTypeSize,
            layoutDirection: fixture.layoutDirection
          ),
          as: .image(precision: 1),
          named: fixture.name
        )
      }

      assertSnapshot(
        of: ToastSnapshotSupport.swiftUIToast(GeniebookToastFixtures.modeSwitchDedicated),
        as: .image(precision: 1),
        named: "mode-switch-dedicated"
      )
    }

    func testSwiftUIParityMatrixFullPage() {
      for fixture in ToastParityFixtures.all {
        assertSnapshot(
          of: ToastSnapshotSupport.swiftUI(
            fixture.configuration,
            device: fixture.device,
            dynamicTypeSize: fixture.dynamicTypeSize,
            layoutDirection: fixture.layoutDirection
          ),
          as: .image(precision: 0.98),
          named: fixture.name
        )
      }
    }

    func testCompactAndFullWidthMatrix() {
      for fixture in ToastWidthFixtures.all {
        assertSnapshot(
          of: ToastSnapshotSupport.swiftUIWidth(
            fixture.configuration,
            device: fixture.device
          ),
          as: .image(precision: 1),
          named: fixture.name
        )
      }
    }

    func testFullWidthUsesSemanticLeadingAlignmentInRTL() {
      assertSnapshot(
        of: ToastSnapshotSupport.swiftUIWidth(
          ToastConfiguration(
            message: "تم الحفظ",
            width: .full,
            style: .info,
            autoDismissDuration: nil,
            isAnimated: false
          ),
          device: .phone,
          layoutDirection: .rightToLeft
        ),
        as: .image(precision: 1)
      )
    }

    func testImageCTAContractMatrix() {
      assertSnapshot(
        of: ToastSnapshotSupport.swiftUIToast(GeniebookToastFixtures.updateVersionImageCTA),
        as: .image(precision: 1),
        named: "inline-phone"
      )
      assertSnapshot(
        of: ToastSnapshotSupport.swiftUIToast(GeniebookToastFixtures.updateVersionLongMessage),
        as: .image(precision: 1),
        named: "responsive-long-message"
      )
      assertSnapshot(
        of: ToastSnapshotSupport.swiftUIToast(
          GeniebookToastFixtures.updateVersionImageCTA,
          dynamicTypeSize: .accessibility3
        ),
        as: .image(precision: 1),
        named: "accessibility"
      )
      assertSnapshot(
        of: ToastSnapshotSupport.swiftUIToast(
          GeniebookToastFixtures.updateVersionImageCTA,
          layoutDirection: .rightToLeft
        ),
        as: .image(precision: 1),
        named: "right-to-left"
      )
      assertSnapshot(
        of: ToastSnapshotSupport.legacyImageCTA(GeniebookToastFixtures.updateVersionImageCTA),
        as: .image(precision: 1),
        named: "legacy-vertical"
      )
    }
  }
#endif
