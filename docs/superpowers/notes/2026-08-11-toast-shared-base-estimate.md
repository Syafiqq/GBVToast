# Plan and estimate: standalone GBVToast

**Status:** implementation-ready plan. No production code yet.
**Project:** `modules/GBVToast`
**Reference app:** `geniebook-student-ios-distribution`
**Reference modal library:** `modules/gb-v3-alert-modal`

## 1. Goal

Build GBVToast as a standalone Swift package with two first-class presentation paths:

1. A pure UIKit toast that can replace Geniebook's existing `VToastViewV2` APIs.
2. A pure SwiftUI toast with a presentation API similar to UIKit and callable from a view model.

Both implementations must be checked against representative production Geniebook toast examples
using deterministic snapshot and behavior tests. GBVToast must work without GBV3AlertModal; an
adapter to the modal infrastructure may be added later, but is not part of the package's core.

## 2. Verified source findings

### Existing Geniebook implementation

The current implementation is under:

`Common/Common/Presentation/UIKit/Widget/Toast/`

| File | Lines | Responsibility |
|---|---:|---|
| `VToastViewV2.swift` | 497 | View hierarchy, visual variants, CTA layout, timer, tap dismissal, configuration. |
| `VToastViewV2+Top.swift` | 69 | Show/hide implementation. |
| `VToastViewV2+Bottom.swift` | 69 | Byte-identical show/hide implementation. |
| `Widget/ActivityIndicator/UIView+Toast.swift` | 261 | Public helpers, dedup, window/view attachment, edge constraints. |

Top and bottom do not need separate view subclasses. Their only meaningful difference is which safe
area edge the presenter anchors to and the direction of the hidden-state translation.

Current production inventory in `geniebook-student-ios-distribution`:

- 29 `showTopToast` invocations.
- 1 `showTopToastDistinct` invocation.
- 0 bottom-toast consumer invocations.
- 16 production files containing top-toast calls.
- 3 meaningful CTA examples.
- Most calls present on `AppCompatHelper.keyWindow`; two present inside a screen view.

Bottom remains a supported library capability, but it is not required for current production parity.

### GBV3AlertModal findings

`ModalDescriptor`, `ModalToken`, `ModalRenderer`, and `ModalExecutor` are technically generic, but
GBVToast should not depend directly on a separately versioned package named `GBV3AlertModal` merely
to reuse these types. That would make a standalone toast library inherit the alert package's release
cycle and public behavior.

`WindowModalRenderer` also cannot safely host a non-blocking toast as currently implemented. It adds
a full-window `UIHostingController.view` to the app window. A clear SwiftUI background does not make
that UIKit hosting view pass touches through to views underneath. A toast needs a host that either:

- occupies only the measured toast frame; or
- overrides hit testing and returns `nil` outside the presented toast.

Therefore, GBVToast owns its presenter and passthrough behavior. A future adapter may allow an app's
modal center to expose the toast presenter without making the toast renderer use the modal renderer.

## 3. Architecture

```text
View model / UIKit caller
          |
    ToastPresenting
          |
  ToastPresentationToken
          |
   ToastPresentationStore
      /             \
UIKitToastPresenter  SwiftUIToastPresenter
      |                     |
 UIKitToastView       ToastContentView
```

### Shared semantic model

`ToastConfiguration` is a `Sendable` value containing platform-neutral intent:

- `message`
- `style`: default, success, error, warning
- `edge`: top or bottom
- `icon`: default, hidden, or named asset reference
- optional CTA title
- CTA layout: dedicated or inline
- automatic dismissal enabled/duration
- animation enabled
- safe-area spacing
- optional phone and pad maximum widths
- optional deduplication key

Platform-specific attributed strings, `UIImage`, `Color`, `UIView`, and `View` do not belong in this
model. UIKit and SwiftUI styling adapters resolve fonts, colors, and images at rendering time.

`ToastResult` has:

- `.cta`
- `.dismissed`

The whole-toast dismiss affordance and CTA are separate actions. CTA resolution is exactly once.

### View-model-facing API

```swift
@MainActor
public protocol ToastPresenting: AnyObject {
    @discardableResult
    func present(_ configuration: ToastConfiguration) -> ToastPresentationToken
    func dismiss(_ token: ToastPresentationToken)
}
```

