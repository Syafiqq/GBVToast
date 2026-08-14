import Testing

@testable import GBVToast

struct GeniebookToastFixtureTests {
  @Test(arguments: GeniebookToastFixtures.all)
  func fixturesCarryRenderableMessages(_ fixture: ToastConfiguration) {
    #expect(fixture.message.isEmpty == false)
  }

  @Test func realProductionFixturesRemainTopEdge() {
    let productionFixtures = [
      GeniebookToastFixtures.modeSwitch,
      GeniebookToastFixtures.tenMinuteReminder,
      GeniebookToastFixtures.reminderUndo,
      GeniebookToastFixtures.hiddenIcon,
    ]

    #expect(productionFixtures.allSatisfy { $0.edge == .top })
  }
}
