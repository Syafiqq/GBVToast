# Typed image CTA design for the Geniebook update-version toast

## Status

Approved design for the GBVToast repository. This document defines the library capability and its verification boundary. Publishing a release and changing the Geniebook consumer occur only after the library work passes.

## Goal

Allow a toast CTA to use a named image asset while GBVToast continues to own layout, presentation, accessibility, dismissal, scene selection, animation, deduplication, and result delivery. The capability must reproduce Geniebook's update-version notification without accepting arbitrary SwiftUI content or UIKit values in the public configuration model.

## Scope

In scope:

- a typed, public text-or-asset CTA label;
- source compatibility for `ToastCTA(title:layout:)`;
- strict, non-crashing asset resolution;
- accessible and responsive SwiftUI rendering on the package's iOS 15 minimum;
- explicit token behavior when an asset is unavailable;
- unit, interaction, layout, and snapshot evidence;
- canonical fixture-matrix and HTML comparison-report updates;
- release-readiness and downstream handoff instructions.

Out of scope:

- arbitrary `View`, `AnyView`, `@ViewBuilder`, closure, `UIImage`, or `Image` CTA content;
- publishing or moving a Git tag as part of implementation;
- editing Geniebook from this repository;
- changing current text CTA visuals or interaction semantics;
- deleting Geniebook's `SnackBar` before its downstream reference search and migration checks pass.

## Public API

