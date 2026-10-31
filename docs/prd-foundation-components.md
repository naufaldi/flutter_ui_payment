# PRD: Foundation component layer

Date: 31 October 2026
Status: proposal for owner review. Nothing in this document is implemented. It does not change `PRD.md`.
Builds on: `PRD.md` §2, §4, §7, §10, §11 and §16a; `docs/decisions.md`; `docs/foundation-plan.md`; the docs catalog in PR #1.

## Ringkasan

Pemilik proyek ingin fondasi komponen yang dapat dipakai ulang seperti katalog Stripe Apps, dengan setiap komponen (Button, Chart, dan lainnya) punya level dan halaman sendiri. Dokumen ini membagi kit menjadi **Tier 1**, komponen fondasi yang memenuhi standar kualitas `PaymentButton`, dan **Tier 2**, pola pembayaran (checkout, status/struk, riwayat, KYC, promosi) yang hanya disusun dari Tier 1. Komponen Tier 1 baru hanya diterima jika diekstrak dari implementasi privat atau duplikat yang sudah ada, atau jika dibutuhkan oleh pola Tier 2. Komponen lain ditolak dan dicatat di "Not in the kit" beserta alternatif Flutter-nya. Aturan ini menjaga keinginan katalog tetap sejalan dengan PRD.md §2: komponen yang dipakai dalam alur nyata lebih bernilai daripada katalog besar.

## 0. Branches and evidence

| Short name | Ref | Contents |
| --- | --- | --- |
| `main` | `057c4e6` | Released 0.1.0. |
| `#1` | `docs/component-catalog` @ `ea78224`, open PR #1 | Per-component docs catalog; public `PaymentCheckbox`, `PaymentRadio`, `PaymentSwitch`, `PaymentTabs`, `PaymentTooltip`, `PaymentSpinner`, `PaymentDivider`; `PaymentButtonVariant.destructive`. |
| `charts` | `feat/charts-kyc-capture` @ `5550bfa`, stacked on #1, in progress; no PR opened yet | `PaymentLineChart`, `PaymentBarChart`, `PaymentMeterChart`, `PaymentSparkline`, `ChartModule`, `MoneyFormat.compact`, `showCaptureSourceSheet`, `KycCaptureGuide`, `CaptureFrameOverlay`, `patterns/chart-layout` docs page. |

Every `file:line` below refers to commit `5550bfa`, checked with `git show 5550bfa:<path>`, unless marked otherwise. Line numbers differ on `main`. The other checkout has uncommitted edits in `charts.dart`, `primitives.dart` and `capture_widgets.dart`. No line cited here depends on them.

## 1. Problem and goal

**Owner request (31 Oct 2026):** "a reusable component foundation, Button, Chart and so on, like Stripe, where each single component is a foundation with its own level and page."

**The tension.** PRD.md §2 assumes that "five to ten components used in a full flow" make a stronger portfolio than "a big catalog without real behavior". It also names the biggest risk: "the library becomes only a screenshot gallery". Copying Stripe's 46-entry list would create exactly that risk.

**The evidence.** Reading the code shows the kit does not need many new components. It needs its existing ones to be consistent:

- **Public controls the kit's own flows bypass.** PR #1 made `PaymentCheckbox`, `PaymentRadio`, `PaymentSpinner` and `PaymentDivider` public. The kit's own flows still use raw `CheckboxListTile` (`verification_widgets.dart:111`, `checkout.dart:492`), a private `_Radio` (`checkout.dart:393`), a raw `CircularProgressIndicator` (`video.dart:299`) and 11 raw `Divider(color: theme.outline)` calls.
- **Four private copies of one text field.** `checkout.dart:102`, `transactions.dart:330`, `payment_extras.dart:562` and `verification_widgets.dart:234` each repeat the same three `OutlineInputBorder`s. They already drift: only the history search adds a `PaymentFocusRing` on top of the accent border.
- **Two copy-to-clipboard controls with different feedback.** `payment_status.dart:152` reports beside the icon in a live region. `payment_receipt.dart:136` reports through a receipt-wide `NoticeBanner` that it shares with the share outcome (`payment_receipt.dart:36, 164`).
- **Five hand-rolled inline text actions.** `PaymentButton` is always full width (`primitives.dart:431`), so it cannot be used inline. Two of the five have no focus ring (`verification_widgets.dart:100`, `video.dart:386`), although the Focus and press page on #1 says every control has one.

**Goal.** Every component has one level (Tier 1 foundation or Tier 2 pattern), one docs page and one quality bar. The kit's own patterns are built only from its Tier 1 components. The docs mirror Stripe's catalog structure, and every Stripe entry the kit does not ship is listed under "Not in the kit" with the reason and the Flutter alternative.

**Proposed PRD.md §16a amendment** (one row to add when the owner approves; this PRD does not edit PRD.md):

| Kelompok | Komponen | Batas |
| --- | --- | --- |
| Fondasi (Tier 1) | `PaymentTextField` (termasuk `PaymentTextField.search`), `PaymentCopyButton`, `PaymentLink`; pola pembayaran wajib memakai `PaymentCheckbox`/`PaymentRadio`/`PaymentDivider`/`PaymentSpinner` | Komponen baru hanya hasil ekstraksi atau kebutuhan pola Tier 2; tidak ada field PIN/OTP/rahasia; clipboard dan tautan dijalankan host lewat callback |

