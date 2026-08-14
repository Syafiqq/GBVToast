# GBVToast library maturation plan

## Capability

GBVToast will provide one canonical, app-agnostic SwiftUI toast renderer for iOS 15 and later, with system-color and system-font defaults. An integrating application may install a root configuration when it needs branded presets. Callers present through a window-level `GBVToast.showToast(...)` facade that can be given scene context and returns a `ToastPresentationToken`.

## Decision

Adopt a **SwiftUI-only renderer with a window-level static facade**.

Do not retain `UIKitToastView` as a separately implemented renderer. Retain only the platform integration needed to:

- host `ToastContentView` in `UIHostingController`;
- attach it to the active foreground window/scene;
- apply top/bottom safe-area positioning;
- manage presentation, dismissal, deduplication, and lifecycle;
- expose `GBVToast.configure(root:)`, `GBVToast.showToast(...) -> ToastPresentationToken`, and token- and ID-based dismissal APIs;
- remain independent of any application-specific compatibility adapter.

The first stable package does not claim macOS support. `Package.swift` must remove the current macOS platform declaration unless a separate AppKit design and implementation is approved later.

## Challenges resolved

### Root configuration, presets, and custom runtime colors

GBVToast itself is themeless: its fallback uses system colors, system fonts, and package-owned layout defaults. An application may install one root configuration that resolves the complete visual treatment:

- foreground/text/CTA/icon tint;
- background;
- default icon;
- typography;
- corner radius and content insets.

The root configuration must define the required presets `normal`, `info`, `danger`, and `warning`. Preserve `custom` for per-toast runtime foreground/background configuration. A custom appearance applies only to that toast and must never mutate root presets.

Use `normal/info/danger/warning/custom` as the canonical package vocabulary. Mapping an application's legacy vocabulary belongs outside the package.

### Font ownership

The package does not ship or assume Open Sans. Its fallback is a system font. An integrating application may supply a custom font and foreground/background/icon presets through the root configuration, installed before its first toast.

### CTA modes

Preserve two explicit production semantics, without describing them merely as rows:

1. `inline`: CTA occupies the message's bottom-trailing flow position. The icon remains top-aligned; multiline text reserves enough trailing space for the CTA.
2. `dedicated`: CTA receives a dedicated trailing column, bottom-aligned against the content while icon and text remain top-aligned.

These names match the production API's intent, although its implementation is counterintuitive. Both modes must switch to a safe vertical fallback when the CTA cannot fit without clipping or unreadable text compression.

### Golden parity versus deliberate improvement

Geniebook is authoritative for supported colors, typography, icons, normal layout, positioning, and CTA semantics. It is not authoritative for known unsafe behavior. In particular, GBVToast must not reproduce the production long-CTA overflow.

The previously unsupported production cases—custom colors, large configurable icons, custom assets, accessibility XXXL, and RTL—are mandatory SwiftUI capabilities and require GBVToast-native approved goldens.

## Implementation contract

### Public model

Retain one `ToastConfiguration` consumed by all presenters. It must cover:

- message;
- semantic preset or custom appearance;
- top/bottom edge;
- default, hidden, or custom icon;
- icon size;
- optional CTA and CTA mode;
- timer dismissal and duration;
- tap-to-dismiss policy;
- animation and Reduce Motion behavior;
- safe-area spacing;
- phone/iPad maximum width;
- deduplication identity.

Add a `GBVToastRootConfiguration` rather than scattering values through the view. Its unset fallback uses system colors and fonts. Tests may install a reference configuration matching imported goldens without making that configuration a production dependency or package default.

`GBVToastRootConfiguration` carries a required `GBVToastRootConfiguration.ID`, a public `Hashable` value initialized from a caller-owned stable string (for example, `"geniebook.toast.v1"`). The ID is the configuration's installation identity; SwiftUI `Color`, `Font`, and `Image` values are deliberately not compared. Independently constructed configurations with the same ID are the same installation, while different IDs are materially different. Callers must change the ID whenever any behavior or visual token changes and must not reuse an ID for different values. Debug builds should diagnose reuse of the active ID with a different package-computable descriptor where possible, but that diagnostic is not the public equality contract.

Root installation has process-lifetime semantics: configuration may be installed before the first presentation; installing a configuration with the active ID again is a no-op; installing a configuration with a different ID after presentation has begun throws a typed `GBVToastConfigurationError.alreadyStarted` error. Tests and previews use an injected runtime/configuration store rather than a public global reset API. Showing without first configuring freezes the system fallback under a package-defined, reserved system-fallback ID as that runtime's root configuration; a later configuration with any caller-owned ID is therefore materially different and throws `alreadyStarted`.

