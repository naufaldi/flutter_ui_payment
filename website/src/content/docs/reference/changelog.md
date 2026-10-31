---
title: Changelog
description: Changes in flutter_ui_payment, copied from CHANGELOG.md in the repository.
---

Copied verbatim from `CHANGELOG.md`. Version 0.1.0 is unreleased and not published.

## Design system Phase 4D-2 (2026-11-01)

- Delivers the 4C–4D specimen captures: 45 new images and 6 refreshed Code/Tabs images.
- Add page modules and detail/overview pages; code wrapping, edge fades and fitted-tab fallback. Closes #18.

## Design system Phase 5-1 (2026-11-01)

- Label phone table selection, show the current sort and allow restoring host order.
- Align sign-in disclosure and brand, context actions, stacked footers, settings Save, switch labels and link-only detail properties.
- Accept property, table and chart modules directly in detail and overview pages (source-compatible widening).
- Add `TransactionDetail.onCopyReference`, `IdentityFieldSpec.group`, and optional `PaymentSearchField.focusNode`.
- Add `IdentityFieldKind.search`. Migration: hosts with exhaustive switches add a `search` case.

## Design system Phase 4D-1 (2026-11-01)

- Add context, full-page, focus, settings, sign-in and onboarding view bodies.

## Design system Phase 4C-3 (2026-11-01)

- Add responsive DataTable with typed cells, paging, selection, actions and local sort/filter. Closes #17.

## Design system Phase 4C-2 (2026-11-01)

- Add responsive ButtonGroup and host-owned TaskList; migrate status and dialog actions.

## Design system Phase 4C-1 (2026-11-01)

- Add PropertyList, responsive Table and LoadingSkeleton.table.
- Status, receipt and transaction details compose PropertyList using the existing InfoRow layout.

## Design system Phase 4B-2 (1 Nov 2026)

- Add Chip, ChipList, SearchField and DateRangePicker, with value/preset/granularity models.
- Add PaymentLocalizations.formatDateRange.
- Applied promo codes use a removable chip; pressable meter rows use list anatomy.
- Improve text and currency specimen spacing. Delivers the 4A–4B specimen captures.

## Design system Phase 4B-1 (1 Nov 2026)

- Add TextArea, Select (single/multiple), DateField and FormFieldGroup.
- Identity fields support text, date and choice; reviews localize date and choice labels.
- Date-kind identity values are ISO calendar dates (yyyy-MM-dd).
- Add currency allowlists and host currency change callbacks; app-wide localized date hints.
- The example KYC form adds date and occupation controls; upload glyph is outlined.

## Design system Phase 4A (1 Nov 2026)

- Add token-only Box, Inline, Icon, Image and Code primitives.
- Add list images and accordion media; deprecate leading.
- VA references have a muted tag and grouped speech. KYC photos retain loading and failure semantics.
- Medium row glyphs scale with text; KYC tips use the 20 dp glyph.
- API generation hides all private constructors.

## Design system Phase 3B (1 Nov 2026)

- Add PaymentIconButton, PaymentLink and PaymentCopyButton with semantic variants, 48 dp targets, focus and press feedback.
- Add PaymentBanner.onDismiss, PaymentMenu.trigger and PaymentButton.focusNode.
- The copy glyph is now outlined. Success shows a 1.5 s check; failures stay inline. Receipt banners report share feedback only; copyFailedReceipt remains API but is no longer used by the kit.
- Policy links align to the gutter with trailing external glyphs. Media and navigation icons use secondary text; all migrated controls gain shared focus/press treatment and ink tooltips.
- Delivers the 2E–3B specimen captures.

## Design system Phase 3A (1 Nov 2026)

- Add PaymentTextField and its controlled search constructor, with persistent labels, type traits and host-error hiding.
- Currency fields gain errorText and hiddenElements. Currency, promo, identity and history fields share state edges and error icons.
- TransactionHistory is stateless. Search uses a 20 dp glyph, accent focus edge and clear-to-refocus behavior.
- Identity update descriptions gain a warning icon; empty promo errors clear on edit.

## Design system Phase 2E (1 Nov 2026)

- Charts gain named series, axis/grid controls, legends and money/percent/number units.
- **Breaking:** remove MeterSegment.color; use the category ramp. MeterSegment.value and ChartPoint.value are optional; supply measure for numeric units. Chart points may be omitted when supplying series.
- Meter legend rows support host actions. Sparklines support inspection.
- Meter swatches are 12 dp; chart headline spacing derives from typography.

## 0.1.0 (unreleased)

Design system Phase 2D-2 (1 Nov 2026):

* Add PaymentTab, size/fitted tabs and lazy state-preserving PaymentTabPanels. Arrow keys move focus only; Enter/Space activate, skipping disabled tabs.
* Breaking: PaymentTabs.labels becomes tabs of PaymentTab values.
* Checkbox adds indeterminate. Checkbox, radio and switch add errorText, required and hiddenElements with icon/text/edge validation and retained semantics.
* Add PaymentCurrencyField size, description and padFractionDigits. AmountInput remains a deprecated typedef until 0.2.0. Padding valid amounts on blur/submit emits no new value.
* Replace combined controls captures with focused specimens and deliver all Phase 2C/2D screenshots here (D27, owner scope revision).