## 2. Definitions

### Tier 1: foundation component

A single-purpose building block. Its parameters use only Flutter types, foundation types (`Money`, `StatusTone`, `AmountParseResult`, `HostError`) and its own small types (`ChartPoint`, `PaymentNavItem`, `PaymentVideoController`). A Tier 1 component may be money-aware, such as `AmountText`, `AmountInput` or `CountdownText`.

### Tier 2: payment pattern

A widget that meets either of these:

- It takes a host verdict, status or content type defined in `lib/src/payment`, `verification`, `receipt` or `promo`. Examples: `PaymentQuote`, `PaymentAttempt`, `BalanceState`, `PromoCodeStatus`, `PromoContent`, `CaptureKind`, `DocumentSlotState`, `TransactionRecord`, and `MerchantHeader.verified`.
- It enforces a rule from PRD §8, §11 or §16a "Batas". Examples: consent starts unchecked, fees are never folded, promotions are always labeled.

The patterns are Checkout, Status and receipt, Transaction history, Verification (KYC) and KYC capture, and Promotions. A Tier 2 widget may only render interactive controls through Tier 1 components. It must not keep private copies of them.

### Admission rule for a new Tier 1 component

A new Tier 1 component is admitted only if one of these is true:

- **(a) Extract.** A private or duplicated implementation already exists in `lib/`. Either it has two or more call sites, or a public Tier 2 API currently forces hosts to reimplement it.
- **(b) Needed by a pattern.** A Tier 2 pattern in the example app needs it, and the need is shown by a concrete screen, field or scenario ID from PRD §9.

Anything else is refused and listed under "Not in the kit" with the Flutter alternative. "Stripe has it" is not evidence.

The **Adopt** status covers existing public Tier 1 components that a Tier 2 pattern bypasses. Adoption work comes before any new component.

### The Button bar (Tier 1 quality checklist)

Each item is testable. "Widget test" means a test in `test/`, run per file with `flutter test --no-pub`.

| # | Requirement | How it is checked |
| --- | --- | --- |
| B1 | Exported from `lib/flutter_ui_payment.dart`; dartdoc on the class and on every parameter | `flutter analyze` (`public_member_api_docs` where enabled); appears in `website/src/data/api.json` after `pnpm gen:api` |
| B2 | Color, radius, spacing, type and motion come only from `PaymentTheme`, `PaymentType` and `PaymentMotion`. No `Color(0x…)` or `Colors.*` literals, except a documented scrim like the camera overlay | Review grep on the new file; renders under the Hairline and Contrast example brands |
| B3 | Light and dark | Widget test pumps both; screenshot pair `ios_catalog_<name>` and `ios_catalog_<name>_dark` |
| B4 | 200% text at 320 dp width: no overflow, nothing clipped, primary action reachable | Widget test with `TextScaler.linear(2)` and no `FlutterError`; `ios_catalog_<name>_200` when text-heavy |
| B5 | Every interactive target is at least 48×48 dp | Widget test on `tester.getSize` (pattern in `test/controls_test.dart:80`) |
| B6 | Contrast: text ≥ 4.5:1; control edges and state marks ≥ 3:1, light and dark | `contrast()` helper (`test/controls_test.dart:32`) on resolved token pairs |
| B7 | Semantics: one node per control, with label, role and state (checked, selected, enabled, busy, value). State is never carried by color alone | Widget test with `matchesSemantics` or `getSemantics` |
| B8 | Keyboard: reachable with Tab, activates with Enter or Space. Focus shows as the `PaymentFocusRing` on controls, or as the 2 px `accent` border on text inputs, never both | Widget test in the style of `test/focus_press_test.dart` |
| B9 | Reduced motion: no animation runs when `MediaQuery.disableAnimations` is true | Widget test |
| B10 | Built-in strings live in `PaymentLocalizations`/`KitStrings` in en and id, and are overridable by parameter | Both locales pumped; long Indonesian strings at 200% |
| B11 | Host ownership: no network, no clipboard or platform-channel call, no URL launching, no timers that poll, no secret input | `grep -rn "Clipboard\|dart:io\|http\|launch" lib` stays empty; `pubspec.yaml` dependencies stay `flutter` only |
| B12 | Docs page in the catalog order: purpose, screenshot, usage, variants and states, when to use and when not, content guidelines, accessibility, Props table, See also | `pnpm build`, `pnpm check:links`, `pnpm check:snippets` |
| B13 | Used by at least one Tier 2 pattern or recorded as owner-approved without one | Inventory table below |

## 3. Inventory: Stripe Apps catalog → kit

Status values:

- **Have:** public, meets or is close to the Button bar.
- **Adopt:** public, but a Tier 2 pattern bypasses it.
- **Extract:** private or duplicated today.
- **In progress:** on `charts`.
- **Refuse:** not in the kit.
- **Internal:** exists but is deliberately not exported.

### Views

| Stripe | Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- | --- |
| ContextView, FullPageView, SettingsView | none | Refuse | These are app shells. The host owns `Scaffold` and routing (PRD §2: no router). The kit's shell need is covered by `AdaptiveNavShell` (`navigation.dart:244`) | Not in the kit |
| OnboardingView | none | Refuse | The kit's onboarding is the Tier 2 `VerificationIntro` (`verification_widgets.dart:16`) | Not in the kit → Verification |
| SignInView | none | Refuse | The kit never receives credentials or secrets (PRD §4, §7, §11) | Not in the kit |