The view model receives `any ToastPresenting` through dependency injection and never imports UIKit or
SwiftUI. `ToastPresentationToken` provides identity plus an optional replayable async result. A simple
imperative callback may also be exposed if required by the app's existing Rx-based view models.

### Presentation policy

Parity-first policy:

- Multiple ordinary presentations may coexist.
- A live presentation with the same non-nil deduplication key causes a new one to be dropped and
  resolved as dismissed.
- Deduplication applies only within the same presenter/window scope.
- No queue and no alert coordinator.
- Stacking layout is deferred; simultaneous toasts may overlap exactly as independent legacy calls do.
- Every teardown path cancels its timer and resolves at most once.

## 4. UIKit implementation

UIKit is the first production path, not a migration-only option.

### Components

- `UIKitToastView`: one final `UIView`, with no top/bottom subclasses.
- `UIKitToastStyle`: maps semantic styles and asset references to UIKit values.
- `UIKitToastPresenter`: owns window/container lookup, constraints, animation, timers, live tokens,
  deduplication, and teardown.
- `UIView+GBVToast`: compatibility conveniences for view-scoped presentation.
- Optional `UIWindow` convenience for app-wide presentation.

The core presenter must not require SnapKit. Using Auto Layout directly keeps GBVToast dependency-free
and genuinely standalone.

### Compatibility boundary

Do not reproduce `DisplayProperties.copyWith`. Provide Swift value defaults and memberwise/configured
initializers. A downstream Geniebook adapter maps existing call-site concepts to
`ToastConfiguration`, allowing incremental migration without baking app namespaces into GBVToast.

The renderer must preserve all behavior proven necessary by fixtures:

- all four visual styles;
- icon shown, hidden, and custom icon;
- dedicated and inline CTA layouts;
- multiline messages;
- phone/pad maximum widths;
- safe-area spacing;
- animated/non-animated presentation;
- auto-dismiss and manual dismissal;
- view-scoped and window-scoped presentation.

## 5. SwiftUI implementation

### Components

- `ToastContentView`: draws one toast and exposes explicit CTA/dismiss actions.
- `SwiftUIToastPresenter`: conforms to the same `ToastPresenting` protocol used by UIKit.
- `PassthroughHostingView`: returns `nil` from hit testing outside the toast's interactive bounds.
- `ToastHostModifier` or `ToastHost`: optional native SwiftUI-tree integration for apps that already
  have a SwiftUI root.

For the UIKit Geniebook app, `SwiftUIToastPresenter` installs a hosting controller in the target
window. Passthrough behavior must be verified by an interaction test; an edge-pinned `VStack` alone
is not sufficient.

The SwiftUI content uses `Button` for CTA and explicit dismissal rather than `onTapGesture`. It must:

- support Dynamic Type without clipping;
- give icons correct decorative or descriptive accessibility behavior;
- announce newly presented messages to VoiceOver where appropriate;
- respect Reduce Motion;
- cancel auto-dismiss tasks on teardown/replacement without resolving from a cancelled task;
- keep all presentation state main-actor isolated.

The public API remains renderer-independent, so a view model triggers SwiftUI presentation in the
same way it triggers UIKit presentation:

```swift
toastPresenter.present(.init(message: message, style: .error))
```

## 6. Real Geniebook parity fixtures

Create a test-only fixture catalog from production examples. Do not import the entire Geniebook app
target into GBVToast tests. Copy only stable input values and test assets, recording each fixture's
source file and line in comments.

Minimum fixture set:

| Fixture | Production behavior covered |
|---|---|
| Default short message | Default graphite styling. |
| Success | Success color and default icon. |
| Error | Error color and default icon. |
| Warning CTA | Warning colors and dedicated CTA. |
| GenieAsk mode-switch CTA | Inline/dedicated adaptive CTA behavior. |
| Upcoming-class undo | CTA result and action layout. |
| Icon hidden | `showIcon: false` parity. |
| Non-animated | `animated: false` configuration. |
| Long localized message | Wrapping, intrinsic height, maximum width. |
| Custom icon | Named asset resolution. |
| Bottom synthetic case | Supported edge behavior; not claimed as a current production call. |

### Snapshot matrix

For every required fixture, render:

1. The legacy Geniebook UIKit reference view.
2. `UIKitToastView` from GBVToast.
3. `ToastContentView` from GBVToast.

