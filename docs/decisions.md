# Decisions and tradeoffs

The owner asked for the component foundation to be completed with decisions made on their behalf. This page records each decision, the reason, and its cost, so they can be reviewed or reversed.

## Scope

- **Bounded inventory.** "All components" was interpreted as: interaction (action rows, menu, confirm dialog, snack bar, disclosure, loading/empty/error), navigation (sidebar, drawer shell), sheets/drawers, video, promotions, and payment additions (action bar, merchant header, step indicator, balance, promo code, transaction history and detail). Not a general design system: Material widgets that already work are used directly rather than wrapped.
- **Out of scope, still.** Real wallets, PIN entry, card storage, ledgers, ad SDKs, real campaigns, tracking. These appear as a disabled "Saved cards" item in the gallery to show the disabled-with-reason state.
- **One package.** New modules live in the same package (`lib/src/interaction`, `navigation`, `overlay`, `media`, `promo`, `payment`). Splitting would only pay off once a consumer needs part of it without the rest.

## API shape

- **Composition over configuration.** `PaymentSheet(header:, body:, footer:)` takes widgets, not a config object; `PaymentSection` gained an optional `trailing:` action instead of a new card type.
- **Controlled where the host owns state, uncontrolled where it doesn't.** `TransactionHistory` (query, filter, records) and navigation selection are fully controlled. `ExpandableSection` supports both modes.
- **Host verdicts, not UI math.** `BalanceCard` takes `BalanceState`; `PromoCodeInput` takes `PromoCodeStatus`; a discount reaches the total only as a new host quote. This keeps the payment invariants from v0.1 intact.
- **Media through an adapter.** `PaymentVideoController` is an abstract `ValueNotifier`. The package stays free of native plugins; the example's 100-line adapter uses the official `video_player` 2.11.1, already cached locally and compatible with Flutter 3.44 and Android API 24.
- **Strings in an extension.** New strings are `KitStrings` on `PaymentLocalizations`, so hosts keep one delegate.

## Interface details (Emil Kowalski's design engineering review)

| Before | After | Why |
| --- | --- | --- |
| Review file names broke mid-word (`ktp_demo_retake.pn` / `g`) | Values keep their width up to 60% of the row; long names use `MiddleEllipsisText` (`ktp_demo_ret…ake.png`) | A file name's start and extension both matter; never break a word mid-character |
| Headline amounts could clip at 200% text (`maxLines: 1`, no fallback) | `FittedBox(scaleDown)` and headline totals capped at 1.6× scale | A hidden digit in a payment amount is worse than a slightly smaller one |
| Checkout "Review" button below the fold; total far above it | `PaymentActionBar` pins the total and action; label above the amount, button hugs its text | The final total and the main action are what the customer needs together |
| Re-quote dimmed the whole summary to 50% opacity | Bar says "Updating total…", action disabled, summary unchanged | Same feedback without an offscreen layer per method switch |
| Status hero: 64 px icon circle and a badge repeating the same icon and title | One 52 px tinted icon and one tone-colored title | Redundant signals add height and push "Check status" below the fold |
| KYC review "Edit" buttons on their own rows; submit below the fold | "Edit" in the section header, spoken as "Edit: Your details" | Saves two rows; two identical "Edit" labels were ambiguous to screen readers |
| App bar title "Status pembaya…" truncated | "Pembayaran" / "Payment" | The status is already the page's headline |
| Method tile clipped its ink with a rounded `Material` clip | `InkWell(borderRadius:)` without the clip | Same ripple shape without a clip on every tile while scrolling |
| — | Navigation selection, drawer items, menu opening: no animation | Used constantly and by keyboard; animation would only add delay |
| — | Sheets 280 ms in / 200 ms out on the iOS drawer curve; disclosure 220/150 ms; chevron 150 ms rotation | Larger surfaces get slightly longer; exits are faster; transform-only where possible |
| — | `LoadingSkeleton` is static | A shimmer repaints every frame and adds no information |
| — | Video controls under the picture, not over it | Always readable, never cover content, survive 200% text |
| Sponsored label truncated the advertiser at 200% | Disclosure wraps to a second line | Who paid for a placement must always be visible |
| Merchant initials clipped, badge floated beside a wrapped name at 200% | Initials fit the box; badge flows inline after the last word | Large text should reflow, not clip |

Reduced motion sets every duration to zero, keeps the busy state as a static icon, and blocks video autoplay.

## Accessibility decisions

- Drawer: opening moves focus into it; scrim, Back and Escape close it; focus returns to the menu button; closed items are not in the tree.
- Disabled navigation and action rows stay visible with a reason; they are not focusable.
- Destructive confirmations put initial focus on the safe choice.
- Sheets separate **Close** (UI only) from **cancel payment** (host request behind confirmation, result still pending until the host confirms).
- Video: every control has a label, the seek slider speaks "0:04 of 0:08", and loading, buffering and finished states are announced.

