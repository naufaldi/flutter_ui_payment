# UI review and execution plan: large text, status screens, polish

Date: 30 October 2026. Planner pass only. The only file written was this one. Baseline: `flutter analyze` reports "No issues found!".

**Evidence:** 75 native PNGs in `example/build/screenshots_hairline/` were opened and inspected. File names below refer to that folder.

**Code read:**
- `lib/src/foundation/{primitives,payment_theme,payment_motion}.dart`
- `lib/src/payment/{payment_status,checkout,payment_extras,transactions}.dart`
- `lib/src/receipt/payment_receipt.dart`
- `lib/src/verification/verification_widgets.dart`
- `lib/src/{promo/promo,interaction/interaction,navigation/navigation,overlay/sheets}.dart`
- `example/lib/{main,themes}.dart`
- `example/lib/screens/{flow_screen,gallery_screen}.dart`
- the tests

**Skills applied, translated from web to Flutter:**
- `emil-ui-review` and its `STANDARDS.md`
- `emil-typography`
- `emil-touch-and-accessibility`
- `emil-ui-polish`
- `emil-design-foundations`

## 1. Verdict and findings

**Verdict: Blocked.** At 200% text the payment-status screens do not show their only action on the first screen. On iOS, "Cek status" is cut off by the bottom bar (`ios_status_unknown_light_200.png`). On Android it is a full screen below the fold (`android_refined_status_unknown_light_200.png`). The unknown outcome is the riskiest state in the product, so this breaks interaction at the accessibility floor. Two accessibility-floor rules are also still unimplemented: the visible focus outline and press feedback on compact controls. At 100%, in light and dark, the Hairline direction mostly holds. The remaining issues are polish.

### Why the 200% status screen reads as "enlarged"

This arithmetic is calibrated against `android_refined_status_unknown_light_200.png`. The emulator is 360×624 dp. Content starts at 80 dp and the bottom bar starts at 560 dp.

| Block (Android, 200%) | Now | Height (dp) |
| --- | --- | --- |
| list padding + band + gap | 8 + 6 + 12 | 26 |
| Title, 15 px ×2, 2 lines × ~40 | | 80 |
| gap + amount (32 × 1.6 = 51 px, line 1.15) | 12 + 59 | 71 |
| gap + lead "Jangan bayar lagi." (line 43.5) | 12 + 43.5 | 55.5 |
| gap + detail: **5 lines** × 43.5 | 2 + 217.5 | 219.5 |
| **Body ends at** | 80 + 452 | **≈ 532** (screenshot: ≈ 532 ✔) |
| divider `spacing * 5` + stacked reference row + 24 gap | 40 + 98 + 24 | 162 |
| "Cek status" button | | 52 → bottom at **≈ 746**, past the bar at 560 |

Icon alignment alone moves nothing. Three changes pull the action up:
- shorter copy, because the detail's last sentence repeats the button;
- actions placed before the reference rows;
- tighter leading for display-size body text.

The target budget is in WP-A.

### Blocking

1. **The status action falls below the fold at 200%.**
   - `lib/src/payment/payment_status.dart:359-429`. The order is message → 40 dp divider (`:383`) → reference rows → 24 → actions.
   - The detail copy (`payment_localizations.dart:212-215`) ends with "Cek status untuk melihat hasilnya." That sentence restates the button directly under it, and at 200% it adds 2 lines.
   - Evidence: `android_refined_status_unknown_light_200.png`, `ios_status_unknown_light_200.png` (button cut by the bar), `ios_status_pending_light_200.png` (button sits only after three stacked detail rows).
   - The same order is used in `TransactionDetail` (`transactions.dart:494-533`).
2. **The status icon does not scale or align at 200%.**
   - A fixed 20 px icon sits next to a 30 px title that wraps to 2 lines. Its `top: 1` nudge pins it above the first line's center, so it reads as a stray dot.
   - Copied in four places:
     - `payment_status.dart:321-347`
     - `payment_receipt.dart:89-115`
     - `transactions.dart:454-475`
     - `verification_widgets.dart:662-685`
   - Evidence: `android_refined_status_unknown_light_200.png`, `ios_status_unknown_light_200.png`, `ios_status_pending_light_200.png`, `ios_receipt_light_200.png`.
3. **There is no visible keyboard focus indicator.**
   - Design-research constraint 6 calls for a 2 px outline at a 2 px offset, ink on light and paper on dark.
   - Every product control uses Material's default focus fill, which is nearly invisible on ink buttons:
     - `PaymentButton`, `primitives.dart:322-355`
     - `_MethodTile` InkWell, `checkout.dart:303`
     - the copy buttons
     - `ActionTile`
     - drawer items
     - filter tabs
     - promo links
     - video controls
   - Known open item in `docs/decisions.md`.
