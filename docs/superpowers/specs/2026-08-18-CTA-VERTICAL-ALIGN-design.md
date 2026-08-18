# Inline CTA vertical alignment design

Date: 2026-08-18
Status: Approved for implementation planning

## Goal

Vertically center every CTA in the iOS 16+ inline message row while preserving semantic trailing placement, current measurement and wrapping, responsive fallbacks, accessibility behavior, and public API compatibility.

## Problem

`ToastInlineLayout.placeSubviews` currently places its CTA at the row’s bottom-trailing corner in left-to-right layouts and bottom-leading corner in right-to-left layouts. The row height is the greater of the measured message and CTA heights. Consequently, whenever those heights differ, the shorter CTA is bottom-aligned instead of visually centered. The gap is especially apparent for a single-line update message paired with an image CTA, but the layout defect applies equally to text and asset CTA labels.

## Scope

In scope:

- iOS 16+ `ToastInlineLayout` CTA placement;
- text and asset CTA labels;
- left-to-right and right-to-left layout directions;
- single-line and multiline message rows;
- focused geometry assertions and representative snapshot regression coverage.

Out of scope:

- optional display sizing for asset CTA images;
- changes to `ToastCTA`, `ToastCTA.Label`, or any other public API;
- changes to CTA measurement, width allocation, wrapping, or fallback thresholds;
- `.dedicated` CTA layout;
- accessibility-size vertical layout;
- the iOS 15 `ToastLegacyResponsiveLayout`, which is already a vertical stack rather than the custom inline row;
- Geniebook application assets, integration code, release publishing, or downstream snapshots.

Asset display sizing remains an independent follow-up from the post-1.0.2 handoff and must not be bundled into this change.

## Design

Keep `ToastInlineLayout.sizeThatFits` unchanged. It continues to:

1. constrain the CTA to its intrinsic width or 45 percent of available width, with a 44-point floor;
2. offer the remaining width to the message;
3. return the available width and the greater of the measured message and CTA heights.

Keep the child measurements in `placeSubviews` unchanged. Only the CTA’s placement point and anchor change.

For left-to-right layout:

- keep the message at the row’s top-leading origin;
- place the CTA at `(bounds.maxX, bounds.midY)` with anchor `.trailing`.

For right-to-left layout:

- keep the message at the row’s top-trailing origin;
- place the CTA at `(bounds.minX, bounds.midY)` with anchor `.leading`.

Using `.trailing` and `.leading` anchors means the placement point addresses the CTA frame’s vertical midpoint. The complete measured CTA frame—including `ToastCTAButton`’s minimum 44×44-point interaction target—is centered, not merely the visible text or image inside it.

The placement rule is label-agnostic. Text and asset labels follow the same inline layout contract, avoiding divergent behavior based on content type.

## Preserved behavior

The change must preserve:

- top-leading message placement;
- semantic horizontal trailing placement in both layout directions;
- the spacing and width allocation between the message and CTA;
- full message and CTA wrapping without truncation;
- the current responsive selection between inline and vertical layouts;
- dedicated CTA layout;
- asset lookup and `.ctaAssetUnavailable` failure behavior;
- minimum CTA interaction target, VoiceOver label, button trait, and action semantics;
- first-result-wins presentation and dismissal behavior.

Existing inline snapshots may change only in the CTA’s vertical position. Dedicated, vertical-fallback, and non-CTA snapshots must not change.

## Verification

### Focused geometry

Add deterministic layout probes that capture the frames assigned by `ToastInlineLayout`. Cover:

- LTR with a short CTA beside a taller multiline message;
- RTL with a short CTA beside a taller multiline message;
- LTR with a CTA frame taller than the message;
- RTL with a CTA frame taller than the message.

For every case, assert within the test suite’s floating-point tolerance that:

- `ctaFrame.midY == layoutBounds.midY`;
- LTR CTA trailing edge equals `layoutBounds.maxX`;
- RTL CTA leading edge equals `layoutBounds.minX`;
- the message remains at the expected top semantic edge;
- the measured layout size and child width proposals remain unchanged from the existing contract.

If the current test target cannot directly inspect `Layout` placements, introduce a small internal, pure placement helper used by `ToastInlineLayout` and test that helper. The helper must accept already-measured bounds/child sizes and return placement points or frames; it must not duplicate measurement policy or become public API.

### Snapshots and regressions

Exercise representative inline rendering for:

- a text CTA with a single-line message;
- an asset CTA with a single-line message;
- an inline CTA with a multiline message;
- right-to-left inline placement.

Update only snapshots whose CTA pixels move because of the approved center alignment. Confirm that dedicated CTA, accessibility vertical fallback, iOS 15 legacy vertical rendering, missing-asset presentation, and current text CTA interaction tests remain green without fixture-semantic changes.

Run the repository’s package tests and snapshot comparison script tests. Regenerate derived snapshot/report artifacts only when the repository’s existing workflow requires them and inspect the diff for unrelated visual changes.

## Acceptance criteria

- In every iOS 16+ inline row, the measured CTA frame is vertically centered in the layout bounds.
- Inline text and asset CTAs use the same centering rule.
- LTR places the CTA at trailing-right; RTL places it at trailing-left.
- Single-line and multiline messages retain their current measurement and top placement.
- CTA width allocation, wrapping, minimum 44×44 interaction target, responsive fallback, and dedicated layout are unchanged.
- No public API changes are introduced.
- Focused geometry tests prove centering and semantic trailing placement.
- Representative inline snapshots record the intended visual change; unrelated snapshots remain unchanged.
- Existing package and script test suites pass.

## Risks and mitigations

- **Broad snapshot churn:** limit the implementation to placement coordinates and inspect every updated reference image; reject changes outside inline CTA vertical position.
- **Testing only visible artwork instead of the tap target:** assert the measured CTA frame’s midpoint, which includes the minimum interaction target.
- **RTL regression:** require mirrored horizontal-edge assertions and an RTL rendering snapshot.
- **Accidental fallback redesign:** leave selection and measurement code untouched and retain dedicated/vertical regression coverage.
- **Coupling to asset sizing:** do not modify `ToastCTA.Label`; keep the display-size follow-up separately scoped.

## Rollback

Reverting the placement-coordinate change and its intentionally updated inline snapshot references restores the previous bottom-aligned behavior. No model migration, persisted state, or downstream API rollback is required.
