# Handoff: research the visual direction before redesigning

Work in `/Users/naufaldisatriya/WebApps/flutter-ui-payment`.

The owner rejected the current component screenshots: **"our component really bad, slop"**. Your task is to research UI inspiration, diagnose the visual problems, and propose a defensible design direction. This first phase is research and art direction. Do not edit production components or continue the landing page yet.

## Context and current state

This is a reusable, generic Flutter payment UI library for an open-source portfolio. It includes optional KYC, checkout, host authorization, manual payment instructions, payment status, receipts, transaction history, interactions, navigation/sidebar/drawer, sheets, video controls, and promotions. Core widgets receive host state and callbacks; they do not process money.

- Read `README.md`, `PRD.md`, `docs/components.md`, `docs/integration.md`, `docs/compatibility.md`, and `docs/decisions.md`.
- Inspect `lib/src/`, the public exports in `lib/flutter_ui_payment.dart`, and the gallery in `example/lib/screens/`.
- Existing behavior, synthetic fixtures, and tests are useful and should be preserved. Functional verification is not evidence of visual quality.
- Landing/docs implementation was interrupted to allow this research-first reset. `website/` currently contains an incomplete package manifest/lockfile; its scripts are not evidence of a working website. `docs/web-plan.md` exists, but its visual direction is unapproved.
- The previous delegate is stopped, with no active run. Inspect live processes before starting any tooling.
- This folder is not a Git repository. There is no confirmed project remote, hosting target, domain, or pub.dev publication. Do not use the personal-workspace remote or deploy/publish anything.

## Start with actual screenshots

Open the native PNGs in `example/build/screenshots/`, especially:

- `android_refined_checkout_light.png`
- `android_refined_checkout_light_200.png`
- `android_refined_status_unknown_dark.png`
- `android_kit_history.png`
- `android_kit_navigation_drawer.png`
- `android_kit_sheet_pending.png`
- `android_kit_promo_200.png`
- `ios_kit_video_playing.png`

Identify problems using visible evidence: typography, hierarchy, density, alignment, surface treatment, radii, iconography, action placement, status communication, and composition. Investigate the accumulated default-Material appearance, oversized repeated containers, pill-heavy controls, and weak distinction between primary and secondary information. Confirm each criticism rather than assuming every instance is wrong.

Separate the actual end-user component from the developer gallery's class-name headings, fixture controls, and scenario selectors. Improve both experiences for their own audiences; do not mistake a gallery heading for a payment UI requirement. Preserve accessibility: smaller visual controls still need at least 48 logical-pixel touch targets.

## Skills and working method

Use `faldi-mode` to retain scope and delivery discipline. Use `emil-ask-emil` to select one or two relevant skills at each stage. Start with `emil-unslop-design` and `emil-design-foundations`. Use the research phase of `emil-get-creative` where useful; no generator or production implementation is requested in this phase. Bring in typography, surfaces, motion, or marketing guidance only for a concrete question.

Make recommendations on the owner's behalf from the project evidence. Do not run a long taste questionnaire. Mark assumptions and genuine uncertainty.

Follow `/Users/naufaldisatriya/.codex/RTK.md`: prefix shell commands with `rtk` or `rtk proxy`. On this 8 GB Mac, use one task-owned automated browser session, establish ownership before reusing anything, preserve user browsers/unrelated servers, and clean up task resources. Read `browser-harness` before web interaction. Do not use T3 `preview_*` to inspect your own edits. Do not install heavy tooling or runtimes silently. No subagents unless requested.

## Research real interfaces

Curate roughly 5–8 strong references, rather than collecting a large moodboard of generic fintech landing pages. Cover these distinct jobs:

1. **Payment/product UI:** actual checkout, order/fee summary, payment methods, pending/unknown state, receipt, transaction history, and relevant sheet/navigation patterns.
2. **Component-library experience:** how individual components, variants, states, and source examples are presented.
3. **Landing/docs:** information architecture, product presentation, installation, search, examples, and API navigation.

Forui (`https://forui.dev/`) remains a benchmark for component-library discovery and documentation. It is not automatically the visual direction for our checkout or a reason to copy its brand. Other starting points may include public Stripe payment demos, Shopify checkout examples, Wise product UI, and established component documentation. Verify what is actually accessible. A provider's marketing homepage is not proof of its checkout interaction design.

Prefer official demos, product screenshots, and design-system documentation. Dribbble/Behance can supplement visual exploration, but label concept work and do not infer usable interactions from a still image. For each reference provide:

- A direct source URL and an inspected screenshot or clearly identified visual excerpt.
- The specific component or pattern being studied.
- What works and why it fits this project's user task.
- What should be adapted, what should not be copied, and any visible limitations.

Do not invent research findings or claim a screenshot was inspected when it was inaccessible. Reference assets are for research, not automatically licensed production assets.

## Deliver the research and recommendation

Save a concise research/art-direction document in `docs/design-research.md`, with links to any local reference boards. Show the visual material in the conversation as well.

Deliver:

1. A screenshot-based critique of the current UI, prioritizing the five most consequential issues. Use Emil's `Before | Proposed direction | Why` table.
2. An annotated reference board, separated into product components and landing/docs, with specific transferable patterns.
3. Two or three genuinely different visual directions. Explain typography, density, palette rationale, surfaces, radius/border system, icon treatment, and motion. Changing the accent color alone is not a different direction.
4. One recommended direction with explicit tradeoffs. Use checkout and pending/unknown status to explain how it would work. Do not create production code or polished variants before the reference research is complete.
5. Five to ten concrete design constraints and a small token proposal. Avoid vague instructions such as "make it premium". Do not preserve teal, purple, large radii, or the existing brand treatments merely because they already exist.
6. A sequenced implementation handoff: foundation, one reference checkout/status slice, reusable components, gallery, then landing/docs. Establish the product visual language before promoting it on the website.

The recommendation should have a recognizable point of view without gradients, decorative effects, or new animation being used to conceal weak hierarchy. Do not assume every card, divider, icon, badge, or caption is necessary.

## Preserve these constraints for the later implementation

- Host/backend remains authoritative for KYC, quotes, authorization, idempotency, status, and refunds.
- Timeout is not failure. Unknown/pending attempts cannot offer pay-again. Quote changes require renewed review/authorization. Refund is separate from original payment success.
- Keep module composition and existing public APIs where practical. No mandatory router, state manager, camera, ads, or media plugin in the core.
- Preserve id/en, light/dark, 200% text, readable complete amounts, keyboard/focus behavior, and reduced motion.
- Android minimum is API 24 with the installed SDK; runtime proof currently covers API 30 arm64, not Android 7–10 or arm32. Do not promise broader compatibility without evidence.
- Work remains local. No package publication, remote creation, merge, or deployment.

**Finish this first phase with the inspected research, visual directions, recommendation, and implementation handoff. Do not start another automatic cosmetic patch or turn this into a testing project.**