4. **Compact controls give no press feedback.** This covers copy, close, dismiss, "Edit", "Kenapa ini?", video play and mute, and the filter tabs. Constraint 10 asks for a 0.96 scale over 100 ms. `PaymentMotion.pressedScale` is unused, and its values (0.97 and `press` = 120 ms, `payment_motion.dart:31,49`) do not match the spec.

### Should fix

5. **The total appears three times on checkout at 200%.**
   - The summary headline is 51 px (`checkout.dart:154-158`), the Total row is 30 px (`:184-191`), and the action-bar total is 40 px. The bar total is uncapped because it uses non-emphasis `AmountText` at 20 px × 2 (`payment_extras.dart:76-83`).
   - Two display-size amounts break constraint 2, and the first screen holds only the headline and one line item.
   - Evidence: `android_refined_checkout_light_200.png`, `ios_checkout_light_200.png`.
6. **The demo account initial overflows its circle.**
   - The 13 px "A" scales to 26 px inside a fixed 28 px circle (`example/lib/screens/flow_screen.dart:159-175`). Flutter caps the AppBar title at about 1.34×, so the initial beside it outgrows the title it sits next to.
   - Evidence: every `*_200.png` flow capture.
7. **`InfoRow` always stacks at large text.**
   - Above 1.5×, every row becomes label, then value (`primitives.dart:178-190`), even when both fit on one line. This doubles row height on checkout, receipt, KYC review and status. For example, "Biaya layanan / Rp2.500" fits in 328 dp at 200% but takes two lines.
   - Evidence: `ios_receipt_light_200.png`, `android_refined_kyc_review_light_200.png`, `ios_checkout_light_200.png`.
8. **The receipt "ID transaksi" row is misaligned.**
   - The value and its 48 dp copy button are vertically centered, so the ID sits about 14 dp below its label (`payment_receipt.dart:154-185`).
   - Evidence: `ios_receipt_light.png`.
9. **The history meta line drops the date at 200%.**
   - `maxLines: 1` with an ellipsis (`transactions.dart:187`) renders "Ruang Bayar Akademi ·…". The date is information, not decoration.
   - Evidence: `android_kit_history_200.png`.
10. **The promo banner CTA steals half the width.**
    - `Flexible(child: quietCta)` beside `Expanded(child: body)` (`promo.dart:257`) splits the row in half. The title wraps to 3 lines and "Ajak" floats in mid-card.
    - Evidence: `android_kit_promo.png`, `ios_kit_promo_dark.png`.
11. **Leading icons are centered on multi-line rows at 200%.**
    - `ActionTile`'s `Row` has the default center alignment (`interaction.dart:65`). The icons float mid-block beside 2–3 line labels.
    - The same fixed-20 px, `top: 1` pattern appears in:
      - `StateMessage`, `interaction.dart:597-602`
      - `NoticeBanner`, `primitives.dart:449-452`
      - `_NavTile`, `navigation.dart:162-168`
      - KYC requirements, `verification_widgets.dart:59-68`
      - the `MerchantHeader` 32 px mark, `payment_extras.dart:180-212`
    - Evidence: `android_kit_interaction_200.png`, `android_kit_checkout_200.png`.
12. **Type sizes in row content are too close together.**
    - `InfoRow` labels and text values are 14 px (`bodyMedium`, `primitives.dart:155-166`). Amounts in the same rows are 15 px w500 (`primitives.dart:28`).
    - On a receipt "Saldo Ruang Bayar" (14) sits under "Rp2.500" (15). Body copy is also 15.
    - One px of difference reads as a mistake, not as hierarchy.
    - Evidence: `ios_receipt_light.png`, `android_refined_kyc_review_light.png`.
13. **Display line-heights are off-grid or unset.**
    - Status body text is 15/1.45, a 21.75 px line (`payment_status.dart:293-297`, `transactions.dart:441-445`, `verification_widgets.dart:690-694`, `interaction.dart:266-270`).
    - The status title has no explicit height, so it falls back to Roboto `titleSmall`'s 1.43.
    - The 1.45 leading stays at 200%, where 30 px glyphs need less.
14. **Selection changes weight on the method row.** The selected method label switches to w500 (`checkout.dart:328`), and the text reflows when you change methods (STANDARDS: no weight change on selection). The 2 px outline and the filled radio already signal selection.
15. **The KYC "Edit" button is not aligned to the edge.** TextButton padding leaves its text about 12 dp inside the value column's right edge (`verification_widgets.dart:509-518`). Evidence: `android_refined_kyc_review_light.png` ("Edit" ends at x 664 px; values end at 688 px).

### Nits

