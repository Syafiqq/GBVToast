#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI
  import UIKit

  @MainActor
  final class SwiftUIToastPresenter: ToastPresenting {
    private struct Live {
      let hostingController: UIHostingController<ToastHostView>
      let token: ToastPresentationToken
      let timer: Task<Void, Never>?
      let configuration: ToastConfiguration
    }

    private weak var containerView: UIView?
    private let root: GBVToastRootConfiguration
    private let store = ToastPresentationStore()
    private let sleeper: any ToastSleeper
    private let didFinish: (ToastPresentationID) -> Void
    private var live: [ToastPresentationID: Live] = [:]

    var isEmpty: Bool { live.isEmpty }

    init(
      containerView: UIView,
      root: GBVToastRootConfiguration,
      sleeper: any ToastSleeper = SystemToastSleeper(),
      didFinish: @escaping (ToastPresentationID) -> Void = { _ in }
    ) {
      self.containerView = containerView
      self.root = root
      self.sleeper = sleeper
      self.didFinish = didFinish
    }

    @discardableResult
    func present(_ configuration: ToastConfiguration) -> ToastPresentationToken {
      let token = ToastPresentationToken()
      guard let containerView else {
        token.resolve(.notPresented(.noEligibleWindow))
        return token
      }
      guard store.insert(token, deduplicationKey: configuration.deduplicationKey) else {
        return token
      }

      let content = ToastContentView(
        configuration: configuration,
        root: root,
        onDismiss: { [weak self, weak token] in
          guard let token else { return }
          self?.finish(token, result: .dismissed)
        },
        onCTA: { [weak self, weak token] in
          guard let token else { return }
          self?.finish(token, result: .cta)
        }
      )
      let controller = UIHostingController(rootView: ToastHostView(
        content: content,
        edge: configuration.edge,
        isAnimated: configuration.isAnimated,
        reduceMotionOverride: nil
      ))
      controller.view.backgroundColor = .clear
      controller.view.translatesAutoresizingMaskIntoConstraints = false
      controller.view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      token.onDismiss = { [weak self, weak token] in
        guard let token else { return }
        self?.finish(token, result: .dismissed)
      }

      containerView.addSubview(controller.view)
      activateConstraints(for: controller.view, configuration: configuration, in: containerView)

      let timer = configuration.autoDismissDuration.map { duration in
        Task { @MainActor [weak self, weak token, sleeper] in
          do {
            try await sleeper.sleep(for: duration)
            try Task.checkCancellation()
            guard let token else { return }
            self?.finish(token, result: .dismissed)
          } catch is CancellationError {
            return
          } catch {
            return
          }
        }
      }
      live[token.id] = Live(
        hostingController: controller,
        token: token,
        timer: timer,
        configuration: configuration
      )

      if UIAccessibility.isVoiceOverRunning {
        UIAccessibility.post(notification: .announcement, argument: configuration.message)
      }
      return token
    }

    func dismiss(_ token: ToastPresentationToken) {
      finish(token, result: .dismissed)
    }

    func dismiss(id: ToastPresentationID) {
      guard let token = live[id]?.token else { return }
      finish(token, result: .dismissed)
    }

    private func finish(_ token: ToastPresentationToken, result: ToastResult) {
      guard let entry = live.removeValue(forKey: token.id) else {
        token.resolve(result)
        store.remove(token.id)
        didFinish(token.id)
        return
      }
      entry.timer?.cancel()
      store.remove(token.id)
      token.resolve(result)
      if entry.configuration.removesOnDismiss {
        entry.hostingController.view.removeFromSuperview()
      } else {
        entry.hostingController.view.isHidden = true
      }
      didFinish(token.id)
    }

    private func activateConstraints(
      for hostedView: UIView,
      configuration: ToastConfiguration,
      in containerView: UIView
    ) {
      var constraints = [
        hostedView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        hostedView.leadingAnchor.constraint(
          greaterThanOrEqualTo: containerView.leadingAnchor,
          constant: ToastWidth.horizontalMargin
        ),
        hostedView.trailingAnchor.constraint(
          lessThanOrEqualTo: containerView.trailingAnchor,
          constant: -ToastWidth.horizontalMargin
        ),
      ]
      switch configuration.edge {
      case .top:
        constraints.append(
          hostedView.topAnchor.constraint(
            equalTo: containerView.safeAreaLayoutGuide.topAnchor,
            constant: configuration.safeAreaSpacing
          ))
      case .bottom:
        constraints.append(
          hostedView.bottomAnchor.constraint(
            equalTo: containerView.safeAreaLayoutGuide.bottomAnchor,
            constant: -configuration.safeAreaSpacing
          ))
      }
      let configuredMaximumWidth = containerView.traitCollection.userInterfaceIdiom == .pad
        ? configuration.maximumPadWidth
        : configuration.maximumPhoneWidth
      if let configuredMaximumWidth {
        constraints.append(
          hostedView.widthAnchor.constraint(lessThanOrEqualToConstant: configuredMaximumWidth)
        )
      }
      if configuration.width == .full {
        constraints.append(
          hostedView.widthAnchor.constraint(lessThanOrEqualToConstant: ToastWidth.fullMaximum)
        )
        let availableWidth = hostedView.widthAnchor.constraint(
          equalTo: containerView.widthAnchor,
          constant: -(ToastWidth.horizontalMargin * 2)
        )
        availableWidth.priority = .defaultHigh
        constraints.append(availableWidth)
      }
      NSLayoutConstraint.activate(constraints)
    }
  }
#endif