Design system Phase 2D-1 (31 Oct 2026):

* Add PaymentList/PaymentListItem with values, sizes and id dispatch; PaymentMenu with item groups; PaymentAccordion/PaymentAccordionItem with separate actions.
* ActionTileGroup, ActionMenu, ActionMenuEntry and ExpandableSection remain deprecated aliases until 0.2.0. ActionTile wraps PaymentListItem with subtitle/onTap mapped to secondaryTitle/onPressed.
* Rows with neither handler nor disabledReason are now read-only, with an ink title and no button role. Disabled rows retain their reason.
* Fix the RTL chevron's double mirror. Separate the example's destructive menu item into a trailing group.

Design system Phase 2C (31 Oct 2026):

* Add PaymentBadge with urgent and optional tone icons, PaymentBanner, showPaymentToast and PaymentToastController, and tooltip placement/type/delay.
* StatusBadge, NoticeBanner and showPaymentSnackBar remain deprecated until 0.2.0.
* Breaking: PaymentSpinner.size takes PaymentSize.small, medium or large instead of a number. Add a cancellable delay.
* Warning and busy use outlined glyphs; banner gap is 12 dp; badge icons scale up to 1.6×. Toasts and tooltips use flat ink tokens.
* Toasts with actions now time out after at least 6 seconds, scaled by reading length. Pending and accessible actions persist. Content disposal cancels the timer.
* Tooltips open immediately on keyboard focus and dismiss on Escape. Banner actions assert hug secondary or quiet buttons in debug.

Design system Phase 2B (31 Oct 2026):

* PaymentButton adds size, width and autofocus. Small draws at 36 dp inside a 48 dp hit box; medium stays 48 and large draws at 56. Hug width has a 112 dp minimum; labels wrap. Desktop/web density changes medium from 40 to 48 dp.
* Confirm dialogs use hug PaymentButtons with neutral focus rings, safe autofocus and 8 dp spacing when stacked. At 320 dp confirm stacks above cancel.
* AmountTextVariant adds caption, row, total, large and display. Replace deprecated emphasis: true with variant: AmountTextVariant.display before removal in 0.2.0.
* CountdownText defaults to label typography with tabular figures.
* Button and amount specimens cover states and sizes. Native screenshot regeneration remains blocked by device support.

Design system Phase 2A (31 Oct 2026):

* Consent and changed-total rows use PaymentCheckbox, aligned on the content gutter with label typography and a 48 dp minimum.
* Method selection shares the radio mark; unavailable methods show a thin disabled ring and their reason.
* Horizontal pattern rules use PaymentDivider. Material 2 and custom DividerTheme hosts now receive a consistent 1 dp thickness.
* Video loading uses a 32 dp white spinner with 3.84 dp stroke, or a 32 dp hourglass under reduced motion.
* Failed photo decoding shows the illustrated capture frame. Row layout is shared internally; no public API change.

Design system Phase 1A (31 Oct 2026):

* Public `PaymentType`: `of`, `isLarge`, `bodyFor`, nine roles, `firstLineHeight`, `tabular` and `reference`.
* New closed token enums: `PaymentSize`, `PaymentWidth`, `PaymentSpace`, `PaymentRadius`, `PaymentTextRole`, `PaymentTextColor`, `PaymentFontWeight`, `PaymentIconSize`, `PaymentFieldPart`; `PaymentTheme.space` resolves spacing.
* `PaymentIcons` defines fixed meanings using existing glyphs.
* `PaymentLocalizations.formatDate` preserves calendar dates; `dateInputPattern` defaults to `DD/MM/YYYY` in both locales and is host-overridable.
* Deprecated `amountStyle(large:)`: migrate row amounts to `type.tabular(type.label)`; use `type.tabular(type.heading)` only when the old 600 weight is needed. `amountStyle(context)` remains the display alias.
* No visual change: shared helpers preserve existing arithmetic and glyphs.

First local version. Not published.

Charts and KYC capture (31 Oct 2026):

* New `PaymentLineChart`, `PaymentBarChart`, `PaymentMeterChart`, `PaymentSparkline` and `ChartModule`: money-only customer spending summaries with distinct pending, unknown and missing marks, host headlines, inspection and accessible summaries.
* New `MoneyFormat.compact` for chart axes and an internal shared hatch painter; StatusBand keeps its stripe geometry.
* New `showCaptureSourceSheet`, `CaptureFrameOverlay` and `KycCaptureGuide`: source intent, passive KTP/selfie framing, host photo review and upload states. No device access or image analysis.
* Example: synthetic camera photos, host rejection/retake flow, charts and capture gallery specimens. Permission follows source selection.
* Docs: chart layout pattern and component references with light/dark and large-text captures.

Visual redesign, "Stripe-calm · Hairline" (owner-approved, 30 Oct 2026; research in `docs/design-research.md`):