### SwiftUI renderer

`ToastContentView` is the only toast visual implementation. It must:

- render all preset and custom appearances;
- use one shared CTA layout engine for inline, dedicated, and vertical fallback;
- size to content up to device/configuration limits;
- support Dynamic Type without clipping;
- use semantic leading/trailing for RTL;
- make the rendering mode explicit for each custom icon, default it to template, and preserve an explicit original-rendering mode;
- expose correct accessibility grouping, CTA action, dismiss action, and announcement behavior.

#### SwiftUI implementation rules

The canonical renderer follows modern SwiftUI practices rather than translating the UIKit implementation line by line:

- Keep `ToastContentView` a small, value-driven view. It receives immutable render data and `@MainActor` actions; presentation timers, deduplication, window lookup, and business state stay outside `body`.
- Split substantial icon, message, CTA, and responsive-layout concerns into dedicated `View` or `Layout` types in separate files. Do not hide a large body behind computed `some View` properties.
- Implement inline/dedicated/vertical selection with SwiftUI's `Layout` protocol on iOS 16 and later. Because the package retains iOS 15 support, isolate one tested size-preference/geometry fallback behind availability rather than spreading geometry reads through content views. Do not use `UIScreen.main.bounds` or device checks.
- Keep package design tokens in SwiftUI-native values. `SwiftUIToastPalette` and the root configuration must not derive colors or images from `UIKitToastPalette`; UIKit remains only the `UIHostingController`/window attachment bridge.
- Avoid type erasure in the steady-state host. Use a concrete `UIHostingController<ToastContentView>` (or another concrete root view type), not `AnyView`.
- Use the newest modifiers available at the iOS 15 deployment floor, with availability-gated modern forms where needed: `foregroundStyle`, shape-based clipping instead of `cornerRadius`, alignment-aware `overlay`, and value-scoped animation. Avoid deprecated modifiers and implicit global animation.
- Read Dynamic Type, layout direction, accessibility contrast/differentiate-without-color, and Reduce Motion through SwiftUI environment values. Use semantic text styles or scaled custom fonts and flexible frames; never truncate required message or CTA content.
- Use SwiftUI animation and transaction APIs for content transitions. When Reduce Motion is enabled, use an opacity-only transition. UIKit animation is allowed only for host attachment behavior that SwiftUI cannot own, and must not duplicate renderer state.
- CTA and explicit controls are real `Button` values with meaningful text labels and at least a 44×44 pt hit target. A decorative icon is hidden from accessibility; an informative custom icon has an explicit label.
- Tap-to-dismiss must not make the CTA a nested button or steal its gesture. If the legacy whole-surface tap gesture is retained, apply button traits only when tap dismissal is enabled, keep the CTA as a separate accessibility action/control, and verify gesture precedence. Prefer an explicit dismiss button where product behavior permits it.
- Provide one grouped toast announcement and named CTA/dismiss actions without double-reading the message. Prefer SwiftUI accessibility modifiers; isolate any iOS 15 notification fallback in the hosting bridge rather than calling `UIAccessibility.post` from the view lifecycle.
- Use `#Preview` fixtures for every preset, CTA mode, long content, XXXL Dynamic Type, Reduce Motion, and RTL. Previews supplement tests and never replace approved snapshots or geometry assertions.

### Presentation surface

Provide one global caller-facing surface. Calling code must not construct or retain a presenter, `UIView`, `UIViewController`, `UIWindow`, or SwiftUI environment object:

```swift
try GBVToast.configure(root: applicationToastConfiguration)
let sceneContext = GBVToast.sceneContext(for: windowScene)
let token = GBVToast.showToast(configuration, in: sceneContext)
GBVToast.dismiss(token)
GBVToast.dismiss(id: token.id)
```

`showToast` is callable directly from UIKit, SwiftUI, a coordinator, a service callback, or a view model after importing `GBVToast`. It returns the existing `ToastPresentationToken`, preserving async result delivery. The facade is `@MainActor`: main-actor view models call it directly, while non-main-actor code crosses the actor boundary with `await` (normally from an existing async operation or a `Task`). No call-site dispatch to `DispatchQueue.main` is required or documented.

```swift
@MainActor
final class LessonViewModel {
  func saveCompleted() {
    GBVToast.showToast(.init(message: "Saved", style: .info))
  }
}

func backgroundRefreshCompleted() async {
  let token = await GBVToast.showToast(.init(message: "Refreshed", style: .info))
  _ = await token.result
}
```

