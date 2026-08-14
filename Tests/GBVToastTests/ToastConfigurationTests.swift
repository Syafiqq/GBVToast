import Testing

@testable import GBVToast

struct ToastConfigurationTests {
  @Test func defaultsMatchTheProductionTopToastContract() {
    let configuration = ToastConfiguration(message: "Saved")

    #expect(configuration.style == .normal)
    #expect(configuration.width == .compact)
    #expect(configuration.edge == .top)
    #expect(configuration.icon == .default)
    #expect(configuration.cta == nil)
    #expect(configuration.autoDismissDuration == 3)
    #expect(configuration.isAnimated)
    #expect(configuration.safeAreaSpacing == 16)
    #expect(configuration.deduplicationKey == nil)
  }

  @Test func fullWidthLayoutIsRepresentable() {
    let configuration = ToastConfiguration(message: "Saved", width: .full)

    #expect(configuration.width == .full)
  }

  @Test func bottomAndInlineCTAStayPlatformNeutral() {
    let configuration = ToastConfiguration(
      message: "Class removed",
      style: .info,
      edge: .bottom,
      cta: ToastCTA(title: "Undo", layout: .inline),
      autoDismissDuration: nil,
      deduplicationKey: "reminder"
    )

    #expect(configuration.edge == .bottom)
    #expect(configuration.cta == ToastCTA(title: "Undo", layout: .inline))
    #expect(configuration.autoDismissDuration == nil)
    #expect(configuration.deduplicationKey == "reminder")
  }

  @Test func stylesMatchTheGeniebookToastTypes() {
    #expect(ToastStyle.builtInCases == [.normal, .info, .danger, .warning])
  }

  @Test func customAppearanceIsPlatformNeutral() {
    let appearance = ToastAppearance(
      foreground: ToastColor(red: 0.1, green: 0.2, blue: 0.3),
      background: ToastColor(red: 0.8, green: 0.7, blue: 0.2)
    )
    let configuration = ToastConfiguration(message: "Custom", style: .custom(appearance))

    #expect(configuration.style == .custom(appearance))
  }

  @Test func persistentToastCanDisableTapAndTimerDismissal() {
    let configuration = ToastConfiguration(
      message: "Connection is unstable",
      autoDismissDuration: nil,
      dismissOnTap: false,
      removesOnDismiss: false
    )

    #expect(configuration.autoDismissDuration == nil)
    #expect(configuration.dismissOnTap == false)
    #expect(configuration.removesOnDismiss == false)
  }

  @Test func geniebookLayoutOptionsRemainRepresentable() {
    let configuration = ToastConfiguration(
      message: "Try again",
      icon: .asset(name: "retry", bundleIdentifier: "com.geniebook.student"),
      cta: ToastCTA(title: "Retry", layout: .dedicated),
      safeAreaSpacing: 24,
      maximumPhoneWidth: 358,
      maximumPadWidth: 480,
      deduplicationKey: "network"
    )

    #expect(configuration.icon == .asset(name: "retry", bundleIdentifier: "com.geniebook.student"))
    #expect(configuration.cta?.layout == .dedicated)
    #expect(configuration.safeAreaSpacing == 24)
    #expect(configuration.maximumPhoneWidth == 358)
    #expect(configuration.maximumPadWidth == 480)
    #expect(configuration.deduplicationKey == "network")
  }

  @Test func oversizedIconCanBeStressTestedWithoutRendererSpecificConfiguration() {
    let configuration = ToastConfiguration(
      message: "Large icon",
      iconSize: 64,
      autoDismissDuration: nil
    )

    #expect(configuration.iconSize == 64)
  }
}
