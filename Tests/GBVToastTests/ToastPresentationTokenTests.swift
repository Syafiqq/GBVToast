import Testing

@testable import GBVToast

@MainActor
struct ToastPresentationTokenTests {
  @Test func resultReplaysAfterResolution() async {
    let token = ToastPresentationToken()

    token.resolve(.cta)

    #expect(await token.result == .cta)
    #expect(await token.result == .cta)
  }

  @Test func firstResolutionWins() async {
    let token = ToastPresentationToken()

    token.resolve(.cta)
    token.resolve(.dismissed)

    #expect(await token.result == .cta)
  }
}
