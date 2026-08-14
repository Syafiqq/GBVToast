#if canImport(SwiftUI) && canImport(UIKit)
  import UIKit

  @MainActor
  final class GBVToastRuntime {
    private let configurationStore: GBVToastConfigurationStore
    private let windowResolver: any ToastWindowResolving
    private var presenters: [ObjectIdentifier: SwiftUIToastPresenter] = [:]
    private var owners: [ToastPresentationID: SwiftUIToastPresenter] = [:]

    init(
      configurationStore: GBVToastConfigurationStore = .init(),
      windowResolver: any ToastWindowResolving = SystemToastWindowResolver()
    ) {
      self.configurationStore = configurationStore
      self.windowResolver = windowResolver
    }

    func configure(root: GBVToastRootConfiguration) throws {
      try configurationStore.configure(root)
    }

    func showToast(
      _ configuration: ToastConfiguration,
      in context: ToastSceneContext?
    ) -> ToastPresentationToken {
      let root = configurationStore.start()
      switch windowResolver.resolveWindow(for: context) {
      case .failure(let reason):
        let token = ToastPresentationToken()
        token.resolve(.notPresented(reason))
        return token
      case .success(let window):
        let key = ObjectIdentifier(window)
        let presenter: SwiftUIToastPresenter
        if let existing = presenters[key] {
          presenter = existing
        } else {
          presenter = SwiftUIToastPresenter(
            containerView: window,
            root: root,
            didFinish: { [weak self] id in
              self?.owners.removeValue(forKey: id)
              if self?.presenters[key]?.isEmpty == true {
                self?.presenters.removeValue(forKey: key)
              }
            }
          )
          presenters[key] = presenter
        }
        let token = presenter.present(configuration)
        if token.isResolved == false {
          owners[token.id] = presenter
        }
        return token
      }
    }

    func dismiss(_ token: ToastPresentationToken) {
      owners[token.id]?.dismiss(token)
    }

    func dismiss(id: ToastPresentationID) {
      guard let presenter = owners[id] else { return }
      // The token is intentionally owned by the presenter; ID dismissal stays internal to it.
      presenter.dismiss(id: id)
    }
  }
#endif
