import Testing

@testable import GBVToast

@MainActor
struct ToastPresentationStoreTests {
  @Test func duplicateLiveKeyDropsNewPresentation() async {
    let store = ToastPresentationStore()
    let first = ToastPresentationToken()
    let duplicate = ToastPresentationToken()

    #expect(store.insert(first, deduplicationKey: "network"))
    #expect(store.insert(duplicate, deduplicationKey: "network") == false)
    #expect(await duplicate.result == .notPresented(.duplicateKey))
    #expect(store.count == 1)
  }

  @Test func removingPresentationReleasesItsKey() {
    let store = ToastPresentationStore()
    let first = ToastPresentationToken()
    let replacement = ToastPresentationToken()

    #expect(store.insert(first, deduplicationKey: "network"))
    store.remove(first.id)

    #expect(store.insert(replacement, deduplicationKey: "network"))
  }

  @Test func distinctKeysCanCoexist() {
    let store = ToastPresentationStore()

    #expect(store.insert(ToastPresentationToken(), deduplicationKey: "one"))
    #expect(store.insert(ToastPresentationToken(), deduplicationKey: "two"))
    #expect(store.count == 2)
  }
}
