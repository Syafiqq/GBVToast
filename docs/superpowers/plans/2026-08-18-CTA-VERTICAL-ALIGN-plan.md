# Inline CTA vertical alignment implementation plan

> **State:** Ready for execution after adversarial review. Execute tasks in order; snapshot work depends on the placement contract established in Task 1.

**Goal:** Vertically center text and asset CTA frames in iOS 16+ inline toast rows while preserving semantic trailing placement and every existing measurement, fallback, interaction, accessibility, and public API contract.

**Design:** Keep `ToastInlineLayout` measurement unchanged. Route only its CTA placement point through a small internal pure helper, then place at the row’s `midY` with `.trailing` in LTR and `.leading` in RTL. Prove the geometry numerically before recording the intentional inline snapshot changes.

**Constraints:** iOS 15 deployment floor, Swift 6 language mode, no public API change, no asset display-size work, no dedicated/vertical-layout redesign, semantic RTL behavior, and no downstream Geniebook edits or release publishing.

## Task 1: Pin and implement the inline placement invariant

**Files:**

- Modify: `Sources/GBVToast/ToastInlineLayout.swift`
- Create: `Tests/GBVToastTests/ToastInlineLayoutTests.swift`

1. Extract the current CTA point and anchor selection from `placeSubviews` into an internal pure placement function alongside `ToastInlineLayout`, without changing behavior. It accepts `CGRect` bounds and `LayoutDirection` and returns a small internal placement value containing the `CGPoint` and semantic `UnitPoint` anchor. Do not move or duplicate width/height measurement policy into the helper.
2. Add characterization tests for the extracted current behavior and run them green: LTR resolves to `(bounds.maxX, bounds.maxY)`/`.bottomTrailing`, and RTL resolves to `(bounds.minX, bounds.maxY)`/`.bottomLeading`. This proves the extraction itself is behavior-preserving.
3. Replace those expectations with the approved contract and add focused Swift Testing cases using non-zero-origin bounds. Run the focused suite and confirm it fails against the extracted bottom-aligned implementation because:
   - the returned point uses `bounds.midY`;
   - LTR uses `bounds.maxX` and semantic trailing;
   - RTL uses `bounds.minX` and semantic leading.
4. Add table-driven cases representing a message taller than the CTA and a CTA taller than the message. Given the chosen semantic center anchor, assert the derived CTA frame midpoint equals `bounds.midY` in every case and its trailing horizontal edge matches the appropriate bound.
5. Update the helper to return `(bounds.maxX, bounds.midY)`/`.trailing` for LTR and `(bounds.minX, bounds.midY)`/`.leading` for RTL. The already-wired `placeSubviews` now receives the corrected placement without any measurement edit.
6. Re-run the focused tests green on an available iOS simulator with snapshot recording disabled. Inspect the source diff and reject any measurement or public-model changes.
7. Commit the tests, helper, and placement correction atomically.

Suggested verification:

```shell
xcrun simctl list devices available
xcodebuild test \
  -workspace .swiftpm/xcode/package.xcworkspace \
  -scheme GBVToast \
  -destination 'platform=iOS Simulator,id=<AVAILABLE-IPHONE-UDID>' \
  -only-testing:GBVToastTests/ToastInlineLayoutTests \
  CODE_SIGNING_ALLOWED=NO
```

Expected commit: `fix: center inline toast CTAs`

## Task 2: Record the intended visual change and reject unrelated churn

**Files:**

- Modify only as needed: `Tests/GBVToastTests/Snapshots/ToastSnapshotTests.swift`
- Modify only as needed: `Tests/GBVToastTests/Fixtures/ToastParityFixtures.swift`
- Modify: affected PNGs under `Tests/GBVToastTests/Snapshots/__Snapshots__/ToastSnapshotTests/`

1. Run these existing snapshot groups without recording and inventory only failures caused by inline CTA vertical movement:
   - `testCTAContractMatrix` for text CTA, multiline, iPad, and RTL cases;
   - `testImageCTAContractMatrix` for inline asset, long-message, and RTL cases;
   - `testSwiftUIRealFixturesFullPage` and `testSwiftUIParityMatrixFullPage` for full-context evidence.
2. Confirm existing fixtures already cover a single-line text CTA, single-line asset CTA, multiline inline CTA, and RTL. Add the smallest named fixture only if one of those cases is genuinely absent; do not rename durable matrix keys or change fixture semantics to manufacture a passing snapshot.
3. Record only the failing inline snapshots using `SNAPSHOT_TESTING_RECORD=failed`. Never use global `all` recording for this task. Because full-page assertions use a non-exact precision, explicitly compare the existing full-page inline images with freshly rendered output; if centering pixels differ but remain under the assertion tolerance, re-record only the affected test method on a clean worktree and discard byte-identical/unrelated outputs before staging.
4. Inventory changed PNG paths before inspecting pixels. Any path whose fixture is dedicated, accessibility vertical, legacy vertical, missing-asset, or non-CTA is a stop condition and must be restored by correcting the recording scope—not staged as incidental churn.
5. Inspect each retained PNG side by side. The CTA’s vertical position may change; container dimensions, message origin and wrapping, horizontal placement, artwork, color, typography, and spacing must remain stable.
6. Re-run all four snapshot groups with recording disabled and require a clean pass.
7. Commit only intentionally changed snapshot references and any strictly necessary fixture/test additions.

