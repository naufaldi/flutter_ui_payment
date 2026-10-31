# Design research and art direction

Date: 30 October 2026. Phase: research only. No production component, gallery or website code was changed.

**Verdict.** The components behave correctly, but they look like stock Material 3. Every section is a large rounded card. Teal tonal pills and tinted icon circles appear on every screen, and the end-user UI and the developer gallery share one visual voice. None of that comes from the payment task. The recommended direction is **Statement**: a flat ruled ledger, a monospace face for money and references, and a status band whose *pattern* (not only its color) separates "pending" from "unknown". It is the furthest of the three options from default Material, and it makes the critical state hardest to misread.

> **Update, 30 Oct 2026: the owner chose a Stripe-like base.** "Stripe-calm" is now the direction: the patterns worth taking from Stripe Checkout, plus Statement's status signals. Statement's paper, monospace amounts and double rule are dropped. See [section 0](#0-current-direction-stripe-calm). Sections 3–4 below are kept as the record of how the choice was made.

Visual board: [design-research/board.html](design-research/board.html) (open it in a browser; it uses Google Fonts). Stripe-calm options: [design-research/options.html](design-research/options.html) and [options.png](design-research/options.png).

## 0. Current direction: Stripe-calm

**What we take from Stripe Checkout** ([demo](https://checkout.stripe.dev/checkout), inspected):

- The order summary has no card: label left, amount right, a hairline only between the items and the total.
- The amount sits near the top, under the merchant, so the customer sees what they pay before the details.
- Payment methods are one bordered list with a 2 px ink outline on the selected row.
- The pay button carries the amount ("Bayar Rp102.500").
- The surface is white, corners are 6–8 px, and amounts use the system sans with tabular figures.
- In the gallery, controls sit in a panel outside the framed product.

**What we keep from Statement**, because Stripe shows no public screen for these states:

- A hatched band means unknown and a solid band means pending.
- "Jangan bayar lagi." comes first on an unknown result.
- Times are labeled ("dikirim 20.08", "sisa 23:59:51").
- There is one primary action, and never a pay-again on pending or unknown.
- Monospace is used only for reference and virtual-account numbers.
- The 10 constraints in section 5 still apply. The exception is constraint 3: amounts are now sans with tabular figures, and mono is for references only.

**Why not all of Stripe:**

- It is the most-imitated payment look, so a clone reads as generic.
- Its finish comes from Stripe's own font, brand color and shadow tuning, and our package ships with no fonts.
- It offers no pattern for the unknown outcome, which is the main job of this kit.

### New references (30 Oct 2026)

| Reference | Type | Capture | Pattern to adapt | Do not copy / limits |
| --- | --- | --- | --- | --- |
| [Uber Base: Feedback & status](https://base.uber.com/6d2425e9f/p/51dcce-feedback--status) | Real, public design system (Uber) | `refs/uber-base-feedback-status.png`, `refs/uber-base-home.png` | Two principles. **Proportional urgency**: match feedback intensity to severity, and reserve interruptive patterns for critical warnings. **Multi-modal**: never rely on one channel; pair color with text and icons. Both support the band + word + sentence status. Also strict black and white with heavy display type. | The Uber Move font (proprietary), the illustration style. No Uber rider or Eats checkout was inspected: those need a login and a cart. |
| [Base Web: Payment Card](https://baseweb.design/components/payment-card/) | Real, open-source component docs (Uber) | `refs/uber-baseweb-payment-card.png` | A live specimen above a props panel (toggles for `disabled`, `error`, `positive`, size), then code. A good model for the gallery's state selector. | The placeholder copy ("Please enter your credit card number…"), and card entry itself is out of scope for this kit. |
| [Polar checkout (docs image)](https://polar.sh/docs/features/checkout/embed) | Real product; static image from official docs, not operated | `refs/polar-checkout-embed.png` | The summary sits **below** the form: muted "Subtotal / Taxes", then a bold billing-period line with a muted "/ yr" unit. An authorization sentence sits directly above the button. Polar embeds Stripe's Payment Element (Card / bank / wallet tabs), which shows Stripe-calm is the de facto developer standard. | The saturated blue button, the card form. The image is a still, so no interaction was verified. |
| [Polar landing](https://polar.sh/) | Real marketing page | `refs/polar-landing.png` | For our landing: a left-aligned two-tone headline (white line + grey line), a real product screen as the hero, monospace only for code-like labels, tabular amounts. | The dark-by-default look, the textured photo frame, the AI-billing copy. |

**Assumption:** "Polymer" was read as **Polar** (polar.sh), because Google's Polymer is a web-components library with no payment UI. Correct this if another product was meant.

**Attempted, not inspected:**

- **Xendit:** xendit.co returned a Cloudflare bot check ("Just a moment…"), so no Xendit UI was seen.
- **Shopify's Hydrogen demo store:** the product variants tried were sold out, so its checkout couldn't be reached.

### Three Stripe-calm options

All three share the base above. They differ in surface depth and type weight, which `emil-surfaces` and `emil-typography` treat as separate decisions. Sketches: `design-research/options.png`, using system fonts only.

| | 1 · Hairline (recommended) | 2 · Lift | 3 · Contrast |
| --- | --- | --- | --- |
| Idea | Stripe's summary on a flat white page | Closest to Stripe Elements | Uber Base's black and white |
| Surface | White, no shadows. Rules separate content; the method list is one bordered group. | Grey canvas `#F5F6F8` with **one** raised white surface per screen. Elevation is a layered shadow (1 px ring + 1–3 px + 4–10 px, 5–6% black), not a border; dark mode collapses it to a 1 px white ring at 9%. | White; rows on `#F3F3F3` fills, no borders |
| Methods | One bordered list, 2 px ink outline on the selected row | Separate raised tiles, 8 px apart | Filled rows; the selected row **inverts** to black with white text |
| Amount type | 32 px w600, −0.01 em | 32 px w600, −0.01 em | 40 px w700, −0.025 em (tight display tracking) |
| Radius | 6 button, 8 group | 6 button, 10 tile, 12 surface (inner radius derived: 12 − padding) | 8 everything |
| Unknown band | Amber hatch, 6 px | Amber hatch inside the raised status surface | Black/yellow caution hatch, 8 px, bold uppercase state line |
| Best when | A library dropped into unknown host layouts | The host app is already soft and card-based | A brand that wants a strong voice |
| Risk | Can look plain without a host brand | Drifts back toward stacked cards if a second surface sneaks in | Heaviest at 200% text; the inverted row and black button hold little room for a host brand |

**Decision (owner, 30 Oct 2026): accepted. 1 · Hairline is the kit default.** Implemented the same day (steps 1–4 of section 8); see the redesign table in [decisions.md](decisions.md). Native evidence: `example/build/screenshots_hairline/`. Step 5 (landing/docs website) is not started. **Not yet implemented** from section 5: the 2 px focus outline (constraint 6; focus still uses Material's default highlight) and the 0.96 press scale on compact controls (constraint 10; full-width buttons correctly do not scale, and `PaymentMotion.pressedScale` is currently unused). A library renders inside layouts it doesn't own. Flat rows nest safely inside a host's own cards and sheets; a raised surface (Lift) inside a host card recreates the card-in-card problem from the critique. Lift can still ship as a documented theme preset by setting an elevation token. Contrast is the pick only if the owner wants personality over neutrality.

**Contrast checks** (WCAG 2): ink `#1A1F36` on white 16.2:1 · muted `#5E6678` 5.8:1 on white, 5.3:1 on `#F5F6F8` · amber `#8A5300` 6.3:1 · unselected radio ring `#7A8396` 3.8:1 (darkened from `#9AA3B5`, which failed the 3:1 minimum for UI components at 2.5:1) · Contrast muted `#545454` 7.6:1.

**Token deltas from section 6** (Hairline):

| Token | Light | Dark | Change |
| --- | --- | --- | --- |
| `surface` | `#FFFFFF` | `#131417` | Replaces `paper`; no warm tint |
| `ink` | `#1A1F36` | `#ECEDF0` | Cool navy-black, matching cool greys |
| `inkMuted` | `#5E6678` | `#A2A8B5` | |
| `rule` | `#E3E6EC` (or ink at 10%) | `#2C2E35` | |
| `selectedOutline` | ink, 2 px | ink, 2 px | |
| `radioRing` | `#7A8396` | `#8E95A3` | Must stay ≥ 3:1 |
| `amountFontFamily` | null (system sans) | | Tabular figures required |
| `referenceFontFamily` | platform mono | | References and VA numbers only |
| `elevation` (Lift preset only) | layered shadow | 1 px white ring at 9% | New, optional |

The dark values are proposals, carried over from section 6's method. They must be contrast-checked in implementation step 1. Reference captures: [design-research/refs/](design-research/refs/). They are third-party screenshots for research only and must be removed or excluded before the repository goes public (see its README). Direction sketches: [design-research/directions.png](design-research/directions.png).

## Method and evidence

- Current UI: native PNGs in `example/build/screenshots/`, opened and inspected: `android_refined_checkout_light(_200)`, `android_refined_status_unknown_dark`, `android_kit_history`, `android_kit_history_detail_unknown`, `android_kit_navigation_drawer`, `android_kit_sheet_pending`, `android_kit_promo_200`, `android_kit_checkout`, `android_receipt_light`, `ios_kit_video_playing`.
- References: captured on 30 Oct 2026 with one task-owned headless `agent-browser` session. Mobile captures are 400×860 and desktop captures are 1280×820. The session was closed after capture. The user's Chrome and the existing `browser-harness` daemon were not used.
- Skills used: `faldi-mode`, `emil-unslop-design`, `emil-design-foundations`, `emil-ui-polish`. `emil-ask-emil` and `emil-get-creative` are user-invoked only and refused model invocation. This document is **not** their output; run `/emil-ask-emil` or `/emil-get-creative` yourself if you want those passes.
- Reference screenshots are research material, not licensed assets. Nothing from them ships.

## 1. Critique of the current UI

The five most consequential issues, each confirmed in a screenshot:

| Before | Proposed direction | Why |
| --- | --- | --- |
| Every section is a 16–18 px-radius bordered white card on a tinted canvas. Checkout nests a bordered, tinted method tile inside a bordered card. Status and receipt stack two cards: hero, then "Detail" (`android_refined_checkout_light`, `android_receipt_light`, `android_kit_history_detail_unknown`). | Flat document on one paper surface. Groups are separated by space and hairline rules. A box appears only around something that is an object: the selected method, a VA number to copy. | Card padding, borders and inter-card gaps take a large share of the first screen and push the method list below the fold (only one method is visible in `android_refined_checkout_light`). When everything is a card, nothing is. |
| The total appears twice on checkout: a 44 px figure in the summary card and 34 px in the action bar. The "Total" label sits top-aligned against a giant number. Line-item values are bold, the same weight as the total (`android_refined_checkout_light`). | One display-size total, in the pinned action bar. The summary total is body-strong, closed with an accounting double rule. Line-item values are regular weight, and fee labels are muted. | Two competing totals with bold everywhere flatten the hierarchy. The customer has to find the number they are agreeing to. |
| Status is a centered icon-in-circle, a colored title and a centered paragraph. Unknown and pending share the same orange family. The unknown screen shows **"Terakhir diperbarui → Belum terkonfirmasi"**, a status placed in a timestamp field (`android_refined_status_unknown_dark`; code: `payment_status.dart:396`). In dark mode "Cek status" is a bright mint slab. | Status is a left-aligned block: a full-width 6 px band, an uppercase state word and the time. Unknown uses a **hatched** band and pending a solid one. "Jangan bayar lagi." is its own first sentence. The time row is omitted, or shows the real time of the last check. The primary action is ink, not neon. | Unknown is the riskiest state in the product (the customer might pay twice). It needs a signal that survives color blindness, a squint and a glance. Centered paragraphs read slower than a left-aligned list of what happens next. |
| Gallery fixture controls (`ready / loading / error / empty`, `stable / quote changed`) look exactly like end-user filter chips (`Semua / Dalam proses …`). Both are pill chips with check icons, and both wrap to a second row. Class names (`TransactionHistory · TransactionListItem · TransactionDetail`) are 26 px bold mono headings that dominate the page, worst at 200% (`android_kit_history`, `android_kit_promo_200`). | Gallery chrome gets its own quieter layer: a "workbench" surface, a framed specimen, a compact state selector outside the frame, and class names as 12 px mono captions. End-user filters become a scrollable text-tab row. | A reviewer can't tell which controls belong to the product. That is the main reason the screenshots read as "slop": the dev harness is judged as UI. |
| Default Material accumulated everywhere: the tonal pill nav indicator, the tonal avatar "A" (a fake identity), 52–64 px tinted icon circles, mixed filled and outlined icons (filled bag beside outlined folder), and the Lumen brand's unchosen indigo in the drawer (`android_kit_navigation_drawer` is the example's Lumen theme, not the kit default). | One outlined icon set at one size, used only where it adds meaning. No decorative avatar. Selection is shown with an ink rule, not a tonal blob. Radii come from a 6 / 8 / 12 scale. Neither the teal nor the indigo is preserved by default. | Each choice is the median Material default. Together they are the "AI-generated" watermark the owner reacted to. |

Also observed (smaller, still real):

- **Mixed number format on one screen.** English checkout shows "Rp102,500" beside "Balance Rp350.000". The balance is a hardcoded Indonesian-format fixture string (`example/lib/adapters/fake_host.dart:420`), not `Money`. Readable, consistent amounts are a requirement, so this must be fixed in the slice.
- **History row wraps badly.** "Paket Belajar · 1 / bulan" wraps mid-phrase, the date wraps after "30", and the amount floats top-right of a three-line block (`android_kit_history`).
- **Promo at 200%.** "Kenapa ini?" is set larger than the sponsor disclosure and competes with it, and the icon tile adds nothing (`android_kit_promo_200`).
- **Video.** The playback controls under the picture are a good decision (`docs/decisions.md`) and should be kept. The teal frame is decoration.
- **Not every instance is wrong.** The pinned action bar, the stacked 200% action bar (`android_refined_checkout_light_200`), the sheet's "closing doesn't cancel" notice and the explicit "Minta pembatalan" (request cancellation) are good decisions. They need restyling, not removal.

## 2. Reference board

"Real" means a live product or official demo that was operated, not a still. Each entry was inspected in the capture listed.

### Payment and product components

| Reference | Type | Capture | Pattern to adapt | Why it fits our task | Do not copy / limits |
| --- | --- | --- | --- | --- | --- |
| [Stripe Checkout demo](https://checkout.stripe.dev/checkout) | Real product, official demo | `refs/stripe-checkout-mobile.png`, `refs/stripe-checkout-desktop.png` | Flat order summary with no card: label left, amount right, a hairline between groups only, and "Total due" at the same size as the rows but heavier. The promo code is shown as a removable inline token. Shown in IDR. | This is exactly our `PaymentSummary` job. It proves a summary needs no container and no oversized total to be clear. | Stripe's purple and wordmark. The decimal IDR ("IDR 539,354.21") is Stripe's FX rendering, wrong for our integer Rupiah. Apple Pay first is a US default. |
| [Midtrans Snap (sandbox demo store)](https://demo.midtrans.com/) | Real product, Indonesian, sandbox | `refs/midtrans-snap-methods.png`, `refs/midtrans-snap-va-list.png`, `refs/midtrans-snap-bca-pending.png` | **Pending VA screen:** the amount and order ID stay pinned top-left, a full-width "Pay within 23:59:54" band sits below them, the VA number is large with a "Copy" text action, "How to pay" is a disclosure, and the only primary action is **"Check status"**, never "pay again". Methods are grouped (recommended / all) as flat rows with bank marks. | This is the closest real match to our `PaymentInstructions` and pending state, in our market and our currency format ("Rp20.000"). It confirms "check status, not pay again" as the convention. | The yellow TEST ribbon, the empty white half-screen below the VA number, and the 3×5 bank logo grid (heavy, logo-dependent). Logos are third-party marks. |
| [GOV.UK Design System: Check answers](https://design-system.service.gov.uk/patterns/check-answers/default/index.html), [Confirmation page](https://design-system.service.gov.uk/patterns/confirmation-pages/default/index.html) | Real, research-backed public design system (the production system behind GOV.UK services) | `refs/govuk-check-answers.png`, `refs/govuk-confirmation.png` | No cards anywhere: bold label, value, inline "Change" link, a hairline between items. The confirmation is one solid block with the reference number, followed by **"What happens next"** in plain sentences. | This fits our review/re-quote and receipt screens, and our "explain what happens next" duty on pending/unknown. It is deliberately non-mainstream yet heavily tested for comprehension. | Crown branding, GDS Transport, the full-bleed green banner, and the underlined "Change" links repeated on every row (we keep the KYC header-level "Edit" decision). |
| [Mercury demo: Transactions](https://demo.mercury.com/transactions) | Real product, public demo | `refs/mercury-demo-transactions.png`, `refs/mercury-demo-transactions-mobile.png` | Right-aligned tabular amounts. A **failed payment's amount is struck through, with a small "Failed" tag** beside the payee. Hairline rows, date column, quiet initials avatars, filters as compact buttons. | This fits our `TransactionHistory`: status carried by the amount's typography plus a word, not by a 48 px icon circle. | The desktop table layout. On a 400 px viewport the table **cuts amounts off** (captured), which our readable-amount rule forbids. Also the US-bank density, the coach-mark tooltip, and the purple CTA. |

### Component presentation, landing and docs

| Reference | Type | Capture | Pattern to adapt | Why it fits | Do not copy / limits |
| --- | --- | --- | --- | --- | --- |
| [Stripe Checkout demo shell](https://checkout.stripe.dev/checkout) (Features / Style panel) | Real product demo UI | `refs/stripe-checkout-desktop.png`, `refs/stripe-checkout-style-panel.png` | **The gallery controls live in a side panel. The product sits inside a framed browser on a dotted workbench canvas.** There are toggles for features, a theme picker, and a device/locale switch under the frame. | This directly solves our gallery-versus-product confusion: controls and specimen never share a visual layer. | The browser-chrome mock, the purple, the hex-input theming (we expose `PaymentTheme` code, not a color picker). |
| [Forui docs: Button](https://forui.dev/docs/widgets/form/button) | Real Flutter library docs (benchmark) | `refs/forui-docs-button.png` | Grouped sidebar, then a breadcrumb, then the title, a one-line purpose and an "API Reference" link. A **Preview / Code** tabbed specimen, and an "On this page" panel listing every variant as an anchor. | This is our docs IA benchmark (`docs/web-plan.md` already follows it). Variant anchors map to our states (Ready / Pending / Unknown / Failed). | Forui's identity, its neutral-black shadcn look, and the ad slot. "A button." as a description is too thin; ours must also state what the host owns. |
| [Forui landing](https://forui.dev/) | Real marketing page | `refs/forui-landing.png` | Only the immediate product proof: real widgets rendered below the fold. | It shows that real output beats illustration. | **Anti-reference for the hero.** The "New" pill badge, a centered two-line headline, two buttons and a generic widget collage: this is the template `emil-unslop-design` names as generated. |
| [teenage engineering: OP–1 field](https://teenage.engineering/products/op-1) | Real product marketing | `refs/te-op1-product.png`, `refs/te-op1-specs.png` | The product itself, rendered large, *is* the hero. The type is a light-weight grotesk with a small outlined tag ("field") as the only label device. Warm-grey neutrals, line-drawn nav marks, almost no color except a functional accent. | Our landing should lead with a large real specimen (the unknown-state switcher) and one restrained type voice. It is distinctive without gradients. | All-lowercase copy, centered paragraphs, dependence on studio photography, and hardware skeuomorphism inside payment UI. |

### Inspected and rejected, or inaccessible

- [wise.design](https://wise.design/) loaded (`refs/wise-design-home.png`), but it is a brand moodboard carousel. `wise.design/components` returned **404**. No Wise product UI was inspected, so no Wise pattern is claimed.
- No Dribbble/Behance concepts were used. Every reference above is a real product, official demo or production design system.

## 3. Three visual directions (first round)

*Superseded by section 0. Kept as the record of the first round.*

Each direction changes containment, type pairing, density, surfaces and status communication, not just the accent color. Sketches: `design-research/directions.png` (HTML sketches, not Flutter output).

### A. Statement: a ledger, not cards

- **Idea:** a bank statement or a well-set receipt. One paper surface; ruled groups; money and references set in a monospace face. The signature is the bookkeeping **double rule under the total**.
- **Type:** IBM Plex Sans for UI text and IBM Plex Mono for amounts, references, VA numbers and countdowns (both OFL 1.1, bundled in the example, not the package). The package default falls back to the platform sans with tabular figures through the existing `amountFontFamily`.
- **Density:** compact. Rows have 48 dp targets with 12 px vertical padding, and no card padding.
- **Palette:** ink on warm paper (`#17181C` on `#F7F6F2`). The primary action is ink, so the brand is optional and host-supplied. Tone hues appear only in the status band and the amount state.
- **Surfaces/radius:** no cards. A 1 px rule separates groups. Radii are 6 for controls, 8 for the selected-method and VA-number boxes, and 12 only for the sheet's top corners.
- **Icons:** one outlined set, 20 px, used only in the status band, navigation and genuinely ambiguous actions. Row icons are deleted.
- **Status:** a full-width 6 px band above an uppercase state word. A solid band means pending and a **hatched** band (caution-tape stripes) means unknown. Failed strikes through the amount. Success is a solid green band plus "Berhasil".
- **Motion:** almost none. The status band and word cross-fade in 160 ms. Amounts never count up. The countdown changes digits with no animation.
- **Risk:** it can feel austere on promo and video, and mono amounts run wider at 200%.

### B. Slip: a counter receipt

- **Idea:** the payment as a physical paper slip handed over a counter (struk). A perforated tear line separates "what you owe" from "how you pay". Status is a rubber-stamp mark.
- **Type:** a condensed display grotesk for amounts (e.g. Barlow Condensed, OFL) with a humanist sans for text. Amounts are big and tall.
- **Density:** medium, generous around the amount and tight inside the slip.
- **Palette:** cream slip on a cool grey counter, with a vermilion stamp accent. Ink text.
- **Surfaces/radius:** one slip object per screen with a 2 px radius and scalloped or perforated edges. The surrounding canvas stays flat.
- **Status:** an outlined, slightly rotated stamp ("MENUNGGU", "BELUM PASTI").
- **Motion:** the stamp lands with a 120 ms scale from 1.04 to 1. The tear line is static.
- **Risk:** it is skeuomorphic and gimmicky after the third screen. A rotated stamp is hard to read at 200% and for screen magnifiers. The slip metaphor doesn't extend to navigation, video or promos.

### C. Instrument: a device panel

- **Idea:** inspired by hardware panels. Flat warm-grey panels separated by 1 px. Small uppercase mono labels. A large light-weight amount like a display readout. Status is an indicator dot plus a word.
- **Type:** a grotesk at light weight (300) for display amounts, and uppercase mono 11–12 px labels with wide tracking.
- **Density:** high, like a spec sheet.
- **Palette:** cool-warm grey panels with one signal orange used only for the primary action. Status uses LED-like dots.
- **Surfaces/radius:** a keycap radius of 10 on every control, and panels with no radius.
- **Status:** a 10 px dot with a state word and a segmented progress bar.
- **Motion:** pressed keycaps scale to 0.96 in 100 ms. The dot pulses only while the host reports an active check, and is static under reduced motion.
- **Risk:** it reads as a tool for engineers, not for a person paying for a course. Light-weight amounts and tiny uppercase labels fail at small sizes and lose contrast in dark mode. A dot is a weak signal for "do not pay again".

## 4. Recommendation, first round: Statement (A)

*Superseded by Stripe-calm (section 0). Its status, copy and checkout-structure decisions carry over; the paper surface, monospace amounts and double rule do not.*

This is the most distinctive direction that keeps the dangerous state the clearest. Its point of view comes from the domain (ledger, receipt, accounting double rule), not from decoration, and it scales to every module without a metaphor breaking.

**Checkout in Statement.** The merchant name is in the 20 px title style, with the order reference in 13 px mono beneath it. No avatar, no card. Line items run label-left (ink) and value-right (mono, regular). The fee label is muted. A hairline sits between the items and the total. "Total" is sans 600 with its amount in mono 600, closed by a double rule. The method list is flat radio rows. The selected row is the only box on the screen: a 1.5 px ink outline at radius 8. The balance appears as muted mono, formatted by `Money`. The pinned action bar keeps the one display-size total (mono 30 px) and an ink "Tinjau pembayaran" button at radius 6, 48 dp tall. At 200% the bar stacks, as it does today. After a re-quote, the changed line shows the old amount struck through next to the new one, and the action reads "Setujui total baru" (approve new total).

**Pending (host says "waiting for transfer").** A solid amber band sits above the line "MENUNGGU PEMBAYARAN · sisa 23:59:51" (the countdown is labeled and in tabular mono, with no animation). Next comes the amount in mono 30. Then the VA number sits in a sunken radius-8 box, set in mono and grouped in fours, on its own full-width line (the Midtrans sandbox issued a 22-digit number). The "Salin" (copy) action sits on the label line and confirms with a check for 1.5 s. "Cara bayar" (how to pay) is a disclosure. The primary action is "Cek status". There is no pay-again.

**Unknown (submit timed out).** The band is **hatched** amber and paper, above "HASIL BELUM DIKETAHUI · dikirim 20.08" (the time is labeled, so the slot never mixes a time of day with a countdown). The first sentence, in body-strong, is "Jangan bayar lagi." (don't pay again). Then one plain sentence: "Pembayaran sudah dikirim, tetapi hasilnya belum diterima. Cek status untuk melihat hasilnya." (the payment was sent but no result has arrived; check status to see it). The copy must not promise an automatic update, because widgets never poll and the host owns polling. It must not name "the bank" either, because balance and wallet methods have none. Host-specific "what happens next" text belongs to the host. Rows show the reference (mono), the submitted time, and the last check, if a snapshot exists. The fake "last updated: not confirmed" row is removed. The primary action is "Cek status". "Hubungi bantuan" (contact support) is a text link that carries the reference. There is no pay-again, matching the PRD invariant.

**Tradeoffs.**

- It gives up the friendly, rounded consumer feel. Promo and video will look sober; that is intended, because a promo should not outshout a payment.
- Mono amounts run wider. In the board at 30 px, Plex Mono 500 measured 4.6% wider than Plex Sans 600 for "Rp102.500" and 9.6% wider for "Rp12.345.678.900" (browser measurement; Flutter may differ). At 200%, `AmountText` already scales down rather than clips, so step 2 must verify with the longest Rupiah value.
- Fonts are not free for hosts: the package stays dependency-free, so hosts who skip the fonts get platform sans with tabular figures. The direction must therefore hold up without the fonts, and the slice will be judged on system fonts first.
- A hatched band needs a small custom painter. It is cheap, but it is a new visual primitive to maintain.
- It is less "brandable" by color alone. Hosts brand through the action color, type and radius tokens instead.

## 5. Design constraints

1. **No card by default.** A container needs a reason: it is selectable, copyable or dismissible. Groups are separated by 24 px of space, then a 1 px rule if space alone is ambiguous. A bordered box never nests inside another.
2. **One display-size amount per screen.** It belongs to the place where the customer commits (the action bar) or to the result (the status/receipt). Every other amount is body size.
3. **Money and references are mono with tabular figures, formatted only by `Money`/`MoneyFormat`.** Hand-typed amount strings are not allowed in fixtures or widgets.
4. **Status uses four signals:** a band pattern (solid / hatched / none), a tone color, an uppercase state word and an explanation sentence. Unknown never shares pending's pattern. Strike-through is reserved for failed or canceled payments. A refunded payment keeps its original amount unstruck and its success band. The refund appears in its own ruled section with its own state, because the PRD treats a refund as separate from the original payment.
5. **Left-align everything in end-user UI.** Centered text is allowed only on a single line under 30 characters.
6. **One primary action per view, in ink.** Secondary actions are ghost buttons with a 1 px rule outline. Tertiary actions are text links. A destructive action sits separated by whitespace and never directly beside the confirm button. Every interactive element shows a 2 px focus outline at a 2 px offset, in ink (light theme) or paper (dark theme). The outline is never brand-colored and never removed.
7. **Radii come from the scale only:** 6 (controls), 8 (single selectable or copyable box), 12 (sheet top). No pills, except a count badge. Nested radius = outer − padding.
8. **Icons:** one outlined set, 20 px, no tinted circles. Delete any icon whose label already says the same thing.
9. **Gallery chrome never uses end-user component styles.** Fixture selectors, class-name captions and the workbench surface have their own tokens (section 7).
10. **Motion is limited to feedback and state change:** 160 ms ease-out cross-fades, sheets 280 / 200 ms, no amount animation, nothing on scroll, and all durations go to zero under reduced motion. Pressed state: compact controls scale to 0.96 over 100 ms. Full-width buttons darken their fill by 8% instead, because scaling a 320 dp slab moves its edges about 6 dp and reads as a lurch rather than a press.

## 6. Token proposal (Statement; see the Hairline deltas in section 0)

Values were checked with the WCAG 2 formula. All text tones are at least 5.3:1 on their surface in both themes. The rule color is decorative, and every interactive outline uses ink (at least 3:1).

| Token | Light | Dark | Notes |
| --- | --- | --- | --- |
| `paper` (surface, scaffold) | `#F7F6F2` | `#131417` | Same surface for the page and its sections |
| `raised` (sheets, menus) | `#FFFFFF` | `#1B1C20` | Dark: topmost is lightest |
| `sunken` (VA number, code) | `#EEECE6` | `#0E0F11` | |
| `rule` | `#D9D7D0` (or ink @ 12%) | `#2C2E33` solid | Alpha in light mode, solid in dark |
| `ink` / `textPrimary` | `#17181C` (16.4:1) | `#ECEAE4` (15.3:1) | |
| `inkMuted` / `textSecondary` | `#5A5D66` (6.1:1) | `#A2A5AD` (7.5:1) | |
| `action` / `onAction` | `#17181C` / `#F7F6F2` | `#ECEAE4` / `#131417` | Host may brand `action` |
| `success` | `#1D6B45` (6.0:1) | `#6FC79B` (9.1:1) | |
| `pending` (warning) | `#8A5300` (5.9:1) | `#E3A64C` (8.6:1) | Unknown = same hue + hatch |
| `danger` | `#A8231C` (6.7:1) | `#F2897F` (7.6:1) | |
| `info` | `#2A55A8` (6.6:1) | `#93B2F0` (8.7:1) | |

| Scale | Values |
| --- | --- |
| Type (logical px, size/line, before text scaling) | amount display: mono 30/36 w500 · title 20/26 w600 · body 15/22 w400 · body-strong 15/22 w600 · label 13/18 w500 muted · state word 12/16 w600 uppercase, +0.08 em · reference: mono 13/18 |
| Space (4 px base) | screen gutter 20 · row padding 12 vertical (≥ 48 dp target) · related 8 · group 24 · section 32 · band-to-state-word gap 10 |
| Radius | control 6 · box 8 · sheet top 12 · badge full |
| Rules | hairline 1 · selected outline 1.5 (ink) · status band 6 (full width, above the state word) · total double rule 1 + 2 gap + 1 |
| Motion | state cross-fade 160 ms ease-out · sheet 280 in / 200 out (unchanged) · press: compact 0.96 scale / 100 ms, full-width 8% darker fill · copy confirmation 1.5 s · reduced motion = 0 |
| Focus | 2 px outline, 2 px offset, ink on light / paper on dark; never brand-colored |

**API impact (to review before implementing, all additive with defaults):**

- `PaymentTheme` gains `raised`, `sunken`, `rule`, `radiusControl`, `radiusBox` and `referenceFontFamily`.
- `radius` stays as the box radius for compatibility.
- `ToneColors` gains an optional `pattern` (solid / hatched).
- Optional: a `density` field.
- `fromColorScheme` keeps deriving everything, so hosts without the extension still work.

## 7. End-user components versus the developer gallery

| | End-user component | Gallery chrome |
| --- | --- | --- |
| Surface | `paper` | "workbench": cool grey `#E9EAEC` / `#0B0C0E` with a faint dot grid. The specimen sits inside a 1 px framed device area (Stripe pattern) |
| Headings | Human task names ("Riwayat transaksi") | Specimen title in human terms + class names as a 12 px mono muted caption |
| Controls | Filters as a scrollable text-tab row with an ink underline | Fixture state selector: compact segmented control or dropdown in gallery-only style (mono 12, no check icons), placed **outside** the specimen frame |
| Code | None | Preview / Code tabs per specimen (Forui pattern) |
| Locale / theme / text scale | Inherited | One toolbar under the frame (Stripe's device/locale switch), shared by every specimen |

## 8. Sequenced implementation handoff

Each step ends with native screenshots (light and dark, id and en, 100% and 200%) inspected against this document, then an owner look before the next step. Behavior, public APIs and tests stay as they are unless a step says otherwise.

1. **Foundation.** Add the tokens above to `PaymentTheme` (additive). Add the Stripe-calm Hairline example theme on system fonts, so no font bundling is needed. Optionally add a Lift preset to prove the elevation token. Add the rule and hatched-band primitives. Fix the fixture amount strings to use `Money`. Exit: the token page renders in both themes, and the contrast table is reproduced.
2. **Reference slice: checkout + pending + unknown.** Restyle `PaymentSummary`, `PaymentMethodPicker`, `PaymentActionBar`, `PaymentConfirmation` (re-quote), `PaymentInstructions` and `PaymentStatusView` to Stripe-calm Hairline. Remove the false "last updated" row. Exit: the three Demo screens pass the constraints, at 200% and in dark mode, and the owner approves the slice. **Stop here if the owner rejects the direction.**
3. **Reusable components.** Restyle receipt, history (struck-through failed amounts, text-tab filters, no wrapping metadata), sheets, `ActionTile`/menu, navigation (ink rule selection, one icon set), promo (one disclosure caption line, no icon tile), video frame, then KYC. Expand nothing.
4. **Gallery.** Introduce the workbench, specimen frame, outside-the-frame state selector, mono class captions and Preview / Code. Retire the pill fixture chips.
5. **Landing and docs.** Only after the product language is approved. Lead with a large real specimen (the unknown-state switcher from `docs/web-plan.md`) and a left-aligned promise: no pill badge, no gradient, no three-card feature grid. Docs follow the Forui IA with state anchors and a "Host owns" note per component. `docs/web-plan.md`'s visual section is superseded by this document; its IA and product answers still stand.

## Open uncertainties

- Font choice: IBM Plex is a recommendation from this research, not owner-approved. Any OFL sans + mono superfamily with tabular figures and good Latin coverage satisfies the constraints.
- Hatched band legibility under Android's high-contrast text and in dark mode is assumed and must be checked in step 2.
- The direction sketches are HTML, not Flutter. Flutter text rendering, especially Plex Mono at 200%, may change widths; step 2 is the real test.