## Performance

The PRD budget is p95 build and raster each under 16.7 ms on a recorded 60 Hz target after a 30 s warm-up. The harness now measures a 30 s window (it measured 20 s before). Android 11 arm64 emulator, profile mode, Impeller on OpenGL ES, X02 checkout at 200% text, fling both ways plus method switch:

| Run | Workload | Build p95 | Raster p50 | Raster p95 |
| --- | --- | --- | --- | --- |
| Before this pass (20 s window) | Checkout 200% | 2.16 ms | 14.92 ms | 19.49 ms |
| Attempt 1 | Checkout 200% | 1.85 ms | 16.63 ms | 31.13 ms |
| Attempt 1 | Same at 100% text (diagnostic) | 1.96 ms | 16.26 ms | 31.83 ms |
| Attempt 2 | Checkout 200% | 2.02 ms | 16.12 ms | 20.41 ms |
| Attempt 2 | Same at 100% text (diagnostic) | 1.94 ms | 16.45 ms | 20.22 ms |
| Attempt 2 | Plain Material list, no kit widgets (control) | 2.37 ms | 16.41 ms | 20.66 ms |

Build time is within budget. The plain Material list also misses the raster budget in the same session. The similar control results and session variance suggest that the emulator's presentation path contributes substantially. They do not isolate every kit rendering cost or prove that the kit cannot be improved. The raster budget is **not met in this environment**. A comparable measurement on another suitable runtime or device would help isolate the cause; physical hardware is not a new mandatory delivery gate.

Artifact limitation discovered during parent review: the screenshot driver overwrote `build/perf/summary.json` with screenshot report data after Attempt 2. Those image bytes were preserved outside the profile folder; Attempt 1's raw metrics remain in `build/perf/checkout_attempt1.json`. Attempt 2's numbers above are the implementation run's recorded results, but its raw summary was not retained. The driver now writes performance output only when the report contains checkout metrics, so later screenshot runs cannot overwrite it. Future profile runs create `summary.json` again. No additional benchmark was run just to replace this artifact.

## Parent review fixes

- A loading video could become ready after the app entered the background and trigger opt-in autoplay. A focused regression reproduced it. Playback now tracks foreground state and consumes autoplay on backgrounding, so returning always requires a tap.
- Older gallery examples contained empty callbacks and clipboard callbacks that reported success without copying. They now show explicit synthetic-host feedback, simulate authorization, preview allowlisted receipt text, and use the real clipboard API with failure handling. The full business flow remains in the Demo tab; gallery feedback does not claim a payment or KYC submission.
- The new component journey was run on iPhone 16 / iOS 18.1. Native video advanced to 4.5 seconds, paused on tab change, and the generated screenshots were inspected.

The code changes that removed per-frame work in checkout (no opacity layer during re-quote, no rounded clip per method tile) are justified by inspection. On this emulator their effect is below the noise.

## Visual redesign: Stripe-calm · Hairline (30 Oct 2026)

The owner rejected the Material-default look. Research, references and the chosen option are in [design-research.md](design-research.md) (section 0).

| Before | After | Why |
| --- | --- | --- |
| Every `PaymentSection` a 16 px bordered card | Flat sections separated by space and hairlines | Library widgets live inside host cards and sheets; flat rows nest without card-in-card |
| Total at 44 px in the summary and again in the bar | Summary leads with the total (32 px), a hairline, a body-weight total row; the bar keeps a 20 px total beside the action | The amount is read first, as on Stripe's hosted checkout; one display size per screen region |
| Method tiles: separate tinted bordered boxes with icons | One bordered list, radio on the leading edge, 2 px outline on the selected row | The selected method is the only emphasized box; method icons repeated their labels |
| Status: centered 52 px icon circle, unknown and pending both orange | `StatusBand` (hatched = unknown, solid = other), icon + title, left amount, "Don't pay again." first | Unknown must not look like pending; shape, tone, icon and words carry it together |
| "Last updated: Not confirmed yet" when no snapshot | Row omitted until a host snapshot exists | A status phrase in a timestamp row was misleading |
| Buttons scale to 0.97 on press | Full-width buttons rely on the pressed state layer | Scaling a 320 dp slab moves its edges several pixels and reads as a lurch |
| Pill chips with check marks for history filters | Text tabs with a 2 px underline, no weight change | Filters are views of one list; weight changes reflow text |
| Drawer/sidebar selection: tonal pill, later a 3 px bar on the leading edge | Selected color plus a muted fill, no bar | The bar read as a stray line beside the item; the fill is the non-color signal |
| Gallery captions and state selector scaled with product text (up to 1.5×, selector unbounded) | Capped at 1.2× | At 200% the developer chrome outgrew the component it documents; product text still scales fully |
| Off-grid gaps: 6 px (`spacing × 0.75`), 10 px (`spacing × 1.25`), 6/2 tag padding, 2 px between nav items, 22 px bottom-bar icons | 8 px grid with 4 and 12 as half-steps: 8, 12, 8/4 tag padding, 4 px, 24 px icons | One spacing system; strokes (1–3 px) and 1–2 px optical nudges are not spacing and stay |
| Gallery fixture chips styled like product filters | Monospace state selector outside a framed specimen on a grey workbench | Reviewers could not tell developer controls from the product |

