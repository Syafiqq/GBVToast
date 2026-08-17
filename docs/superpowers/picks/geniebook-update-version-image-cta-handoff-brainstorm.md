# Geniebook update-version image CTA brainstorm

Source: `docs/geniebook-update-version-image-cta-handoff.md`

## Decision 1: public model and rendering approach

Which implementation shape should carry image CTA content while preserving GBVToast's deterministic configuration model?

- **A. Add a nested `ToastCTA.Label` enum with `.text` and `.asset` cases, keep the existing title initializer, and render both through one CTA button path. (Recommended)** This preserves source compatibility, `Sendable`/`Equatable`, deduplication semantics, and a bounded public capability.
- **B. Add a separate `ToastImageCTA` type and a second optional configuration property.** This avoids changing `ToastCTA`, but creates mutually exclusive CTA fields and duplicated layout/action behavior.
- **C. Accept a SwiftUI view or closure as the CTA label.** This is flexible, but breaks the handoff's concurrency, equality, and deterministic-fixture constraints.

Recommendation: A.

Answer: **A — approve as written.** (auto-accepted — lazy/away)

Answer: **A — implement and verify the library here, then preserve publishing and consumer migration as explicit handoff gates.** (auto-accepted — lazy/away)

## Proposed design

Add `ToastCTA.Label` with `.text(String)` and `.asset(name:bundleIdentifier:renderingMode:accessibilityLabel:)`, expose `label`, and retain `init(title:layout:)` as a source-compatible convenience initializer. Replace direct `title` rendering with a single semantic `Button` whose label switches between underlined text and an intrinsic-size original/template image inside a minimum 44×44 interaction frame.

Use a strict internal asset resolver for both presenter preflight and image construction. Before deduplication-store insertion or view attachment, an unresolved asset CTA completes its token as `.notPresented(.ctaAssetUnavailable)` and produces no host view. Existing text CTA behavior remains byte-for-byte snapshot compatible. Both iOS 16 custom layouts and the iOS 15 legacy fallback receive the typed label renderer; accessibility Dynamic Type continues to select the vertical layout, and semantic layout direction continues to control trailing placement.

Verification covers model compatibility/equality, strict resolver behavior, no-presentation behavior, exactly-once CTA completion, ordinary dismiss taps, hit-area geometry, inline/long/accessibility/RTL rendering, and a real `update-version-image-cta` fixture added to the canonical JSON matrix and regenerated HTML report. Release publishing and downstream Geniebook edits remain gated follow-up work after the library commit passes tests.

## Decision 5: design approval

Should this design become the standalone specification and basis for the implementation plan?

- **A. Approve as written. (Recommended)** It satisfies the handoff while keeping the public model deterministic and missing assets observable.
- **B. Revise the missing-asset policy to show a message-only toast.** This weakens the update prompt's actionable contract.
- **C. Expand the public API with text fallback content for asset labels.** This adds scope not required by the consumer handoff.

Recommendation: A.

Answer: **A — nested typed label enum and shared button path.** (auto-accepted — lazy/away)

## Decision 2: missing-asset behavior

What should happen when an asset CTA cannot resolve its named image?

- **A. Do not present the toast and complete its token with a dedicated `notPresented` reason. (Recommended)** This avoids showing an update prompt with no usable App Store action, makes failure observable, and keeps the visual/accessibility contract coherent.
- **B. Present the message without a CTA and let normal dismissal resolve the token.** This preserves informational content, but silently removes the notification's primary action and makes configuration failure easy to miss.
- **C. Present a text fallback CTA.** This needs additional public fallback content not required by the handoff and expands the API.

Recommendation: A, with asset preflight before host presentation and a specific, testable not-presented reason.

Answer: **A — fail presentation explicitly with a dedicated not-presented reason.** (auto-accepted — lazy/away)

## Decision 3: asset resolution boundary

How should GBVToast resolve and validate CTA assets without putting UIKit values into the public model?

- **A. Introduce one internal UIKit-backed asset resolver used by presentation preflight and SwiftUI rendering, with strict bundle-identifier semantics. (Recommended)** The public value stays platform-neutral while preflight and rendering agree; an invalid explicit bundle identifier cannot silently fall back to the main bundle.
- **B. Resolve independently in the presenter and CTA view.** This changes fewer existing files, but risks disagreement between validation and rendering.
- **C. Store a resolved `UIImage` in `ToastCTA.Label`.** This simplifies rendering but violates the public `Sendable`/`Equatable` configuration contract.

Recommendation: A. `nil` bundle identifier means `Bundle.main`; a supplied identifier must resolve that exact bundle, otherwise the asset is missing.

Answer: **A — one strict internal resolver shared by preflight and rendering.** (auto-accepted — lazy/away)

## Decision 4: plan scope across repositories and release

How far should this repository's implementation plan go into the downstream Geniebook migration?

- **A. Make the GBVToast capability, tests, fixture/report updates, and release-readiness checks executable tasks here; document publishing and Geniebook migration as ordered handoff gates, not actions in this repository. (Recommended)** This keeps the plan runnable in the current repository without pretending it can verify or mutate an absent consumer checkout.
- **B. Include detailed code-edit tasks for both GBVToast and Geniebook.** This is comprehensive, but the downstream paths, generated asset symbol, and package-resolution state cannot be inspected here.
- **C. Limit the plan strictly to the public model.** This is too narrow to satisfy rendering, interaction, snapshots, and consumer handoff acceptance criteria.

Recommendation: A.
