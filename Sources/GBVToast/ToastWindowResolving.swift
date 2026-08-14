#if canImport(UIKit)
  import UIKit

  @MainActor
  protocol ToastWindowResolving: AnyObject {
    func resolveWindow(for context: ToastSceneContext?) -> Result<UIWindow, ToastNotPresentedReason>
  }

  @MainActor
  final class SystemToastWindowResolver: ToastWindowResolving {
    func resolveWindow(for context: ToastSceneContext?) -> Result<UIWindow, ToastNotPresentedReason> {
      let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      if let context {
        guard let scene = scenes.first(where: {
          $0.session.persistentIdentifier == context.sceneIdentifier
        }), let window = eligibleWindow(in: scene) else {
          return .failure(.sceneUnavailable)
        }
        return .success(window)
      }

      let windows = scenes.compactMap(eligibleWindow(in:))
      switch windows.count {
      case 0: return .failure(.noEligibleWindow)
      case 1: return .success(windows[0])
      default: return .failure(.ambiguousWindows)
      }
    }

    private func eligibleWindow(in scene: UIWindowScene) -> UIWindow? {
      guard scene.activationState == .foregroundActive else { return nil }
      return scene.windows.first(where: {
        $0.isKeyWindow && $0.isHidden == false && $0.alpha > 0 && $0.windowLevel == .normal
      })
    }
  }
#endif