Contrast: tone foregrounds are fixed values (light ≥ 5.8:1 on white, dark ≥ 7.6:1 on #131417); the unselected radio uses the secondary text color (≥ 3:1). Verification: `flutter analyze` clean, 57 package tests (two new: unknown outcome without a fake update time; failed struck through, refunded not), 12 integration flow tests, and native screenshots in `example/build/screenshots_hairline/`: 45 on iOS (iPhone 16 simulator, iOS 18.1; light, dark, 200%, id/en) and 30 on Android (the `flutter_minimal` emulator, kit suite only; the pending and receipt flow captures exist for iOS only).

Open items from this pass:

- Focus outline (design rule 6) and compact-control press scale (rule 10) are not implemented yet; `PaymentMotion.pressedScale` is unused.
- Judgment calls made during the restyle, to confirm with the owner: expired amounts are no longer struck through (only failed and canceled); `BalanceCard` shows its balance at 20 px instead of the 32 px headline; `ActionTile`, `ExpandableSection` and `TransactionListItem` dropped their side padding to align with section titles (hosts listing them edge to edge add their own); in the history list pending and unknown share the amber tag and differ by icon and word, with the hatched band only on the detail screen; `PromoContent.icon` is accepted but not drawn; `ActionMenu` keeps a light shadow so it reads as floating.
- Summary item labels use the secondary text color, like every `InfoRow` label; Stripe sets item names in the primary color and only fees muted.
- `flutter test` intermittently fails to load a test file with "Unable to connect to flutter_tester process: WebSocketException" on this machine, also with `--concurrency=1`; runs that load pass 57/57. Environment issue, not a test failure.

## Large-text review and foundation pass (30–31 Oct 2026)

Orchestrated: an Opus (high) planner wrote [ui-review-plan.md](ui-review-plan.md) and [foundation-plan.md](foundation-plan.md); Opus (medium) executors implemented disjoint work packages; the orchestrator verified on devices.

| Before | After | Why |
| --- | --- | --- |
| At 200% text the status screen's only action ("Cek status") fell below the bottom bar | `StatusHeader` (icon grows with text up to 1.6×, centred on the first line); actions before the reference rows; unknown copy drops the sentence that repeated the button | The one action that resolves an unknown payment must be reachable without scrolling |
| Summary headline, Total row and bar total all shown at 200% | Headline omitted above 1.5× text; bar total capped at 1.6× | Three copies of the same number crowded the first screen |
| Label/value rows always stacked at large text | They share a line when they fit (value at the end edge), otherwise the value wraps flush left | Less vertical space without clipping |
| No visible keyboard focus; `pressedScale` unused | Neutral 2 px focus ring (keyboard only) on MVP and secondary controls; compact controls press to 0.96 over 100 ms, full-width buttons do not scale, reduced motion disables it | Design rules 6 and 10 |
| ~90 ad-hoc text styles borrowing Material roles (stray letter-spacing, 4 line-heights at 15 px, 4 weights) | Internal `PaymentType` with 9 roles on 7 sizes and 2 weights (400/600), explicit leading and zero tracking | One type system; Material defaults no longer leak in |
| `outline` (1.25:1) used for control edges; disabled = Material opacity | New `border` (≥ 3:1) for control edges, `disabled` solid token, `outline` stays the decorative rule | Inputs and secondary buttons need a 3:1 edge; opacity-disabled is unpredictable |
| VA pending: two 32 px amounts, w700 countdown, VA number as a tracked amount | One display amount; VA number in monospace (`referenceFontFamily`); countdown 15 w600 tabular; steps folded under "Cara bayar" | One display amount per screen; reference numbers read digit by digit |
| VA instructions appended after the status view | `PaymentStatusView.instructions` slot: before the actions at normal text, after them above 1.5×; hidden when the outcome is unknown | Keeps "Cek status" on the first screen at 200%; an account to pay into must not appear while the outcome is unknown |
| Authorization "ready" in a blue info box; green applied discount | Plain title and muted message; banners only for failed/expired/canceled; discount in ink | Tinted boxes are for problems, not the normal path |
| Section gaps 36–48 dp, sheet gutter 20 | Spacing 4/8/12/16/24/32; sections stack to 24; sheet gutter 16 | One rhythm across screens |

Public API additions (all optional): `StatusHeader`, `InfoRow.trailing`, `PaymentStatusView.instructions`, `PaymentTheme.border`/`disabled`/`referenceFontFamily` and radius getters, `PaymentLocalizations.howToPay`. Changed values: `PaymentMotion.press` 100 ms, `pressedScale` 0.96. `PaymentType` stays internal until the owner approves making it public.

Superseded: `PaymentType` exported in Phase 1A (D15, Q6).

Verification: `flutter analyze` clean (package and example); 89 package tests across 7 files pass when run per file; 12 integration flow tests pass on the iPhone 16 simulator; iOS screenshot suites (including new `status_va_pending`, `requote`, `authorize` captures) pass with no exceptions. Focus and press are verified by widget tests only (static screenshots cannot show them).

Open: the re-quote checkbox sits ~11 dp inside the gutter (Material list-tile tap target); `AmountInput` caps its label/helper at 1.6× along with the amount; Lumen/Contrast preset still close to Hairline.

## Charts and KYC capture (31 Oct 2026)

Charts here are customer-facing spending summaries. PRD §4 excludes operational dashboards; this work does not add one. PRD.md stays unchanged.

- Chart values are Money and each chart uses one currency. Only settled values enter spoken lowest/highest/latest summaries. Pending is outlined/dashed, unknown is hatched/dotted, and missing leaves a gap. Unknown must never look like pending.
- Host verdicts, not UI math: a ChartModule headline and delta come from the host. The kit never computes a displayed total. Meter widths use amounts, while legends show amounts, never percentages.
- ChartState mirrors PromoSlot states. Hosts choose loading > error > empty > ready. Plot height stays constant across states; meter height is intrinsic.
- Meter categories use an accent-to-surface ramp with at most five entries, constrained to 3:1 surface contrast. Status tones are not categories. Hosts group extra categories into Other.
- Compact money is only for axes: Indonesian rb/jt/M/T with NBSP; English K/M/B/T. Integer rounding promotes a carried suffix and never changes payment confirmation formatting.
- Line/bar pointer inspection is supplemental and has no keyboard inspection target. Generated summaries expose the same amounts without pointer use. No multi-series chart support.
- Capture source choice precedes host permission. The kit opens no camera, gallery or file picker and performs no OCR, liveness, face matching or photo scoring. The host owns photos, uploads and verdicts. Uploaded is not verified.
- Camera previews use a theme-independent black54 scrim and white outline for visibility over arbitrary content. Illustration surfaces use theme tokens. Overlays ignore pointer input.
- Demo photos use PictureRecorder, a CONTOH / SPECIMEN watermark and a drawn masked NIK. Photo bytes live only in the capture screen. SyntheticIdCard uses PrivacyMask for its NIK row.
- The foundation specimen adds compact money; the amount, info-row and status-badge alt text changes travel with the refreshed capture.

Implementation details resolved against the repository: PaymentButton has a secondary variant, not a named secondary constructor. MeterSegment is non-const to keep its non-negative Money assertion (Dart disallows property access in a const assertion). Capture geometry lives in a separate internal file so ratio and face/card separation can be tested without rendering. The gallery uses shorter capture viewports; the flow guide retains its portrait default. The Starlight changelog keeps its required frontmatter and mirrors the root changelog body verbatim.


## Design system revision 3 and Phase 1A (31 Oct 2026)

Owner answers, accepted for implementation:

| Question | Decision |
| --- | --- |
| Q1 | Superseded: field kinds, D36. |
| Q2 | Keep switches. |
| Q3 | Internal resolvers. |
| Q4 | Patterns. |
| Q5 | onCopyReference. |
| Q6 | Export PaymentType. |
| Q7 | PaymentSize + PaymentWidth, D29. |
| Q8 | PaymentListItemSize standard/large. |
| Q9 | Remove MeterSegment.color. |
| Q10 | Restyle toast. |
| Q11 | Map Stripe text onto nine roles, D35. |
| Q12 | DD/MM/YYYY in both locales, host-overridable. |

| Decision | Contract | Reason and source |
| --- | --- | --- |
| D28 | **Parity rule.** All 48 Stripe entries and their sub-components ship (admission clause (c)). Their props are variants, translated by the §6 conventions table. **Not mirrored**, each with its reason: `TextField type: "password"` (D1a); CurrencyField `fractionDigitOffset` (`Money` is integer minor units); Box and Inline numeric sizes, `margin`/`bleed`, shadows, `zIndex`, `overflow` (B2, §3.5); DOM attributes; the SVG-string `brandIcon` (→ a host widget); DateRangePicker `timeZone` (host-owned dates); OnboardingView's auto-close delay (D44). Every `href` or route is a host callback. | The owner's decision, held inside the constraints that still apply: SDK only, no network, no secrets, host-owned decisions.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D29 | **Sizes keep a 48 dp hit area.** `PaymentSize` (`small`, `medium`, `large`) changes the drawn container and padding only. The layout box, which bounds Flutter hit-testing, stays ≥ 48×48 dp, with the visual centered, as Material's padded tap target does. `medium` is today's look and the default everywhere. | Stripe's sizes are visual. Flutter hit-tests within the layout box, so the only way to keep B5 with a 36 dp button is a 48 dp box. The cost is row height, which is accepted.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D30 | **Tables on phones collapse rows into list rows.** Below 600 dp of available width, or at `PaymentType.isLarge`, `PaymentTable` and `PaymentDataTable` render each row as a list row: the pinned or row-header cell is the title, numbers sit end-aligned, other cells become caption lines, and actions become a trailing menu. The wide layout keeps columns and scrolls horizontally, with pinned columns fixed. | Horizontal scrolling with a sticky column fails at 320 dp and 200% text (B4): two-axis scrolling, clipped headers, and cells read without their header. The collapse reuses the list anatomy and its semantics.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D31 | **Views and pages are Scaffold-free bodies** with header, scroll content and footer regions. The host supplies the `Scaffold`, route, tab or sheet. Only FocusView presents itself (`showPaymentFocusView`, through the existing sheet functions). No router, no app bar, no `Navigator.push` otherwise. | PRD §2 keeps routing with the host. One rule for all eleven layouts. It matches `PaymentSheet`, which already lays out header, content and footer.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D32 | **`PaymentSignInView` has no credential input and no free widget slot.** Actions call the host; the footer takes `PaymentLink`s and a footnote only; a test asserts no `EditableText`. | Stripe's SignInView is itself a redirect-to-sign-in screen. The kit never receives secrets (PRD §7, §11).  [PRD §8](prd-foundation-components.md#8-decisions) |
| D33 | **Token primitives.** `PaymentBox`, `PaymentInline` and `PaymentIcon` accept only **New** token enums: `PaymentSpace`, `PaymentRadius`, `PaymentTextRole`, `PaymentTextColor`, `PaymentFontWeight`, `PaymentIconSize`, `PaymentKeyline`. Supersedes D16 and D26. `PaymentType` itself gains no roles. | Parity, without opening a raw-value escape hatch that would break B2.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D34 | **Naming.** Stripe entries are `Payment<StripeName>` (Img → `PaymentImage`). Renamed classes on `main` (`ExpandableSection`, `StatusBadge`, `NoticeBanner`, `ActionMenu`/`ActionMenuEntry`, `AmountInput`, `ActionTile`/`ActionTileGroup`, `showPaymentSnackBar`) stay for one minor release: as a `@Deprecated` typedef when the constructor is unchanged, otherwise as a deprecated wrapper. Names only on #1/#4 change freely. Kit-specific names (`InfoRow`, `PaymentSheet` …) stay. Docs slugs follow the Stripe name, with redirects. | One naming scheme that a reader can map to Stripe's sidebar; §9 rule 6 for anything on `main`.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D35 | **Inline roles map onto the nine `PaymentType` roles** (§3.2 table); no new roles. | D15 froze nine roles; `lead` and `kicker` would add looks with no second use. Q11 confirms.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D36 | **Dates.** `PaymentDateField` and `PaymentDateRangePicker` delegate the calendar to Flutter's `showDatePicker` / `showDateRangePicker` and offer typed entry. The kit formats (`formatDate`, en and id) and validates the date's form; the host supplies ranges, presets and rules. No time-zone math. `IdentityFieldSpec` gains **New** `kind` (`text`, `date`, `choice`). Supersedes D4 and Q1. | SDK-only, host-owned business rules; the date of birth gets a real date control.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D37 | **`PaymentSearchField<T>` is Stripe's combobox**: it filters host options locally, or the host searches remotely through `onQueryChanged`. Single and `.multiple` selection. `PaymentTextField.search` stays the list filter. | Stripe's SearchField picks values from a list; the history search filters a visible list. Two jobs, two names.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D38 | **Feedback parity.** Badge `urgent` → `PaymentBadge.urgent` (solid danger), with no new `StatusTone`. Banner types map to tones and gain `onDismiss` (host removes it). Toast gains `pending` and a controller with `update` and `dismiss`; the 30-character limit is guidance. | `StatusTone` stays five values, so every exhaustive switch is untouched. A named constructor makes "urgent but not danger" unrepresentable.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D39 | **Charts parity:** `axis`, `grid`, `showLegend`, `inspectable`, `series` (≤ 3; ramp + dash, never tones), `unit` (+ `ChartPoint.measure`), meter `onSegmentPressed` through the legend rows. | Stripe's chart props; the charts decisions (no tone categories, paint-only) still hold.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D40 | **Overlay parity.** `PaymentTooltip` gains 12 placements on `OverlayPortal`, plus `type` (label vs description semantics) and `delay`. `PaymentMenu` gains groups, a custom trigger and `onAction`. `PaymentFocusView` gains `size` and `confirmClose`. | Flutter's `Tooltip` only places above or below; `OverlayPortal` is in the SDK.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D41 | **`PaymentListItem` replaces `ActionTile`** and gains `value`, `image`, `size` (`standard` 48 / `large` 64) and `id`; **`PaymentList` replaces `ActionTileGroup`** and gains `onAction`. Still no compact density, and still separate classes for switch, checkbox and radio rows. Supersedes part of D19 and Q8. | One public action-row class, not two. Stripe's sizes are both ≥ 48 dp.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D42 | **`PaymentImage` takes a host `ImageProvider`.** The kit never constructs a network image. `alt` is required (`''` = decorative). Loading and error states are built in. | B11: no network in `lib`; the D9 error-state gap becomes impossible.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D43 | **`PaymentDataTable` works on host rows.** Local paging and selection only; offset and cursor paging are host callbacks; no sorting or filtering (not in Stripe's props); column reorder and resize on wide layouts only, with a keyboard menu. | Host owns data and queries; nothing the kit computes changes a total.  [PRD §8](prd-foundation-components.md#8-decisions) |
| D44 | **`PaymentOnboardingView.completed`** shows a completion state and calls `onCompleted` once. There is no kit timer. Phone layout: a step header plus a collapsible task list. | B11 (no kit timers that act on their own); the host owns navigation.  [PRD §8](prd-foundation-components.md#8-decisions) |

D26 superseded by D33; multiples table and review grep stay.

### Phase 1A implementation decisions

Only `space` is a public resolver; other token resolvers stay internal until 4A.
Size, Width and FieldPart resolve per component. Circle uses circular(999),
matching navigation.dart's existing pill. Icon sizes reuse badge 14
(primitives.dart), merchant 16 (payment_extras.dart), row 20 clamped at 1.6×,
video 32 and state 48. No sizes are migrated in this phase.
`formatDate` does not call toLocal: a calendar date belongs to the host zone.
`dateInputPattern` requires DD, MM, YYYY once each and a repeated /, . or -;
a host LocalizationsDelegate supplies an app-wide override. Contrast radius
stays 8; only its inaccurate comment changes. Major spacing remains unused.

### Icon family audit (record only)

Outlined: all `*_outline(d)` glyphs (26). Stroke glyphs kept: check, close,
chevron_left/right, expand_more, more_vert, menu, search, search_off, remove,
undo, sync, call_split, open_in_new, edit_note, fingerprint, schedule, block.
Deferred: copy_rounded → copy_outlined (3B), warning_amber_rounded →
warning_amber_outlined (2C), hourglass_top → hourglass_top_outlined (2C;
checkout.dart:566), upload_file → upload_file_outlined (4B).
Media exception: play_arrow, pause, replay.
ActionTile manually swaps to chevron_left in RTL even though both SDK glyphs
have matchTextDirection: a double flip. Fix in 2D with an RTL test.

### Design-principle flags for later phases

| Finding | Follow-up |
| --- | --- |
| Rounded copy/warning and filled hourglass/upload glyphs | 2C, 3B, 4B |
| Double-mirrored RTL chevron | 2D |
| Literal icon size 18 in capture_widgets.dart:334 | 4A |
| Badge icon does not scale | 2C |
| Toast uses SnackBar defaults, D22 | 2C |
| Chart literal spacing | 2E |
| Solid outline hex vs alpha hairline preference | Document for owner review |
| Bold is a third weight | Running-text emphasis only; Contrast amountWeight w700 precedent |
| Banner icon/title gap 8 vs 12 elsewhere | 2C |
| hourglass_top means busy and authorization wait | 2C |

### Plan deviations

None. Simulator comparison is optional and omitted; permanent geometry and
old-glyph tests pass before and after the refactor.


### Phase 1B foundation documentation

Hairline token values are exported from the actual example theme and checked
for drift by example/test/token_export_test.dart. API member tables retain
existing constructor, static and getter metadata for snippet validation.
TokenTable rejects unknown, missing and duplicate rows. At 320 px, generated
tables scroll inside their own wrapper, matching the existing swatches and
Starlight table pattern, so the document itself stays within the viewport.
No plan deviation; no library rendering changes in 1B.

### Phase 2A implementation decisions

- RowShell and RadioMark live in internal files and are not exported. Shared Dart libraries require public names. The shell retains each row's content and semantics and the transaction row's lack of centering.
- Leading slots intentionally retain existing differences: ActionTile icons scale to 32 at 200%; selection marks retain a 20 dp slot. Unification belongs in Phase 2D.
- VerticalDivider in navigation remains: PaymentDivider is horizontal-only. Word-boundary review excludes VerticalDivider.
- Checkbox labels use label 15/20 instead of body 15/22, on the 16 dp content gutter with a 48 dp minimum.
- Video loading stroke changes from 3 to 3.84; reduced-motion hourglass changes from 24 to 32. Its spinner is excluded from semantics because the status line announces loading.
- Failed photo decoding uses the illustrated frame without a preview. The semantic label remains photo until Phase 4A.
- Native proof completed on iPhone 16 / iOS 18.1: all three screenshot suites and all 14 flow tests pass. Captures were inspected in light, dark and 200% text; reapproval scrolls to the checkbox only at 200%. The flow locator uses PaymentCheckbox rather than obsolete consent copy. Below-status-bar regression differences are limited to generated timestamps and the live countdown; action tiles, checkout and choice controls are pixel-identical. WebP assets and documentation embeds are published with this change.

Element counts (same host and synthetic workload, base → Phase 2A): history 847 → 862, confirmation 406 → 409, intro 344 → 346. RowShell and PaymentDivider each add a component element, without adding render objects or layout/paint passes. This is the documented exception to §12’s equal-or-lower element count criterion.

Plan correction: the suggested literal English reapproval sentence did not match the actual localization. The test taps PaymentCheckbox instead, preserving the same interaction without duplicating localized copy.

### Phase 2B implementation decisions

- MinTapTarget sits outside PaymentFocusRing: layout/hit box stays at least 48 dp while focus follows the small visual. The render object preserves all four intrinsics, dry layout and baseline for PaymentActionBar; hit forwarding rejects positions outside its bounds.
- Medium keeps Material default padding and 20 dp icons, preserving existing mobile geometry. The PRD table's 16 dp side padding contradicted D29's medium-equals-current rule and is corrected; the table already said 20 dp icons despite the plan describing that cell as 16. Small uses 12 dp padding and 16 dp icons/spinners; large uses 24 dp padding and 20 dp icons/spinners.
- Standard visual density is explicit: desktop/web medium buttons change from 40 to 48 dp. Hug remains at least 112 dp for every size; revisit small module-header uses in 4C/4D.
- Dialog overflow goes up, so Confirm stacks above Cancel with 8 dp spacing. At 320 dp this also stacks at 100%. Destructive initial focus is Cancel.
- Total amounts use heading weight, preserving w600 under hosts with w700 amountWeight. The five variants reproduce the existing merges. Countdown defaults to label plus tabular figures.
- D27 applies to Button only here; choices/tabs and the full dialog variants specimen remain Phase 6. The 200% confirm capture fixture is included.
- Native proof completed on iPhone 16 / iOS 18.1: all three screenshot suites and all 14 flow tests pass. Inspected button states/sizes/focus, all five amount roles and both dialog layouts. The 200% dialog uses the longer host label "Sign out everywhere" to exercise stacking on this iPhone. Foundation capture explicitly resets its retained scroll position; the new amount specimen appears below its unchanged original section. New WebP assets replace the old button captures.

Plan correction from dialog geometry: stock AlertDialog action padding and per-button padding stacked 112 dp actions even at 393 dp. Use token-based 16 dp actions padding and 4 dp per-button horizontal padding to retain an 8 dp horizontal gap and fit the two actions on the normal iPhone width. The narrow/200% layout still stacks with an 8 dp vertical gap.

Phase 2B element counts on the same workload: history: 862, confirmation: 410, intro: 347. MinTapTarget adds one centered render wrapper per button. It has no LayoutBuilder, speculative remeasurement or new timers; the literal no-added-layout-pass target is not claimed because the hit-area wrapper performs layout. Frame times were not benchmarked in this screenshot/flow task; no frame-time improvement is claimed. The existing bounded render-wrapper cost is unchanged.

Analyzer correction: MinTapTarget.updateRenderObject accepts RenderObject and casts internally. Exposing the private render class in its public method produced library_private_types_in_public_api; the internal rendering behavior is unchanged.

### Phase 2C implementation decisions

Renames use deprecated typedefs, preserving constructors and Type identity. The snack bar wrapper retains its Material controller return. The API parser now records aliases and deprecations, and snippet checks resolve their targets. Existing documentation slugs stay until Phase 6.

Toast duration scales by words: clamp 1000 + 300 × words to 4–10 seconds, or 6–10 with an action. Pending and accessible actions persist. SnackBar persist is explicitly true because the kit owns timeouts. The content owns timer cleanup: messenger disposal does not complete closed futures. A surface-colored TextButton and focus ring provide the inverted action until Phase 3B.

Warning and reduced-motion busy use outlined icons. Checkout's bank-wait hourglass was never rendered outside exceptions and is now schedule. Tooltip placement is one twelve-value enum instead of side × alignment. Description uses Flutter's semantic tooltip property to preserve spoken trigger information; label names the trigger. Bubbles ignore pointers and semantics. Keyboard focus shows immediately, Escape dismisses.

Owner scope revision: retain behavioral tests and zero-issue analysis; run native flow and docs captures once on final 2D-2. No regression pixel diffs or exhaustive visual inspection. Screenshots are delivered in 2D-2; earlier docs retain existing Screen names.

Plan correction: button_sizes_test also asserts PaymentSpinner.size. Migrate its 16-dp expectation to PaymentSize.small; the rendered dimension stays 16 dp. This call site was omitted from the verified list.

The existing row-family oracle also covers refund badges at 2×. Their text moves 8.4 dp because the planned badge icon cap grows from 14 to 22.4. Update only those expected positions by the intentional delta.

### Phase 2D implementation decisions

Use typedefs for constructor supersets and a wrapper for ActionTile's renamed arguments. A row without a handler and without a reason is read-only; its value stays in merged semantics. A value precedes the navigation chevron. Menu entries use an abstract class with a private constructor for a closed, parser-compatible hierarchy. Destructive actions belong in a separate final group.

Accordion actions are siblings of the header toggle. A LayoutBuilder exists only when actions exist; widths below 400 dp or large text stack actions. Leading-slot unification remains deferred to Phase 4A because painted marks and list icons have different established metrics.

Plan correction: give PaymentMenu an owned trigger FocusNode and MenuAnchor.childFocusNode, so closing restores focus to the actual trigger. The previous stateless implementation had not supplied that return target. Behavioral tests exercise grouped actions and Escape from an active item. Geometry-only new guards are omitted under the owner's revised scope.

### Phase 2D-2 implementation decisions

Tab-bar roles sit inside the scroll view. Tabs own FocusNodes for manual arrow navigation; Enter/Space activate. This requires StatefulWidget rather than the plan's stateless sketch, with nodes synchronized to tab count and disposed. A disabled tab's outer semantics wraps its tooltip so the direct child retains role, enabled=false and the reason hint; nesting the role inside the tooltip lost those properties at the merge boundary in the behavioral test.

Panels lazily build visited children and use Offstage, TickerMode and ExcludeFocus, not IndexedStack, so short panels do not inherit the tallest height. Selection errors use icon + text + danger edge. Mixed follows Material tristate semantics; required is semantics-only. Hidden text remains spoken.

Currency field small/default/large retain amountLarge typography and use padding changes of minus/default/plus 8 dp. Helper content adds height. padFractionDigits appends locale-specific missing minor digits on blur or submit without reporting a new amount. This is formatting, not a value change. The owner removed new geometry-only guards; behavioral size tests cover the relative height steps instead.

The behavioral currency-size fixture with description and minimum helper measures 92/100/108 dp at 1×. Helpers contribute to total InputDecorator height; the medium input padding remains unchanged and each adjacent size differs by 8 dp.

Native runner deviation: flutter test built and started flow_test but stalled before the VM-service handshake. Its shutdown also terminated the app, so attaching with use-existing-app could not connect. The normal flutter drive command with the same flow_test target then passed all stories, including payment deduplication, lost responses, re-quotes, recovery and account isolation. No application assertion was relaxed.

Plan correction: key each outer Offstage by panel index, not only the nested KeyedSubtree. Starting at panel 1 and later inserting panel 0 would otherwise reconcile unkeyed wrappers by position and replace visited state. A focused regression covers that ordering. This does not change the independently verified payment flow or captured default panel visuals.

Capture harness corrections: the appended menu specimens made the old global More actions finder ambiguous; scope it to the first account-menu trigger. A tail-only mode rechecks that failed portion without repeating the specimen matrix. Tooltip captures now assert the message and settled opacity before saving and offer a tooltip-only mode. The full pass produced all 40 new assets; focused reruns repair the harness outputs instead of repeating regression matrices. An intermediate tooltip harness compile error was discarded rather than accepting Flutter's stale-app fallback.

The final tooltip-only native run used a successful fresh build, asserted opacity 1, passed all four captures and produced visible bubbles in light/dark/200% and edge-flip screenshots. The stale paused app was closed through agent-device before this run.
