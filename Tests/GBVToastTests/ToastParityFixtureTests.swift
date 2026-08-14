import Testing

@testable import GBVToast

struct ToastParityFixtureTests {
  @Test func matrixCoversEveryAppearance() {
    let styles = ToastParityFixtures.all.map(\.configuration.style)
    for style in ToastStyle.builtInCases {
      #expect(styles.contains(style))
    }
    #expect(styles.contains { if case .custom = $0 { true } else { false } })
  }

  @Test func matrixCoversComponentsEdgesAndDevices() {
    let configurations = ToastParityFixtures.all.map(\.configuration)
    #expect(configurations.contains { $0.icon == .hidden && $0.cta == nil })
    #expect(configurations.contains { $0.icon == .default && $0.cta == nil })
    #expect(configurations.contains { $0.icon == .hidden && $0.cta?.layout == .inline })
    #expect(configurations.contains { $0.icon == .default && $0.cta?.layout == .inline })
    #expect(configurations.contains { $0.icon == .hidden && $0.cta?.layout == .dedicated })
    #expect(configurations.contains { $0.icon == .default && $0.cta?.layout == .dedicated })
    #expect(configurations.contains { $0.edge == .top })
    #expect(configurations.contains { $0.edge == .bottom })
    #expect(ToastParityFixtures.all.contains { $0.device == .phone })
    #expect(ToastParityFixtures.all.contains { $0.device == .pad })
  }

  @Test func matrixIncludesRequestedStressCases() {
    let names = Set(ToastParityFixtures.all.map(\.name))
    #expect(names.contains("stress-large-icon"))
    #expect(names.contains("stress-long-title"))
    #expect(names.contains("stress-long-cta"))
  }

  @Test func widthMatrixCoversPhonePadCompactAndFull() {
    #expect(ToastWidthFixtures.all.count == 4)
    #expect(ToastWidthFixtures.all.contains {
      $0.device == .phone && $0.configuration.width == .compact
    })
    #expect(ToastWidthFixtures.all.contains {
      $0.device == .phone && $0.configuration.width == .full
    })
    #expect(ToastWidthFixtures.all.contains {
      $0.device == .pad && $0.configuration.width == .compact
    })
    #expect(ToastWidthFixtures.all.contains {
      $0.device == .pad && $0.configuration.width == .full
    })
  }
}