### Layout

| Stripe | Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- | --- |
| Box | none | Refuse | Flutter `Container`, `Padding` and `DecoratedBox` with `PaymentTheme` tokens | Not in the kit |
| DetailPage, OverviewPage | none | Refuse | Page templates; the host owns the page. Content for them is Tier 2 (`TransactionDetail` `transactions.dart:378`, `PaymentStatusView`) | Not in the kit |
| Divider | `PaymentDivider` (#1) | Have + **Adopt** | `primitives.dart:487`; raw `Divider(color: theme.outline)` at `transactions.dart:318, 462`, `payment_status.dart:74, 418, 440`, `checkout.dart:206, 276`, `payment_receipt.dart:112, 159`, `interaction.dart:157`, `video.dart:367` | `components/divider` |
| (kit) Section | `PaymentSection` | Have | `primitives.dart:650` | `components/section` |

### Navigation

| Stripe | Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- | --- |
| Button | `PaymentButton` (primary, secondary, quiet, destructive) | Have | `primitives.dart:262`; destructive added on #1 | `components/button` |
| ButtonGroup | none | Refuse (decision D6) | `PaymentActionBar` is a total plus a single action (`payment_extras.dart:18`), not a group. The real groups are a vertical button stack with domain ordering (`payment_status.dart:400`), a `Wrap` (`primitives.dart:626`) and a host `List<Widget>` (`transactions.dart:382`) | Rules on the Button page |
| Link | `PaymentLink` | **Extract** | Five private `TextButton`s: `verification_widgets.dart:100` (policy, `open_in_new`, no focus ring), `verification_widgets.dart:537` (review "Edit"), `promo.dart:104` (underlined "why"), `promo.dart:210` (quiet CTA), `video.dart:386` (retry, no focus ring) | new `components/link` |
| Menu | `ActionMenu` | Have | `interaction.dart:188` | `components/action-menu` |
| Tabs | `PaymentTabs` (#1) | Have | `controls.dart:333`; used by `TransactionHistory` | `components/tabs` |
| (kit) Navigation shell | `AdaptiveNavShell`, `NavSidebar` | Have | `navigation.dart:49, 244` | `components/navigation` |
| (kit) Step indicator | `PaymentStepIndicator` | Have | `payment_extras.dart:260`; takes only labels and an index, so it is Tier 1 | `components/step-indicator`; the page is new, the component is on the Checkout page today |

### Content

| Stripe | Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- | --- |
| Accordion | `ExpandableSection` | Have | `interaction.dart:365` | `components/expandable-section` |
| Badge | `StatusBadge` | Have | `primitives.dart:503` | `components/status-badge` |
| Banner | `NoticeBanner` | Have | `primitives.dart:548` | `components/notice-banner` |
| Chip | none | Refuse (D8) | Pill chips were replaced by text tabs for history filters (`docs/decisions.md`, Hairline table). The only chip-like widget is the applied-promo tag inside `PromoCodeInput` (`payment_extras.dart:477-505`), one private use | Not in the kit |
| Code | `PaymentCopyButton` | **Extract** (D3) | The payment need is "copy this reference", not code blocks: `_CopyButton` `payment_status.dart:152` (VA number) and the inline `IconButton` `payment_receipt.dart:136` (transaction ID) | new `components/copy-button` |
| DataTable, Table | none | Refuse | Mobile payment UI; row lists are covered by `TransactionHistory` and `InfoRow` groups | Not in the kit |
| FocusView | `PaymentSheet`, `showPaymentSheet`, `showPaymentSideSheet` | Have | `sheets.dart:90, 145, 180` | `components/sheets` |
| Icon | none | Refuse | Flutter `Icon`; the size and color rules belong on the foundations pages | Not in the kit |
| Img | none | Refuse (D9) | `PromoContent.media` is a host `Widget?` slot (`promo.dart:51`). `KycCaptureGuide` draws a bare `Image` with no `errorBuilder` (`capture_widgets.dart:253`). That is a local fix, not a component | Not in the kit |
| Inline | none | Refuse | Flutter `Text.rich` | Not in the kit |
| List | `ActionTile`, `ActionTileGroup` | Have | `interaction.dart:22, 145` | `components/action-tile` |
| PropertyList | `PaymentSection` + `InfoRow` | Have (D5: no new class) | `primitives.dart:141, 650`; used by summary, receipt and detail | `components/info-row` gets a "Property list" section |
| Spinner | `PaymentSpinner` (#1) | Have + **Adopt** | `primitives.dart:445`; raw `CircularProgressIndicator` at `video.dart:299` ignores reduced motion | `components/spinner` |
| TaskList | none | Refuse (D7) | No list in the kit has per-item completion. Linear progress is `PaymentStepIndicator`; per-document state is `DocumentUploadTile` | Not in the kit |
| Toast | `showPaymentSnackBar` | Have | `interaction.dart:326` | `components/toast` |
| Tooltip | `PaymentTooltip` (#1) | Have (B13: owner-approved on #1, no Tier 2 use yet) | `controls.dart:450` | `components/tooltip` |
| (kit) Amount text | `AmountText` | Have | `primitives.dart:15` | `components/amount-text` |
| (kit) Info row | `InfoRow`, `MiddleEllipsisText` | Have | `primitives.dart:63, 141` | `components/info-row` |
| (kit) Countdown | `CountdownText` | Have | `primitives.dart:858` | `components/countdown` |
| (kit) Privacy mask | `PrivacyMask` | Have | `primitives.dart:825` | `components/privacy-mask` |
| (kit) Action bar | `PaymentActionBar` | Have | `payment_extras.dart:18`; takes `Money` plus a widget, so it is Tier 1 | `components/action-bar`; the page is new, the component is on the Checkout page today |
| (kit) Video | `PaymentVideoPlayer`, `PaymentVideoController` | Have | `video.dart:97` | `components/media` |

### Forms

| Stripe | Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- | --- |
| TextField | `PaymentTextField` | **Extract** (D1) | Four copies: `checkout.dart:102` (`AmountInput`), `transactions.dart:330` (search), `payment_extras.dart:562` (promo code), `verification_widgets.dart:234` (`IdentityForm`, a `TextFormField`) | new `components/text-field` |
| SearchField | `PaymentTextField.search` | **Extract** (D2), as a variant of the TextField extraction | `transactions.dart:330-360`: search icon, clear button labelled `clearSearch`, controlled `query` | new `components/search-field` |
| CurrencyField | `AmountInput` | Have; rebuilt on `PaymentTextField` | `checkout.dart:19` | `components/amount-input` |
| Checkbox | `PaymentCheckbox` (#1) | Have + **Adopt** | `controls.dart:13`; raw `CheckboxListTile` in `VerificationIntro` (`verification_widgets.dart:111`) and the re-quote consent in `PaymentConfirmation` (`checkout.dart:492`). The second is the open "re-quote checkbox ~11 dp inside the gutter" item in `docs/decisions.md` | `components/checkbox` |
| Radio | `PaymentRadio` (#1) | Have + **Adopt** | `controls.dart:91`; `PaymentMethodPicker` keeps a private `_Radio` (`checkout.dart:393`) that draws the same mark but shows `Icons.block` when disabled | `components/radio` |
| Switch | `PaymentSwitch` (#1) | Have (B13: owner-approved on #1, no Tier 2 use yet) | `controls.dart:162` | `components/switch` |
| DateField | none | Refuse for now (D4) | The only date in the product is the KYC date of birth. It is typed `DD-MM-YYYY` text with a host validator in the example (`example/lib/screens/flow_screen.dart:398`). `IdentityFieldSpec` has no field kinds (`verification_models.dart:64`). `TransactionFilter` has no date filter (`kit_strings.dart:219`) | Not in the kit |
| DateRangePicker | none | Refuse | No use anywhere | Not in the kit |
| Select | none | Refuse (D4) | `IdentityFieldSpec` has no options, and the example has no province or occupation field. A few options use a `PaymentRadio` group; many options use `showPaymentSheet` with `PaymentRadio` rows | Not in the kit |
| FormFieldGroup | none | Refuse | No multi-input single question in the kit. Grouping is `PaymentSection`; validation and focus-to-first-error live in `IdentityForm` | Not in the kit |
| TextArea | none | Refuse | No free-text input in any pattern. Refund requests are outside the library (PRD §4) | Not in the kit |

### Charts

| Stripe | Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- | --- |
| LineChart | `PaymentLineChart` | In progress | `charts.dart:18` | `components/line-chart` |
| BarChart | `PaymentBarChart` | In progress | `charts.dart:44` | `components/bar-chart` |
| Sparkline | `PaymentSparkline` | In progress | `charts.dart:68` | `components/sparkline` |
| MeterChart | `PaymentMeterChart` | In progress | `charts.dart:255` | `components/meter-chart` |
| (kit) Chart module | `ChartModule` | In progress | `charts.dart:336`; loading, ready, empty and error with a constant plot height | `patterns/chart-layout` |

The charts are only used in `example/lib/screens/gallery_charts.dart`, not in any Tier 2 pattern. They are admitted because the owner asked for them by name. Under B13, Phase 2 gives them a Tier 2 consumer (D10).

### Feedback and overlays (kit-specific)

| Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- |
| `showPaymentConfirmDialog` | Have | `interaction.dart:259` | `components/dialog` |
| `StatusHeader`, `StatusBand` | Have | `primitives.dart:700, 761` | `components/status-header` |
| `LoadingSkeleton` | Have | `interaction.dart:498` | `components/loading-skeleton` |
| `StateMessage` | Have | `interaction.dart:573` | `components/state-message` |

### Internal foundations (not exported)

| Kit | Status | Evidence |
| --- | --- | --- |
| `PaymentFocusRing`, `PaymentPressScale` | Internal | `foundation/focus_ring.dart` is not in the export list. Tests import it through `src/`. #1's "Focus and press" page says "internal to the package". |
| `PaymentType` | Internal | `foundation/payment_type.dart`; "stays internal until the owner approves" (`docs/decisions.md`) |
| `ChartPainter`, `MeterPainter`, hatch painter | Internal | `charts/chart_painters.dart`, `foundation/hatch.dart` are not exported |

The orchestrator's draft listed `PaymentFocusRing` and `PaymentPressScale` as "Have". They are internal. Exporting them is open question Q3.

### Tier 2 patterns (composed from Tier 1)

| Pattern | Widgets | Docs |
| --- | --- | --- |
| Checkout | `PaymentSummary`, `PaymentMethodPicker`, `PaymentConfirmation`, `AuthorizationPrompt`, `MerchantHeader`, `BalanceCard`, `PromoCodeInput` | `patterns/checkout` |
| Status and receipt | `PaymentInstructions`, `PaymentStatusView`, `RefundSection`, `PaymentReceipt` | `patterns/status-receipt` |
| Transaction history | `TransactionHistory`, `TransactionListItem`, `TransactionDetail` | `patterns/history` |
| Verification (KYC) | `VerificationIntro`, `IdentityForm`, `DocumentUploadTile`, `VerificationReview`, `VerificationStatusView` | `patterns/verification` |
| KYC capture | `showCaptureSourceSheet`, `KycCaptureGuide`, `CaptureFrameOverlay` | `patterns/kyc-capture` |
| Promotions | `PromoCard`, `PromoSlot` | `patterns/promotions` |

### Counts (46 Stripe entries)

| Status | Count | Entries |
| --- | --- | --- |
| Have | 17 | Divider, Button, Menu, Tabs, Accordion, Badge, Banner, FocusView, List, PropertyList, Spinner, Toast, Tooltip, CurrencyField, Checkbox, Radio, Switch |
| ...of which Adopt work | 4 | Divider, Spinner, Checkbox, Radio |
| Extract | 4 | Link, Code (as copy button), TextField, SearchField |
| Build | 0 | none |
| In progress | 4 | LineChart, BarChart, Sparkline, MeterChart |
| Refuse | 21 | 5 Views, Box, DetailPage, OverviewPage, ButtonGroup, Chip, DataTable, Icon, Img, Inline, Table, TaskList, DateField, DateRangePicker, Select, FormFieldGroup, TextArea |

Kit-specific Tier 1 components with no Stripe equivalent: `PaymentSection`, `AdaptiveNavShell`/`NavSidebar`, `PaymentStepIndicator`, `AmountText`, `InfoRow`/`MiddleEllipsisText`, `CountdownText`, `PrivacyMask`, `PaymentActionBar`, `PaymentVideoPlayer`, `ChartModule`, `showPaymentConfirmDialog`, `StatusHeader`/`StatusBand`, `LoadingSkeleton`, `StateMessage`.

## 4. Decisions

| ID | Decision | Reason |
| --- | --- | --- |
| D1 | Extract **`PaymentTextField`**, built on `TextFormField` so it works with or without a `Form`. Migrate all four copies. Focus is the 2 px `accent` border only. The history search drops its extra `PaymentFocusRing`. | Four copies of one decoration that already drift. `IdentityForm` needs `validator` and `forceErrorText`, so a plain `TextField` wrapper would break it. The Focus and press page already says text fields show focus by their border. |
| D1a | `PaymentTextField` has **no `obscureText`** and no PIN or OTP mode. | The kit never receives secrets (PRD §7, §11). A missing parameter is a stronger signal than a docs warning. |
| D2 | **Search is a named constructor, `PaymentTextField.search`, not its own class.** It still gets its own docs page, mirroring Stripe's SearchField. It is controlled (`query` plus `onChanged`) and has no built-in debounce. | There is only one search call site, so a separate class would fail rule (a). As a variant of the four-site TextField extraction it costs no extra API surface. Debounce is host policy, like polling. |
| D3 | **`PaymentCopyButton`** is the compact icon control, not a "copyable text" composite. It takes `value` and `onCopy: Future<bool> Function(String)`. Feedback is inline: on success the icon becomes a check and "Copied" is announced in a live region. On failure the words are shown under the icon. The receipt's `NoticeBanner` then reports only the share outcome. | The two existing call sites lay out differently (`Row` vs `InfoRow.trailing`). Only the control is shared. Feedback next to the value does not depend on where the host places a banner. The host still owns the clipboard (B11). |
| D4 | **No DateField, no Select** for now. | Neither passes the admission rule: there is no options field, and the date of birth is typed text in the example. For birth dates, typed entry is a reasonable pattern. A picker would be a UX change that needs its own justification. Revisit if `IdentityFieldSpec` gains field kinds (Q1). |
| D5 | **PropertyList** is documented, not built: `PaymentSection` + `InfoRow`. | Behavior that already exists; a new class would be catalog filler. |
| D6 | **No ButtonGroup class.** The Button page states the rules: one primary per group, a vertical full-width stack with a `spacing` gap, quiet for "contact support". | The three existing groups differ (domain-ordered stack, `Wrap`, host list). A shared class would only wrap a `Column`. |
| D7 | **No TaskList.** | No list in the kit has per-item completion. `VerificationIntro`'s list explains what data is asked for and why; it is not a set of tasks. |
| D8 | **No Chip.** The applied-promo tag stays private to `PromoCodeInput`. | One use. Chips were already rejected for filters. `StatusBadge` covers status tags. |
| D9 | **No Img component.** Phase 1 fixes `KycCaptureGuide` so a failed `photo` falls back to the frame overlay (`errorBuilder`). | Promo media is a host widget slot. The only kit-drawn image lacks an error state. That is a bug in a pattern, not a missing primitive. |
| D10 | **Charts** are admitted at the owner's request. Phase 2 adds a "Spending summary" (`ChartModule` + `PaymentBarChart`) above the history list in the example, giving them a Tier 2 consumer. `BalanceCard` keeps its `LinearProgressIndicator` limit bar (`payment_extras.dart:386`). | Charts are documented as "customer-facing spending summaries" (`docs/decisions.md` on `charts`), and history is that place. The limit bar is one ratio with a 90% warning tone. The charts decisions forbid status tones as meter categories, so `PaymentMeterChart` does not fit it. |
| D11 | **`PaymentLink`** is a new compact component. `PaymentButton` stays full width. | Full width is a design decision with its own press rule: no scale on wide slabs (`docs/decisions.md`). Inline actions are compact controls that use the 0.96 press scale. Mixing both into one widget would give one class two press rules. |
| D12 | **Adopt before extract.** The method picker uses `PaymentRadio`'s mark. A disabled method shows the disabled circle plus its existing unavailable reason, replacing `Icons.block`. | One radio look across the kit. The reason text, not the icon, is the non-color disabled signal (B7). |
| D13 | **No FormFieldGroup, TextArea or DateRangePicker.** | FormFieldGroup: no multi-input single question exists. `PaymentSection` groups fields; `IdentityForm` owns validation and focus. TextArea: no pattern takes free text. Refund requests are outside the library (PRD §4). DateRangePicker: no date filtering anywhere (`TransactionFilter`). |
| D14 | **`showCaptureSourceSheet` and `CaptureFrameOverlay` are Tier 2 (KYC capture).** Their docs move from Overlays to Patterns. | Both take verification types (`CaptureSource`, `CaptureKind`) and keep the §16a/§4 boundary: the kit opens no camera. |

## 5. Phased plan

Each phase is one or more PRs. Per the owner's standing rule, every PR stops before merge. A merge needs the owner to name the destination.

### Phase 0: land what exists

- **Merge PR #1, then the charts PR, to `main`.** The charts PR is not opened yet. Opening it belongs to the charts work, not to this initiative. Merging is the owner's decision, after each PR's own verification.
- **Rebase the docs branch.** This PRD's branch (`docs/foundation-prd`) is rebased onto `main` afterwards.
- **No new code.** Phase 1 branches from `main` once both PRs are merged. If they are still open, Phase 1 stacks on `charts`.

### Phase 1: adopt and extract (three PRs)

**PR 1A: adopt.** Pure refactor, with no public API change except D12's visual change.

- `VerificationIntro` and `PaymentConfirmation` use `PaymentCheckbox`.
- `PaymentMethodPicker` uses the shared radio mark (D12).
- The 11 raw dividers use `PaymentDivider(height: …)`.
- The video loading state uses `PaymentSpinner`.
- `KycCaptureGuide` gets its photo `errorBuilder` (D9).

Screenshots to re-take and inspect:

- `ios_catalog_controls_choices`, plus the dark variant
- KYC intro, and the same at `_200`
- checkout re-quote (`requote`)
- video loading.

**PR 1B: text fields.** New `PaymentTextField` with its `.search` constructor; migrate `AmountInput`, `PromoCodeInput`, `IdentityForm` and `TransactionHistory`.

```dart
PaymentTextField({
  Key? key,
  required String label,
  TextEditingController? controller,
  FocusNode? focusNode,
  String? hint,
  String? helper,
  StatusTone helperTone = StatusTone.neutral, // IdentityForm "needs update" = warning
  String? errorText,                          // host/server error (forceErrorText)
  FormFieldValidator<String>? validator,      // runs inside a Form
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  TextInputType keyboardType = TextInputType.text,
  TextInputAction? textInputAction,
  List<TextInputFormatter> inputFormatters = const [],
  TextCapitalization textCapitalization = TextCapitalization.none,
  Iterable<String>? autofillHints,
  bool enabled = true,
  bool reference = false,                     // monospace referenceFontFamily (promo code)
  PaymentTextFieldSize size = PaymentTextFieldSize.body, // .amount for AmountInput
  String? prefixText,
  Widget? prefixIcon,
  Widget? suffix,
  bool autocorrect = true,
  bool enableSuggestions = true,
}) // no obscureText (D1a)

PaymentTextField.search({
  Key? key,
  required String query,
  required ValueChanged<String> onChanged,
  String? label,            // default: new generic l10n.search (history passes searchTransactions)
})
```

States: empty, filled, focused, error, helper, disabled, `reference`, `amount`.

Tests (`test/text_field_test.dart`):

- B3–B10.
- Server error clears after an edit (the existing `IdentityForm` behavior).
- Focus moves to the first invalid field.
- The search clear button resets `query` and has the `clearSearch` label.
- No focus ring and border at the same time.

Screenshots:

- `ios_catalog_text_field` with `_dark` and `_200`
- `ios_catalog_search_field` with `_dark`.

**PR 1C: link and copy.** New `PaymentLink` and `PaymentCopyButton`; migrate the five inline actions and both copy sites.

```dart
PaymentLink({
  Key? key,
  required String label,
  required VoidCallback? onPressed,      // host opens URLs; the kit never launches
  bool external = false,                 // trailing open_in_new + "opens outside the app" hint
  PaymentLinkEmphasis emphasis = PaymentLinkEmphasis.accent, // .muted = caption, underlined
  String? semanticLabel,                 // e.g. "Edit: Your details"
})

PaymentCopyButton({
  Key? key,
  required String value,
  required Future<bool> Function(String value) onCopy, // host owns the clipboard
  String? tooltip,                                     // default l10n.copy
})
```

States: idle, pressed (0.96 scale), focused (ring), disabled; for copy also copied and failed.

New strings, in en and id: `opensExternally` (1C) and a generic `search` (1B). `copy`, `copied`, `copyFailed` and `retry` already exist.

Tests (`test/link_copy_test.dart`):

- 48 dp target.
- One semantics node with the button role.
- `external` adds the hint.
- Copy success and failure are announced.
- A double tap while `onCopy` is pending calls it once.
- B6 for muted links in dark mode.

Screenshots:

- `ios_catalog_link` with `_dark`
- `ios_catalog_copy_button` with `_dark`
- receipt and VA pending re-taken.

### Phase 2: pattern adoption

There are no Build items. Under the rule, every candidate was either extracted or refused.

- **Spending summary (D10).** Add a `ChartModule` + `PaymentBarChart` above `TransactionHistory` in the example's history screen. Host-owned totals; all four `ChartState`s are reachable from the scenario picker. Screenshots `ios_catalog_history_spending` with `_dark` and `_200`.
- **Owner-approved builds.** Anything the owner approves from Q1 or Q2 lands here, each with its own API sketch reviewed before code.

### Phase 3: docs information architecture

Extend the structure that exists on #1 and `charts`; do not start a new one.

- **Sidebar.** `Start`, `Concepts`, `Foundations` (unchanged), then `Components` in Stripe groups:
  - Layout: Divider, Section
  - Navigation: Button, Link, Action menu, Tabs, Navigation shell, Step indicator
  - Content: Amount text, Info row (with property list), Copy button, Expandable section, Tooltip, Countdown, Privacy mask, Action bar, Video
  - Forms: Text field, Search field, Amount input, Checkbox, Radio, Switch
  - Charts: Line, Bar, Meter, Sparkline
  - Feedback: Status badge, Notice banner, Toast, Status header, Spinner, Loading skeleton, State message
  - Overlays: Dialog, Sheet

  Then `Patterns`, then `Reference`.
- **Patterns.** "Payment flows" becomes Patterns: Checkout, Status and receipt, Transaction history, Verification, KYC capture (which absorbs the current `components/capture-source-sheet` page, D14), Promotions. The existing `patterns/chart-layout` joins it, with three new pages:
  - **Loading:** skeleton vs spinner vs a busy button.
  - **Empty and error states:** `StateMessage`, `ChartState`, `PromoSlot`.
  - **Forms:** labels, error timing, focus to the first error, no secret fields.
- **Redirects.** Moved pages get redirects through the existing mechanism (`astro.config.mjs` `redirects`, `public/_redirects`, `netlify.toml`).
- **Overview page.** Gains a "Stripe Apps name → kit" column.
- **Not in the kit.** Becomes a table with one row per refused entry: name, reason, and the Flutter alternative. It drops the stale sentence "Text fields exist only inside…".
- **Screenshots.** New captures are registered in `website/scripts/screens.mjs`. The docs only use `example/build/screenshots_hairline`.

## 6. Acceptance and verification

### Every phase

These are local commands. The repo has no CI (PR #1 body).

- **Format and analyze.** `dart format --output=none --set-exit-if-changed .`, then `flutter analyze` in the package and in `example/`.
- **Package tests.** Run file by file: `flutter test --no-pub test/<file>.dart`. The full suite intermittently fails to load on this machine with a `flutter_tester` WebSocket error (`docs/decisions.md`).
- **Integration flow.** `cd example && flutter test --no-pub integration_test/flow_test.dart -d <iPhone 16 / iOS 18.1 simulator>`; all existing tests pass.
- **Screenshots.** `catalog_screenshots_test.dart` on the same simulator. Each new or changed capture is opened and inspected: light, dark, and 200% where the component is text-heavy.
- **Docs.** In `website/`: `pnpm build`, `pnpm check:links` (0 broken), `pnpm check:snippets` (0 problems).

### Phase-specific acceptance

| Phase | Happy flow | Edge states | Security | Performance |
| --- | --- | --- | --- | --- |
| 0 | `main` builds and passes the above with #1 and charts merged | — | Unchanged | Unchanged |
| 1A | KYC → checkout → pay → receipt unchanged in `flow_test` | Disabled method shows reason plus the disabled circle; re-quote checkbox aligned to the gutter at 100% and 200%; video loading still under reduced motion; KYC guide photo error shows the frame | No behavior change | Widget count equal or lower; no new animations |
| 1B | Identity form submits; amount parses; promo applies; search filters | P01 (empty, zero, over limit, pasted formatted amount); K02 (non-ASCII name, server error clears on edit, focus to first error); search clear at 200%; Indonesian helper text at 200% | NIK still masked in review (`maskInReview`); no `obscureText` in the public API; no new dependency | One fewer `PaymentFocusRing` layer in history; no extra rebuilds per keystroke (the controller is owned the same way as today) |
| 1C | Copy VA number and receipt ID; open policy; edit from review | P15 (clipboard fails → "copy failed" visible); double tap while pending; external hint spoken | Copy only receives host-passed values (VA number, transaction ID), never NIK; no `Clipboard`, `url_launcher` or `dart:io` in `lib` | Static press scale only (100 ms, 0 under reduced motion) |
| 2 | History shows a spending summary from host data | Loading, empty, error with retry, pending and unknown bars (hatched, never like pending); 200% | Values are host `Money`; the kit computes no totals | Charts are paint-only (`CustomPainter`, no `AnimationController` in `lib/src/charts`) |
| 3 | Every Tier 1 component has a page that meets B12 | Redirects resolve; 320 px pages do not scroll sideways | Docs screenshots use synthetic data only | `dist/` size noted; WebP only |

**Done for this initiative:**

- Every Tier 1 row is Have, with B1–B13 checked.
- No Tier 2 file contains a private copy of a Tier 1 control. Review grep: no `CheckboxListTile`, `_Radio`, `OutlineInputBorder`, raw `Divider(` or `CircularProgressIndicator` outside `lib/src/controls` and `lib/src/foundation`.
- "Not in the kit" lists all 21 refusals.

## 7. Non-goals, risks, open questions

### Non-goals

- Matching Stripe's list one to one, or building any entry because Stripe has it.
- App shells, page templates, tables, rich text.
- PIN, OTP or password fields, or any secret input. A photo-grid gallery browser, which belongs to the host or the OS picker.
- New dependencies, network calls, URL launching or clipboard access inside `lib`.
- Making `PaymentType`, `PaymentFocusRing` or `PaymentPressScale` public without owner approval.

### Risks

| Risk | Mitigation |
| --- | --- |
| Visible behavior changes during extraction: receipt copy feedback moves from the receipt-wide banner to beside the copy button; the method picker's disabled icon changes; history search loses its double focus indicator | Listed in CHANGELOG under each PR; before and after screenshots inspected |
| A new public API is hard to change after 0.1.x | Sketches above are reviewed before code; constructors take only what current call sites use; no `style` escape hatch beyond `reference` and `size` |
| The catalog drifts back into filler | The admission rule and B13 are written on the components overview page; each refusal has a row with a reason |
| Maintenance: three new public widgets (`PaymentTextField` with `.search`, `PaymentLink`, `PaymentCopyButton`), each with docs, screenshots and tests | Each replaces two to five private copies, so total code goes down |
| `IdentityForm` regression: server errors, focus order, autofill | Existing K02/K07 tests plus new per-field tests in 1B |
| Branch churn: #1 and charts are unmerged | Phase 1 waits for Phase 0 or stacks on `charts`; it never edits files those PRs are still changing |

### Open questions for the owner

1. **Date of birth.** Should `IdentityFieldSpec` gain field kinds (`text`, `date`, `choice`)? If yes, that would admit a `PaymentDateField`, which renders typed entry plus an optional host-opened `showDatePicker`, and a `PaymentSelect`, which opens a sheet of `PaymentRadio` rows. The default here is no (D4).
2. **Switch and Tooltip have no Tier 2 consumer.** Keep them as owner-approved catalog entries (the current position), or give each a real use, for example a refund-notification `PaymentSwitch` in a settings example?
3. **Export `PaymentFocusRing` and `PaymentPressScale`?** Hosts building their own controls would then match the kit's focus and press exactly. Today the Focus page tells them to imitate the behavior by hand.
4. **Sidebar wording.** Keep "Patterns" as Stripe does, or "Payment patterns" to make the tier explicit?
5. **TransactionDetail reference.** It shows the reference as `SelectableText` without copy (`transactions.dart:448`). Should it accept an optional `onCopyReference` using `PaymentCopyButton`? This is not in scope unless approved.

## 8. Issue checklist

```markdown
### Foundation component layer (docs/prd-foundation-components.md)

**Phase 0: land what exists**
- [ ] Merge PR #1 (docs/component-catalog) to main (owner)
- [ ] Open the charts PR (feat/charts-kyc-capture, stacked on #1), then merge to main (owner)

**Phase 1A: adopt existing Tier 1 in Tier 2 patterns**
- [ ] VerificationIntro consent → PaymentCheckbox
- [ ] PaymentConfirmation re-quote consent → PaymentCheckbox (fixes gutter offset)
- [ ] PaymentMethodPicker `_Radio` → shared PaymentRadio mark (D12)
- [ ] 11 raw `Divider(color: theme.outline)` → PaymentDivider
- [ ] PaymentVideoPlayer loading → PaymentSpinner
- [ ] KycCaptureGuide photo errorBuilder (D9)

**Phase 1B: text fields**
- [ ] PaymentTextField (no obscureText) + docs page + tests + screenshots
- [ ] PaymentTextField.search + Search field docs page + tests + screenshots
- [ ] Migrate AmountInput, PromoCodeInput, IdentityForm, TransactionHistory

**Phase 1C: link and copy**
- [ ] PaymentLink + docs page + tests + screenshots
- [ ] PaymentCopyButton + docs page + tests + screenshots
- [ ] Migrate 5 inline TextButtons and 2 copy controls

**Phase 2: pattern adoption**
- [ ] History spending summary (ChartModule + PaymentBarChart) in the example
- [ ] Owner decisions on Q1–Q5 recorded in docs/decisions.md

**Phase 3: docs**
- [ ] Sidebar: Components in Stripe groups; Payment flows → Patterns (with redirects)
- [ ] Patterns: loading, empty and error states, forms (chart layout exists)
- [ ] New pages: Link, Copy button, Text field, Search field, Step indicator, Action bar
- [ ] Overview: Stripe name → kit column
- [ ] "Not in the kit" table with 21 refusals and Flutter alternatives
- [ ] PRD.md §16a amendment row (after owner approval)
```
