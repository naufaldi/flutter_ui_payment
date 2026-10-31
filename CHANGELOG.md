## 0.1.0 (unreleased)

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
