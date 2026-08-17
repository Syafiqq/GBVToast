# GBVToast

GBVToast is an iOS 15+ SwiftUI-rendered toast library with a window-level facade. UIKit is used
only to resolve a foreground scene and host the canonical `ToastContentView`.

Install one application root before the first presentation:

```swift
try GBVToast.configure(root: applicationToastConfiguration)
```

Then present from any main-actor UIKit, SwiftUI, coordinator, service, or view-model code:

```swift
let token = GBVToast.showToast(
  ToastConfiguration(
    message: "Reminder removed",
    width: .full,
    style: .info,
    cta: ToastCTA(title: "Undo", layout: .dedicated)
  )
)

if await token.result == .cta {
  restoreReminder()
}
```

For multi-window applications, capture an opaque context at the scene integration boundary and
pass it through application state without retaining UIKit objects:

```swift
let context = GBVToast.sceneContext(for: windowScene)
let token = GBVToast.showToast(configuration, in: context)
GBVToast.dismiss(token)
GBVToast.dismiss(id: token.id)
```

The canonical styles are `.normal`, `.info`, `.danger`, `.warning`, and per-toast `.custom`.
Icons may be default, hidden, or custom assets with explicit template/original rendering.
CTA layouts are `inline` and `dedicated`; the renderer automatically falls back vertically when
width or Dynamic Type makes the requested horizontal layout unsafe.

CTA labels may be text or named assets. The existing `ToastCTA(title:layout:)` initializer remains
available. Image-only CTAs require an explicit accessibility label and use original rendering by
default:

```swift
let cta = ToastCTA(
  label: .asset(
    name: "AppStoreButton",
    bundleIdentifier: Bundle.main.bundleIdentifier,
    renderingMode: .original,
    accessibilityLabel: "Open App Store"
  ),
  layout: .inline
)
```

A supplied bundle identifier is resolved strictly and never falls back to the main bundle. If the
bundle or image is unavailable, the toast is not attached and its token resolves as
`.notPresented(.ctaAssetUnavailable)`.

Toast widths are `.compact` (the default, wrapping the content) and `.full`. Full-width toasts fill
the available horizontal space while preserving 16-point device-edge margins, and are capped at
400 points on wider devices. Per-device maximum widths can still provide a tighter cap.

Requests that cannot become visible resolve as `.notPresented(reason)`, including missing or
ambiguous windows, unavailable captured scenes, and duplicate keys within one scene.

## Snapshot comparison report

Run the SwiftUI snapshot suite and build the self-contained comparison against imported
Geniebook production goldens:

```shell
python3 Scripts/generate_snapshot_comparison.py
```

The report is written to `.build/reports/toast-snapshot-comparison.html`.
`Tests/GBVToastTests/Fixtures/toast_snapshot_matrix.json` is the ground truth.
