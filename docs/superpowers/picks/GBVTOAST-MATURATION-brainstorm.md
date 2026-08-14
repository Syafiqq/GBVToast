# GBVToast maturation review decisions

The user requested a poor-pick review of the existing GBVToast maturation plan and marked themselves away. No Jira-style ticket ID was supplied, so `GBVTOAST-MATURATION` is the documentation identifier for this review (assumed and flagged).

## Context

The existing plan is `docs/2026-08-14-gbvtoast-library-maturation-plan.md`. The request is to mature and review that plan, not implement it.

## Decisions

### Platform contract

Question: Which platform contract should the first stable release support?

- iOS 15+ only for the first stable release; remove the unsupported macOS declaration. **(Recommended)**
- Keep macOS and design a separate AppKit presentation surface.
- Keep macOS declared but document the window facade as unavailable there.

Answer: iOS 15+ only. **(auto-accepted — lazy/away)**

Rationale: the current implementation and planned window facade use UIKit throughout. Claiming macOS support without an AppKit design creates a false package contract.

### Presentation result contract

Question: What should `GBVToast.showToast` return?

- Return `ToastPresentationToken`, preserving async CTA/dismissed results and token-based dismissal; also allow dismissal by semantic ID. **(Recommended)**
- Return no value and make CTA callbacks part of configuration.
- Return only a semantic presentation ID.

Answer: return `ToastPresentationToken` and retain both token- and ID-based dismissal. **(auto-accepted — lazy/away)**

Rationale: this preserves the already-tested result contract and avoids losing CTA outcome handling during facade consolidation.

### Scene selection

Question: How should a process-wide facade select a window in a multi-scene application?

- Accept an optional scene/window context; without one, present only when exactly one eligible foreground key window exists, otherwise fail deterministically. **(Recommended)**
- Pick the first foreground scene returned by UIKit.
- Queue until a foreground window becomes available.

Answer: accept optional context and fail deterministically when the context-free choice is ambiguous or absent. **(auto-accepted — lazy/away)**

Rationale: UIKit scene enumeration order is not a user-intent contract, and silently choosing a window can display a toast in the wrong workspace.

### Root configuration installation

Question: What is the root configuration reinstallation policy?

- Permit configuration before first presentation; identical repeat installs are no-ops; reject a different configuration after presentation starts; use an injected runtime for isolated tests/previews. **(Recommended)**
- Last configuration always wins.
- Expose a public global reset API.

Answer: freeze a materially different root configuration after first presentation, with injected runtimes for tests. **(auto-accepted — lazy/away)**

Rationale: a process-global visual contract should not change underneath live or future presentations, while tests should not require a production reset escape hatch.

### Custom icon rendering

Question: How should custom icon rendering mode be selected?

- Make rendering mode explicit on each custom icon, defaulting to template. **(Recommended)**
- Always use template rendering.
- Always preserve original pixels.

Answer: explicit per icon, defaulting to template. **(auto-accepted — lazy/away)**

Rationale: this supports both tintable glyphs and branded multicolor assets without hidden asset-catalog behavior.

### CTA fallback control

Question: Should callers directly select the vertical CTA fallback?

- Keep fallback automatic and internal for the first stable API. **(Recommended)**
- Add a public `.vertical` CTA mode.
- Add a per-toast force-fallback Boolean.

Answer: automatic and internal. **(auto-accepted — lazy/away)**

Rationale: vertical layout is a safety response to available space and accessibility conditions, not a third semantic CTA mode.

### Non-presentation and identity contract

Question: How should callers observe a request that never became visible, and what identity should dismissal use?

- Add `ToastResult.notPresented(reason)` for missing/ambiguous windows and duplicate keys; keep the generated `ToastPresentationID` on the returned token for ID dismissal; keep `deduplicationKey` separate. **(Recommended)**
- Resolve every non-presentation as `.dismissed` and dismiss only by token.
- Add a caller-supplied ID to `ToastConfiguration` and overload it for deduplication.

Answer: add a typed non-presentation result, retain generated presentation IDs, and keep deduplication keys separate. **(auto-accepted — lazy/away)**

Rationale: a request that was never shown is observably different from a user/system dismissal, while overloading identity and deduplication creates collision and lifecycle ambiguity.

### Root configuration rejection API

Question: How should a materially different late root installation report rejection?

- Make `configure(root:)` throwing with a typed `alreadyStarted` error; identical repeat installs remain non-throwing no-ops. **(Recommended)**
- Trigger a debug-only assertion and silently ignore it in release builds.
- Return a Boolean.

Answer: use a typed throwing configuration API. **(auto-accepted — lazy/away)**

Rationale: a thrown domain error is deterministic and testable in every build configuration, unlike an assertion or an easily ignored Boolean.
