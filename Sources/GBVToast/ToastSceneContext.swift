public struct ToastSceneContext: Sendable, Hashable {
  let sceneIdentifier: String

  init(sceneIdentifier: String) {
    self.sceneIdentifier = sceneIdentifier
  }
}