Extend `ToastResult` with a typed `.notPresented(reason)` outcome so missing/ambiguous windows and duplicate requests are distinguishable from `.dismissed`. A caller may provide an opaque, `Sendable` `ToastSceneContext`; this lets a multi-window view model retain routing context without importing UIKit or retaining a window.

GBVToast provides `@MainActor public static func sceneContext(for windowScene: UIWindowScene) -> ToastSceneContext` as the creation contract. A UIKit scene delegate, view controller, or the package's small SwiftUI integration adapter calls it while attached to the target scene, then passes the opaque value into application state or a view model. The context stores only a package-owned stable scene identifier, not the `UIWindowScene` or a window; at presentation time the resolver maps that identifier back to a currently connected, eligible scene. A disconnected, background, or windowless captured scene resolves as `.notPresented(.sceneUnavailable)` and never falls back to another scene. Tests use the injectable resolver to create contexts for synthetic scene identifiers and do not require real UIKit scenes. A public initializer from an arbitrary identifier is intentionally unavailable.

Without context, the resolver presents only when exactly one eligible foreground key window exists; no eligible window or multiple eligible windows resolves the token as `.notPresented(...)` rather than choosing by enumeration order. The facade must be backed by an injectable runtime/presenter/window resolver for tests. A scoped-view API beyond the small capture adapter is explicitly deferred until a real future use case requires it.

The runtime generates a `ToastPresentationID` for each token; callers do not supply it through `ToastConfiguration`. ID-based dismissal resolves the runtime that owns the token and therefore needs no scene argument. `deduplicationKey` remains a separate caller-supplied concept and is scoped to the resolved scene. A duplicate live key in the same scene drops the new request and resolves its token as `.notPresented(.duplicateKey)`; the same key in different scenes does not collide.

### Application integration boundary

GBVToast exposes only its new configuration and presentation APIs. Legacy application adapters, call-site migration, dependency wiring, rollout, and removal of existing app implementations belong to a separate scope. This library plan must not introduce Geniebook legacy types or signatures into the package.

## Matrix decisions

| Key | Authority | Required result |
| --- | --- | --- |
| `bottom-synthetic` | SwiftUI native | Keep current SwiftUI geometry; update Geniebook preset tokens and icon asset. |
| `hidden-icon-error` | SwiftUI native + production tokens | Keep hidden-icon structure; match production danger foreground/background/font. |
| `mode-switch-inline-cta` | Geniebook layout/content | Implement production `inline` bottom-trailing flow behavior and use real localized copy in the real fixture. |
| `reminder-undo` | Geniebook CTA semantics | Use dedicated trailing CTA column; use production-localized copy. |
| `ten-minute-warning-cta` | Geniebook CTA semantics | Use dedicated trailing CTA column and warning preset; use production-localized copy. |
| `default-title-only` | SwiftUI native + production tokens | Keep SwiftUI content sizing; match normal preset. |
| `success-icon-title` | SwiftUI native + production tokens | Keep SwiftUI layout; match production success/info token and icon. |
| `error-hidden-icon-multiline` | SwiftUI native + production tokens | Keep wrapping; match danger preset. |
| `warning-icon-title` | SwiftUI native + production tokens | Keep layout; match warning preset and icon. |
| `custom-colors-title` | GBVToast extension | Keep runtime custom foreground/background; add contract tests that presets remain unchanged. |
| `inline-cta-with-icon` | Inline CTA contract | Match production bottom-trailing flow and icon top alignment. |
| `inline-cta-without-icon` | Inline CTA contract | Same flow without leaving icon spacing. |
| `dedicated-cta-with-icon` | Dedicated CTA contract | Dedicated trailing column, CTA bottom-aligned, icon top-aligned. |
| `dedicated-cta-without-icon` | Dedicated CTA contract | Same layout without leaving icon spacing. |
| `ipad-inline-cta-centered` | Inline CTA + iPad width | Verify 480 pt maximum and production inline behavior. The key should be renamed if “centered” does not describe the final contract. |
| `ipad-dedicated-cta-bottom` | Dedicated CTA + iPad width | Verify 480 pt maximum and bottom-aligned dedicated CTA. |
| `bottom-custom-spacing` | Positioning contract | Verify bottom safe area and custom spacing independently of CTA behavior. |
| `stress-large-icon` | Responsive extension | Keep configurable icon; verify it does not overlap text/CTA and can trigger vertical fallback. |
| `stress-long-title` | Responsive extension | Wrap message without clipping; retain safe SwiftUI behavior rather than copying production excess height. |
| `stress-long-cta` | Responsive extension | Never reproduce Geniebook overflow. Fall back vertically and wrap the CTA. |
| `custom-asset-icon` | SwiftUI extension | Add deterministic template and original-rendering test assets and snapshots. |
| `accessibility-extra-extra-extra-large` | Accessibility extension | Add XXXL fixture; allow vertical fallback and full text/CTA wrapping. |
| `right-to-left-layout` | Internationalization extension | Add RTL fixture using semantic alignment and mirrored component order where appropriate. |

