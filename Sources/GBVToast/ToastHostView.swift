#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI

  struct ToastHostView: View {
    let content: ToastContentView
    let edge: ToastEdge
    let isAnimated: Bool
    var reduceMotionOverride: Bool?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPresented = false

    var body: some View {
      ZStack {
        if isPresented {
          content
            .transition(transition)
        }
      }
      .animation(isAnimated ? .easeOut(duration: 0.25) : nil, value: isPresented)
      .task { isPresented = true }
    }

    private var transition: AnyTransition {
      guard (reduceMotionOverride ?? reduceMotion) == false else { return .opacity }
      return .offset(y: edge == .top ? -12 : 12).combined(with: .opacity)
    }
  }
#endif
