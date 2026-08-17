# Geniebook update-version toast: image CTA handoff

## Objective

Add an image-based call-to-action to GBVToast so Geniebook can replace its last standalone
toast-like component: the UIKit `SnackBar` used when a newer App Store version is available.

This is a library capability, not a request for an arbitrary custom SwiftUI content closure.
GBVToast should remain the owner of layout, presentation, accessibility, dismissal, scene
resolution, animation, deduplication, and result delivery.

## Current Geniebook behavior

The remaining implementation is `Geniebook/Custom/Components/SnackBar/SnackBar.swift`, presented
by `APIClient.showUpdateAvailableNotifier(newVersion:)`.

Its observable contract is:

- bottom presentation in the active application window;
- full-width dark container with approximately 15-point safe-area margins;
- multiline white message using `L10n.newVersion("(<version>)")`;
- trailing `icAppstore100` image button rendered as authored, without template tinting;
- button tap opens `itms-apps://itunes.apple.com/us/app/geniebook/id905900825`;
- automatic dismissal after two seconds;
- a new notification removes the previous one before presenting;
- only the snackbar bounds intercept touches; the transparent window-sized host does not block
  the rest of the application.

This component is independent of the retired `VToastViewV2` implementation.

## Missing GBVToast capability

`ToastCTA` currently requires a text `title`. GBVToast already supports the required edge, width,
palette, timing, callback result, and deduplication behavior, but it cannot render the App Store
asset as the CTA label.

## Proposed public API

Extend `ToastCTA` with typed label content while preserving its existing initializer:

```swift
public struct ToastCTA: Sendable, Equatable {
  public enum Label: Sendable, Equatable {
    case text(String)
    case asset(
      name: String,
      bundleIdentifier: String? = nil,
      renderingMode: ToastIcon.RenderingMode = .original,
      accessibilityLabel: String
    )
  }

  public let label: Label
  public let layout: Layout

  public init(label: Label, layout: Layout = .dedicated) {
    self.label = label
    self.layout = layout
  }

  public init(title: String, layout: Layout = .dedicated) {
    self.init(label: .text(title), layout: layout)
  }
}
```

The exact naming may change, but the resulting value must remain `Sendable` and `Equatable`.
Do not accept `AnyView`, `@ViewBuilder`, `UIImage`, `Image`, or a closure in the configuration
model: those would weaken concurrency guarantees, equality, deduplication tests, and deterministic
snapshot fixtures.

Reuse the library's existing asset-resolution behavior where practical. A missing asset must not
crash. It should either omit the CTA and make presentation/result behavior explicit, or resolve
the request as a documented `notPresented` reason; cover the chosen policy with tests.

## Rendering contract

- `.text` must preserve all current behavior and snapshot output.
- `.asset` must render inside a real SwiftUI `Button` and use the configured rendering mode.
- The visible image may retain its intrinsic size, but the interactive target must be at least
  44×44 points.
- The asset CTA must have an explicit VoiceOver label and button trait.
- Inline placement is trailing beside the message in left-to-right layouts and follows semantic
  direction in right-to-left layouts.
- At accessibility Dynamic Type sizes or insufficient width, the existing responsive layout may
  move the CTA below the message without clipping it.
- The CTA action must resolve `ToastPresentationToken.result` as `.cta` exactly once and follow
  the same removal behavior as text CTAs.
- Tapping outside the CTA must retain the configured `dismissOnTap` behavior.

## Geniebook target configuration

The intended consumer call is equivalent to:

```swift
let token = GBVToast.showToast(
  ToastConfiguration(
    message: L10n.newVersion("(\(newVersion))"),
    width: .full,
    style: .normal,
    edge: .bottom,
    icon: .hidden,
    cta: ToastCTA(
      label: .asset(
        name: "ic_appstore_100",
        bundleIdentifier: Bundle.main.bundleIdentifier,
        renderingMode: .original,
        accessibilityLabel: "Open App Store"
      ),
      layout: .inline
    ),
    autoDismissDuration: 2,
    safeAreaSpacing: 15,
    deduplicationKey: "geniebook.update-version"
  )
)

if await token.result == .cta {
  openAppStore()
}
```

Confirm the generated asset name when integrating; the code example records intent rather than
overriding Geniebook's resource generator.

## Required tests

### Model and compatibility

- Existing `ToastCTA(title:layout:)` source continues to compile and equals `.text(title)`.
- Text and asset labels participate correctly in `Equatable`.
- Asset metadata, rendering mode, bundle identifier, and accessibility label survive configuration
  construction unchanged.

### Rendering and interaction

- Original-rendered image CTA in inline layout on phone.
- Image CTA responsive fallback with a long message.
- Image CTA at an accessibility Dynamic Type size.
- Right-to-left semantic placement.
- Missing-asset behavior.
- CTA tap returns `.cta` once and dismisses according to configuration.
- Non-CTA tap preserves normal dismiss semantics.
- Hit target is at least 44×44 points.

### Snapshot evidence

Add a real-fixture full-page snapshot named `update-version-image-cta` using a test-bundle App
Store image asset. Add it to the canonical snapshot matrix and regenerate the self-contained HTML
comparison report. The fixture must cover bottom placement, full width, dark palette, multiline
message, original asset rendering, and 15-point safe-area spacing.

## Consumer handoff and release

1. Implement and verify the capability in GBVToast.
2. Publish a new semantic version; do not move the existing `1.0.1` tag.
3. In Geniebook, update the exact package pin and resolved revision.
4. Replace `APIClient.showUpdateAvailableNotifier(newVersion:)` with GBVToast.
5. Add the update-version occurrence to Geniebook's UI snapshot inventory.
6. Verify the App Store action and two-second dismissal in the app.
7. Delete `SnackBar` only after a reference search confirms it has no other callers.

## Acceptance criteria

- Geniebook can reproduce the current update-version notification without an app-owned overlay.
- Existing text CTA API and snapshots remain unchanged.
- The image CTA is typed, sendable, equatable, accessible, responsive, and asset-safe.
- The library test suite and snapshot verification pass.
- Geniebook can remove `SnackBar` after consuming the released version.
