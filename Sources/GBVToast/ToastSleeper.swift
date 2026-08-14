import Foundation

protocol ToastSleeper: Sendable {
  func sleep(for duration: TimeInterval) async throws
}

@available(macOS 10.15, *)
struct SystemToastSleeper: ToastSleeper {
  func sleep(for duration: TimeInterval) async throws {
    let nanoseconds = UInt64(max(0, duration) * 1_000_000_000)
    try await Task.sleep(nanoseconds: nanoseconds)
  }
}
