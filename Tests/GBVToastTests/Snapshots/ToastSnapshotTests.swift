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
  }
#endif