Suggested verification:

```shell
xcrun simctl list devices available
SNAPSHOT_TESTING_RECORD=failed xcodebuild test \
  -workspace .swiftpm/xcode/package.xcworkspace \
  -scheme GBVToast \
  -destination 'platform=iOS Simulator,id=<AVAILABLE-IPHONE-UDID>' \
  -only-testing:GBVToastTests/ToastSnapshotTests/testCTAContractMatrix \
  -only-testing:GBVToastTests/ToastSnapshotTests/testImageCTAContractMatrix \
  -only-testing:GBVToastTests/ToastSnapshotTests/testSwiftUIRealFixturesFullPage \
  -only-testing:GBVToastTests/ToastSnapshotTests/testSwiftUIParityMatrixFullPage \
  CODE_SIGNING_ALLOWED=NO
```

Then repeat the same command without `SNAPSHOT_TESTING_RECORD`.

Expected commit: `test: record centered inline toast CTAs`

## Task 3: Run the full regression and artifact gate

**Files:**

- No planned source changes.
- Do not stage the ignored `.build/reports/toast-snapshot-comparison.html` artifact.

1. Run the complete GBVToast test scheme on the same selected simulator with parallel testing disabled and snapshot recording unset.
2. Run `Tests/ScriptTests/test_generate_snapshot_comparison.py`.
3. Regenerate `.build/reports/toast-snapshot-comparison.html` from approved snapshots with `--skip-tests`. Verify that the report remains self-contained and contains the existing inline text, RTL, and update-version image CTA cards.
4. Inspect `git diff --check`, `git status --short`, and the commit range for the execution. Confirm:
   - no `ToastCTA`/public API or asset sizing changes;
   - no dedicated, accessibility, legacy, or non-CTA snapshot modifications;
   - no generated report is staged;
   - every repository change belongs to this alignment slice.
5. If verification reveals a required correction, make the smallest fix in the task that owns it, rerun the focused and full gates, and commit that verified correction atomically. If no correction is needed, create no empty commit.

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
rg -n "Inline Cta|Right To Left|Update Version Image Cta|data:image/png;base64" \
  .build/reports/toast-snapshot-comparison.html
git diff --check
git status --short
```

## Completion criteria

- The CTA frame midpoint equals the inline layout bounds midpoint in LTR and RTL, including unequal message/CTA heights.
- Horizontal placement remains semantic trailing.
- Message placement and layout measurement code are unchanged.
- Text and asset CTA inline snapshots show only the approved vertical-position difference.
- Dedicated, accessibility vertical, iOS 15 legacy vertical, missing-asset, and non-CTA behavior remain green and visually unchanged.
- The complete simulator test scheme and script tests pass with snapshot recording disabled.
- The generated comparison report is inspected but not staged.
- Asset display sizing, downstream Geniebook integration, tagging, and publishing remain separate follow-ups.

## Execution shape

The tasks are sequential: the geometry contract and fix establish the pixels that Task 2 records, and Task 3 verifies both. Prefer `superpowers:executing-plans` in a separate session with review checkpoints when that skill is available. Do not split these dependent tasks across parallel implementation agents.

## Adversarial plan review

**Verdict: GO.** The plan is executable in sequence after the corrections below. No unresolved no-go item or unmarked assumption remains.

1. **Finding: the original red/green sequence introduced the test helper before claiming the current behavior failed.** Depending on the helper’s initial implementation, the first test could pass immediately or fail only to compile, so the plan did not reliably demonstrate the regression. **Resolution:** Task 1 now extracts and characterizes the current bottom-aligned behavior green, flips expectations to the approved centered contract red, then updates the already-wired helper green.
2. **Finding: full-page snapshot precision can accept a small vertical movement without producing a failed snapshot to record.** A passing threshold is not proof that the stored PNG reflects the new center alignment, especially because the comparison report consumes approved images. **Resolution:** Task 2 now explicitly compares fresh full-page output, scopes any forced recording to an affected test method, and discards byte-identical or unrelated outputs before staging.
3. **Finding: a looped snapshot method can touch unaffected reference files during recording.** Incidental churn could hide a dedicated or fallback regression. **Resolution:** Task 2 now inventories paths first and treats every non-inline fixture change as a stop condition rather than a reviewable update.
4. **Finding: the task could accidentally test the visible image midpoint instead of the full interaction frame.** That would miss the contract for a 44-point minimum CTA target. **Resolution:** the design and Task 1 geometry cases define the child’s measured CTA frame—including the button target—as the frame whose midpoint must equal `bounds.midY`.
5. **Finding: the available `review` skill is absent.** **Resolution:** this section records the required inline adversarial equivalent, with each finding fixed in the plan and an explicit GO verdict.