`ToastCTA` gains a nested label value:

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

  public enum Layout: Sendable, Equatable {
    case dedicated
    case inline
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

The stored `title` property is replaced by `label`; the source-compatible initializer is retained. No deprecated compatibility accessor is needed because the current API contract exposes construction and equality, while repository callers do not read `title`. If external source-compatibility validation identifies direct `cta.title` reads, add a deprecated computed accessor only if it can define asset behavior without ambiguity; otherwise treat that as a semver-major concern before release.

Asset accessibility labels are required and non-optional because an image-only control has no meaningful spoken label to infer. The default rendering mode is `.original`, matching authored App Store artwork and making the image-CTA default safe for the motivating use case.

## Asset resolution

Add one internal UIKit-backed resolver used by both presentation preflight and SwiftUI label rendering. It accepts the asset name and optional bundle identifier and returns the resolved image or `nil`.

Resolution rules are strict:

1. A `nil` bundle identifier selects `Bundle.main`.
2. A supplied bundle identifier must resolve using `Bundle(identifier:)`.
3. An invalid supplied identifier is a failure; it does not fall back to `Bundle.main`.
4. The named image must resolve from the selected bundle.
5. Failure never traps or creates an empty button.

The resolver remains internal so `ToastCTA.Label` stays platform-neutral, `Sendable`, and `Equatable`. Existing toast-icon resolution should be moved onto the same helper where doing so preserves its documented behavior; tests must pin any intentional strictness change before that refactor is retained.

## Missing-asset presentation policy

Add `ToastNotPresentedReason.ctaAssetUnavailable`.

`SwiftUIToastPresenter.present(_:)` preflights only `.asset` CTA labels after creating the token and confirming the container still exists, but before inserting the token into the deduplication store or attaching a hosting view. If resolution fails, it resolves the token as `.notPresented(.ctaAssetUnavailable)` and returns immediately.

Consequences:

- no host view or auto-dismiss task is created;
- no deduplication key is reserved;
- no VoiceOver announcement is posted;
- no message-only toast is shown with an unusable action;
- a corrected request using the same deduplication key can be presented immediately;
- the result remains exactly-once because `ToastPresentationToken` owns idempotent resolution.

Window eligibility remains the first presentation prerequisite. If the container is gone, `.noEligibleWindow` wins because asset validation cannot make that presentation eligible.

## Rendering and layout

Extract a small internal CTA-label view or equivalent `@ViewBuilder` used by every CTA rendering path:

- `.text` renders the current font, underline, multiline alignment, and fixed-size behavior unchanged;
- `.asset` renders the resolved image using the configured template/original mode, preserves its aspect ratio and intrinsic visual size, and does not apply palette tint in original mode;
- the enclosing SwiftUI `Button` owns a minimum 44×44 frame/content shape, so small artwork does not produce a small touch target;
- the image label is explicitly exposed with its supplied accessibility label; the enclosing control retains the button trait;
- the message remains a sibling accessibility element hidden in favor of the toast container's message label, matching current behavior.

The same label renderer is used by:

- the iOS 16 inline custom layout;
- the iOS 16 dedicated custom layout;
- the accessibility-size vertical layout;
- the iOS 15 legacy responsive fallback.

Existing layout selection remains authoritative. Inline layout places the CTA at semantic trailing in left-to-right and right-to-left environments. Accessibility Dynamic Type uses the vertical fallback. The current width-aware layout may place content vertically when needed; implementation tests must prove long content does not clip. If the existing custom `Layout` cannot satisfy the image's intrinsic size and the message's readable minimum simultaneously, the implementation may add an internal fit decision, but it must not change the public layout enum.

## Interaction and lifecycle

The image is the label of a real `Button`, not a gesture target. Both text and asset variants call the existing `handleCTA()` path. The presenter completes the token with `.cta`, cancels the timer, removes or hides the host according to `removesOnDismiss`, releases the deduplication key, and invokes its finish callback.

The button consumes its own tap. Taps elsewhere continue through `ToastDismissModifier`: they resolve `.dismissed` only when `dismissOnTap` is enabled. Competing CTA, background-tap, programmatic-dismiss, and timer events continue to rely on token/store idempotence; tests assert one observable result and one removal.

## Test strategy

### Model and compatibility

- construct `ToastCTA(title:layout:)` and compare it with `ToastCTA(label:.text(...),layout:)`;
- compare equal and unequal text labels;
- compare asset labels across name, bundle identifier, rendering mode, accessibility label, and layout;
- round-trip asset metadata through `ToastConfiguration`;
- compile representative existing text-CTA fixtures unchanged.

### Resolver and presentation

- resolve a known test-bundle asset;
- reject an unknown asset name;
- reject an invalid explicit bundle identifier without main-bundle fallback;
- verify missing assets return `.notPresented(.ctaAssetUnavailable)`;
- verify no live presentation, timer, or deduplication reservation remains after rejection;
- verify a valid retry with the same key can present.

### Rendering, layout, and accessibility

- inline original-rendered image on a phone;
- long-message responsive fallback without clipping;
- accessibility Dynamic Type vertical layout;
- right-to-left semantic placement;
- dedicated layout coverage through the shared renderer;
- minimum 44×44 button hit area while retaining intrinsic image size;
- explicit VoiceOver label and button semantics;
- regression snapshots for existing text CTAs.

### Interaction

- CTA tap resolves `.cta` once and follows configured removal behavior;
- repeated CTA completion attempts do not change the result;
- non-CTA tap preserves enabled and disabled `dismissOnTap` behavior;
- auto-dismiss cannot overwrite a prior CTA result.

### Snapshot evidence

Add a test-catalog App Store image fixture and a real full-page fixture named `update-version-image-cta`. It uses bottom placement, `.full` width, normal/dark styling, hidden leading icon, multiline update-version copy, inline original-rendered image CTA, two-second duration, and 15-point safe-area spacing.

Add the fixture to `testSwiftUIRealFixturesFullPage`, include its name in `Tests/GBVToastTests/Fixtures/toast_snapshot_matrix.json`, record the image snapshot, and regenerate the self-contained comparison HTML using `Scripts/generate_snapshot_comparison.py`. Commit the asset source, snapshot, and matrix together. The report is a reproducible build artifact under ignored `.build/reports`; verify it contains the fixture but do not force-add it.

## Verification and release gates

Library work is ready for release only when:

- focused model, resolver, presenter, interaction, and snapshot tests pass;
- the full Swift package test suite passes;
- snapshot recording is disabled during the final verification run;
- the comparison-report script tests pass and the regenerated report contains `update-version-image-cta`;
- `git diff --check` reports no whitespace errors;
- existing text CTA snapshots show no unintended changes;
- the public API is reviewed for semantic-version compatibility.

Afterward, publish a new semantic version without moving `1.0.1`. In the Geniebook repository, confirm the generated App Store asset symbol/name, update the exact package pin and resolved revision, replace `APIClient.showUpdateAvailableNotifier(newVersion:)`, add the occurrence to the UI snapshot inventory, verify the App Store deep link and two-second dismissal, and delete `SnackBar` only after a reference search finds no remaining callers.

## Risks and mitigations

- **Direct external reads of `ToastCTA.title`:** inspect known consumers before choosing the release version; do not invent an asset-string value for compatibility.
- **Preflight/render mismatch:** use one resolver and test both call sites with the same test-bundle asset.
- **Asset-catalog identity differences:** keep bundle semantics explicit and verify `Bundle.module.bundleIdentifier` in the package test environment.
- **Image dimensions harming layout:** retain intrinsic artwork, enforce the hit target independently, and snapshot long, accessibility, phone, and RTL cases.
- **Snapshot churn:** isolate the new fixture and require existing text snapshots to remain unchanged.
- **Downstream resource naming:** treat the handoff's `ic_appstore_100` as intent until Geniebook's generator is checked.
