#if canImport(UIKit)
  import UIKit

  @MainActor
  enum ToastAssetResolver {
    static func image(named name: String, bundleIdentifier: String?) -> UIImage? {
      let bundle: Bundle
      if let bundleIdentifier {
        guard let identifiedBundle = Bundle(identifier: bundleIdentifier) else { return nil }
        bundle = identifiedBundle
      } else {
        bundle = .main
      }
      return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
  }
#endif
