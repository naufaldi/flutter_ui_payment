## UI review P7c (2026-11-01)

- **Copy failure label under the glyph (#46).** `PaymentCopyButton`'s persistent "Copy failed" label now starts under the 20 dp glyph instead of under the 48 dp tap box, so it overhangs the box by 2 dp at 1× instead of 16 dp. On a container's last row it no longer crosses the container's border. The button still keeps its size, and nothing moves. No API change.
- **Document tile at large text.** Above 1.5× text, `DocumentUploadTile` shows its status badge under the title and limits instead of beside the title. Beside the title the badge got half the row, so "Belum ditambahkan" broke inside a word at 200% on a small phone. No API change.
- **Example: KYC documents scenarios.** Scenarios that open on the documents step (K03–K05) start with the details filled in, so the onboarding header reads "Step 2 of 3: Documents" instead of "Step 1 of 3: Your details".
- **Capture harness.** One `CAPTURE_ONLY` session now covers every registered catalog capture in every look, including the step indicator, media, box, inline, icon, divider, text area, checkbox, switch, link, icon button, amount text, badge and spinner specimens. The full session no longer shoots `_variants` captures, so each capture has one writer. The busy buttons are shot half a spinner cycle later, so their rings show a long arc instead of a dash. `ios_catalog_menu_open` is gone: on a phone the menu is the D55 sheet, and the Surfaces page now shows `ios_catalog_menu_sheet`.
- **Captures and docs.** Every docs capture was refreshed on iPhone 16 Pro, iPhone SE (3rd gen) and iPad mini, including new iPad captures of the KYC details, documents and review steps (#64). The Design decisions page gains a "UI review, 1 November 2026" section that summarises D45–D62 with links to the issues that hold the "before" evidence.

## UI review P7a (2026-11-01)

- **Pinned submit in KYC onboarding (D62, #64).** `PaymentOnboardingView` takes `primaryAction` and one quiet `secondaryAction`, pinned in the shared footer when its height is bounded, full width on phones; the footer is hidden while `pending` or `completed`. New `IdentityFormController` (a `ChangeNotifier`): `submit()` runs the form's own validation and focus-first-error and resolves `false` when a field is invalid, and `busy` / `canSubmit` drive a host button. `IdentityForm.controller` hides the form's inline button. `VerificationReview.inlineSubmit: false` hides the review's button, and `VerificationReview.submitButton(…)` builds the same button (disabled until every document is uploaded, busy with "Submitting…") for the footer; `VerificationReview.isReady` exposes that rule. All additive: without a controller or `primaryAction` the inline buttons stay. The example's details, documents and review steps pin "Continue", "Continue to review" and "Submit for verification". To pin a step's submit:

  ```dart
  final identity = IdentityFormController(); // the host owns and disposes it
  PaymentOnboardingView(title: title, tasks: tasks, primaryAction: PaymentButton(label: 'Continue', busy: identity.busy, onPressed: identity.submit), child: IdentityForm(fields: fields, controller: identity, onSubmit: save))
  ```

- **Header title never breaks inside a word (D59a, P5 regression).** When a header's title on one line and its "Label ›" link don't fit side by side, the link takes its own line under the header text, start-aligned with its 48 dp target, instead of taking half the row and breaking the title mid-word ("Transacti / ons" at 200% on a small phone). A ⋮ menu stays on the title row. No API change.
- **History: list before the month's figures (#58).** The example's history page shows the month's payments, refunds and most-used method after the transaction list, so at 100% on an iPhone 16 Pro the first row's title, amount and date are on the first screen. At 200% on an iPhone SE the first screen still ends before the first row (see #58).
- **Example app bar.** "Demo tools" moved from its own app-bar icon into the settings sheet, so the bar keeps at most two trailing actions and step titles such as "Konfirmasi pembayaran" fit at 100%.

## UI review P7b (2026-11-01)

- **Field labels above the box at large text (#73).** Above 1.5× text, `PaymentTextField`, `PaymentTextArea`, `PaymentCurrencyField`, `PaymentDateField`, `PaymentSelect` and the phone `PaymentSearchField` trigger show their label above the box, where it wraps, instead of a floating label that kept one line and ellipsized ("Date of birth (opt…"). The box keeps its height, so fields of different types still line up (#47). The label stays the field's spoken name, and tapping it focuses the field or opens the picker. While the label is above, the hint shows only when the field has focus, as it does behind a floating label. Normal text is unchanged. No API change. **Migration:** tests that find a field's label at 2× find it above the box; tests that read `InputDecoration.labelText` or `hintText` at 2× see null.
- **Quiet buttons on the column edge (#65).** A quiet `PaymentButton` with `width: PaymentWidth.hug` is a text action: its text starts on the column edge, like `PaymentLink`, and its press and focus box hangs outward by its padding (at most 12 dp, inside a 16 dp gutter); in a row's trailing slot the text sits on the end edge. It hugs its label with the 48 dp tap floor instead of the 112 dp hug minimum. The overhang is drawn but not tappable: the target, at least 48 × 48 dp, runs from the column edge past the end of the text. In a `PaymentButtonGroup`, in accordion actions, in `AdaptiveNavShell` app bar actions, and when it fills the width (footers, confirm sheets, stacked groups), its label stays centred as before. No API change. **Migration:** a quiet hug button in your own `Row` or `Wrap` now hangs into the gap before it; put side-by-side buttons in a `PaymentButtonGroup` to keep them centred.

## UI review P6 (2026-11-01)

- **Pinned priority action on the payment path (D62, #49, #64).** `PaymentConfirmation`, `AuthorizationPrompt`, `PaymentStatusView`, `VerificationIntro` and `VerificationStatusView` pin their priority action when their height is bounded, for example as a screen's body. The content scrolls in the 640 dp column. A footer at the bottom, inside the safe area, holds a full-width primary on phones, with at most one quiet action under it (D59): "Back to review" under authorize, and the host's `secondaryAction` or the quiet "Contact support" under the status primary. The status view's other actions, and every verification status action after the first, stay in the content as hug buttons. `VerificationIntro` shows its consent hint with the pinned Continue. Inside a scroll view (unbounded height) the layout is unchanged. New `header` on all five widgets (host content above the widget's own, inside its scroll region) and `PaymentStatusView.secondaryAction` (one quiet host action, e.g. "Done"; asserted quiet). All additive. **Migration:** a host that already gives one of these widgets a bounded height, such as `Scaffold(body: PaymentStatusView(…))` or an `Expanded`, now gets a pinned footer and an internal scroll. To keep the old inline layout, put the widget in a `SingleChildScrollView` or `ListView`. To keep a banner or summary above it in the same scroll, pass it as `header` instead of wrapping both in a `Column`:

  ```dart
  // Before: a Column hands the status view an unbounded height
  Column(children: [PaymentBanner(tone: StatusTone.info, title: 'Cancellation requested'), PaymentStatusView(attempt: a, onAction: act)])
  // After: the banner scrolls with the status and the action is pinned
  PaymentStatusView(header: PaymentBanner(tone: StatusTone.info, title: 'Cancellation requested'), attempt: a, onAction: act)
  ```

- **Example flow (D62, #49, #58, #64).** From KYC through the receipt the app's tab bar is hidden, and back leaves the flow. KYC intro and status, confirm, authorize, payment status and receipt fill the screen with their pinned action. The receipt's "Selesai" is the primary, with a quiet "Lihat detail" under it (#49-1). The checkout bar holds only "Tinjau pembayaran", busy while the total updates, so the total isn't repeated a third time and the bar is compact at 200% (#64, #58). Host tools move from the end of each step to a "Demo tools" sheet in the app bar. Cancel, back and close are quiet wherever they sit beside another action, including the footer Close of the gallery's order-details sheet, which repeated the header close (#49-3). A sheet whose only action is Close keeps it primary (D54).
- **Receipt share hugs its label (D59).** `PaymentReceipt`'s "Share receipt" is a start-aligned hug button instead of a full-width one, so under a screen's pinned "Done" it reads as an inline action, not a second footer action. No API change.

## UI review P5 (2026-11-01)

- **Centred content column (D53, #57).** At 600 dp and wider, views and pages keep their header, body and footer content in a centred column up to 640 dp; hairlines and scroll bars still span the window. From 840 dp, a page with a secondary column (`PaymentDetailPage` with `secondary`, `PaymentFullPageView` around a `PaymentOverviewPage` with `secondary`) keeps two columns up to 1040 dp. `PaymentOnboardingView`'s wide sidebar layout is centred up to 1040 dp. `PaymentActionBar` keeps its content in the 640 dp column. Phones are unchanged.
- **Header navigation, footer action (D59a, D62, #63, #64).** On phones a page header holds navigation only: `pageLink`, or a single header action, sits on the title row as "Label ›"; two or more actions go behind ⋮ (the D55 action sheet). Nothing stacks under the title any more. Wide headers keep their hug buttons. The screen's priority action pins in a bottom footer: full width on phones, with at most one action under it (D59). New `PaymentFullPageView.pageLink`, `.primaryAction` and `.secondaryAction`, and `PaymentDetailPage.primaryAction` and `.secondaryAction`, all additive. `ViewFooter` stacks below 600 dp instead of 400, so `PaymentContextView`, `PaymentSettingsView` and `PaymentFocusView` footers are full width on every phone. **Migration:** `PaymentFullPageView.pageAction` is deprecated (removed in 0.2.0); it still renders. Use `pageLink` for an action that opens another screen and `primaryAction` for the screen's main step:

  ```dart
  // Before
  PaymentFullPageView(title: 'Transactions', pageAction: PaymentButton(label: 'Statement', onPressed: openStatement), child: body)
  // After
  PaymentFullPageView(title: 'Transactions', pageLink: PaymentLink(label: 'Statement', onPressed: openStatement), child: body)
  ```

  Tests that tapped a phone header button by its `PaymentButton` type find a link with the same label and key, or the ⋮ "More actions" sheet.
- **Large text (#49, #66).** At large text the header scrolls with the body instead of staying pinned, so the context and settings views show their content on the first screen at 200%.
- **Account-linking sign-in (D61, #63, #58).** `PaymentSignInView` shows the connecting app's tile (`requesterBrand`) beside the account's (`brand`), one headline, what the app can do (`canDo`, ✓) and can never do (`cannotDo`, ✕) in plain view, and pins one legal sentence (`legalNotice`, with `{0}`, `{1}` replaced by inline links to `legalLinks`), the primary and a quiet secondary to the footer, so the action stays on the first screen of a small phone at 200%. The brand shows as a 48 dp tile. New strings `signInCan` / `signInCannot`. Without `legalNotice`, `legalLinks` still render as a row of links. **Migration:** `learnMore` and `footnote` are deprecated (removed in 0.2.0) and still render; move what the app can see into `canDo` / `cannotDo`, and reassurance such as "never sees your PIN" into `cannotDo`.
- **Detail page (#63, #66).** The phone breadcrumb's chevron hangs outside the column so its glyph starts on the title edge, and the breadcrumb → title gap is one gap instead of 16 + 16.
- **Tables on wide screens (#57).** `PaymentTable` and `PaymentDataTable` cells and headers share one inset; the outer cells sit on the content edge, so a numeric last column ends on the value edge. A data-table ID cell starts on its column edge.
- **Field group legend (#66).** In `PaymentFormFieldGroup` every first control sits 16 dp below the legend: a field's edge (it was 8 dp) and a checkbox, radio or switch row's label (it was about 22 dp). The row's 48 dp target reaches into the gap but never onto the legend. Rows outside a group are unchanged.
- **Other #66 items.** `PaymentContextView`'s leading icon centres on the title's first line, 12 dp from it. `PaymentOverviewPage` modules are spaced evenly (a chart module gets the same space under it as a page module). `PaymentOnboardingView` spaces the error, content and "All steps" accordion by 16, and its loading row has a 12 dp gap between spinner and text. A single link value in `PaymentDetailPagePropertyList` shares its label's line in every layout.

## UI review P4 (2026-11-01)

- **Search sheet on phones (D50, #54).** Below 600 dp `PaymentSearchField` is a field trigger that opens a full-height search sheet: a focused search field, 48 dp result rows and, for `.multiple`, the draft chips and a full-width "Done" ("Selesai") that applies them; close discards the draft. Focus returns to the field, and focusing it from code never opens the sheet. At 600 dp and wider the list floats in an overlay with the surface fill, the control edge and elevation instead of pushing the page down. The API is unchanged. **Migration:** a phone-sized test that typed into the field's `EditableText` now taps the field and types into the sheet's.
- **Kit date sheets (D52, D52a, #56).** `PaymentDateField`'s calendar button no longer opens Flutter's `showDatePicker`. It opens a kit sheet with a full-width "Choose date" ("Pilih tanggal"): a day / month / year wheel when `lastDate` is more than five years after `firstDate` (a date of birth), opening at the value or at `lastDate`; otherwise a full-height month calendar. Typed entry stays the primary path, with validation on blur unchanged. The sheets respect large text and use kit colours and en / id strings. **Migration:** tests that look for a `DatePickerDialog` find a `BottomSheet`; tap a day by its spoken date and then "Choose date". Hosts no longer need `GlobalMaterialLocalizations` for Indonesian calendar labels. Pass `lastDate: today` for a date of birth.
- **Kit range calendar (D51, #55).** "Custom range" no longer opens `showDateRangePicker`. It opens a full-height sheet with scrolling months: the first tap sets the start, the second the end, and the range shows in the accent. "Type dates" in the header switches to two typed fields. The pinned footer shows the range, a full-width "Apply" ("Terapkan") and a quiet "Clear" ("Hapus") that reports `null`. Weeks start on Monday in Indonesian. "Custom range" in the presets sheet is now a radio row on the presets' text column. **Migration:** pass `lastDate: today` for history ranges; tests that tapped the Material "Save" now tap "Apply".
- **New `PaymentLocalizations` members.** `monthName(int)`, `formatMonthYear(DateTime)`, `formatDateLong(DateTime)`, `weekdayShort(int)` and `firstDayOfWeek`. Additive.
- **Form items (#65).** An empty `PaymentSelect` keeps its hint on one line, so it matches its siblings' height at 200%. A horizontal `PaymentFormFieldGroup` stays side by side while each field gets 140 dp (it was 360 dp for the whole group), so Month / Year fit a phone card. `IdentityForm` puts 24 dp around field groups and before its action. A radio group's error goes on the last option only (documented on `PaymentRadio.errorText`).

## UI review P3 (2026-11-01)

- **Reference rows (D57, #62).** `InfoRow.reference`, `PaymentPropertyListItem.reference` and `PaymentDetailValue.reference` show an ID or reference as monospace tabular text on the value edge, with no fill. A trailing copy button centres on the first line and its glyph sits on the value edge while the 48 dp target stays in the row. `PaymentDetailValue.onCopy` adds that copy button. Keep `PaymentCode` for multi-line technical text. All additive.
- **Exact chart values (D58, #62, #63).** Line and bar charts select the latest settled period at rest and show its exact value ("29 Okt · Rp420.000", tabular) in a fixed band above the plot, with a guide line from the point or bar top. The selected point is a filled dot; the selected bar, or the group of bars, gets a 1.5 dp accent outline 2 dp outside it, open at the baseline. Tap, horizontal drag or hover selects another period; leaving returns to rest. `inspectable: false` keeps the rest label without gestures. Series of 12 points or fewer mark every settled point. The y-axis gutter fits its scaled labels instead of a fixed 76. With several series the label has one line per series; only the first repeats the period, and a long series name truncates before the amount does. `ChartModule` reserves the headline caption line only when there is a caption or delta, puts a `group` (16) gap under the headline instead of `section` (24), and caps the plot at `compactHeight` above 1.5× text (#58). The sparkline is unchanged. **Migration:** the plot starts below the value band, one caption line per series (22 dp at 1× for one series, as before; about 40 dp for two; more at large text), so a host that measured plot geometry sees a smaller plot. Modules with a headline are 8 dp shorter, and 26 dp shorter (18 dp line + 8 dp gap) when they have no caption or delta.
- **Table rows on phones (D60, #63).** Narrow and large-text `PaymentTable` and `PaymentDataTable` rows show the title on the first line, with the data table's checkbox and ⋮ centred on it, and every other column, amount included, as a label on the start edge and its value on the value edge. "Label: value" text and the floating amount are gone. The table's Total footer has a divider before it. The data table's select-all label starts on the row titles' inset, and an ID title shows non-breaking hyphens (U+2011) on one line, scaling down only when it does not fit, so it never breaks at a hyphen or mid-digit; speech keeps the original. **Migration:** tests that found narrow cells by "Label: value" text, or a narrow ID title by its hyphenated text, find the value text on its own, or the title with U+2011 (its semantics label is unchanged).
- **Section header (#62).** `PaymentSection` uses one 36 dp header band with or without a trailing action; the action's 48 dp target overhangs the band into the section padding. Titled sections without an action grow from 24 to 36 dp in the header.
- **Navigation (#62).** The selected item adds heading weight and a 2 dp accent indicator on its start edge, so the fill is never the only cue. Rows are 48 dp apart (no 4 dp gap).
- **Dates (#63, #65).** `formatDate`, `formatDateTime` and `formatDateRange` join day, month and year with no-break spaces (U+00A0). A same-month range glues its en dash with U+2060 ("1–31 Oct 2026" never splits); a longer range keeps one break after "– ". **Migration:** hosts or tests that compare formatted dates with plain-space strings compare with ` ` instead.
- **Other #62 items.** The task list documents its connector: it marks order, not progress. The image specimen gets run spacing.

## UI review P2 (2026-11-01)

- **Confirm sheet on phones (D45, #45).** Below 600 dp `showPaymentConfirmDialog` is a bottom confirm sheet: title, message, then full-width actions with the confirm action on top and a quiet Cancel below, on one 16 dp inset at every text scale and language. At 600 dp and wider it is a centred dialog with one row of equal-width buttons, confirm trailing. The scrim, swipe down, Back and Escape still resolve `false`, and Cancel still gets first focus when the action is destructive. The signature and `Future<bool>` are unchanged. **Migration:** tests that look for an `AlertDialog` find a `BottomSheet` on phone-sized surfaces and a `Dialog` on wide ones.
- **Menu action sheet on phones (D55, #61).** Below 600 dp `PaymentMenu` opens a bottom action sheet: full-width 48 dp rows, group titles as captions, destructive items last after a divider, and a full-width Cancel. The sheet closes before `onSelected` or `onAction` runs, and focus returns to the trigger. On wide windows the anchored menu keeps 16 dp from the window edges, and items without an icon keep the icon column when a sibling has one. **Migration:** a test that taps a phone menu item and checks the callback after a single `pump()` now needs `pumpAndSettle()`.
- **Tap tooltips (D49, #53).** `PaymentTooltip` opens on tap as well as on hover, long press and focus. A second tap, an outside tap or Escape closes it. The new `trigger` builder (`(toggle, focusNode) => PaymentIconButton(…, onPressed: toggle)`) makes an info button toggle its hint, hides the button's Material tooltip and keeps its name for screen readers. **Migration:** `child` is now nullable; pass exactly one of `child` and `trigger`. An info icon with a no-op `onPressed` moves to `trigger`.
- **Banner anatomy (D48, D48a, #52).** The tone icon and the close glyph centre on the title's first line. Title, message and actions share one text column. The close target overlaps the padding, so a dismissible banner keeps the height of the same banner without close. A banner button draws small. **Migration:** `PaymentBanner.actions` now asserts at most one hug secondary `PaymentButton` plus at most one `PaymentLink`. Turn a quiet button or a second button into a `PaymentLink`, and drop `onDismiss` from a banner about a changed amount while the payment is open; that banner states old → new.
- **Stacked button groups (#65).** `PaymentButtonGroup(collapse: none)` keeps one row of hug buttons while they fit. Otherwise it stacks every button at full width, with the emphasized action on top.
- **Sheets, state message, privacy mask (#61).** `PaymentSheetHeader` centres the title's first line on the close button at every text scale, and keeps that height while the close button is hidden. The `StateMessage` action hugs its label (no 280 cap), and its message uses the body size for the text scale. `PrivacyMask` keeps its lock 16 dp from the edges and scales it down in a short strip.
- **One primary per surface (D54); no warning button (D47).** The example's sheet "Done" is primary and the trigger that opens a sheet stays secondary. The promo "Why this?" opens a sheet with one primary Close. Docs only: warnings are banner, badge or toast states, not a button variant.

## UI review P1 (2026-11-01)

- **Spacing roles (D46, #50).** Every kit spacing value resolves through `PaymentTheme.space(PaymentSpace.<role>)`; one role uses one value. StatusHeader's icon → text gap moves from 8 to `block` (12), like toast, banner, state message, accordion and skeleton. The chart's unknown-point square and the navigation badge padding move from 7 to 8. No API change.
- **First-line alignment (D56).** List rows, accordion headers, toasts, state messages, status headers and the task list centre their icon and trailing control on the title's first line: a single-line list row shares one centre line with a 48 dp control, and the toast icon no longer sits 4 pt above its message.
- **List values at large text (#60).** Above 1.5× text a `PaymentListItem` value moves under the title at label size instead of shrinking beside it.
- **Tabs (#60).** A tab row that scrolls shows an end fade, and the selected or focused tab scrolls into view.
- **Fields (#47).** Every field size has explicit padding: text starts 16 in and fields are 48, 56 and 64 dp. Search suggestions share the field's text edge. The currency field matches the text field's height.
- **Chips (#48).** Labels centre in the 48 dp box with 16 dp side padding; a chip that wraps becomes a rounded rectangle so text never enters the pill's ends.
- **Stable layouts (#46).** The action bar keeps one height while the total updates. Loading skeleton rows match a two-line list row and use the outline fill. The countdown reserves its widest format. Chart readouts and meter legends use tabular figures. **Migration:** a host that sized a box around `LoadingSkeleton` needs about 62 dp per row (12 + 20 + 18 + 12) instead of 48.
- **Copy failure (#46).** `PaymentCopyButton` keeps its 48 dp box: failure shows a danger glyph and a persistent "Copy failed" label under the button, cleared by the next press or a new value. **Migration:** hosts that laid out space for the old inline label under the button no longer need it.
- **Link edges (#65).** `PaymentLink` text starts on the column edge and its 48 dp target extends past a short label; trailing links in section headers sit on the end edge.
- **Demo (#59).** Every gallery specimen and the flow screens' table, property and chart labels are bilingual; captures add Indonesian looks (`_id`, `_id_200`).

## Design system Phase 4D-2 (2026-11-01)

- Delivers the 4C–4D specimen captures: 45 new images and 6 refreshed Code/Tabs images.
- Add page modules and detail/overview pages; code wrapping, edge fades and fitted-tab fallback. Closes #18.

## Design system Phase 6-3 (2026-11-01)

- Add 14 named kit specimens, including empty/error messages, loading, contextual layouts and all chart-module states.
- Refresh the full native capture catalog and add sign-in, KYC onboarding, history, transaction detail, report, statement, fees and settings screenshots to component/pattern documentation.
- Replace legacy component captures with named specimens; deprecated D34 aliases remain until 0.2.0.
- Preserve horizontal detail-property composition while keeping vertical link values centered.

## Design system Phase 6-2 (2026-11-01)

- Give all 65 component pages a closed variant set, payment-specific selection rules, do/don't guidance, real source usage and example/story references.
- Document Step indicator, Action bar and Chart module; document PaymentEmptyMessage with state messages.
- Replace placeholder dartdoc with field meaning and add check:pages as a permanent docs structure lint. No runtime API changes.

## Design system Phase 6-1 (2026-11-01)

- Flatten the component sidebar, move payment flows into Patterns and redirect 13 legacy URLs in Astro and hosting configuration.
- Publish the 48-entry Stripe-to-kit overview, five composition patterns and the D28-only Not in the kit reference.
- Deprecate unsupported DataTable reorder/resize flags, callback and unused strings under the approved D28 amendment; removal is scheduled for 0.2.0.

## Design system Phase 5-3 (2026-11-01)

- Add transaction detail with reference copying and attempt history; report problems through a focused task with discard confirmation and safe host metadata.
- Add settlement statements with search, selection and download preparation, fee schedules with contextual help, and grouped account settings with save/retry feedback.
- Add A02–A05 fixtures and the H04 sign-in → KYC → payment → detail → report integration story. No public library API changes.

## Design system Phase 5-2 (2026-11-01)

- Add external sign-in with cancellation retry, KYC onboarding with grouped identity fields and province search, and transaction history with spending, date presets and removable filters.
- Show order context beside wide checkout; keep one primary payment action.
- Add H04 and A01 scenarios, including empty and failed history states. Example-only changes; no public package API delta.

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
