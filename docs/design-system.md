# Design system: daily guide

Use this guide to find the active rule before changing a component or composing a host screen. It is derived navigation, not a new contract. [Documentation map](README.md) explains document roles.

The [product PRD](../PRD.md) and [foundation specs](prd-foundation-components.md) define requirements. The [§8 register](prd-foundation-components.md#8-decisions) records approved decisions: apply the latest relevant amendment or supersession, not an isolated older row. [Source exports](../lib/rakit_ui.dart), generated [API data](../website/src/data/api.json) and [component docs](components.md) describe shipped APIs. Approved requirements can remain unimplemented; report that gap explicitly.

## Scope and layers

Docs navigation (D105): **Components** describe public APIs, **Patterns** explain
domain composition and behavior, **Guides** cover general layout/state recipes,
and **Blocks** provide copyable mobile host screens with source and runnable demos.
Blocks reuse components/patterns; they add no package runtime. Existing guide URLs
remain stable even when their sidebar group changes.

- **Platforms (D64):** iOS on iPhone/iPad and Android phones/tablets. Web is documentation and gallery preview only; desktop is out of scope.
- **Foundations:** shared tokens and rules. **Tier 1 components:** reusable controls, views and pages. **Tier 2 patterns:** compose Tier 1 and enforce payment/KYC presentation contracts. Tier 1 does not depend on Tier 2 types.
- Views and pages are Scaffold-free bodies with named host slots; the host owns routing and the surrounding shell. FocusView is the presentation exception (D31).
- Admit a component through extraction of existing duplication, a concrete Tier 2 need, or the approved 48-entry Stripe parity scope (D28). Extra variants need evidence under §9. Token layout primitives use the D33 enums.

Source: [§2 definitions and admission](prd-foundation-components.md#2-definitions), [§7 patterns](prd-foundation-components.md#7-patterns-tier-2-composed-from-tier-1).

## Host boundary

The kit renders host data and reports intent. The host owns network, clipboard, URLs, camera/media engines, permissions, routing, authentication, pricing, KYC decisions, payment status, idempotency, persistence and polling. No secrets, platform-channel calls or polling timers in `lib/`; dependencies remain Flutter SDK only (B11).

D73 keeps haptics host-owned through existing callbacks. Material controls retain SDK-owned tap/long-press feedback; this does not add a kit haptic API. Use the [§12 boundary check](prd-foundation-components.md#12-acceptance-and-verification) and [integration guide](integration.md).

## Tokens and brands

- Kit-owned defaults use `PaymentTheme`, `PaymentType` and `PaymentMotion` (B2). Use semantic roles rather than raw brand values. Documented scrims are explicit exceptions, not a general raw-color escape hatch.
- Resolve colors through `PaymentTheme.of(context)` and status pairs through `tone(StatusTone)`. Hosts install a theme extension or derive one with `PaymentTheme.fromColorScheme` and `copyWith`. Status remains icon + words, never color alone.
- Spacing uses `PaymentTheme.space(PaymentSpace.<role>)` (D33/D46). On the default 8 dp base, the scale is 4 / 8 / 12 / 16 / 24 / 32 dp; changing the theme's spacing base scales these roles together. One role resolves to one value. Do not make an arbitrary gap into a new role.
- Use semantic type, radius, icon and motion roles. Brands change tokens rather than adding branded variants.
- Radius roles (D101): `PaymentTheme.radius` is the box corner and the base. Set `tagRadius`, `controlRadius` or `sheetRadius` on the theme to change one role, for example square boxes with pill tags; an unset role keeps 0.5 / 0.75 / 1.5 × `radius`. Widgets read roles through the getters or `PaymentRadius`; never hard-code a corner. To change only fields, use `PaymentFieldTheme` (D102). Verify the example's Hairline and Contrast brands, light and dark.

Details: [token boundary §3.0](prd-foundation-components.md#30-token-layer-rule), [color](prd-foundation-components.md#31-color), [type](prd-foundation-components.md#32-typography-font-and-its-variants), [spacing](prd-foundation-components.md#33-spacing), [radius](prd-foundation-components.md#34-radius), [motion](prd-foundation-components.md#37-motion), [shipped theming](https://rakit-ui.netlify.app/concepts/theming/).

## Customization: today versus approved migration

**Shipped today:** use the theme extension and the specific component's documented parameters. For example, `PaymentButton` exposes `variant`, `size` and `width`; its defaults are `primary`, `medium` and `fill`. It also accepts `PaymentButtonStyle` through `style`, and `PaymentButtonTheme` supplies shared/per-variant family defaults (D100). Fields (text, search, text area, select, date, date-range field, currency and the forms composed from them) take fill, resting outline, corners and input typography from the theme-only `PaymentFieldTheme` (D102); they have no instance `style`. Content composition already exists through APIs such as `PaymentBox.children`, `PaymentInline.rich` with typed spans, `PaymentSection.child` and view/page slots. Availability varies by family; check the component Props table and generated API instead of assuming every component supports the same customization.

**Adoption and example order (D98/D100):** teach and adopt in this order. Skip any surface a family does not ship; its Props table is the boundary.

1. Shared defaults: `PaymentTheme`, `PaymentType`, `PaymentMotion`, configured once.
2. App or scoped family theme (`PaymentButtonTheme`, `PaymentFieldTheme`) for a product-wide or subtree-wide look.
3. Named host preset for an intentionally repeated subset or feature-specific look that a scoped theme would over-apply. It is a host function or value, not kit API. Theme-dependent presets take `BuildContext` and resolve tokens from the current theme so light/dark and brand changes apply; never freeze resolved colors in a top-level `final`.
4. Inline instance `style` only for a one-off exception, setting only the differing fields. A family without instance `style`, such as fields, uses a scoped theme around that one instance instead.

The everyday example omits `style` and uses only semantic `variant`/`size`/`width`. Repeated raw inline styling is never the default teaching. Do not invent custom variants, preset APIs or a utility-class styling DSL.

**Migration status:** Button (D100), theme radius roles (D101), the field family (D102) and toast theme scope (D103) are implemented. The family review is recorded in the [D98 family disposition](decisions.md#d98-family-disposition): each exported family's surfaces, the gaps D100–D103 resolved and the deliberate limits. Host adoption is shown by two checkout compositions in `example/lib/compositions/host_checkout.dart`. D98 is implemented and locally verified as of 3 November 2026, including combined tests, Android light/dark captures and independent review. This is not a package publication or deployment. **Rule for any later gap:** add a typed instance override or scoped family theme only when a demonstrated gap requires it, through a new decision. Resolve selected variant/size semantic defaults, then the nearest family theme, then non-null instance overrides. Missing overrides preserve resolved values; derive scoped themes from their parent and preserve unrelated extensions. Document supported properties and state resolution per family. Prefer suitable Flutter style types without promising unrestricted forwarding.

Appearance overrides do not reorder structure. Use children/slots for structure and builders only when component-owned data/state is required. Repeated overrides belong in a shared host theme or named host preset, per the order above. B2 still governs kit defaults; documented host theme/style inputs are permitted customization boundaries.

Keep 48 dp hit areas, focus, semantics, busy/repeated-action protection, reduced motion, reachable actions at 320 dp/200%, and payment invariants. Constrain unsupported geometry rather than forwarding fixed sizes blindly. Host content and color-pair responsibilities remain explicit. Existing state ownership and source compatibility/default rendering stay intact unless a separate decision authorizes a change.

Migration order: Button pilot, related family batches, then two structurally different host checkout compositions using the same foundation and host data/callbacks. Review every exported visual family; models/formatters and already-composable APIs need no artificial styling surface. Future copyable blocks are host compositions, not a required runtime layer.

D106 adds Soft, a third example host preset, by tokens only: a tinted page, a host inset panel (`SoftInsetPanel`), an indigo accent and radius roles 8/12/16/20. Hairline stays the default; see [design research §9](design-research.md#9-showcase-themes).

D104 connects the invoice and recovery compositions in `example/lib/compositions/host_checkout_journey.dart`. It demonstrates one attempt through lost-response/offline recovery to its matching confirmed receipt. It is host source with injected callbacks, not a package runtime; persistence, price/auth checks and effects stay with the host. See the Checkout pattern documentation for adoption and session identity.

Full contract and acceptance: [D98 in §2](prd-foundation-components.md#customization-and-composition-contract-d98). Do not invent API names for this migration.

## Quality bar and state stories

Every applicable [B1–B13 requirement](prd-foundation-components.md#the-button-bar-tier-1-quality-checklist) remains a gate:

| Rules | Daily check |
| --- | --- |
| B1–B3 | Exported, documented API; semantic defaults; light/dark rendering. |
| B4–B6 | 320 dp at 200% text without clipping and with reachable primary action; targets ≥48×48 dp at every size; text contrast ≥4.5:1, control/state marks ≥3:1. |
| B7–B9 | One semantic control node with role/state; keyboard activation and visible focus; reduced motion follows both flags, with named SDK exceptions. |
| B10–B11 | Built-in en/id strings overridable by parameter; host effects and secrets stay outside the kit. |
| B12–B13 | Purpose, specimen, usage, closed variants and when to use them, states, do/don't, content, accessibility, Props, related docs; real pattern/example use or recorded owner approval. |

Choose applicable states from [§4](prd-foundation-components.md#4-components-how-to-read-the-matrices), including disabled reasons, busy, invalid, empty/error/retry and pending/unknown. A finished upload never proves KYC; timeouts and elapsed countdowns never prove failure or success. Fees remain visible, changed terms require re-approval, snapshots reconcile without stale overwrites, and refunds remain a separate lifecycle. See [product invariants](../PRD.md#8-state-dan-invariant) and [integration](integration.md).

## Interaction and responsive rules

- D29: small visuals still occupy a ≥48 dp hit box. Busy actions prevent repeated activation; server-side deduplication remains host-owned.
- D65–D67: both reduced-motion flags produce zero kit animation; keep the named SDK exceptions honest. D94 limits content handoffs to the recorded recipes; frequent ready-state data changes stay instant and outgoing content cannot take focus or taps.
- D92: confirm, search, menu and focus overlays use the window's shortest side, under 600 dp for phone forms. Content layout still follows available width. D45 confirms use phone sheets and wide dialogs with safe dismissal/focus behavior.
- D77: newest kit toast replaces showing/waiting toasts. D95 places it above the current route's pinned kit footer using the recorded scaffold/route rules, without splitting the toast queue.

Sources: [§8 current decisions](prd-foundation-components.md#8-decisions), [motion spec](prd-foundation-components.md#37-motion), [focus and press](prd-foundation-components.md#38-focus-and-press). Keep component-specific interaction detail in its spec.

## Variants, documentation and proof

Use the closed variant sets in shipped APIs; a brand is not a variant. New non-parity variants require two real uses that differ in meaning. Follow [§9 governance](prd-foundation-components.md#9-variant-governance) and D34 compatibility: old renamed APIs remain deprecated for the compatibility window, with removal scheduled for 0.2.0; they are still present today.

Write one focused widget test per changed host-visible story and representative affected-rule checks. Test relevant failure/disabled/custom-content edges, not every combination. Follow [AGENTS.md](../AGENTS.md) for final-head checks and the flow test only when its path changes. Public API changes regenerate API data; documentation-only organization adds no runtime verification claim.

Use [§10 specimen requirements](prd-foundation-components.md#10-docs-and-specimen-requirements). D81 makes documentation captures Android-only without changing product scope. D82 uses keyed specimens capped at 1200 dp; D90 continues taller specimens in ordered parts. Overlays/states keep real screen size. Inspect every capture before claiming visual proof, and follow the shared device lock/lifetime rules in AGENTS.md.
