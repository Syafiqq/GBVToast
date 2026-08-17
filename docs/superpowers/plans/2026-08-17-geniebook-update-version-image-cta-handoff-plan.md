# Typed image CTA implementation plan

> **State:** Ready for execution after review. Implement in order; later tasks depend on the public model and shared resolver established earlier.

**Goal:** Add a typed, asset-backed CTA label that can reproduce Geniebook's update-version toast without weakening GBVToast's value semantics, accessibility, or presentation lifecycle.

**Design:** `ToastCTA.Label` carries either text or asset metadata. One strict internal UIKit asset resolver supplies both presenter preflight and SwiftUI rendering. An unresolved asset CTA never attaches a host and resolves its token as `.notPresented(.ctaAssetUnavailable)`. Existing text CTA construction and snapshots remain unchanged.

**Constraints:** iOS 15 minimum, Swift 6 language mode, `Sendable` and `Equatable` public configuration, semantic RTL placement, minimum 44×44 interaction target, no arbitrary view/closure API, and no downstream Geniebook edits or release tagging in this repository.

## Task 1: Introduce the typed CTA model without text regressions

**Files:**

- Modify: `Sources/GBVToast/ToastCTA.swift`
- Modify: `Tests/GBVToastTests/ToastConfigurationTests.swift`

1. Add failing model tests that prove:
   - `ToastCTA(title: "Undo", layout: .inline)` equals `ToastCTA(label: .text("Undo"), layout: .inline)`;
   - text labels differ by value and asset labels differ by each metadata field;
   - asset metadata survives inside `ToastConfiguration` unchanged;
   - the default asset rendering mode is `.original` and the default CTA layout remains `.dedicated`.
2. Run the focused configuration tests and confirm the new cases fail because `Label`/`label` do not exist.
3. Add `ToastCTA.Label`, the stored `label`, the designated label initializer, and the source-compatible title initializer. Keep every value `public`, `Sendable`, and `Equatable` as designed.
4. Replace test-only direct assumptions about the stored `title` property with label assertions; do not touch existing call sites that use `ToastCTA(title:)`.
5. Re-run focused tests and commit the model plus tests atomically.

Suggested verification:

```shell
xcrun simctl list devices available
xcodebuild test \
  -workspace .swiftpm/xcode/package.xcworkspace \
  -scheme GBVToast \
  -destination 'platform=iOS Simulator,id=<AVAILABLE-IPHONE-UDID>' \
  -only-testing:GBVToastTests/ToastConfigurationTests \
  CODE_SIGNING_ALLOWED=NO
```

Expected commit: `feat: add typed toast CTA labels`

## Task 2: Centralize strict asset resolution and reject invalid asset CTAs

**Files:**

- Create: `Sources/GBVToast/ToastAssetResolver.swift`
- Modify: `Sources/GBVToast/ToastIconView.swift`
- Modify: `Sources/GBVToast/ToastResult.swift`
- Modify: `Sources/GBVToast/SwiftUIToastPresenter.swift`
- Create: `Tests/GBVToastTests/ToastAssetResolverTests.swift`
- Modify: `Tests/GBVToastTests/SwiftUIToastPresenterTests.swift`

1. Add a small known asset to the test catalog only if the existing `ToastTestIcon` cannot be loaded predictably through `Bundle.module`; use the existing asset first to avoid duplicate fixtures.
2. Write failing resolver tests for a known test-bundle asset, an unknown name, an invalid explicit bundle identifier, and `nil` identifier/main-bundle semantics. Make resolver inputs injectable enough for tests without exposing them publicly.
3. Write failing presenter tests proving an unresolved asset CTA:
   - resolves `.notPresented(.ctaAssetUnavailable)`;
   - adds no subview and leaves `isEmpty` true;
   - does not reserve its deduplication key, demonstrated by a subsequent valid presentation using the same key;
   - does not schedule auto-dismiss work, using an injected counting sleeper whose invocation count remains zero after the result resolves.
4. Add `ToastNotPresentedReason.ctaAssetUnavailable`.
5. Implement `ToastAssetResolver` with strict bundle selection: `nil` means `.main`; a supplied identifier that does not resolve returns `nil`; image lookup failure returns `nil`.
6. Preflight asset CTA labels in `SwiftUIToastPresenter.present(_:)` after the container guard and before `store.insert`. Return the already-resolved token without creating content, a timer, or an accessibility announcement.
7. Move `ToastIconView` to the shared resolver only if focused icon snapshots/tests confirm no behavior change. If current icon fallback is compatibility-sensitive, keep icon rendering unchanged and limit the shared resolver contract to CTA preflight/rendering; document that accepted deviation in the code review notes.
8. Run focused resolver and presenter tests, then commit.

Suggested verification:

```shell
xcrun simctl list devices available
xcodebuild test \
  -workspace .swiftpm/xcode/package.xcworkspace \
  -scheme GBVToast \
  -destination 'platform=iOS Simulator,id=<AVAILABLE-IPHONE-UDID>' \
  -only-testing:GBVToastTests/ToastAssetResolverTests \
  -only-testing:GBVToastTests/SwiftUIToastPresenterTests \
  CODE_SIGNING_ALLOWED=NO
```

