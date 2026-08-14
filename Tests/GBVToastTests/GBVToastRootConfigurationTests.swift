#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI
  import Testing
  @testable import GBVToast

  @MainActor
  struct GBVToastRootConfigurationTests {
    @Test func independentlyConstructedRootsWithTheSameIDAreNoOps() throws {
      let store = GBVToastConfigurationStore()
      try store.configure(makeRoot(id: "application.v1", radius: 12))
      _ = store.start()

      try store.configure(makeRoot(id: "application.v1", radius: 99))

      #expect(store.root?.cornerRadius == 12)
    }

    @Test func aDifferentRootIDIsRejectedAfterPresentationStarts() throws {
      let store = GBVToastConfigurationStore()
      try store.configure(makeRoot(id: "application.v1"))
      _ = store.start()

      #expect(throws: GBVToastConfigurationError.alreadyStarted) {
        try store.configure(makeRoot(id: "application.v2"))
      }
    }

    @Test func showingWithoutConfigurationFreezesTheReservedFallback() {
      let store = GBVToastConfigurationStore()

      let root = store.start()

      #expect(root.id == GBVToastRootConfiguration.systemFallbackID)
      #expect(throws: GBVToastConfigurationError.alreadyStarted) {
        try store.configure(makeRoot(id: "application.v1"))
      }
    }

    private func makeRoot(id: String, radius: CGFloat = 16) -> GBVToastRootConfiguration {
      let preset = GBVToastRootConfiguration.Preset(
        foregroundStyle: .primary,
        backgroundStyle: .secondary
      )
      return .init(
        id: .init(id),
        normal: preset,
        info: preset,
        danger: preset,
        warning: preset,
        cornerRadius: radius
      )
    }
  }
#endif
