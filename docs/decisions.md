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