16. **Off-grid spacing:**
    - `const SizedBox(height: 2)`:
      - `primitives.dart:187`
      - `payment_status.dart:365`
      - `payment_receipt.dart:124,129`
      - `transactions.dart:181,482,490`
      - `promo.dart:169`
      - `sheets.dart:60`
      - `interaction.dart:618`
    - `Wrap(spacing: 6)`, `transactions.dart:203`
    - `SizedBox(height: 6)`, `example/lib/screens/gallery_screen.dart:235`
    - `minHeight: 52`, `checkout.dart:307`
    - `top: 2` on the unavailable reason, `checkout.dart:337`
    - `Divider(height: spacing * 5)` (40), `payment_status.dart:383`. It is on-grid, but it is the largest gap on the screen for a minor separator.
17. **Mixed icon sizes:** the radio is 18 px (`checkout.dart:375-376`) beside 20 px icons elsewhere.
18. **Too many weights:** product text uses 400, 500, 600 and 700 (the countdown, `payment_status.dart:85`). Not changed in this pass; listed for a later type cleanup.
19. **Dialog actions stack unevenly:** at 100%, "Tetap bayar" sits right-aligned above a red filled button (`android_kit_sheet_confirm.png`). It is acceptable, because initial focus goes to the safe choice. Leave it.
20. **The Lumen preset barely differs from Hairline:** only black vs navy and w700 amounts (`android_kit_checkout_lumen.png` vs `android_kit_checkout.png`). See section 5.

**Checked and fine:**
- the hatched vs solid band in light and dark (`android_refined_status_unknown_dark.png`, `ios_status_pending_light.png`);
- no pay-again on pending or unknown;
- the refund kept separate;
- tone contrast in dark mode;
- the bottom bar without a pill;
- gallery captions capped at 1.2×;
- no vertical accent lines;
- the 100% checkout layout (`android_refined_checkout_light.png`, `_dark.png`);
- sheets (`android_kit_sheet_pending.png`);
- the drawer (`android_kit_navigation_drawer.png`);
- video (`android_kit_video_playing.png`);
- history detail (`android_kit_history_detail_unknown.png`).

## 2. Decisions (made on the owner's behalf)

| # | Decision | Rationale |
| --- | --- | --- |
| D1 | **Status header at large text:** the title scales fully, with no cap, and may wrap. Its line-height is explicit: 15/20. The icon scales with the text up to 1.6× (20 → 32 px). It sits in a box exactly one first line tall (`scaler.scale(15) × 20/15`), so it centers on the first line. The band stays 6 px. | This is how platform large titles treat glyph companions. It keeps product text unclamped and fixes the "tiny floating icon" without a cap. |
| D2 | **Status-page order:** header → amount → explanation → *actions* → details (references, update time) → refund. This applies to `PaymentStatusView` and `TransactionDetail`. The receipt keeps details before Share, because it is a settled record. | On an unresolved payment, "what do I do now" outranks the reference numbers. This is the biggest single lever on the 200% budget. |
| D3 | **Shorten the unknown detail copy:** id "Pembayaran sudah dikirim, tetapi hasilnya belum diterima."; en "Your payment was sent, but no result has arrived." | The dropped sentence repeated the "Cek status" button, which now sits directly below. The copy still promises no auto-update and names no bank. |
| D4 | **Body leading:** multi-line explanatory body text uses 15/22 (height 22/15) at ≤ 1.5× and 1.3 above 1.5×. | 22 px is on the token scale. Large glyphs need less relative leading, as at Apple's accessibility sizes. |
| D5 | **Display amounts** keep the existing 1.6× cap. The action-bar total (20 px) gets the same cap, to 32 px at most, through `MediaQuery.withClampedTextScaling` around its `AmountText`. | One rule for display roles (≥ 20 px). 32 px is fully readable, and `FittedBox` still prevents clipping. |
| D6 | **The summary headline amount is omitted above 1.5× text scale.** The widget applies this itself, with no API change. It stays at 100%, as the owner approved. The Total row always remains. | At 200% the headline and the Total row are both large, and the pinned bar repeats the total. This leaves two totals, never one hidden. It needs no coupling to the host. |
| D7 | **`InfoRow` at large text reflows instead of always stacking.** It uses `Wrap(alignment: spaceBetween, spacing: 16, runSpacing: 4)`: label and value share a line when they fit, otherwise the value starts the next line, left-aligned. At ≤ 1.5× the current `Row` stays. | Halves the height of short rows at 200% without clipping anything. |
| D8 | **`InfoRow` labels and text values become 15 px**, matching row amounts and body text. Captions stay 13. | Removes the 14/15 near-duplicate step. Stripe sets label and amount at one size. |
| D9 | The **demo account initial** is developer chrome: a 32 px circle with the initial capped at 1.3×. | Matches Flutter's AppBar title cap (about 1.34×) beside it. Product text is untouched. |
| D10 | **Leading icons beside text** (ActionTile, StateMessage, NoticeBanner, nav tiles, KYC requirements) follow D1: scale with text to 1.6× and center on the first line. In `ActionTile`, the trailing chevron also aligns to the first line, which is Material's 3-line list behavior. | One alignment rule everywhere. Centering on a whole multi-line block is what made 200% look broken. |
| D11 | **Focus outline and compact press scale ship as a follow-up wave (WP-D)**, after A–C merge. Both need one shared primitive applied in almost every interactive file, which cannot be split disjointly across parallel packages. | Keeps the parallel packages compile-independent. The owner's complaint (200%) lands first. |
| D12 | The **history meta line** gets `maxLines: 2` at every size. | The date must never be elided. At 100% the line still fits on one row. |

