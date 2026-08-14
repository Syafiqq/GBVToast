#if canImport(SwiftUI) && canImport(UIKit)
  import UIKit

  @MainActor
  public enum GBVToast {
    private static let runtime = GBVToastRuntime()

    public static func configure(root: GBVToastRootConfiguration) throws {
      try runtime.configure(root: root)
    }

    public static func sceneContext(for windowScene: UIWindowScene) -> ToastSceneContext {
      ToastSceneContext(sceneIdentifier: windowScene.session.persistentIdentifier)
    }

    @discardableResult
    public static func showToast(
      _ configuration: ToastConfiguration,
      in context: ToastSceneContext? = nil
    ) -> ToastPresentationToken {
      runtime.showToast(configuration, in: context)
    }

    public static func dismiss(_ token: ToastPresentationToken) {
      runtime.dismiss(token)
    }

    public static func dismiss(id: ToastPresentationID) {
      runtime.dismiss(id: id)
    }
  }
#endif
