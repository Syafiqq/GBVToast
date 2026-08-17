#if canImport(UIKit)
  import Testing
  import UIKit
  @testable import GBVToast

  @MainActor
  struct ToastAssetResolverTests {
    @Test func resolvesImageFromAnExplicitBundle() throws {
      let identifier = try #require(Bundle.module.bundleIdentifier)

      let image = ToastAssetResolver.image(
        named: "ToastTestIcon",
        bundleIdentifier: identifier
      )

      #expect(image != nil)
      #expect(image?.size == CGSize(width: 64, height: 64))
    }

    @Test func updateVersionArtworkHasExpectedIntrinsicSize() throws {
      let identifier = try #require(Bundle.module.bundleIdentifier)
      let image = try #require(ToastAssetResolver.image(
        named: "UpdateVersionAppStore",
        bundleIdentifier: identifier
      ))

      #expect(image.size == CGSize(width: 40, height: 40))
    }

    @Test func rejectsUnknownAssetAndBundleWithoutFallback() {
      #expect(ToastAssetResolver.image(
        named: "MissingToastAsset",
        bundleIdentifier: Bundle.module.bundleIdentifier
      ) == nil)
      #expect(ToastAssetResolver.image(
        named: "ToastTestIcon",
        bundleIdentifier: "invalid.bundle.identifier"
      ) == nil)
    }
  }
#endif