**Public API changes (all additive, list in CHANGELOG):**
- the new `StatusHeader` widget in `primitives.dart` (exported);
- a new optional `InfoRow.trailing` parameter;
- `PaymentMotion.pressedScale` changes value from 0.97 to 0.96, and `press` changes from 120 to 100 ms. These are value changes, not signature changes (WP-D).

No other signatures change.

**Visible behavior changes hosts will see in public widgets (also list in CHANGELOG):**
- D3: the `statusUnknownDetail` copy is shorter.
- D6: `PaymentSummary` omits its headline amount above 1.5× text.
- D2: `PaymentStatusView` and `TransactionDetail` show actions before the detail rows.
- D7/D8: `InfoRow` uses 15 px labels and values and reflows at large text.

The old copy does not appear under `website/` (checked with grep).

## 3. Work packages

Packages A, B and C run **in parallel**. Their file sets are disjoint, and **no package uses a symbol another package adds**: B and C use only existing APIs. Each test file has one owner. `docs/decisions.md` and `CHANGELOG.md` are owned by no package. The orchestrator updates them after the merge. WP-D runs **after** A–C have merged.

Shared definitions every package inlines (the repo idiom; no shared helper):
- `final large = MediaQuery.textScalerOf(context).scale(10) > 15;`
- First-line icon box:

  ```dart
  final scaler = MediaQuery.textScalerOf(context);
  final line = scaler.scale(15) * 20 / 15;              // first line of a 15/20 title
  final iconSize = scaler.clamp(maxScaleFactor: 1.6).scale(20);
  SizedBox(width: iconSize, height: line, child: Center(child: Icon(..., size: iconSize)))
  ```

  The title next to it must set `fontSize: 15, height: 20 / 15`. For a 14 px `titleSmall` title (NoticeBanner), use `scaler.scale(14) * 20 / 14` and `height: 20 / 14`.

### WP-A: Foundation and status-family screens (the owner's complaint)

**Files (exclusive):**
- `lib/src/foundation/primitives.dart`
- `lib/src/foundation/payment_localizations.dart`
- `lib/src/payment/payment_status.dart`
- `lib/src/receipt/payment_receipt.dart`
- `lib/src/payment/transactions.dart`
- `lib/src/verification/verification_widgets.dart`
- `test/widgets_test.dart`

**Changes:**

1. **`primitives.dart`: add a public `StatusHeader`.**
   - Signature: `StatusHeader({Key? key, required StatusTone tone, required IconData icon, required String title, bool hatched = false})`.
   - Builds: `StatusBand(tone, hatched)` → `SizedBox(height: theme.spacing * 1.5)` (12) → `Row(crossAxisAlignment: start)`.
   - The Row holds the first-line icon box (D1, color `tone.foreground`), then `SizedBox(width: theme.spacing)`, then `Expanded(Semantics(header: true, Text(title, style: titleSmall.copyWith(fontSize: 15, height: 20/15, fontWeight: w600, color: tone.foreground))))`.
   - The title stays a plain `Text`, not `Text.rich`, so `find.text(...)` in the tests keeps working.
   - Doc comment: four signals; hatched means the outcome is unknown.
2. **`primitives.dart` `InfoRow`:**
   - **(a)** Replace the large-text `Column` (`:182-190`) with `Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.start, spacing: theme.spacing * 2, runSpacing: 4, children: [labelWidget, valueWidget])`.
   - **(b)** Labels (non-emphasis) and `valueText`: `bodyMedium` → `fontSize: 15` (D8). The emphasis label stays `titleMedium` w600.
   - **(c)** Add optional `Widget? trailing`. When it is set, render `Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(<existing label/value layout>), trailing])`, so label and value share the top line and a 48 dp action centers against them.
   - **(d)** The `:187` gap of 2 goes away with the Wrap; `runSpacing` is 4.
