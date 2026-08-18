# CTA vertical alignment brainstorm

Source: `docs/geniebook-update-version-image-cta-handoff.md`, especially “Inline alignment change” and the follow-up acceptance criteria.

User intent: prepare a docs-only design and reviewed implementation plan autonomously. No production code is changed by this pick.

## Decision 1 — scope

Which part of the combined post-1.0.2 follow-up belongs in this pick?

- **A. Limit this pick to inline CTA vertical alignment; leave optional asset display sizing for a separate pick. (Recommended)** This matches the request, keeps the plan atomic, and avoids coupling a layout correction to a public API extension.
- **B. Plan both inline alignment and optional asset display sizing together.** This follows the whole follow-up section, but broadens the requested slice and mixes visual placement with API evolution.
- **C. Plan asset display sizing only.** This would not address the requested alignment gap.

Recommended answer pending auto-acceptance under the user’s autonomous/lazy-away instruction.

Answer: **A — vertical alignment only. (auto-accepted — lazy/away)**

Asset display sizing is explicitly out of scope. This pick may mention it only as an independent follow-up and must not add `CGSize` or alter `ToastCTA.Label`.

## Decision 2 — implementation approach

How should the inline CTA be vertically centered?

- **A. Change only `ToastInlineLayout.placeSubviews`: keep measurement unchanged, place the CTA at `bounds.midY`, and use semantic `.trailing`/`.leading` anchors. (Recommended)** This directly repairs the iOS 16+ inline layout while preserving widths, wrapping, vertical fallback, dedicated layout, and the iOS 15 legacy vertical stack.
- **B. Replace the custom inline `Layout` with a center-aligned `HStack`.** This is simpler superficially, but would discard the existing width allocation and responsive behavior.
- **C. Center asset CTAs conditionally while retaining bottom alignment for text CTAs.** This minimizes text snapshot changes, but creates label-type-dependent layout semantics that contradict the brief’s requirement for all inline CTAs.

Recommended answer pending auto-acceptance under the user’s autonomous/lazy-away instruction.

Answer: **A — update only the custom layout’s placement coordinates and anchors. (auto-accepted — lazy/away)**

The design will treat label content uniformly and will not alter sizing, measurement, fallback selection, or public API.

## Decision 3 — verification contract

What evidence should define successful centering without obscuring regressions?

- **A. Add focused layout geometry assertions for LTR/RTL and short/tall message rows, then update only intentionally affected inline snapshots and run the existing package/script suites. (Recommended)** Geometry tests prove the invariant numerically; snapshots preserve visual and semantic-direction coverage.
- **B. Rely only on snapshot diffs.** This checks rendered output, but makes the exact vertical-center invariant indirect and reviewer-dependent.
- **C. Add only a unit test for the anchor choice and skip snapshots.** This is fast, but misses integration changes in actual text/asset rendering and layout direction.

Recommended answer pending auto-acceptance under the user’s autonomous/lazy-away instruction.

Answer: **A — numeric geometry assertions plus focused snapshots and existing suites. (auto-accepted — lazy/away)**

The invariant is that the CTA frame’s `midY` equals the inline layout bounds’ `midY` within test tolerance in both layout directions. Message placement remains top-leading, horizontal CTA placement remains semantic trailing, and existing fallback/dedicated behavior is regression-tested rather than redesigned.

## Proposed design

The bug is isolated to iOS 16+ `.inline` placement. `ToastInlineLayout.sizeThatFits` already reports the taller of the message and CTA, and `placeSubviews` already computes the final child sizes. Keep those calculations intact. In LTR, place the message at top-leading and the CTA at `(bounds.maxX, bounds.midY)` with `.trailing`; in RTL, place the message at top-trailing and the CTA at `(bounds.minX, bounds.midY)` with `.leading`.

This centers the CTA’s complete measured frame—including its 44-point minimum interaction target—inside the row. It applies consistently to text and asset labels. It does not affect `.dedicated`, accessibility-size vertical layout, the iOS 15 legacy vertical layout, responsive width allocation, asset resolution, actions, accessibility labels, or public API.

Focused geometry probes will exercise a shorter CTA beside a taller multiline message and a taller CTA beside a shorter message in both directions, asserting vertical center and semantic horizontal placement. Existing representative inline text/asset snapshots will be updated only where the intended alignment changes pixels; dedicated and fallback snapshots must remain stable. Full package and snapshot-report script checks close the regression gate.

No challenge gate applies: the user named the problem and requested autonomous documentation, but did not prescribe an implementation solution.

## Decision 4 — design approval

Is this placement-only design ready to become the standalone specification?

- **A. Approve the design as written. (Recommended)** It satisfies the scoped brief with the smallest behavior change and a measurable acceptance contract.
- **B. Revise the design to include asset display sizing.** This would reverse the atomic scope decision and introduce a public API change.
- **C. Defer the design.** This leaves the known inline-alignment gap without an implementation-ready plan.

Recommended answer pending auto-acceptance under the user’s autonomous/lazy-away instruction.

Answer: **A — approve the placement-only design as written. (auto-accepted — lazy/away)**

## Recommendations digest

- **Scope:** vertical alignment only; asset display sizing remains a separate follow-up. **auto-accepted (lazy/away)**
- **Approach:** preserve measurement and change only the custom inline layout’s CTA placement point/anchor. **auto-accepted (lazy/away)**
- **Verification:** numeric LTR/RTL geometry assertions plus focused snapshots and the existing full regression suites. **auto-accepted (lazy/away)**
- **Design approval:** promote the placement-only design to a standalone specification and implementation plan. **auto-accepted (lazy/away)**
- **Plan review:** GO after correcting the red/green sequence, threshold-tolerant snapshot handling, recording-scope safeguards, and full CTA-frame geometry definition. No unresolved `?` item or assumed-and-flagged decision remains.

## Decision 5 — execution path

The plan’s tasks are sequential and dependent. Neither `superpowers:executing-plans` nor `superpowers:subagent-driven-development` is installed in this repository. How should execution be handed off?

- **A. End this poor-pick at the reviewed plan and execute it manually in a separate session with the documented review checkpoints. (Recommended)** This matches the sequential plan and preserves this skill’s docs-only terminal state.
- **B. Install or enable `superpowers:executing-plans`, then start a separate execution session.** This provides the preferred named runner but adds setup outside this pick’s documentation scope.
- **C. Decline implementation for now.** The reviewed plan remains available without selecting a runner.

Recommended answer pending auto-acceptance under the user’s autonomous/lazy-away instruction.

Answer: **A — hand off the reviewed sequential plan for manual execution in a separate session. (auto-accepted — lazy/away)**

This poor-pick is complete. It does not implement production or test code.