* Sections are flat (no card); the order summary leads with the total; methods are one bordered list with radios and a 2 px outline on the selected row.
* New `StatusBand`: solid for settled or waiting states, hatched when the outcome is unknown. Status, receipt, transaction detail and KYC status use band → title → amount → message, left-aligned.
* Unknown outcome now reads "Don't pay again." first (`statusUnknownLead`, `statusUnknownDetail`); the "last updated" row is shown only when a host snapshot exists.
* `PaymentTheme` defaults: radius 8 (controls 6), amount weight 600 at 32 px, contrast-checked tone colors independent of the host seed.
* Buttons 48 dp with no press scale; status badges are small tags; history filters are text tabs; failed and canceled amounts are struck through, refunds are not.
* New `ActionTileGroup` (hairlines between action rows). `PromoContent.icon` is kept but no longer drawn.
* Large text and foundation pass: `StatusHeader`, `InfoRow.trailing`, `PaymentStatusView.instructions`; `PaymentTheme.border`, `disabled`, `referenceFontFamily` and radius getters; internal role-based type scale; keyboard focus ring and 0.96 press on compact controls (`PaymentMotion.press` 100 ms, `pressedScale` 0.96); summary headline hidden and bar total capped at 1.6× above 1.5× text; one display amount on VA pending with a monospace VA number and folded steps.
* Example: Hairline and Contrast brands, gallery workbench with framed specimens and a separate fixture-state selector, fixture amounts formatted through `MoneyFormat`.

Controls (owner-approved catalog work, 31 Oct 2026):

* New `PaymentCheckbox`, `PaymentRadio`, `PaymentSwitch`: label rows with one 48 dp target and one screen-reader node each, a `disabledReason` line, state shown by shape as well as color.
* New `PaymentTabs` (the history filter tabs, made public; `TransactionHistory` now uses it), `PaymentTooltip`, `PaymentSpinner` (still hourglass under reduced motion; `PaymentButton`'s busy state uses it) and `PaymentDivider`.
* `PaymentButtonVariant.destructive`: surface label on the danger fill, the colors of a destructive `showPaymentConfirmDialog`. Exhaustive `switch`es over `PaymentButtonVariant` need the new case.
* Example: a Controls gallery section and `catalog_screenshots_test.dart` (English captures for the docs catalog).

Component foundation (user-authorized expansion, 30 Oct 2026):

* Interaction: `ActionTile`, `ActionMenu`, `showPaymentConfirmDialog`, `showPaymentSnackBar`, `ExpandableSection`, `LoadingSkeleton`, `StateMessage`.
* Navigation: `AdaptiveNavShell` (sidebar ≥ breakpoint, modal drawer below, Escape/Back close, focus return), `NavSidebar`, `PaymentNavItem`, `PaymentNavSection`.
* Sheets: `PaymentSheet`, `PaymentSheetHeader`, `showPaymentSheet`, `showPaymentSideSheet`.
* Media: `PaymentVideoPlayer` with `PaymentVideoController` adapter contract; example adapter for `video_player` 2.11.1 and a bundled synthetic clip.
* Promotions: `PromoCard`, `PromoSlot`, `PromoContent` with mandatory labeling.
* Payment: `PaymentActionBar`, `MerchantHeader`, `PaymentStepIndicator`, `BalanceCard`, `PromoCodeInput`, `TransactionHistory`, `TransactionListItem`, `TransactionDetail`, `TransactionRecord`.
* Foundation: `MiddleEllipsisText`, `KitStrings`, `PaymentSection.trailing`, `PaymentMotion.drawer`/`sheetEnter`/`sheetExit`; amounts scale down instead of clipping.
* Refinements: pinned checkout total and action, simplified status hero, KYC review edit actions in section headers, file names that no longer break mid-word, no opacity layer on re-quote, no clip per method tile.
* Example: gallery reorganized into sections behind `AdaptiveNavShell`; side rail on wide windows; perf harness measures 30 s and can run the checkout workload alone with a plain-list control.

* Foundation: `PaymentTheme` extension, `PaymentLocalizations` (en, id), `PaymentMotion` tokens with reduced-motion support, integer `Money` with strict locale-aware parsing, amount, row, button, badge, banner, section, privacy mask and countdown primitives.
* Verification (optional): consent intro, host-driven identity form, document slots with host limits and stale-upload protection, review with masking, status view without bypass actions.
* Checkout: amount input, summary with every fee, method picker with unavailable reasons, confirmation that requires re-approval when terms change, host authorization prompt.
* Status: manual (virtual account) instructions, `PaymentAttempt` with snapshot reconciliation (stale, duplicate, wrong attempt, success downgrade), status view that never offers paying again while unresolved, separate refund section.
* Receipt with allowlisted share data and share/copy feedback.
* Example app: full Ruang Bayar journey, scenario picker for the PRD matrix (K01–K08, P01–P15, X01–X04), component gallery, two brands, light/dark, id/en, text scale and reduced motion, fake host with idempotency, recovery store and account switching.