3. **`primitives.dart` `NoticeBanner` (`:449-452`):** first-line icon box for the 14 px title (scale cap 1.6). Title `height: 20/14`. Leave the `:466` gap at 4.
4. **`payment_localizations.dart:212-215`:** `statusUnknownDetail` → en "Your payment was sent, but no result has arrived."; id "Pembayaran sudah dikirim, tetapi hasilnya belum diterima." (D3). Change no other strings.
5. **`payment_status.dart` `PaymentStatusView.build`:**
   - Replace `:317-347` with `StatusHeader(tone: look.tone, icon: look.icon, title: look.title, hatched: unknown)` inside the existing `AnimatedSwitcher`, keeping the key on the title.
   - Body style: `fontSize: 15, height: large ? 1.3 : 22 / 15`.
   - Lead → detail gap: `2` → `4`.
   - Reorder (D2): the header, amount and message blocks stay as they are. The unavailable `NoticeBanner` keeps its 16 gap. Then `SizedBox(height: theme.spacing * 3)` and the **action buttons** (unchanged logic and order).
   - Then the details: `Divider(color: theme.outline, height: theme.spacing * 4)` (32, was 40), then the reference, transaction and last-updated `InfoRow`s, then the refund section (16 gap).
   - The reference `MiddleEllipsisText` style changes from `bodyMedium` to `fontSize: 15`.
6. **`payment_receipt.dart`:**
   - Replace `:87-115` with `StatusHeader(tone: StatusTone.success, icon: Icons.check_circle_outline, title: l10n.statusSucceededTitle)`.
   - Change `:124` and `:129` gaps from `2` to `4`.
   - Transaction-ID row (`:154-185`): `InfoRow(label:…, value: SelectableText(…, fontSize 15, tabular), trailing: <existing 48 dp IconButton>)`.
   - Keep the order (details before Share).
7. **`transactions.dart`:**
   - `TransactionListItem`: `:181` gap `2` → `4`. `:187` `maxLines: 1` → `2` (D12). `:203` `Wrap(spacing: 6, …)` → `spacing: 8`.
   - `TransactionDetail`: replace `:452-475` with `StatusHeader(...)`. Body height as in step 5. `:482`/`:490` gaps `2` → `4`.
   - Reorder (D2): the actions block (`:525-531`, 16 gap before it, 8 between actions) moves to directly after the unknown copy and before the "Detail" `PaymentSection`. The refund section stays last.
   - Reference style: `fontSize: 15`.
8. **`verification_widgets.dart`:**
   - `VerificationStatusView`: replace `:660-685` with `StatusHeader(tone, icon, title, hatched: outcomeUnknown)`. Message height as in step 5.
   - Requirements list (`:59-68`): first-line icon box (title 15/20, w500).
   - `editButton` (`:509-518`): add `padding: EdgeInsets.zero, alignment: AlignmentDirectional.centerEnd` to `styleFrom`. Keep `minimumSize: Size(48, 48)`.

**Target budget after WP-A (Android 200%, same dp as section 1):**

8 + 6 + 12 (top) + 80 (title, 2 lines) + 12 + 59 (amount) + 12 + 39 (lead at 1.3) + 4 + **117 (detail: 3 lines × 39)** + 24 + 52 (button) = **425** → the button's bottom edge is at 80 + 425 = **505 dp**, above the bar at 560. On iOS (content 114–753 dp) the bottom edge is at about 539 dp.

**Acceptance (orchestrator, from new screenshots):**

| Screenshot | Check |
| --- | --- |
| `android_refined_status_unknown_light_200.png`, `ios_refined_status_unknown_light_200.png` (kit suite) and `ios_status_unknown_light_200.png` (flow suite) | "Cek status" is **fully visible above the bottom bar** with no scrolling. The icon is visibly larger (about 32 dp) and centered on the line "Hasil belum". The detail is 3 lines. The band is hatched. |
| `ios_status_pending_light_200.png` | "Cek status" is visible directly after "Menunggu konfirmasi bank (simulasi)." Reference rows come after the button. "Referensi pembayaran" and its value either share a line or wrap cleanly. The band is solid. |
| `android_refined_status_unknown_light.png`, `_dark.png`, `ios_status_pending_light.png`, `ios_status_pending_dark.png` | At 100% the structure is band, icon + title on one line, amount, message, button, then hairline and details. The dark band is still hatched or solid as appropriate. |
| `ios_receipt_light.png` | The "ID transaksi" label and "TRX-004070" sit on the same top line, with the copy icon centered beside them. |
| `ios_receipt_light_200.png` | The icon is centered on the "Pembayaran berhasil" line. "Biaya layanan" and "Rp2.500" sit on one line. |
| `android_refined_kyc_review_light.png` | The right edge of "Edit" aligns with the value column (±2 dp). |
| `android_refined_kyc_review_light_200.png` | Short rows ("Tanggal lahir … 17-08-1995") are on one line, or wrap with the value left-aligned under the label. Nothing is clipped. |
| `android_kit_history_200.png` | The meta line shows the date ("30 Okt 2026, 22.00") and is not elided. |
| `android_kit_history_detail_unknown.png` | "Cek status" sits above the "Detail" heading. The band is hatched. |