Expected commit: `feat: reject unavailable toast CTA assets`

## Task 3: Render accessible image labels through every layout path

**Files:**

- Create: `Sources/GBVToast/ToastCTALabelView.swift`
- Modify: `Sources/GBVToast/ToastContentView.swift`
- Modify: `Sources/GBVToast/ToastLegacyResponsiveLayout.swift`
- Modify: `Tests/GBVToastTests/SwiftUIToastPresenterTests.swift`
- Modify: `Tests/GBVToastTests/Snapshots/ToastSnapshotSupport.swift`
- Modify: `Tests/GBVToastTests/Snapshots/ToastSnapshotTests.swift`

1. Add failing focused view/layout tests or inspection helpers for:
   - asset CTA use of a real `Button` action path;
   - a minimum 44×44 button frame independent of artwork dimensions, measured after hosting and layout rather than inferred from a screenshot;
   - preservation of the supplied accessibility label and button semantics, inspected from the hosted UIKit accessibility tree;
   - `.original` versus `.template` rendering configuration;
   - non-CTA taps with `dismissOnTap` enabled and disabled;
   - first-result-wins when CTA and timer/dismissal compete.
2. Add named snapshot fixtures for a phone inline image CTA, long-message fallback, accessibility Dynamic Type, and RTL. Add a direct snapshot or focused rendering test for `ToastLegacyResponsiveLayout` so the iOS 15 code path is exercised even when the selected simulator runs a newer OS. Prefer a compact image-CTA matrix rather than duplicating the full existing parity matrix.
3. Confirm the focused test/snapshot run fails before renderer changes.
4. Implement one internal `ToastCTALabelView` (or an equivalent single builder) for `.text` and `.asset`. Preserve the exact existing text modifiers. For assets, use the resolver's image, apply the selected rendering mode, retain aspect ratio/intrinsic visual size, and set the explicit accessibility label.
5. Make the enclosing button provide the 44×44 minimum interaction frame/content shape. Keep action handling in `ToastContentView.handleCTA()` and the legacy layout's existing callback.
6. Route iOS 16 inline/dedicated, accessibility vertical, and iOS 15 legacy layouts through the same label renderer. Preserve semantic trailing alignment from the existing layout implementations.
7. If a long message and intrinsic image cannot fit inline without clipping, add an internal fit/fallback decision and pin it with the long-message snapshot; do not add a public layout case.
8. Record only the new image-CTA snapshots. Re-run existing text CTA snapshot tests without recording and require no diffs.
9. Commit renderer, interaction coverage, and focused snapshots.

Suggested verification:

```shell
xcrun simctl list devices available
xcodebuild test \
  -workspace .swiftpm/xcode/package.xcworkspace \
  -scheme GBVToast \
  -destination 'platform=iOS Simulator,id=<AVAILABLE-IPHONE-UDID>' \
  -only-testing:GBVToastTests/SwiftUIToastPresenterTests \
  -only-testing:GBVToastTests/ToastSnapshotTests/testCTAContractMatrix \
  CODE_SIGNING_ALLOWED=NO
```

Expected commit: `feat: render accessible image toast CTAs`

## Task 4: Add the real update-version fixture and comparison evidence

**Files:**

- Create: `Tests/GBVToastTests/Resources/ToastTestAssets.xcassets/UpdateVersionAppStore.imageset/Contents.json`
- Create: test image file under `Tests/GBVToastTests/Resources/ToastTestAssets.xcassets/UpdateVersionAppStore.imageset/`
- Modify: `Tests/GBVToastTests/Fixtures/GeniebookToastFixtures.swift`
- Modify: `Tests/GBVToastTests/Snapshots/ToastSnapshotTests.swift`
- Create: `Tests/GBVToastTests/Snapshots/__Snapshots__/ToastSnapshotTests/testSwiftUIRealFixturesFullPage.update-version-image-cta.png`
- Modify: `Tests/GBVToastTests/Fixtures/toast_snapshot_matrix.json`
- Modify: `golden-images/geniebook-toast-goldens/manifest.json`
- Modify: `Tests/ScriptTests/test_generate_snapshot_comparison.py`
- Modify: `README.md`

