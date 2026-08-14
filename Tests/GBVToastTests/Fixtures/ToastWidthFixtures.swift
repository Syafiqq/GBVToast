@testable import GBVToast

enum ToastWidthFixtures {
  static let all: [ToastParityFixture] = [
    fixture(name: "width-iphone-compact", device: .phone, width: .compact),
    fixture(name: "width-iphone-full", device: .phone, width: .full),
    fixture(name: "width-ipad-compact", device: .pad, width: .compact),
    fixture(name: "width-ipad-full", device: .pad, width: .full),
  ]

  private static func fixture(
    name: String,
    device: ToastParityFixture.Device,
    width: ToastWidth
  ) -> ToastParityFixture {
    ToastParityFixture(
      name: name,
      device: device,
      configuration: ToastConfiguration(
        message: "Saved",
        width: width,
        style: .info,
        autoDismissDuration: nil,
        isAnimated: false
      )
    )
  }
}