## Execution plan

### Phase 0 — Lock root configuration and tests

1. Remove the unsupported macOS declaration from `Package.swift`, or stop and produce an approved AppKit design before retaining it.
2. Define `GBVToastRootConfiguration`, its stable hashable installation ID, canonical preset vocabulary, reserved system-fallback identity, and the frozen-after-first-presentation installation policy. Test independently constructed roots with equal IDs as no-ops and different IDs as `alreadyStarted`, without comparing SwiftUI visual values.
3. Specify `showToast` token/result behavior, main-actor and non-main-actor view-model call paths, `sceneContext(for:)` capture at UIKit and SwiftUI integration boundaries, opaque context storage without retaining UIKit objects, generated presentation IDs, scene-scoped deduplication keys, and typed missing-window/ambiguous-window/disconnected-captured-scene/duplicate-key outcomes in tests before adding the facade.
4. Encode inline/dedicated semantics in tests before changing the renderer. Vertical fallback remains automatic and internal, not a third public CTA mode.
5. Keep the 23-key manifest as ground truth and classify each row as production parity or GBVToast extension.
6. Add focused layout assertions in addition to snapshots: component order, frames, no overlap, safe-area offsets, and fallback selection.

Exit: public names, root initialization, window selection, and golden authority are unambiguous.

### Phase 1 — Root configuration and reference presets

1. Introduce the root configuration and system-default preset model in package-owned types; do not reuse Geniebook generated types.
2. Add test-only reference presets matching the imported golden foreground/background values, typography, radius, insets, and icons.
3. Make custom icon rendering mode explicit and default custom icons to template rendering.
4. Update SwiftUI snapshots for non-CTA baseline cases first.
5. Verify custom runtime colors do not affect root preset definitions.

Exit: simple SwiftUI cases match approved appearance and UIKit rendering is not used as an oracle.

### Phase 2 — CTA layout engine

1. Implement production inline flow behavior using a dedicated SwiftUI `Layout` type on iOS 16+, plus one isolated and behavior-equivalent iOS 15 fallback.
2. Implement the dedicated trailing column.
3. Add deterministic vertical fallback for long CTA, large Dynamic Type, or insufficient width.
4. Cover icon shown/hidden, short/long title, short/long CTA, phone/iPad, and RTL.

Exit: all CTA matrix rows pass without truncation, overlap, or overflow.

### Phase 3 — SwiftUI-only renderer and window facade

1. Implement the `@MainActor` static facade, opaque `Sendable` scene context, deterministic scene-aware window resolver, overlay host, and injectable runtime test seams. The public facade must not require callers to own a presenter or UIKit view/window object.
2. Preserve `ToastPresentationToken`, CTA result delivery, and both token- and generated-ID-based dismissal while routing all content through SwiftUI.
3. Replace the current UIKit-derived `SwiftUIToastPalette`, `AnyView` host, UIKit renderer animations, and view-lifecycle `UIAccessibility.post` call with the SwiftUI-native contracts above.
4. Delete `UIKitToastView`, `UIKitToastPalette`, and duplicate UIKit renderer snapshots only after bridge parity tests pass.
5. Change the comparison report to Geniebook golden versus canonical GBVToast SwiftUI output; retain a temporary hosted column only while validating window-host geometry.

Exit: one renderer produces identical content regardless of presenting surface.

### Phase 4 — Complete the SwiftUI matrix

1. Add custom asset test resources and rendering-mode choice.
2. Add accessibility XXXL and Reduce Motion coverage.
3. Add RTL coverage.
4. Verify VoiceOver label/action ordering and minimum CTA hit target.

Exit: every one of the 23 matrix rows has a reviewed SwiftUI golden; no SwiftUI column is empty.

### Phase 5 — Library hardening and release readiness