**Tests:** `flutter test test/widgets_test.dart`, `flutter test test/kit_components_test.dart`, `flutter test test/payment_models_test.dart` and `flutter test test/money_test.dart`, each run separately. Also run `flutter analyze`.

### WP-B: Checkout, action bar, merchant header

**Files (exclusive):**
- `lib/src/payment/checkout.dart`
- `lib/src/payment/payment_extras.dart`
- `test/checkout_large_text_test.dart` (new, with its own `host()` harness copied from the `widgets_test.dart` pattern)

**Changes (existing APIs only):**

1. **`checkout.dart` `PaymentSummary`:** compute `large`. When `large` is true, omit the headline `Align(AmountText(quote.total, emphasis: true))` and its following `SizedBox(height: theme.spacing)` (`:154-158`) (D6). The Total row (`:184-191`) is unchanged. Update the comment: the headline is dropped at large text because the Total row carries the total and the pinned bar repeats it.
2. **`checkout.dart` `_MethodTile`:**
   - Remove `fontWeight: selected ? FontWeight.w500 : null` (`:328`).
   - `minHeight: 52` → `48` (`:307`).
   - Unavailable reason `top: 2` → `4` (`:337`).
   - `_Radio`: `18` → `20` (`:375-376`). Selected border `5` → `6`; unselected stays 1.5. The disabled `Icons.block` goes from size 18 to 20.
3. **`payment_extras.dart` `PaymentActionBar`:** wrap the bar's `AmountText` (`:77-83`) in `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.6, child: …)` (D5). Put the wrapper *inside* the existing `Flexible`: `Flexible` must stay the direct child of the `Flex`, or Flutter throws a ParentDataWidget error. Change no other layout.
4. **`payment_extras.dart` `MerchantHeader`:**
   - Set the name style to `height: 20 / 15`.
   - Wrap the 32 px mark in `Padding(top: max(0, (scaler.scale(15) * 20 / 15 - 32) / 2))`, so it centers on the first name line at large text. At 1× the padding is 0 and nothing changes.

**Acceptance:**

| Screenshot | Check |
| --- | --- |
| `android_refined_checkout_light_200.png`, `ios_refined_checkout_light_200.png`, `ios_checkout_light_200.png` | There is no headline amount under "Ringkasan pesanan"; the first line item follows directly. The bar's "Rp102.500" is visibly smaller than in the current capture: about 32 dp tall, down from about 40 dp. "Tinjau pembayaran" is fully visible. |
| `android_refined_checkout_light.png`, `_dark.png`, `ios_checkout_light.png`, `ios_checkout_dark.png` | The 100% layout matches the current capture: headline present, Total row, bar with total beside the button. The selected method label has the same weight as the unselected one. The radio is 20 dp and the 2 px selection outline is unchanged. |
| `android_kit_checkout_200.png` | The "RB" mark is vertically centered on the first line "Ruang Bayar". |

**New tests** (`test/checkout_large_text_test.dart`):
- At `textScale: 2`, `PaymentSummary` shows the total **once** (`find.text('Rp102,500')` finds one widget, the Total row). At `textScale: 1` it shows it twice.
- `PaymentActionBar`'s amount is capped at 1.6×. Pump the bar at `textScale: 1` and record `h1 = tester.getSize(find.text('Rp102,500')).height`. Pump it again at `textScale: 2` and assert the new height is ≤ `h1 * 1.6 + 1`. Uncapped, it would be about `h1 * 2`.

**Tests:** `flutter test test/checkout_large_text_test.dart`, `flutter test test/widgets_test.dart` (read-only regression run: the 320 pt / 200% overflow test exercises `PaymentConfirmation`) and `flutter analyze`.

### WP-C: Kit components and example chrome

**Files (exclusive):**
- `lib/src/interaction/interaction.dart`
- `lib/src/promo/promo.dart`
- `lib/src/overlay/sheets.dart`
- `lib/src/navigation/navigation.dart`
- `example/lib/screens/flow_screen.dart`
- `example/lib/screens/gallery_screen.dart`
- `test/kit_components_test.dart`

**Changes (existing APIs only):**