Capture stable fully-presented states at fixed phone and pad sizes. Add selected landscape and
accessibility Dynamic Type cases. Do not snapshot timers or animation frames.

Use two gates:

- Approved snapshots for each renderer, so failures are understandable.
- Geometry/semantic assertions for important parity invariants such as margins, safe-area offset,
  maximum width, CTA visibility, message wrapping, and icon visibility.

Pixel identity between UIKit and SwiftUI is a target, not the only assertion. Rendering engines may
differ slightly in font rasterization; any precision tolerance must be recorded and justified.

### Behavior and interaction tests

- auto-dismiss uses an injected clock/scheduler;
- manual dismissal cancels pending auto-dismiss;
- CTA resolves `.cta` exactly once;
- background tap/touch reaches the underlying view outside a SwiftUI toast;
- touching the toast does not reach the underlying view;
- same-key dedup drops and resolves the new request;
- different keys coexist;
- token dismissal removes the correct presentation;
- presenter/window teardown resolves remaining tokens and releases views;
- top/bottom constraints respect the safe area;
- Reduce Motion selects the non-motion transition.

## 7. Work plan and estimate

| Phase | Deliverable | Size |
|---|---|---:|
| 0 | Package/platform setup, fixture inventory, test assets, snapshot harness | S |
| 1 | Shared configuration, result, token, presenter protocol, injected clock, policy tests | S–M |
| 2 | UIKit view and presenter, compatibility conveniences, behavior tests | M |
| 3 | Legacy Geniebook versus GBVToast UIKit fixture snapshots and parity fixes | M |
| 4 | SwiftUI content, presenter, passthrough host, accessibility and cancellation tests | M |
| 5 | Legacy/UIKit versus GBVToast SwiftUI fixture snapshots and parity fixes | M |
| 6 | Example app/gallery for both renderers and view-model-triggered demonstrations | S–M |
| 7 | Geniebook integration adapter and incremental migration guide | S |

**Headline: M–L** for the complete requested scope. The largest uncertainty is visual parity across
UIKit and SwiftUI plus correct window-level touch passthrough, not the basic toast layout.

## 8. Delivery sequence and acceptance gates

### Milestone A — UIKit standalone

Accepted when:

- GBVToast has no runtime dependency on Geniebook, SnapKit, or GBV3AlertModal.
- UIKit callers can present on either a `UIView` or `UIWindow`.
- UIKit parity fixtures and behavior tests pass.
- The example app demonstrates top, error/CTA, dedup, and view-scoped cases.

### Milestone B — SwiftUI standalone

Accepted when:

- The same `ToastPresenting` API works when backed by SwiftUI.
- A plain view model can trigger and dismiss the toast without importing SwiftUI.
- Touches pass through outside the toast and are captured inside it.
- SwiftUI parity, accessibility, timer cancellation, and lifecycle tests pass.

### Milestone C — Geniebook adoption-ready

Accepted when:

- A documented adapter maps existing Geniebook parameters to `ToastConfiguration`.
- Representative current call sites compile against an integration example.
- Migration can happen incrementally without changing every call site at once.
- GBV3AlertModal integration, if desired, is an optional app-level composition rather than a core
  GBVToast dependency.

## 9. Decisions resolved by this plan

1. The repo is the existing sibling package at `modules/GBVToast`.
2. GBVToast does not depend on GBV3AlertModal.
3. Top and bottom are supported by one edge parameter; top alone is required for current app parity.
4. Deduplication is drop-new and resolve-dismissed, matching `Distinct` behavior.
5. UIKit and SwiftUI are equally supported renderers behind one view-model-facing protocol.
6. Window-level SwiftUI uses a dedicated passthrough host, not `WindowModalRenderer` unchanged.
7. Real Geniebook fixture snapshots are required deliverables, not deferred downstream work.

## 10. Explicit non-goals for the first release

- Serial toast queueing.
- Automatic multi-toast stacking or collision avoidance.
- Replacing all Geniebook call sites in this package's initial implementation.
- Extracting a shared presentation-core package from GBV3AlertModal.
- Supporting arbitrary caller-supplied UIKit or SwiftUI view content inside a toast.
- Snapshotting animation frames or relying on wall-clock sleeps in tests.
