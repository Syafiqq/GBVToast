@MainActor
@available(macOS 10.15, *)
final class ToastPresentationStore {
  private struct Entry {
    let token: ToastPresentationToken
    let deduplicationKey: String?
  }

  private var entries: [ToastPresentationID: Entry] = [:]
  private var activeKeys: Set<String> = []

  var count: Int {
    entries.count
  }

  @discardableResult
  func insert(_ token: ToastPresentationToken, deduplicationKey: String?) -> Bool {
    if let deduplicationKey, activeKeys.contains(deduplicationKey) {
      token.resolve(.notPresented(.duplicateKey))
      return false
    }

    entries[token.id] = Entry(token: token, deduplicationKey: deduplicationKey)
    if let deduplicationKey {
      activeKeys.insert(deduplicationKey)
    }
    return true
  }

  func remove(_ id: ToastPresentationID) {
    guard let entry = entries.removeValue(forKey: id) else {
      return
    }
    if let deduplicationKey = entry.deduplicationKey {
      activeKeys.remove(deduplicationKey)
    }
  }
}
