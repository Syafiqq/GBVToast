#if canImport(SwiftUI) && canImport(UIKit)
  import Testing
  import UIKit
  @testable import GBVToast

  @MainActor
  struct GBVToastRuntimeTests {
    private final class Resolver: ToastWindowResolving {
      var result: Result<UIWindow, ToastNotPresentedReason>
      var byScene: [String: UIWindow] = [:]

      init(_ result: Result<UIWindow, ToastNotPresentedReason>) {
        self.result = result
      }

      func resolveWindow(for context: ToastSceneContext?) -> Result<UIWindow, ToastNotPresentedReason> {
        guard let context else { return result }
        return byScene[context.sceneIdentifier].map(Result.success)
          ?? .failure(.sceneUnavailable)
      }
    }

    @Test(arguments: [
      ToastNotPresentedReason.noEligibleWindow,
      .ambiguousWindows,
    ])
    func contextFreeWindowFailuresAreTyped(_ reason: ToastNotPresentedReason) async {
      let runtime = GBVToastRuntime(windowResolver: Resolver(.failure(reason)))

      let token = runtime.showToast(.init(message: "Saved"), in: nil)

      #expect(await token.result == .notPresented(reason))
    }

    @Test func disconnectedCapturedSceneDoesNotFallBack() async {
      let fallback = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
      let runtime = GBVToastRuntime(windowResolver: Resolver(.success(fallback)))

      let token = runtime.showToast(
        .init(message: "Saved"),
        in: .init(sceneIdentifier: "disconnected")
      )

      #expect(await token.result == .notPresented(.sceneUnavailable))
      #expect(fallback.subviews.isEmpty)
    }

    @Test func duplicateKeysAreScopedToTheResolvedScene() async {
      let firstWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
      let secondWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
      let resolver = Resolver(.success(firstWindow))
      resolver.byScene = ["first": firstWindow, "second": secondWindow]
      let runtime = GBVToastRuntime(windowResolver: resolver)
      let configuration = ToastConfiguration(
        message: "Offline",
        autoDismissDuration: nil,
        isAnimated: false,
        deduplicationKey: "network"
      )

      let first = runtime.showToast(configuration, in: .init(sceneIdentifier: "first"))
      let duplicate = runtime.showToast(configuration, in: .init(sceneIdentifier: "first"))
      let otherScene = runtime.showToast(configuration, in: .init(sceneIdentifier: "second"))

      #expect(await duplicate.result == .notPresented(.duplicateKey))
      #expect(first.isResolved == false)
      #expect(otherScene.isResolved == false)
      runtime.dismiss(first)
      runtime.dismiss(otherScene)
    }

    @Test func generatedIDDismissalFindsTheOwningPresenter() async {
      let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
      let runtime = GBVToastRuntime(windowResolver: Resolver(.success(window)))
      let token = runtime.showToast(
        .init(message: "Saved", autoDismissDuration: nil, isAnimated: false),
        in: nil
      )

      runtime.dismiss(id: token.id)

      #expect(await token.result == .dismissed)
    }
  }
#endif
