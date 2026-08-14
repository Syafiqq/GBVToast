# Geniebook production toast golden snapshots

## Objective

Generate full-page snapshots from Geniebook's actual production UIKit toast implementation and use those PNGs as the visual golden reference for GBVToast.

The snapshots must be rendered inside the Geniebook codebase. Do not copy or recreate the production toast view in GBVToast. This ensures the golden captures Geniebook's real fonts, colors, icons, assets, constraints, safe-area behavior, and CTA layout.

## Source of truth

The canonical case list is:

`Tests/GBVToastTests/Fixtures/toast_snapshot_matrix.json`

Every key in that file must have a Geniebook snapshot row. Unsupported or not-yet-representable cases must still be reported in the export manifest with `status: "unsupported"`; silently omitting a key is a failure.

The initial contract contains 23 keys:

### Real Geniebook scenarios

- `bottom-synthetic`
- `hidden-icon-error`
- `mode-switch-inline-cta`
- `reminder-undo`
- `ten-minute-warning-cta`

### Parity and stress matrix

- `default-title-only`
- `success-icon-title`
- `error-hidden-icon-multiline`
- `warning-icon-title`
- `custom-colors-title`
- `inline-cta-with-icon`
- `inline-cta-without-icon`
- `dedicated-cta-with-icon`
- `dedicated-cta-without-icon`
- `ipad-inline-cta-centered`
- `ipad-dedicated-cta-bottom`
- `bottom-custom-spacing`
- `stress-large-icon`
- `stress-long-title`
- `stress-long-cta`
- `custom-asset-icon`
- `accessibility-extra-extra-extra-large`
- `right-to-left-layout`

## Required render environment

Use a deterministic test host with these logical page definitions. The simulator model used to run the test may differ, but the snapshot canvas and traits must match exactly.

| Logical device | Canvas | Safe area | Scale | Default locale/direction |
| --- | --- | --- | --- | --- |
| `iphone-14` | 390×844 pt | top 47 pt, bottom 34 pt | 3× | `en_US`, LTR |
| `ipad-10th-generation` | 820×1180 pt | top 24 pt, bottom 20 pt | 2× | `en_US`, LTR |

Additional rules:

- Use light appearance.
- Disable animation before capturing.
- Use the production Geniebook font registration and asset bundles.
- Use a fixed, opaque page background of `#F4F6FA`.
- Render the entire page, not a cropped toast.
- Position the toast relative to the declared safe area and production spacing.
- Use accessibility category `.accessibilityExtraExtraExtraLarge` only for `accessibility-extra-extra-extra-large`.
- Force RTL only for `right-to-left-layout`.
- Do not snapshot timers, intermediate animation frames, or transient dismissal state.

## Fixture requirements

Build the fixtures against the real production toast API. Use the exact values in `ToastParityFixtures.swift` and `GeniebookToastFixtures.swift` as the portable case specification.

Each fixture must explicitly define:

- case key;
- logical device;
- message;
- color/style variant;
- icon source, visibility, size, and tint;
- CTA title and layout;
- top or bottom edge;
- safe-area spacing;
- phone/iPad maximum width;
- content-size category;
- layout direction.

For the five real scenarios, instantiate the same configuration used by the cited Geniebook call site wherever possible. If production behavior differs from the portable GBVToast fixture, production Geniebook behavior wins and the difference must be noted in the manifest.

## Suggested Geniebook test structure

Use XCTest plus the snapshot framework already approved in Geniebook. Snapshot UI rendering is UIKit/XCTest work; it does not need Swift Testing.

```swift
@MainActor
final class VToastGoldenSnapshotTests: XCTestCase {
  func testProductionToastGoldens() {
    for fixture in VToastGoldenFixtures.all {
      let page = GoldenPageViewController(device: fixture.device)
      page.showProductionToast(fixture.makeProductionConfiguration())

      assertSnapshot(
        of: page,
        as: .image(
          on: fixture.device.viewImageConfig,
          traits: fixture.traits
        ),
        named: fixture.key
      )
    }
  }
}
```

The test host must call the real production presenter/view. A copied `VToastViewV2`, simplified layout, or standalone test rewrite is not an acceptable golden source.

## Export contract

Export one directory containing:

```text
geniebook-toast-goldens/
├── manifest.json
└── images/
    ├── bottom-synthetic.png
    ├── hidden-icon-error.png
    └── ...one PNG for every supported matrix key
```

`manifest.json` must use this shape:

```json
{
  "schemaVersion": 1,
  "source": {
    "repository": "geniebook-student-ios-distribution",
    "commit": "FULL_GIT_SHA",
    "toastImplementation": "MODULE/TYPE_NAME",
    "xcode": "VERSION",
    "iosRuntime": "VERSION"
  },
  "cases": {
    "warning-icon-title": {
      "status": "captured",
      "image": "images/warning-icon-title.png",
      "device": "iphone-14",
      "canvasPoints": [390, 844],
      "scale": 3,
      "pixelSize": [1170, 2532]
    },
    "custom-asset-icon": {
      "status": "unsupported",
      "reason": "Production API does not currently accept a custom icon asset"
    }
  }
}
```

Export validation must fail when:

- a matrix key is absent from the manifest;
- a `captured` entry has no PNG;
- dimensions or scale differ from the declared device;
- an image is transparent or toast-cropped;
- the manifest commit does not match the tested Geniebook checkout;
- unexpected extra keys are present without first updating the canonical matrix.

## Import and golden-test behavior in GBVToast

Commit the approved export under:

`Tests/GBVToastTests/Golden/GeniebookUIKit/`

GBVToast tests should:

1. Validate the export manifest against `toast_snapshot_matrix.json`.
2. Treat every captured Geniebook PNG as immutable input—not as a baseline that GBVToast automatically records over.
3. Render the corresponding GBVToast SwiftUI fixture using the same page, traits, and scale.
4. Compare the SwiftUI output to the Geniebook golden with an explicit image-diff tolerance.
5. Attach the golden, actual, and diff images on failure.
6. Keep unsupported cases visible in the HTML matrix with an empty Geniebook column.

Start with a strict pixel match. If antialiasing or renderer differences require tolerance, approve one small global value and document it; do not assign ad hoc per-case tolerances that hide layout, color, asset, or typography drift.

Goldens may only be updated by importing a new Geniebook export. Each update must record the Geniebook commit and receive visual review. Running GBVToast tests must never rewrite production goldens.

## Acceptance criteria

- All 23 canonical keys appear in the Geniebook export manifest.
- Every Geniebook-supported key is captured from the actual production toast implementation.
- Phone/iPad and top/bottom cases visibly use full-page geometry.
- Production fonts, colors, icons, tinting, safe areas, CTA layouts, and width rules are present.
- The export is reproducible from a documented Geniebook test command.
- GBVToast can validate/import the export and generate side-by-side golden/SwiftUI/diff evidence.
- Unsupported cases remain explicit and can be filled gradually without changing existing keys.

## Geniebook handoff

Provide:

1. the test code and fixture adapter;
2. the exact command used to record and verify snapshots;
3. the exported `geniebook-toast-goldens` directory;
4. the Geniebook commit SHA;
5. a short note for every unsupported or production-divergent case.
