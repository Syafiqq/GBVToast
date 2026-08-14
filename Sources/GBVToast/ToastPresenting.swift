@MainActor
@available(macOS 10.15, *)
public protocol ToastPresenting: AnyObject {
  @discardableResult
  func present(_ configuration: ToastConfiguration) -> ToastPresentationToken
  func dismiss(_ token: ToastPresentationToken)
}