1. Exercise repeated configure/show/dismiss cycles, concurrent requests, deduplication, scene changes, backgrounding, and missing-window behavior.
2. Verify memory ownership: overlay hosts, timers, closures, and presentation tokens must be released after dismissal.
3. Document the public API, root bootstrap, view-model usage, preset/custom configuration, CTA modes, and test hooks.
4. Remove the duplicate UIKit renderer, obsolete renderer-specific snapshots, and any transitional API that is not part of the agreed package contract.
5. Run the supported platform matrix and produce a reviewed 23-row SwiftUI report.
6. Mark the first stable package version only after source compatibility and golden-update policy are documented.

Exit: the package has one renderer, a stable public API, complete test evidence, no application-specific dependencies, and is ready for a separate integration project.

## Verification gates

- Unit tests for root preset/custom resolution, system fallback, and safe root reconfiguration behavior.
- Unit tests for missing, unique, and ambiguous eligible windows; explicit scene routing; scene-scoped deduplication; and typed `.notPresented` token resolution.
- Compile and behavior tests proving a `@MainActor` view model can call the facade directly and a non-main-actor async caller can call it with `await`, without constructing a presenter or UIKit object.
- Parameterized behavior tests for tap, unclosable, timer, CTA, deduplication, and removal policy.
- Full-page phone/iPad snapshots for every matrix key.
- Geometry assertions for top/bottom safe areas and CTA layout modes.
- SwiftUI architecture checks: no UIKit palette dependency in render code, no `AnyView` host, no `UIScreen.main.bounds`, no geometry reading outside the isolated iOS 15 layout fallback, no unscoped animation, and no business/presentation logic in `body` or lifecycle modifiers.
- Accessibility tests for conditional dismiss traits, separate CTA/dismiss actions, 44×44 pt controls, one announcement, decorative versus informative icons, Differentiate Without Color, Dynamic Type, RTL, and opacity-only Reduce Motion behavior.
- Window-host versus direct SwiftUI snapshots must be identical because they host the same view.
- No snapshot-record mode in normal CI; golden updates require explicit review.

## Non-goals

- Migrating entire UIKit screens to SwiftUI.
- Migrating Geniebook toast call sites or building its legacy compatibility adapter.
- Deciding the application rollout, deprecation, or removal schedule.
- Reproducing Geniebook's long-CTA overflow bug.
- Keeping two independent renderer implementations for theoretical UIKit purity.
- A scoped `UIView` or SwiftUI subtree presentation API before a concrete use case exists.
- Making GBVToast depend on Geniebook generated asset or font namespaces.
- macOS/AppKit support in the first stable package release.

## Resolved decisions

1. Root configuration freezes after the first presentation. Identical repeat installs are no-ops; materially different late installs throw `GBVToastConfigurationError.alreadyStarted`; showing before configuration freezes the system fallback; tests/previews inject an isolated runtime.
2. Custom icon rendering is explicit per icon and defaults to template.
3. Vertical CTA fallback is automatic and internal for the first stable API.
4. The first stable release supports iOS 15+ only; the unsupported macOS declaration is removed.
5. `showToast` returns `ToastPresentationToken`, and dismissal remains available by token and by its generated `ToastPresentationID`; deduplication keys remain separate and scene-scoped.
6. Scene context is optional, but context-free presentation succeeds only with one unambiguous eligible foreground key window.
7. Requests that never become visible resolve as typed `.notPresented(reason)` results rather than `.dismissed`.
8. Any caller can use the global facade after importing the package. View models do not depend on presenter/UIKit objects; multi-window routing uses an opaque `Sendable` context, and non-main-actor callers cross to the facade with `await`.
9. `ToastContentView` is SwiftUI-native: UIKit is confined to window hosting and unavoidable iOS 15 accessibility bridging, responsive layout uses SwiftUI `Layout` on iOS 16+ with one isolated iOS 15 fallback, state and side effects live outside `body`, and interaction/accessibility behavior follows the implementation rules above.

## Handoff

The library architecture is ready for implementation. Begin with Phase 0 contract tests, then use TDD for root configuration, window resolution, token/result preservation, and the CTA layout engine. Do not delete the UIKit renderer until the SwiftUI host passes the bridge-parity gate. Application integration starts only after this maturation plan reaches its release-readiness exit criteria.

## Plan review verdict

**GO** — the plan is implementation-ready in its stated order. The review resolved the platform mismatch, preserved token/result behavior, made scene selection deterministic, separated presentation identity from deduplication, and closed every root/icon/layout policy decision.

Execution remains gated by tests in Phase 0. In particular, no UIKit renderer deletion is allowed until the iOS-only bridge-parity suite passes. A host-side `swift test` baseline on 2026-08-14 passed 17 model/store tests, but conditional compilation skipped UIKit/SwiftUI presenter and snapshot suites; that baseline is not evidence for the deletion gate.