1. **`interaction.dart` `ActionTile`** (`:65-113`):
   - `Row(crossAxisAlignment: CrossAxisAlignment.start)`.
   - The leading icon goes in the first-line icon box (D10). The title style adds `height: 20 / 15`.
   - The **default chevron** goes in `SizedBox(height: line, child: Center(...))`, so it aligns to the first line.
   - A **custom `trailing`** goes in `ConstrainedBox(constraints: BoxConstraints(minHeight: line), child: Center(child: trailing))`, never a fixed height, so a switch or a 48 dp button is never squeezed.
2. **`interaction.dart` `StateMessage`** (`:595-623`): first-line icon box instead of `Padding(top: 1)`. Title `height: 20 / 15`. `:618` gap `2` → `4`.
3. **`interaction.dart` `showPaymentConfirmDialog` body** (`:266-270`): `height: 1.45` → `large ? 1.3 : 22 / 15`.
4. **`promo.dart`:**
   - Banner row (`:251-258`): `Flexible(child: quietCta)` → `quietCta`. The body keeps `Expanded`.
   - `:169` gap `2` → `4`.
5. **`sheets.dart:60`:** gap `2` → `4`.
6. **`navigation.dart` `_NavTile`** (`:162-168`): `Row(crossAxisAlignment: start)` with the first-line icon box. Label `height: 20 / 15`. Wrap the trailing badge in `ConstrainedBox(minHeight: line)` with `Center`, so it stays on the first line without being squeezed.
7. **`example/lib/screens/flow_screen.dart` `_AccountMenu`** (`:159-175`): circle `28` → `32`. Text `textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3)` (D9).
8. **`example/lib/screens/gallery_screen.dart:235`:** `SizedBox(height: 6)` → `8`.

**Acceptance:**

| Screenshot | Check |
| --- | --- |
| Every flow `*_200.png` (`android_refined_*_light_200.png`, `ios_*_light_200.png`) | The "A" sits wholly inside its circle, and the circle is not clipped by the app bar. |
| `android_kit_promo.png`, `ios_kit_promo.png`, `ios_kit_promo_dark.png` | The banner title "Ajak teman, sama-sama dapat Rp10.000" takes ≤ 2 lines. "Ajak" sits at the right edge with no floating gap. |
| `android_kit_promo_200.png` | The disclosure still wraps and stays visible. Nothing is clipped. |
| `android_kit_interaction_200.png` | Each leading icon and chevron is centered on the first line of its label ("Riwayat transaksi", "Ubah PIN", "Keluar dari"). |
| `android_kit_interaction.png`, `android_kit_navigation_drawer.png`, `android_kit_sheets.png` | 100% rows look unchanged. One-line rows stay centered, because the first-line box equals the line height. |

**New test** (`test/kit_components_test.dart`): a `PromoCard(layout: PromoLayout.banner)` at 390 dp and 1× gets a title `Text` wider than 60% of the card (`getSize(find.text(title)).width > 0.6 * getSize(find.byType(PromoCard)).width`).

**Tests:** `flutter test test/kit_components_test.dart`, `flutter test test/widgets_test.dart` (regression) and `flutter analyze`.

### WP-D (follow-up wave, after A–C merge): focus outline and compact press

**Files:**
- `lib/src/foundation/focus_ring.dart` (new, **not** exported)
- `lib/src/foundation/payment_motion.dart`
- `lib/src/foundation/primitives.dart`
- `lib/src/payment/checkout.dart`
- `lib/src/payment/payment_status.dart`
- `lib/src/receipt/payment_receipt.dart`
- `lib/src/payment/transactions.dart`
- `lib/src/verification/verification_widgets.dart`
- `lib/src/interaction/interaction.dart`
- `lib/src/promo/promo.dart`
- `lib/src/overlay/sheets.dart`
- `lib/src/navigation/navigation.dart`
- `lib/src/media/video.dart`
- `test/focus_press_test.dart` (new)

**Changes:**

