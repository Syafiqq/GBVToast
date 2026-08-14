#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI
  import Testing
  import UIKit
  @testable import GBVToast

  @MainActor
  struct SwiftUIToastPresenterTests {
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
  }
#endif
