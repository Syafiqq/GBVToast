import Foundation

@MainActor
@available(macOS 10.15, *)
public final class ToastPresentationToken {
  public let id = ToastPresentationID()

  private var resolvedResult: ToastResult?
  private var waiters: [UUID: CheckedContinuation<ToastResult, Never>] = [:]
  var onDismiss: (() -> Void)?

  public init() {}

  var isResolved: Bool { resolvedResult != nil }

  public var result: ToastResult {
    get async {
      if let resolvedResult {
        return resolvedResult
      }

      let waiterID = UUID()
      return await withTaskCancellationHandler {
        await withCheckedContinuation { continuation in
          if let resolvedResult {
            continuation.resume(returning: resolvedResult)
          } else {
            waiters[waiterID] = continuation
          }
        }
      } onCancel: {
        Task { @MainActor [weak self] in
          self?.cancelWaiter(waiterID)
        }
      }
    }
  }

  public func dismiss() {
    onDismiss?()
  }

  func resolve(_ result: ToastResult) {
    guard resolvedResult == nil else {
      return
    }

    resolvedResult = result
    onDismiss = nil
    let pendingWaiters = waiters.values
    waiters.removeAll()
    for waiter in pendingWaiters {
      waiter.resume(returning: result)
    }
  }

  private func cancelWaiter(_ id: UUID) {
    waiters.removeValue(forKey: id)?.resume(returning: .dismissed)
  }
}
