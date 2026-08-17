#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI
  import Testing
  import UIKit
  @testable import GBVToast

  @MainActor
  struct SwiftUIToastPresenterTests {
    private actor CountingSleeper: ToastSleeper {
      private(set) var count = 0

      func sleep(for duration: TimeInterval) async throws {
        count += 1
      }
    }

    private struct ImmediateSleeper: ToastSleeper {
      func sleep(for duration: TimeInterval) async throws {}
    }

    @Test func hostUsesAConcreteContentSizedSwiftUIRoot() {
      let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
      let presenter = SwiftUIToastPresenter(
        containerView: container,
        root: .systemFallback
      )

      _ = presenter.present(
        ToastConfiguration(message: "Saved", autoDismissDuration: nil, isAnimated: false)
      )
      container.layoutIfNeeded()

      let hostedView = container.subviews.first
      #expect(hostedView?.frame.width ?? 390 < container.bounds.width)
      #expect(hostedView?.frame.height ?? 844 < container.bounds.height)
    }

    @Test func fullWidthUsesPhoneMargins() {
      let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
      let presenter = SwiftUIToastPresenter(
        containerView: container,
        root: .systemFallback
      )

      _ = presenter.present(
        ToastConfiguration(
          message: "Saved",
          width: .full,
          autoDismissDuration: nil,
          isAnimated: false
        )
      )
      container.layoutIfNeeded()

      #expect(container.subviews.first?.frame.width == 358)
      #expect(container.subviews.first?.frame.minX == 16)
    }

    @Test func fullWidthIsCappedAt400OnWideContainers() {
      let container = UIView(frame: CGRect(x: 0, y: 0, width: 820, height: 1_180))
      let presenter = SwiftUIToastPresenter(
        containerView: container,
        root: .systemFallback
      )

      _ = presenter.present(
        ToastConfiguration(
          message: "Saved",
          width: .full,
          autoDismissDuration: nil,
          isAnimated: false
        )
      )
      container.layoutIfNeeded()

      #expect(container.subviews.first?.frame.width == 400)
      #expect(container.subviews.first?.frame.midX == container.bounds.midX)
    }

    @Test func autoDismissUsesInjectedSleeperWithoutWallClockDelay() async {
      let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
      let presenter = SwiftUIToastPresenter(
        containerView: container,
        root: .systemFallback,
        sleeper: ImmediateSleeper()
      )

      let token = presenter.present(
        ToastConfiguration(message: "Saved", autoDismissDuration: 60, isAnimated: false)
      )

      #expect(await token.result == .dismissed)
    }

    @Test func contentHonorsTapDismissPolicyAndCTAResult() {
      var dismissCount = 0
      var ctaCount = 0
      let view = ToastContentView(
        configuration: .init(message: "Persistent", dismissOnTap: false),
        onDismiss: { dismissCount += 1 },
        onCTA: { ctaCount += 1 }
      )

      view.handleDismiss()
      view.handleCTA()

      #expect(dismissCount == 0)
      #expect(ctaCount == 1)
    }

    @Test func dismissalCanKeepHiddenHost() async {
      let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
      let presenter = SwiftUIToastPresenter(containerView: container, root: .systemFallback)
      let token = presenter.present(.init(
        message: "Persistent shell",
        autoDismissDuration: nil,
        removesOnDismiss: false,
        isAnimated: false
      ))

      presenter.dismiss(token)

      #expect(await token.result == .dismissed)
      #expect(container.subviews.count == 1)
      #expect(container.subviews.first?.isHidden == true)
    }

    @Test func missingCTAAssetDoesNotPresentOrReserveItsKey() async throws {
      let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
      let sleeper = CountingSleeper()
      let presenter = SwiftUIToastPresenter(
        containerView: container,
        root: .systemFallback,
        sleeper: sleeper
      )
      let key = "update-version"

      let rejected = presenter.present(.init(
        message: "Update available",
        cta: .init(label: .asset(
          name: "MissingToastAsset",
          accessibilityLabel: "Open App Store"
        )),
        autoDismissDuration: 2,
        deduplicationKey: key
      ))

      #expect(await rejected.result == .notPresented(.ctaAssetUnavailable))
      #expect(container.subviews.isEmpty)
      #expect(presenter.isEmpty)
      #expect(await sleeper.count == 0)

      let identifier = try #require(Bundle.module.bundleIdentifier)
      let accepted = presenter.present(.init(
        message: "Update available",
        cta: .init(label: .asset(
          name: "ToastTestIcon",
          bundleIdentifier: identifier,
          accessibilityLabel: "Open App Store"
        )),
        autoDismissDuration: nil,
        deduplicationKey: key
      ))

      #expect(container.subviews.count == 1)
      presenter.dismiss(accepted)
      #expect(await accepted.result == .dismissed)
    }

    @Test func imageCTAButtonMeetsMinimumInteractionSize() throws {
      let identifier = try #require(Bundle.module.bundleIdentifier)
      let button = ToastCTAButton(
        label: .asset(
          name: "ToastTestIcon",
          bundleIdentifier: identifier,
          accessibilityLabel: "Open App Store"
        ),
        font: .body,
        action: {}
      )
      let controller = UIHostingController(rootView: button)

      let size = controller.sizeThatFits(in: CGSize(width: 200, height: 200))

      #expect(ToastCTAButton.minimumTargetSize == 44)
      #expect(size.width >= 44)
      #expect(size.height >= 44)
    }
  }
#endif