1. **`focus_ring.dart`: `PaymentFocusRing({required Widget child, required BorderRadius radius})`.**
   - `Focus(canRequestFocus: false, skipTraversal: true, onFocusChange: …)` tracks whether the child or any descendant has focus.
   - Listen to `FocusManager.instance.addHighlightModeListener`. Paint only when `highlightMode == FocusHighlightMode.traditional`. This is the Flutter equivalent of `:focus-visible`, so touch never shows the ring.
   - Paint with `CustomPaint(foregroundPainter:)`: an RRect equal to the child rect inflated by 3, stroke 2. The inner edge then sits 2 px outside the control, which gives the 2 px offset.
   - Ring radius = control radius + 3. Color `PaymentTheme.textPrimary` (ink on light, #ECEDF0 on dark). Never accent.
   - No ancestor may clip it. Known clippers:
     - `_NavTile`'s `Material(clipBehavior: Clip.antiAlias)`, `navigation.dart` around line 150. The ring must wrap the *outside* of that `Material`.
     - horizontally scrolling tab rows (history filters), which clip at their edges. Add 4 px of horizontal padding inside the scroll view.
     - the method list's bordered `DecoratedBox` and the gallery's `Material` frame. Add a 4 px inset where needed.
2. **`focus_ring.dart`: `PaymentPressScale({required Widget child})`.**
   - A `Listener` (down, up, cancel) drives `AnimatedScale(scale: pressed ? motion.pressedScale : 1, duration: motion.press, curve: PaymentMotion.easeOut)`.
   - With reduced motion, `pressedScale` is 1 and `press` is zero.
3. **`payment_motion.dart`:** `pressedScale` `0.97` → `0.96`; `press` `120` → `100` ms (constraint 10).
4. **Apply the ring** to:
   - `PaymentButton` (all variants)
   - `_MethodTile` (radius 8)
   - the copy buttons (status and receipt)
   - `ActionTile`, `ActionMenu`, `ExpandableSection` header
   - `_NavTile`
   - history filter tabs, list items and search
   - promo CTA, "Kenapa ini?" and dismiss
   - sheet close
   - KYC "Edit"
   - video play, mute and slider
   Set Material focus overlays to transparent where the ring replaces them (`focusColor: Colors.transparent`, `overlayColor` focused → transparent).
5. **Apply the press scale** to compact controls only: copy, close, dismiss, "Edit", "Kenapa ini?", video play and mute, and filter tabs. Never apply it to full-width buttons or rows; those keep the pressed state layer.

**Acceptance:** widget tests only. Static screenshots cannot show focus or press. Also check `flutter analyze` and that no screenshot changes at rest.

**New tests** (`test/focus_press_test.dart`):
- **Focus:** with `FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional`, send Tab to a `PaymentButton`. A `CustomPaint` with the ring painter is present, and its color equals `textPrimary`. With `alwaysTouch` it is absent.
- **Press:** `tester.startGesture` on a copy button. The `AnimatedScale.scale` is 0.96. After release it is 1.
- **Reduced motion:** with `MediaQueryData(disableAnimations: true)`, the scale stays 1 while pressed.

**Tests:** every test file, each run separately, plus `flutter analyze`.

## 4. New tests worth adding (minimal)

All of these go in **WP-A** (`test/widgets_test.dart`, using its `host()`):
1. **Status order at 200%:** an unknown `PaymentStatusView` at `textScale: 2`, `size: 360×624`. `getTopLeft(find.text('Check status')).dy < getTopLeft(find.text('Payment reference')).dy`.
2. **Header icon centered on the first line:** for the same widget, the icon's center minus the title's top equals `15 × 2 × 20/15 / 2` (±1). The icon size is 32.
3. **`InfoRow` reflow:** `InfoRow(label: 'Fee', value: AmountText(Money.idr(2500)))` at `textScale: 2`, width 328. The label and value have equal top `dy`.
4. **Unknown copy:** `find.textContaining('Check the status')` finds nothing. The existing "Don't pay again." test stays.

WP-B and WP-C tests are listed in their packages. WP-D tests are listed in WP-D.

## 5. Out of scope and owner questions

**Owner questions (material):**
1. **The checkout headline at 100%.** This plan keeps the approved "headline + Total row + bar total" layout at normal text size and drops the headline only at large text (D6). Should the headline also go at 100% whenever the action bar is pinned? That would make checkout show the total twice, not three times. Recommendation: keep it at 100% as approved.
2. **Shorter unknown copy (D3).** The approved Statement copy loses its last sentence because the button now sits directly under it. Confirm.
3. **The Lumen ("Contrast") preset** is nearly indistinguishable from Hairline. Should it show the option-3 traits (filled rows, inverted selected row, 40 px amount), or stay a minimal "brand via tokens" proof?

**Out of scope:**
- the landing/docs website (design-research section 8, step 5);
- performance work;
- physical-device checks;
- focus styling for example-only chrome (the gallery state picker, the host tools);
- dialog action layout (Nit 19);
- reducing weights to three (Nit 18).

**Run notes for the orchestrator:**
- Regenerate screenshots with `example/integration_test/kit_screenshots_test.dart` (`refined_*`, `kit_*`, both platforms) and `example/integration_test/screenshots_test.dart` (`ios_status_*`, `ios_receipt_*`, `ios_checkout_*`, `ios_kyc_review_*`; iOS only, per decisions.md).
- Run per-file `flutter test`, because whole-suite runs hit the local "Unable to connect to flutter_tester" flake.