1. Add the authored App Store test artwork to a dedicated test-catalog imageset with correct scale metadata. Do not substitute an SF Symbol or template-tinted placeholder.
2. Add `GeniebookToastFixtures.updateVersionImageCTA` with multiline version copy, `.full`, `.normal`, `.bottom`, hidden leading icon, inline original asset CTA, two-second duration, 15-point safe-area spacing, and the update-version deduplication key.
3. Add `update-version-image-cta` to the real-fixture snapshot list.
4. Record its full-page snapshot on the canonical simulator and inspect it for bottom placement, 15-point safe-area spacing, full width, dark palette, multiline message, original artwork, and non-clipping layout.
5. Add the fixture to the real-fixture group in `toast_snapshot_matrix.json`. Add a matching unsupported entry to the Geniebook golden manifest unless a production golden is supplied; explain that the new library-capability fixture has no imported production image.
6. Update report-script assertions to derive or expect the new total and verify the generated HTML includes the update-version card. Update README's stale hard-coded matrix count (currently lower than the existing matrix) to the accurate count or remove the brittle number.
7. Run the script unit tests, then generate `.build/reports/toast-snapshot-comparison.html` from the recorded snapshots with `--skip-tests`. Verify the output is self-contained and contains `Update Version Image Cta`; do not force-add the ignored report.
8. Run the real-fixture snapshot test without recording and commit the fixture asset, snapshot, matrix, manifest, tests, and README together.

Suggested verification:

```shell
python3 -m unittest Tests/ScriptTests/test_generate_snapshot_comparison.py
python3 Scripts/generate_snapshot_comparison.py --skip-tests
rg -n "Update Version Image Cta|data:image/png;base64" .build/reports/toast-snapshot-comparison.html
```

Expected commit: `test: add update-version image CTA evidence`

## Task 5: Run the release-readiness gate and write the consumer handoff

**Files:**

- Modify: `README.md`
- Create: `docs/geniebook-update-version-image-cta-integration.md`

1. Add README API documentation for text and image CTA labels, strict bundle semantics, required accessibility labels, `.ctaAssetUnavailable`, and the existing text initializer.
2. Write a downstream checklist containing:
   - confirm Geniebook's generated App Store asset name;
   - publish a new semantic version without moving `1.0.1`;
   - update the exact package pin and resolved revision;
   - replace `APIClient.showUpdateAvailableNotifier(newVersion:)` with the async token-result flow;
   - retain the `itms-apps` URL behavior;
   - add the occurrence to Geniebook's UI snapshot inventory;
   - verify two-second dismissal and the App Store action;
   - delete `SnackBar` only after a no-caller reference search.
3. Run all package tests on the selected simulator with snapshot recording disabled.
4. Run script tests, regenerate the comparison report, inspect the new card, run `git diff --check`, and inspect `git status --short` to ensure no generated build artifacts are staged.
5. Review `git diff` specifically for unintended existing text CTA snapshot changes. Any such changes are a stop condition unless explained and approved.
6. Commit documentation only after all gates pass. Do not tag or publish from this task.

Suggested verification:

```shell
xcrun simctl list devices available
xcodebuild test \
  -workspace .swiftpm/xcode/package.xcworkspace \
  -scheme GBVToast \
  -destination 'platform=iOS Simulator,id=<AVAILABLE-IPHONE-UDID>' \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
python3 -m unittest Tests/ScriptTests/test_generate_snapshot_comparison.py
python3 Scripts/generate_snapshot_comparison.py --skip-tests
git diff --check
git status --short
```

Expected commit: `docs: add image CTA consumer handoff`

## Completion criteria

- Every acceptance criterion in the approved design has automated or inspected evidence.
- The complete test suite passes with recording disabled.
- Existing text CTA snapshots are unchanged.
- The update-version fixture is present in the canonical matrix and generated report.
- Missing asset requests resolve explicitly and do not reserve deduplication state.
- The worktree contains no staged user-owned or ignored report artifacts.
- Publishing and Geniebook migration remain explicit follow-up gates, not implied completed work.

## Adversarial plan review

**Verdict: GO.** The plan is executable in sequence after resolving the findings below. No unresolved no-go item or unmarked assumption remains.

1. **Finding: simulator commands were machine-specific.** A hard-coded `iPhone 16 Pro` destination could fail despite an available supported simulator. **Resolution:** every xcodebuild block now starts by listing available devices and uses an explicit selected iPhone UDID.
2. **Finding: the missing-asset timer assertion was not observable.** Merely awaiting the immediate not-presented result would not prove the sleeper was never called. **Resolution:** Task 2 now requires an injected counting sleeper and asserts zero invocations.
3. **Finding: snapshots cannot prove interaction geometry or accessibility traits.** Visual evidence alone is insufficient for the 44×44 and VoiceOver requirements. **Resolution:** Task 3 now requires post-layout hosted-view geometry measurement and UIKit accessibility-tree inspection.
4. **Finding: running on a modern simulator does not exercise the iOS 15 branch.** An “iOS 15-compatible” fixture could still execute the iOS 16 custom `Layout`. **Resolution:** Task 3 directly renders/tests `ToastLegacyResponsiveLayout` independent of runtime availability checks.
5. **Finding: adding a matrix key without a golden-manifest key makes report generation fail by design.** **Resolution:** Task 4 already updates both the matrix and manifest, using an explicit unsupported production-golden entry when no source golden exists.
6. **Finding: the generated HTML lives under ignored `.build` and must not be force-added.** **Resolution:** Tasks 4 and 5 treat it as regenerated inspection evidence and explicitly check staged state.
