# Foundation plan: type, spacing, color, radius, icons (MVP: Payment / PPOB)

Date: 30 October 2026. This was a planner pass. The only file written is this one. No code, tests, themes or assets were changed.

**Inputs:**
- `docs/design-research.md`: section 0 (Stripe-calm · Hairline), section 5 (constraints) and section 6 (tokens).
- `docs/decisions.md`
- `docs/ui-review-plan.md`. Its WP-A to WP-D are implemented and are not proposed again here.
- The code in `lib/src` and `example/lib`.
- Skills: `emil-design-foundations` (the lens for this pass), `emil-typography`, `emil-color`, `emil-surfaces` and `emil-unslop-design`, translated to Flutter.

**Inventory method.** Two scripts, kept outside the repo:
- `inventory.py`: regex counts of `fontSize`, `FontWeight`, `height`, `letterSpacing`, `textTheme` roles, `EdgeInsets`, `SizedBox`, `spacing *`, `Color(0x…)`, `Colors.*`, alpha, radii and icon sizes.
- `styles.py`: resolves every `textTheme.X?.copyWith(…)` and `TextStyle(…)` to its effective size, weight, leading and tracking, using Flutter's Material 3 (2021) defaults for whatever the call does not set.

Counts below are for `lib/src` unless marked "example".

**Screenshot caveat.** Every PNG in `example/build/screenshots_hairline/` is older than `lib/src/foundation/primitives.dart` (modified 23:19). The Android set (22:13) is also older than all of WP-A to WP-D. The iOS set (23:06–23:07) includes WP-A to WP-D but predates the last `InfoRow` change. So the **Before** column below cites code; the images were used only to confirm what code produces.

## 1. Verdict

The Hairline direction holds: flat sections, one bordered method list, the status band, a single ink primary. What is missing is a *system* underneath it.

- **Type.** Text is styled in 90 places by borrowing a Material role and overriding the size. Every borrowed role leaks its Material 3 tracking and leading. The result is 9 font sizes, 4 weights, 5 tracking values at the same 15 px size, and 4 line boxes for 15 px text. Same-role text drifts: the "supporting line under a title" is 12, 13 or 14 px depending on the widget.
- **Spacing.** It is on a 4 px grid, but the rhythm between sections is the accidental sum of nested padding: `PaymentSection` 8 + `InfoRow` 8 + the host's gap. Checkout's summary → methods gap is 36 dp. The status screen's ruled gap is 48 dp, against 40 on the receipt.
- **Color.** One token, `outline` (1.25:1), serves as both the hairline rule and the method-group edge. The control borders are ad hoc alpha blends: `textSecondary` at 50% gives 2.12:1. Disabled has no token, so `PaymentButton` falls back to Material's 38%/12% opacity, about 1.8:1.
- **One hard MVP defect.** The VA-pending screen shows **two display-size amounts** and a lone w700 countdown, while the VA number is styled as a 16 px amount rather than a reference.

Fix order: a short **WP-0** adds the tokens and one internal style source and migrates the primitives. Then three disjoint packages run in parallel.

## 2. Top findings (Before → After)

| Before | After | Why |
| --- | --- | --- |
| **VA pending shows two 32 px amounts.** `PaymentStatusView(amount:)` renders the display amount (`payment_status.dart:330-336`). `PaymentInstructions` repeats it as `AmountText(emphasis: true)` in an emphasis row (`:72-76`). The countdown is the only w700 in `lib` (`:84-87`). | Instructions show "Jumlah dibayar" as a **total row** (heading label, 15/20 w600 amount). The countdown is heading-weight tabular (15/20 w600). The display amount stays only in the status header. | Constraint 2: one display amount per screen. Two equal totals make the customer compare them. |
| **The VA number is styled as an amount.** It uses `amountStyle(large: false)` with +1.5 tracking, 16 px sans (`payment_status.dart:55-62`). `referenceFontFamily` from research §0/§6 was never added. | New role `amountLarge` (20/28 w600) with `referenceFontFamily` (platform mono) and no tracking hack. Capped at 1.6×. | The VA number is the thing the customer copies into a banking app. Mono separates 0/O and 1/l. Research §0: mono is for references only. |
| **VA instructions sit below the status actions and the reference rows.** In the flow, `PaymentInstructions` comes after `PaymentStatusView` (`flow_screen.dart:745-752`). | `PaymentStatusView` gains an optional `instructions:` slot. At normal text it renders after the explanation and before the actions; above 1.5× it renders after the actions. The steps collapse under "Cara bayar". | On a VA screen, *what to pay into* outranks "Cek status", which is Midtrans' order. At 200% the action must stay on the first screen (the F9 arithmetic). The slot is additive. |
| **Material tracking leaks.** Styles borrow `bodyLarge` (+0.5), `bodyMedium` (+0.25), `bodySmall` (+0.4), `labelMedium` (+0.5) and `titleSmall` (+0.1). 15 px text appears at 0.1, 0.25 and 0.5 tracking; for example `checkout.dart:334` vs `primitives.dart:168` vs `:656`. | Every role sets `letterSpacing` explicitly: 0 for text, −0.32 for display only. | Body sizes get no tracking (`emil-typography`). The loose +0.5 is visible on iOS in "Saldo Ruang Bayar" and "Pembayaran sudah dikirim". |
| **15 px text has four line boxes:** 21.4 (M3 1.43, 11×), 22.5 (M3 1.5, 3×), 20 (6×) and 22 (4×). | Two leadings: 20 for single-line row text, 22 for paragraphs (1.3 above 1.5× text). | Leading follows role, not whichever Material role was borrowed. |
| **The supporting line under a title has three sizes.** 12: method detail `checkout.dart:289`, footnote `:482`, limit `payment_extras.dart:433`, refund note `payment_status.dart:481`, InfoRow caption `primitives.dart:188`. 13: merchant detail `payment_extras.dart:266`, step `:328`, history meta `transactions.dart:194`, receipt date `payment_receipt.dart:107`. 14: provider `payment_status.dart:49`, sheet subtitle `sheets.dart:64`. | One `caption` role: 13/18 w400, `textSecondary`. | One role, one size. 12 is reserved for tags. |
| **Body text is 14 in some places and 15 in others.** `NoticeBanner` title and message are 14 (`primitives.dart:511-523`). So are VA steps (`payment_status.dart:119`) and promo/sheet/video bodies. | `body` 15/22 everywhere. The `NoticeBanner` title becomes `heading` 15/20 w600. | A 14/15 one-pixel step reads as a mistake, not as hierarchy (`ui-review-plan` finding 12, now applied kit-wide). |
| **Weights: 400, 500, 600, 700.** w500 is used 6×: row amounts `primitives.dart:29`, history title `transactions.dart:127`, filter tabs `:265`, promo tag `payment_extras.dart:524`, nav `navigation.dart:97`, KYC `verification_widgets.dart:85`. w700 is used once (countdown). | Two weights: **400 and 600**. `amountWeight` stays a host token for amounts. | Restraint reads as intent. Line-item values at regular weight is the research §1 decision. |
| **The Total row label (16) is larger than its amount (15).** The label is `titleMedium` 16 w600 (`primitives.dart:164`); the amount is 15 w600 (`checkout.dart:195`). | Both are `heading` 15/20 w600. | Label and amount are one line of meaning. Stripe sets them at one size. |
| **The re-quote consent sentence is unstyled Material.** `CheckboxListTile` title at 16/24 +0.5 (`checkout.dart:471-473`). | `body` 15/22 ink. | It is the sentence the customer agrees to. It must match the summary it refers to. |
| **Section rhythm is accidental.** Summary → methods is 8 (row) + 8 (section) + 12 (`flow_screen.dart:610`) + 8 = 36. Confirmation summary → "Bayar dengan" is also 36 (`checkout.dart:454`). Status ruled gap is 48 (`payment_status.dart:381`, `spacing*4`), against 40 on the receipt and history detail. | Named gaps, 4/8/12/16/24/32, used by role (§4.2). Sections stack flush, which gives 24 visible. Every ruled separation is `Divider(height: 24)`. | Space with a system, not eyeballing. The same relationship should get the same gap on every screen. |
| **`Divider(color: outline)` with no height** (`payment_status.dart:71`) takes the host's `DividerTheme.space`: 1 in the example, 16 in a plain host. | `Divider(height: theme.spacing * 2)` | The kit must not change layout with an unrelated host theme value. |
| **One token for the rule and the control edge.** `outline` (#E3E6EC, 1.25:1) draws hairlines *and* the method group. Secondary buttons use `textSecondary@0.5` (2.12:1) (`primitives.dart:369`, `verification_widgets.dart:322`). The example input uses `@0.75` (`themes.dart:184`). Package inputs set no color (`checkout.dart:119`, `payment_extras.dart:605`). | `outline` is documented as the **rule** (decorative). New `border` token for control edges (inputs, secondary buttons, the unselected checkbox): solid `lerp(textSecondary, surface, 0.25)`, which is 3.37:1 light and 4.85:1 dark. | A rule recedes. A control edge must meet 3:1 (WCAG 1.4.11). Alpha borders change contrast with whatever sits behind them. |
| **Disabled is opacity.** `PaymentButton` sets no disabled colors (`primitives.dart:349-385`), so Material's onSurface 38% on 12% applies: 1.83:1 light, 2.36:1 dark. | New `disabled` token, solid `lerp(textSecondary, surface, 0.45)`, on a `surfaceMuted` fill. | `emil-design-foundations`, Color 14: a dedicated token, not `opacity`. |
| **Copy icons differ:** 24 in status (`payment_status.dart:157`, no `size`) and 20 in the receipt (`payment_receipt.dart:157`). Promo remove is 18 (`payment_extras.dart:543`). | Icon scale 14 (in tags) / 16 (inline in text) / 20 (controls and leading icons). | One size per job. |
| **Two "large text" thresholds:** `> 13` (1.3×) in `PromoCodeInput` (`payment_extras.dart:563,618`) and `> 15` (1.5×) everywhere else. | One internal helper `PaymentType.isLarge(context)` (> 1.5×). Promo keeps a named local `_stackAt = 1.3` with a comment. | One rule hosts can reason about. The promo row is tighter, so its exception is named, not accidental. |
| **The applied discount is green** (`payment_extras.dart:549-552`). | Ink, with the minus sign from `Money` carrying the meaning. | Colored money competes with the total. Green is for state, not for amounts. |
| **The authorization `ready` state is an info-blue tinted box with a blue w600 title** (`checkout.dart:565-571`). It is the loudest element on the normal path. | `ready`/`inProgress`/`approved` render as plain `heading` + `body` (ink/muted). `NoticeBanner` is kept for `failed`/`expired`/`canceled`. | Proportional urgency (Uber Base): a box is for an exception, not for the expected next step. |
| **The host tools panel inside the Demo flow uses product styling:** a `surfaceMuted` bordered tile with an icon (`flow_screen.dart:842-868`). It reads as product UI in every flow capture. | Gallery workbench voice: workbench fill, mono 12 title capped at 1.2×, no leading icon. Keys are kept. | Gallery chrome never uses end-user component styles (constraint 9). The owner asked for chrome to be visually separate. |

## 3. Inventories

### 3.1 Typography (effective values, `lib/src`)

**Sizes in use: 9** (11, 12, 13, 14, 15, 16, 17, 20, 32). Example chrome adds 12 mono and 17 (app bar).

| Size | Uses | Where (sample) | Role it is really playing |
| --- | --- | --- | --- |
| 11 | 2 | `navigation.dart:228` (badge), `payment_status.dart:173` ("Disalin") | tag (below the 12 floor) |
| 12 | 21 | `primitives.dart:188,434`, `checkout.dart:289,350,482`, `payment_extras.dart:216,433`, `payment_status.dart:113,481`, `payment_receipt.dart:188`, `interaction.dart:112,482`, `navigation.dart:205`, `promo.dart:94`, `verification_widgets.dart:94,139,389` | caption **and** tag |
| 13 | 10 | `payment_extras.dart:70,266,328`, `transactions.dart:194`, `payment_receipt.dart:108`, `video.dart:488`, `navigation.dart:94`, `verification_widgets.dart:371,701` | caption |
| 14 | 14 | `primitives.dart:511,522`, `payment_extras.dart:54,523`, `payment_status.dart:49,119`, `transactions.dart:264`, `sheets.dart:64`, `promo.dart:187`, `video.dart:387`, `interaction.dart:672`, `verification_widgets.dart:57,405,411,573` | body / notice / tab |
| 15 | 29 | rows, titles, buttons, body | body, label, heading |
| 16 | 5 | `payment_theme.dart:125` (`amountStyle(large:false)`), `primitives.dart:164` (Total label), `payment_status.dart:84` (countdown), `payment_extras.dart:599`, `transactions.dart:390` (inputs) | heading / input |
| 17 | 2 | `interaction.dart:297`, `sheets.dart:53` | sheet/dialog title |
| 20 | 2 | `payment_extras.dart:86` (bar total), `:400` (balance) | large amount |
| 32 | 1 | `payment_theme.dart:129` | display amount |

**Weights:** w400 60, w600 25, w500 11, w700 3 (1 in `lib`), plus `amountWeight` 2.

**Tracking at 15 px:**

| Tracking | Uses | Example |
| --- | --- | --- |
| 0.1 | 9 | titleSmall-based: section title, StatusHeader, merchant |
| 0.25 | 7 | bodyMedium-based: InfoRow label/value, references |
| 0.5 | 8 | bodyLarge-based: method label, status body, history title, ActionTile, balance |
| inherit | 5 | buttons |

Tracking at other sizes:
- 12 px: 0.4 (14×) and 0.5 (3×)
- 14 px: 0.1, 0.25 and 0.5
- 16 px: 0.15 and 1.0 (promo input)

There are 4 explicit tracking values: −0.32 display, 0.5 promo tag, 1 promo input, 1.5 VA number.

**Leading at 15 px:**

| Leading | Uses | Source |
| --- | --- | --- |
| 1.43 (21.4 px) | 11 | M3 |
| 20/15 | 6 | explicit |
| `large ? 1.3 : 22/15` | 4 | explicit |
| 1.5 (22.5 px) | 3 | M3 |
| inherited | 5 | — |

Display amounts use 1.15 (36.8 px).

**`textTheme` roles borrowed:**

| Role | Uses |
| --- | --- |
| bodySmall | 22 |
| bodyMedium | 20 |
| titleSmall | 10 |
| bodyLarge | 9 |
| titleMedium | 3 |
| labelMedium | 3 |
| labelLarge | 2 |
| labelSmall | 2 |
| titleLarge | 2 |
| headlineMedium | 1 |

That is 10 roles, almost all with an overridden size.

**Same-role drift (examples):**
- **Row label:** InfoRow `bodyMedium` 15 +0.25 / 21.4 (`primitives.dart:168`). Method name `bodyLarge` 15 +0.5 / 22.5 (`checkout.dart:334`). ActionTile `bodyLarge` 15 +0.5 / 20 (`interaction.dart:103`). History title `bodyLarge` 15 **w500** +0.5 / 22.5 (`transactions.dart:125`). Four settings for one role.
- **Heading:** section title 15 w600 / 21.4 (`primitives.dart:585`). StatusHeader 15 w600 / 20 (`:656`). Total label **16** w600 / 24 (`:164`). NoticeBanner title **14** w600 / 20 (`:511`).
- **Large amount:** bar total 20 (capped 1.6×, `payment_extras.dart:82-90`). Balance 20 (**uncapped**, `:398-401`, so 40 px at 200%). VA number 16 (`payment_status.dart:57`).

### 3.2 Spacing

**`theme.spacing *` multipliers:**

| Multiplier | dp | Uses |
| --- | --- | --- |
| 1 | 8 | 38 SizedBox uses + padding |
| 1.5 | 12 | 42 |
| 2 | 16 | 26 |
| 0.5 | 4 | 10 |
| 3 | 24 | 4 |
| 2.5 | 20 | 3 (off-scale: `sheets.dart:34,115,117`) |
| 4 | 32 | 1 |

**Literals in `lib`:**
- `SizedBox` 4 (13×), 8 (4×) and 12 (1×) bypass `theme.spacing`.
- EdgeInsets literals: `all(8)` (`payment_extras.dart:211`), `all(12)` (`video.dart:320`), `top: 16` (`promo.dart:130`), `symmetric(h: 8, v: 4)` (tags).
- No off-grid literals remain in `lib` (WP-A to WP-D fixed the 2s and 6s).
- Example: `vertical: 2` (`flow_screen.dart:904`, host log lines), `fromLTRB(4, 16, 4, 8)` (`scenario_picker.dart:51`), `fromLTRB(20, 0, 20, 20)` (`main.dart:304`).

**Effective gaps per screen (100%, visible text-to-text in dp, built from the nesting):**

| Screen | Relationship | Now | Built from |
| --- | --- | --- | --- |
| Checkout | Summary Total → "Metode pembayaran" | **36** | row 8 + section 8 + `flow_screen.dart:610` 12 + section 8 |
| Checkout | Section title → method box | **4** | `primitives.dart:596` |
| Checkout | Section title → first row | 12 | 4 + row 8 |
| Re-quote | Summary → "Bayar dengan" | **36** | row 8 + 8 + `checkout.dart:454` 12 + 8 |
| Re-quote | Footnote → Pay button | 16 | `checkout.dart:485` |
| Authorize | Total rows → prompt | **32** | row 8 + section 8 + `flow_screen.dart:704` 16 |
| Authorize | Notice → button | 16 | `checkout.dart:572` |
| Status | Message → primary action | 24 | `payment_status.dart:363` |
| Status | Last button → rule → first detail row | **24 / 24** | button pad 8 + `spacing*4` divider + row 8 |
| Status | Details → refund | 32, no rule | row 8 + 16 + section 8 |
| VA pending (flow) | Status details → instructions title | **20** | row 8 + `flow_screen.dart:745` 4 + section 8 |
| VA instructions | Number → rule | host-dependent | `payment_status.dart:71` |
| Receipt | Date → "Detail" | 24 | 16 + section 8 |
| Receipt | Details → refund (ruled) | 20 / 20 | row 8 + `Divider(24)` + 8 |
| Receipt | Last row → Share | 24 | row 8 + 16 |
| History detail | Copy → actions | **16** | `transactions.dart:510` |
| History detail | Actions → "Detail" | 24 | 16 + 8 |
| History item | Row padding / title → meta / meta → tags | 12 / 4 / 8 | consistent |
| Sheets | Side gutter | **20** | `spacing*2.5` (screen gutter elsewhere is 16) |

### 3.3 Color

- **Hardcoded hex in `lib`:** 8, all tone foregrounds in `payment_theme.dart:75-78`. These are contrast-checked: light 6.3–7.2:1 on white, dark 7.6–9.1:1 on #131417, and ≥ 5.5:1 on their own containers.
- **Example themes:** 18 hex values (`themes.dart`). Gallery workbench: 2 (`gallery_screen.dart:198-199`).
- **`Colors.*` in `lib`:**
  - `transparent` 14 (focus-fill removal, ok)
  - `white`, `black`, `black54`, `white70` in `video.dart:281-363` (over-video controls, acceptable)
  - `black54` scrim in `sheets.dart:203`
- **Alpha-based:**
  - `textSecondary@0.5` for the secondary button and KYC outline: `primitives.dart:369`, `verification_widgets.dart:322`, and the example's `themes.dart:144`
  - `@0.75` for the example input (`themes.dart:184`)
  - white@0.12 in video (`video.dart:425`)
  - `accent@0` as the animated outline start (`checkout.dart:307`, fine)
- **Token usage:**

  | Token | Uses |
  | --- | --- |
  | spacing | 140 |
  | textSecondary | 55 |
  | textPrimary | 31 |
  | accent | 26 |
  | outline | 22 |
  | radius | 22 |
  | surface | 12 |
  | surfaceMuted | 7 |
  | danger | 7 |
  | onAccent | 4 |
  | warning | 3 |
  | success | 2 |

- **Missing:**
  - `border` (control edge ≥ 3:1)
  - `disabled`
  - `referenceFontFamily`, proposed in research §6 and never added
- **To remove:**
  - `textSecondary.withValues(alpha: …)` for borders
  - Material's implicit disabled opacity on `PaymentButton`
  - green amounts (discount)
  - the info tint on the normal authorization path
- **Contrast** (WCAG 2, computed):

  | Pair | Light | Dark |
  | --- | --- | --- |
  | ink | 16.2:1 | 15.7:1 |
  | muted | 5.76:1 | 7.72:1 |
  | muted on `surfaceMuted` | 5.32:1 | 6.99:1 |
  | `outline` (rule) | 1.25:1 | 1.36:1 |
  | radio ring #7A8396 | 3.81:1 | — |
  | proposed `border` | 3.37:1 (3.12 on muted) | 4.85:1 (4.39 on muted) |
  | proposed `disabled` | 2.30:1 (2.13 on muted) | 3.16:1 |

  Lumen proposed `border` is 4.0:1 light and 5.55:1 dark. Disabled text is exempt from 1.4.3; it is kept above 2:1 so the label stays legible.
- **Dark risk:** `surfaceMuted` #1C1E23 on #131417 is about 1.1:1. That is fine as a fill, but no meaning may ride on the fill alone. Today none does: the promo tag and step circles also carry text.

### 3.4 Radius, borders, icons

**Radius:**

| Radius | Uses | Where |
| --- | --- | --- |
| `radius*0.75` = 6 | 21 | controls |
| `radius` = 8 | 2 | method list |
| `radius*0.5` = 4 | 1 | promo |
| literal 4 | 5 | badge, promo tag, state skeletons, checkbox (example) |
| 12 | 3 | dialog `interaction.dart:294`, sheet `sheets.dart:176`, example dialog |
| 24 | 8 | circular focus rings on 48 dp icon buttons |
| 2 | 2 | 4 px progress bar, KYC progress |
| 3 | 1 | band, half its height |
| 1.5 | 1 | step bars |
| 30 | 1 | video play disc |
| 999 | 1 | nav count badge |

Everything maps to a 4 / 6 / 8 / 12 / full scale. The 2, 3 and 1.5 values are "full" on thin bars.

**Borders:**
- 1 px rules and the group edge (`outline`)
- 2 px selected method outline (accent)
- 1.5 px unselected radio and 6 px selected radio
- 2 px focused input (example)
- the 2 px focus ring (WP-D)

**Icons:**

| Size | Uses | Where |
| --- | --- | --- |
| 20 | 14 | standard |
| scaled `iconSize` | 6 | first-line boxes |
| default 24 | 6 in `lib` | including the status copy button and the video/sheet close buttons |
| 14 | 2 | badge, promo tag |
| 18 | 2 | promo remove `payment_extras.dart:543`, KYC `verification_widgets.dart:118` |
| 16 | 1 | verified mark |
| 32 / 36 | 1 each | video |
| 48 | 1 | privacy lock |

### 3.5 Hierarchy per MVP screen (100%)

Emphasis means w600+ or colored text, not counting the primary button label.

| Screen | Primary actions | Display amounts | Total shown | Emphasis now | Verdict / change |
| --- | --- | --- | --- | --- | --- |
| Checkout | 1 (Tinjau) | 1 (+20 px bar total) | 3 (headline, Total row, bar) | 6: 2 section titles, headline, Total label, Total value, bar | OK by the owner's 100% decision. Row amounts drop to w400; Total label 16 → 15. |
| Re-quote confirmation | 1 (Bayar Rp…) | 1 | 5 (headline, notice old→new, Total, consent, button) | 6 + amber notice title | Keep the repetition, which is safety copy. Consent → body. "Bayar dengan": method name in ink, detail as caption (now inverted: name muted, detail ink, `checkout.dart:455-461`). |
| Authorization (flow) | 1 + quiet back | 1 (inside a right-aligned row, `flow_screen.dart:687-703`) | 1 | Total label, display amount, blue title in a blue box | Plain heading + body for `ready`. The flow shows a caption "Total" + a left-aligned display amount. |
| VA pending | 1 (Cek status) | **2** | 2 | **7**: tone title, amount, section title, VA number, "Jumlah dibayar" label, second amount, w700 countdown | §2 rows 1–3. After: display 1, emphasis 4 (tone title, amount, VA number, countdown). |
| Status unknown | 1 | 1 | 1 | 3: tone title, amount, "Jangan bayar lagi." | Correct; tracking/leading only. |
| Status pending / success / failed | 1 | 1 | 1 | 2 | Correct; tracking/leading only. Divider → 24. |
| Receipt | 0 filled (Share secondary, Done quiet) | 1 | 2 (headline, Total) | 5: green title, amount, "Detail", Total ×2 | OK. A settled record has no forced next step (see owner question 2). |
| History list | — | 0 | — | Per row: w500 title, w500 amount, w600 tag | Title → heading w600; amount → w400 tabular (ink if settled, muted otherwise); tag stays. |
| History detail | 1 | 1 | 1 | Sheet title + tone title + amount + lead | OK. Copy → actions gap 16 → 24. |

## 4. Proposed foundation

### 4.1 Type scale (7 sizes, 9 roles, 2 weights)

Every role sets `height` and `letterSpacing` explicitly and sets `leadingDistribution: even`. Each role also **copies `fontFamily` and `fontFamilyFallback` from `Theme.of(context).textTheme.bodyMedium`**, so the host's font always applies.

Copying is required because inheriting is not enough. `ButtonStyle.textStyle` and `InputDecoration` label styles are resolved per property rather than merged with `DefaultTextStyle`. A role with no family would render a `PaymentButton` label in the platform font for a host that sets `ThemeData(fontFamily: …)`. Today's const button label (`primitives.dart:346`) already has this bug. Amount roles add `fontFeatures: [FontFeature.tabularFigures()]` and `amountFontFamily`. Reference roles add `referenceFontFamily`.

| Role | Size/line | Weight | Tracking | Color | Used for | At 200% |
| --- | --- | --- | --- | --- | --- | --- |
| `display` | 32/36 (h 1.125) | `amountWeight` (600) | −0.32 | textPrimary | the one display amount: summary headline, status, receipt, history detail | Capped at 1.6× (51 px), with `FittedBox(scaleDown)`. Omitted from the summary above 1.5× (already done). |
| `amountLarge` | 20/28 | `amountWeight` | 0 | textPrimary | action-bar total, balance, VA number (+ mono), entered top-up amount in `AmountInput` | Capped at 1.6× (32 px) everywhere. Today only the bar is capped. |
| `title` | 17/24 | 600 | 0 | textPrimary | sheet, dialog and example app-bar titles | Scales fully and wraps |
| `heading` | 15/20 | 600 | 0 | textPrimary or tone | section title, status title, Total label + amount, merchant name, notice title, button label, history row title, countdown | Scales fully. Line 20/15 stays (30/40 at 2×). First-line icon boxes already key off it. |
| `body` | 15/22 | 400 | 0 | textPrimary | paragraphs: status explanation, notice message, consent, VA steps, promo body | Leading → 1.3 above 1.5× (existing D4) |
| `label` | 15/20 | 400 | 0 | textPrimary (values) / textSecondary (labels) | single-line row text: InfoRow label + value, method name, row amounts, filter tabs, ActionTile title | Scales fully. InfoRow wraps (D7, already done). |
| `caption` | 13/18 | 400 | 0 | textSecondary | supporting lines: method detail, fee note, meta, captions, footnotes, merchant detail, step label, limit, receipt date | Scales fully, `maxLines` ≥ 2 where it carries data |
| `tag` | 12/16 | 600 | 0 | tone foreground | `StatusBadge`, nav count badge, copy feedback, step numbers | Scales fully. Tags sit in a `Wrap`. |
| `input` | 16/24 | 400 | 0 | textPrimary | text fields (promo code + mono, search) | Scales fully |

That makes 7 sizes (12, 13, 15, 16, 17, 20, 32) where today there are 9, and 2 weights where today there are 4. There are 9 roles over those 7 sizes because three roles share 15 px and differ only in leading or weight: `heading` is 15/20 w600, `label` is 15/20 w400 and `body` is 15/22 w400. Naming them separately is what keeps a row label from drifting back to paragraph leading. `numeric` is a modifier, not a role: `.tabular` adds tabular figures, and `.reference` adds tabular figures plus `referenceFontFamily`. References in rows (attempt ID, transaction ID) use `label.reference`, so a mono 15/20 row. The VA number uses `amountLarge.reference`.

**Exposure: recommend an internal (not exported) `PaymentType` helper.** It lives in `lib/src/foundation/payment_type.dart` and is created with `PaymentType.of(context)`, the same pattern as `amountStyle(context)`. It reads `PaymentTheme` for colors, `amountWeight`, `amountFontFamily` and `referenceFontFamily`.

- **Why not a public `PaymentTypography` ThemeExtension:** it adds a second registration and fallback path, plus `lerp`/`copyWith`, for values still being tuned. It freezes 9 roles as public API before the owner sees them.
- **Why not getters on `PaymentTheme`:** they would expose an unexported type or force public role classes now.
- **The tradeoff:** hosts cannot reuse or override a single role yet. They brand through `fontFamily`, `amountWeight`, `amountFontFamily`, `referenceFontFamily` and color tokens, as today. Promote the helper to a public `PaymentTheme.textStyles(context)` after the owner approves the regenerated screenshots. That change is additive.
- **Public `amountStyle` stays**, re-implemented on the roles:
  - `large: true` → `display`, whose line changes from 36.8 to 36.
  - `large: false` → 15/20 `amountWeight` tabular, tracking 0. This was 16 px `titleMedium`. It is a visible change; list it in the CHANGELOG.

### 4.2 Spacing scale (on `theme.spacing` = 8)

| Name | Value | Multiplier | Rule |
| --- | --- | --- | --- |
| inline | 4 | `spacing * 0.5` | label → caption, title → meta, lead → detail, amount → subtitle, tag icon → text, section title → first `InfoRow` (which adds its own 8) |
| related | 8 | `spacing` | `InfoRow` vertical padding, between stacked actions, icon → label, title → non-row content (box, text, badge) |
| block | 12 | `spacing * 1.5` | band → status title, header → amount, amount → message, tappable-row vertical padding (≥ 48 dp), notice padding, action-bar vertical padding |
| group | 16 | `spacing * 2` | screen and sheet gutter, between groups inside one section, inline notice after a message |
| section | 24 | `spacing * 3` | content → primary action. The visible gap between sections: two `PaymentSection`s stack **flush** (8 + 8 + the last row's 8 = 24). A ruled separation is `Divider(height: spacing * 3)`. |
| major | 32 | `spacing * 4` | empty/state message padding only |

**Ownership:** the library owns spacing *inside* a widget and the section padding. The host owns the gap between top-level blocks, and the example follows the same table. `PaymentSection` keeps its 8 vertical padding, so there is no visible change for hosts. Allowed multipliers: 0.5, 1, 1.5, 2, 3, 4. Literal `SizedBox(height: 4/8/12)` in `lib` become `theme.spacing` multiples, so a host's `spacing: 10` scales them too. Strokes (1, 1.5, 2, 3), the 6 px band, 48 dp targets and the 112/240 button bounds are not spacing and stay literal.

### 4.3 Color tokens (additive on `PaymentTheme`)

| Token | Default | Hairline light | Hairline dark | Use |
| --- | --- | --- | --- | --- |
| `outline` (existing, re-documented) | — | #E3E6EC | #2C2E35 | **Rule only:** hairlines, the method-group edge, the action-bar top. Decorative; may be < 3:1. |
| `border` (new) | `Color.lerp(textSecondary, surface, 0.25)` | #868C9A (3.37) | #7E838E (4.85) | Control edges: input enabled border, secondary button side, unselected checkbox, KYC outlined controls |
| `disabled` (new) | `Color.lerp(textSecondary, surface, 0.45)` | #A6ABB5 | #62656E | Disabled control label and icon. The disabled fill is `surfaceMuted`. |
| `referenceFontFamily` (new, `String?`) | null → `'Menlo'` with fallback `['monospace', 'Courier']`, the example's existing stack | | | VA number, attempt/transaction references, promo code |

The constructor takes optional `Color? border`, `Color? disabled` and `String? referenceFontFamily`. Public getters resolve the derived default, so existing `const PaymentTheme(...)` calls and `fromColorScheme` keep compiling.

**`copyWith` forwards the raw nullable field** (`border: border ?? _border`), never the resolved getter. Both example brands are built as `fromColorScheme(scheme).copyWith(textSecondary: …)`. Copying the resolved value would freeze `border` and `disabled` to the scheme's `onSurfaceVariant` instead of the overridden muted color. `lerp` may lerp the resolved colors.

Focus stays on `textPrimary` (WP-D) and selection on `accent`. No tone changes. The example themes set `border` and `disabled` explicitly to the table values; Lumen uses its derived values (4.0 / 5.55).

### 4.4 Radius and icon scale

**Radius:** add derived `BorderRadius` getters, like the existing `borderRadius` (additive, no constructor change). Each one returns `BorderRadius.circular(radius × factor)`.

| Getter (`BorderRadius`) | Value | Use |
| --- | --- | --- |
| `tagBorderRadius` | `radius * 0.5` = 4 | badges, tags |
| `controlBorderRadius` | `radius * 0.75` = 6 | buttons, inputs, notices, menus |
| `radius` / `borderRadius` | 8 | selectable/copyable box (unchanged) |
| `sheetBorderRadius` | `radius * 1.5` = 12 | sheet top, dialog |

"Full" stays literal for circles and thin bars.

**Icons:**

| Size | Use |
| --- | --- |
| 14 | inside 12 px tags only |
| 16 | inline in 15 px text (verified mark) |
| 20 | all controls, radio, copy, close, chevrons, leading icons, first-line boxes before scaling |
| 32 / 36 | video transport, documented exception |
| 48 | privacy lock, documented exception |

## 5. Decisions (made on the owner's behalf)

| # | Decision | Rationale |
| --- | --- | --- |
| F1 | Type roles as in §4.1, behind an internal `PaymentType`. Promote it after screenshot approval. | Enforces one style source without freezing values as API. |
| F2 | Two weights (400/600). `amountWeight` stays the host's lever for amounts. | Restraint; w500/w700 each had one or two accidental users. |
| F3 | Row amounts are regular weight (400). Only the Total row and display amounts are heavy. | Research §1: line-item values at regular weight; the total is the one to find. |
| F4 | Caption 13 everywhere. 12 is for tags only. Nothing below 12. | One supporting size. The 11 px badge and "Disalin" break the floor. |
| F5 | Explicit tracking 0 on all text roles, −0.32 on display only. Promo code and VA number lose their tracking hacks in favor of mono. | Body sizes get no tracking. Mono already spaces characters. |
| F6 | `border` and `disabled` tokens. `outline` is documented as the rule. | Separate decorative and functional edges; no opacity-based states. |
| F7 | `referenceFontFamily`, defaulting to the platform mono stack. | Approved in research §0/§6 but never built. |
| F8 | VA pending: one display amount (status header). Instructions use a heading-weight total row. The countdown is `heading` tabular. Steps are plain tabular numbers, not tinted circles. | Constraint 2; the countdown stops competing; circles were decoration. |
| F9 | `PaymentStatusView.instructions` slot (additive, default null). At ≤ 1.5× text it renders after the explanation and before the actions. Above 1.5× it renders after the actions and before the reference rows. The VA steps always collapse into an `ExpandableSection` titled "Cara bayar" / "How to pay". | At 100%, what to pay into comes before "Cek status" (Midtrans pattern). At 200% the action must stay on the first screen (D2), and the arithmetic below shows the slot would push it under the bar. |
| F10 | `AuthorizationPrompt`: no tinted box for `ready`/`inProgress`/`approved`; `NoticeBanner` only for `failed`/`expired`/`canceled`. | Proportional urgency. |
| F11 | Section gaps per §4.2. Sections stack flush; ruled gaps are `Divider(height: 24)`; content → primary action is 24. | One rhythm for one relationship. |
| F12 | `PaymentConfirmation` "Bayar dengan": method name `label` ink, detail `caption`. | The name is the information, the detail supports it. Today it is inverted. |
| F13 | The discount amount is ink, not green. | Colored money competes with the total. |
| F14 | The history row title is `heading` (w600); the amount is `label` w400 tabular. | People scan for the name. Tabular figures align amounts without weight. |
| F15 | Icon scale 14/16/20. The status copy icon goes from 24 to 20 and promo remove from 18 to 20. | One size per job. |
| F16 | Package inputs set `enabledBorder: border` and `focusedBorder: accent 2 px` with `controlBorderRadius`. | The kit already owns button styling. Inputs looked different in hosts without the example's `inputDecorationTheme`. |
| F17 | Sheet gutter 20 → 16. | The 8 grid with 4/12 half-steps; 16 is the screen gutter everywhere else. |
| F18 | Host tools in the flow use the gallery workbench voice. Workbench and mono tokens move to one example file. | Gallery chrome is visually separate from the product (constraint 9). |
| F19 | One large-text helper (> 1.5×). The promo row keeps a named 1.3 exception. | Removes the silent `> 13` vs `> 15` drift. |

**F9 arithmetic (VA pending, P09).** This uses the dp budget from `ui-review-plan.md` §1: Android 360×624 has content from 80 to 560, and iOS has content from 114 to 753. Heights use the §4.1 roles.

| Block | 100% | 200%, slot before actions |
| --- | --- | --- |
| list pad + band + gap + title | 8 + 6 + 12 + 20 = 46 | 8 + 6 + 12 + 40 = 66 |
| gap + display amount | 12 + 37 | 12 + 59 (1.6× cap) |
| gap + message | 12 + 22 (1 line) | 12 + 78 (2 lines at 1.3) |
| gap + section pad + "Instruksi transfer" + gap | 16 + 8 + 20 + 4 | 16 + 8 + 40 + 4 |
| provider caption | 18 | 36 |
| gap + VA number row (48 dp copy target) | 4 + 48 | 4 + 52 |
| rule | 16 | 16 |
| "Jumlah dibayar" row | 36 | ≈ 100 (wraps) |
| countdown row + date caption | 54 | ≈ 92 |
| "Cara bayar" collapsed header | 48 | 48 |
| gap + "Cek status" | 24 + 52 | 24 + 52 |
| **Button bottom** | 477 → Android 557 (< 560 ✔), iOS 591 ✔ | 715 → Android 795 ✘, iOS ≈ 749, under the bar's edge ✘ |

Above 1.5×, the slot moves after the actions. The button's bottom is then 66 + 71 + 90 + 24 + 52 = 303, which is Android 383 ✔. With the steps expanded instead of collapsed, even 100% would be past 560 on Android. That is why "Cara bayar" collapses.

**Public API changes (additive; list in CHANGELOG):**
- `PaymentTheme`:
  - `border`, `disabled`, `referenceFontFamily`, all optional with derived defaults
  - getters `tagBorderRadius`, `controlBorderRadius`, `sheetBorderRadius`
- `PaymentStatusView.instructions` (`Widget?`)
- `PaymentLocalizations.howToPay`

**Visible changes:**
- `amountStyle(large: false)` goes from 16 → 15 px.
- Row amounts change from w500 to w400.
- Caption, body, tracking and leading change kit-wide.
- The VA instructions total is no longer display size.
- The authorization ready state has no box.
- The discount is ink.

## 6. Work packages

**Order:** WP-0 runs alone and merges. Then WP-A, WP-B and WP-C run in parallel.

**Rules for the parallel wave:**
- File sets are disjoint.
- No wave package uses a symbol another wave package adds. They use only WP-0 symbols and existing APIs.
- Each test file has exactly one owner.
- `docs/decisions.md` and `CHANGELOG.md` belong to the orchestrator after the wave.

**Local flake:** `flutter test` sometimes fails to load a file with "Unable to connect to flutter_tester process: WebSocketException". Run test files one at a time and retry a file on that error. It is an environment issue, not a test failure.

**Screenshot regeneration:** after the wave, the orchestrator runs `example/integration_test/kit_screenshots_test.dart` (iOS and Android) and `example/integration_test/screenshots_test.dart` (iOS) to `example/build/screenshots_hairline/`. Acceptance files are named per package.

### WP-0: foundation tokens (alone, first)

**Files (exclusive):**
- `lib/src/foundation/payment_theme.dart`
- `lib/src/foundation/payment_type.dart` (new, **not** exported from `lib/flutter_ui_payment.dart`)
- `lib/src/foundation/primitives.dart`
- `lib/src/foundation/payment_localizations.dart`: one new string only, `howToPay` (en "How to pay", id "Cara bayar")
- `example/lib/themes.dart`
- `example/lib/dev_chrome.dart` (new)
- `test/foundation_tokens_test.dart` (new)

**Changes:**

1. **`payment_theme.dart`.**
   - Add optional constructor params `Color? border`, `Color? disabled` and `String? referenceFontFamily`, stored privately.
   - Add public getters:
     - `border`: `_border ?? Color.lerp(textSecondary, surface, 0.25)!`
     - `disabled`: `_disabled ?? Color.lerp(textSecondary, surface, 0.45)!`
     - `referenceFontFamily`: `_referenceFontFamily ?? 'Menlo'`
     - `referenceFontFamilyFallback`: `const ['monospace', 'Courier']`
   - Add `BorderRadius` getters:
     - `tagBorderRadius`: `BorderRadius.circular(radius * 0.5)`
     - `controlBorderRadius`: `BorderRadius.circular(radius * 0.75)`
     - `sheetBorderRadius`: `BorderRadius.circular(radius * 1.5)`
   - Extend `copyWith` and `lerp` to cover the new fields. **`copyWith` forwards the raw private field** (`border: border ?? _border`, and the same for `disabled` and `referenceFontFamily`), so a later `textSecondary` override still re-derives them. `lerp` lerps the resolved colors.
   - Doc comments:
     - `outline` is "hairline rule, decorative".
     - `spacing` lists §4.2's six names and multipliers.
   - Re-implement `amountStyle`:
     - `large: true`: 32, `height: 36/32`, −0.32, `amountWeight`, tabular, `amountFontFamily`.
     - `large: false`: 15, `height: 20/15`, `letterSpacing: 0`, `amountWeight`, tabular, `amountFontFamily`.
2. **`payment_type.dart`.** A class `PaymentType` with:
   - `factory PaymentType.of(BuildContext)`
   - `static bool isLarge(BuildContext)` (`MediaQuery.textScalerOf(context).scale(10) > 15`)
   - final `TextStyle` fields: `display`, `amountLarge`, `title`, `heading`, `body`, `label`, `caption`, `tag`, `input`, with exact values from §4.1
   - a `bodyFor(BuildContext)` returning `body` with `height: 1.3` when `isLarge`
   - an extension on `TextStyle` with `tabular` and `reference(PaymentTheme)`

   Every style sets `fontSize`, `height`, `fontWeight`, `letterSpacing`, `leadingDistribution: TextLeadingDistribution.even` and a color (`tag`: none).

   Font family:
   - Every style copies `fontFamily` and `fontFamilyFallback` from `Theme.of(context).textTheme.bodyMedium` (§4.1).
   - Amount roles (`display`, `amountLarge`) use `amountFontFamily ?? <that family>`.
   - `reference` replaces the family with `referenceFontFamily` plus its fallback.
3. **`primitives.dart`** (migrate every style site in this file):

   | Widget | Change |
   | --- | --- |
   | `AmountText` | Non-emphasis base = `label.tabular` with `amountFontFamily` (w400, was 15 w500 `:25-29`). Emphasis base = `display`. Keep the 1.6× cap for emphasis. **Add the same 1.6× cap when the merged `fontSize ≥ 20`**, so the bar, balance and any `amountLarge` amount are capped. |
   | `InfoRow` | Label `label` + `textSecondary`. Emphasis label `heading`. Value `label`. Caption `caption`. Padding `theme.spacing` (unchanged). |
   | `PaymentButton` | `textStyle: heading` (replaces the const at `:346`, so the label carries the host family). Add `disabledBackgroundColor: theme.surfaceMuted` and `disabledForegroundColor: theme.disabled` to all three variants (quiet: foreground only). Secondary side: `WidgetStateBorderSide.resolveWith((s) => BorderSide(color: s.contains(WidgetState.disabled) ? theme.disabled : theme.border))` via `.copyWith(side: …)`. It was `textSecondary@0.5` (`:369`). Shape radius `theme.controlBorderRadius`. |
   | `StatusBadge` | Text `tag`, icon 14, radius `theme.tagBorderRadius`. |
   | `NoticeBanner` | Title `heading` (15/20, so the first-line box uses `scaler.scale(15) * 20 / 15`). Message `body` in `textPrimary`. Radius `controlBorderRadius`. |
   | `PaymentSection` | Title `heading`. Gap stays `spacing * 0.5`. |
   | `StatusHeader` | Title `heading` + tone color. Band gap `spacing * 1.5`. |
   | `PrivacyMask` | Unchanged. |
   | `CountdownText` | Unchanged API. The caller passes the style. |

4. **`example/lib/themes.dart`.**
   - Hairline: `border: dark ? Color(0xFF7E838E) : Color(0xFF868C9A)` and `disabled: dark ? Color(0xFF62656E) : Color(0xFFA6ABB5)`.
   - Lumen: leave the derived defaults.
   - `outlinedButtonTheme.side` and `inputDecorationTheme.enabledBorder` use `payment.border` (`:144`, `:184`).
   - `snackBarTheme`/`popupMenuTheme` use `payment.controlBorderRadius`; `dialogTheme` uses `payment.sheetBorderRadius`.
   - App-bar title stays 17 w600. Add `height: 24/17, letterSpacing: 0`.
5. **`example/lib/dev_chrome.dart`.**
   - Move `_workbench`'s two colors into a public `Color devWorkbench(BuildContext)`.
   - Add `TextStyle devMono(Color color)`: 12/16.8 (height 1.4), Menlo with fallback `['monospace']`.
   - Add `TextScaler devScaler(BuildContext)` (clamp 1.2).
   - Do **not** edit `gallery_screen.dart` (WP-C switches it over).
6. **`test/foundation_tokens_test.dart`.**
   - (a) Each `PaymentType` role has the §4.1 size, height, weight and `letterSpacing` (0 except display −0.32), checked at text scale 1.
   - (b) The derived `border` is ≥ 3:1 against `surface` and `surfaceMuted` for `fromColorScheme(ColorScheme.fromSeed(seedColor: Color(0xFF1A1F36)))` in light and dark. Use `computeLuminance`.
   - (c) A disabled `PaymentButton` paints its label in `theme.disabled`, found through `DefaultTextStyle` under the button.
   - (d) `AmountText(money, style: TextStyle(fontSize: 20))` at `textScale: 2` is ≤ 1.6× its 1× height + 1.
   - (e) `PaymentTheme.fromColorScheme(s).copyWith(textSecondary: x).border == Color.lerp(x, s.surface, 0.25)`, and the same for `disabled` with 0.45.
   - (f) Under `ThemeData(fontFamily: 'X')`, a `PaymentButton` label's effective `fontFamily` is `'X'`. Read it from the `DefaultTextStyle` above the label `Text`.

**Acceptance (no screenshots; WP-0 is verified through the wave's captures):**
- `flutter analyze` is clean.
- `flutter test test/foundation_tokens_test.dart` passes.
- These regressions pass, each run separately: `flutter test test/widgets_test.dart`, `flutter test test/kit_components_test.dart`, `flutter test test/checkout_large_text_test.dart`, `flutter test test/focus_press_test.dart`, `flutter test test/payment_models_test.dart` and `flutter test test/money_test.dart`.
- If a regression asserts an old size or weight (for example w500), update **only** the assertion, and note it in the report.

### WP-A: checkout and commit path

**Files (exclusive):**
- `lib/src/payment/checkout.dart`
- `lib/src/payment/payment_extras.dart`
- `test/checkout_large_text_test.dart`

**Changes:**

1. **`AmountInput`** (`checkout.dart:96-123`):
   - `style: type.amountLarge`, so the entered top-up amount reads at 20/28 and is capped at 1.6× via `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.6)` around the `TextField`.
   - `prefixStyle: type.amountLarge.copyWith(color: theme.textSecondary)`
   - `labelStyle: type.label` and `helperStyle`/`errorStyle: type.caption` (error in `danger.foreground`)
   - `enabledBorder: OutlineInputBorder(borderRadius: theme.controlBorderRadius, borderSide: BorderSide(color: theme.border))`
   - `focusedBorder`: the same with `BorderSide(color: theme.accent, width: 2)`
2. **`PaymentSummary`:** unchanged structure. The Total row value is `AmountText(quote.total, style: TextStyle(fontWeight: FontWeight.w600))`, which now renders at 15/20 to match the `heading` label.
3. **`PaymentMethodPicker` / `_MethodTile`:**
   - Wrap the bordered box in `Padding(top: theme.spacing * 0.5)`, so title → box = 8 visible (4 + 4).
   - The method name is `label` (+ `textSecondary` when disabled).
   - Detail and fee note are `caption`.
   - The unavailable reason is `caption` in `danger.foreground` (keep `top: spacing * 0.5`).
   - The disabled `Icons.block` uses `theme.disabled`.
4. **`PaymentConfirmation`:**
   - Remove `SizedBox(height: theme.spacing * 1.5)` (`:454`), so sections stack flush (24 visible).
   - "Bayar dengan" child becomes a `Column`: `SizedBox(height: theme.spacing * 0.5)` (title → non-row content = 8), then `Text(method.label, style: type.label)`, plus `Text(method.detail, style: type.caption)` if not null. No `InfoRow` (F12).
   - Re-quote consent: `CheckboxListTile(title: Text(…, style: type.body), side: BorderSide(color: theme.border, width: 2))`. The unselected checkbox edge is a control edge (§4.3).
   - Footnote `caption`.
   - Gap before the pay button: `spacing * 2` → `spacing * 3` (`:485`).
5. **`AuthorizationPrompt`** (F10). For `ready`, `inProgress` and `approved`, replace the `NoticeBanner` with:

   ```
   Column(start) [
     Semantics(header) Text(title, heading),
     SizedBox(spacing * 0.5),
     Text(message, bodyFor(context) + textSecondary),
   ]
   ```

   Wrap it in `Semantics(liveRegion: phase != ready, container: true)`. Keep `NoticeBanner` for `failed`, `expired` and `canceled`. Gap before the button: `spacing * 2` → `spacing * 3`.
6. **`PaymentActionBar`:**
   - The updating text is `caption` (it was 14).
   - The total label is `caption`.
   - The total is `AmountText(total, style: type.amountLarge)`. Keep the clamp wrapper inside `Flexible`; the `AmountText` cap now also applies, which is harmless.
7. **`MerchantHeader`:**
   - The name is `heading`.
   - Detail is `caption`.
   - Initials are `tag` at 12, keeping `FittedBox` and `Padding(theme.spacing)` instead of `all(8)`.
   - `boxRadius` is `theme.controlBorderRadius`.
8. **`PaymentStepIndicator`:** label `caption.tabular`. The gap between bars is `theme.spacing * 0.5`.
9. **`BalanceCard`:**
   - Prepend `SizedBox(height: theme.spacing * 0.5)` before the first child (title → content = 8).
   - The unavailable text is `label` + `textSecondary`.
   - The balance is `AmountText(balance, style: type.amountLarge)`, now capped at 1.6× through WP-0's `AmountText` rule.
   - The limit text is `caption`.
10. **`PromoCodeInput`:**
    - The applied tag text is `label.reference(theme)` (tracking removed). Tag radius `tagBorderRadius`, icon 14, padding `symmetric(horizontal: spacing, vertical: spacing * 0.5)`.
    - Remove icon size 18 → 20.
    - Discount `AmountText(discount)` with no color (F13).
    - Field `style: type.input.reference(theme)` (it was +1 tracking) and the borders from step 1.
    - Replace both `scale(10) > 13` with `const _stackAt = 1.3;` `MediaQuery.textScalerOf(context).scale(10) > 10 * _stackAt`, with a comment explaining why this row stacks earlier.
11. Replace remaining literal `SizedBox`/`EdgeInsets` 4/8/12 in both files with `theme.spacing` multiples. Strokes and 48/112/240 stay.

**Acceptance (regenerated screenshots):**

| Screenshot | Check |
| --- | --- |
| `ios_checkout_light.png`, `android_refined_checkout_light.png` | Row amounts "Rp100.000" and "Rp2.500" are visibly regular weight. "Total" and its amount are one size. Text is not loosely tracked (compare "Saldo Ruang Bayar" letter gaps to the current capture). "Metode pembayaran" sits 8 dp above the method box (it was 4). |
| `ios_checkout_light_200.png`, `android_refined_checkout_light_200.png` | No headline amount. The bar total is ≤ 32 dp tall. "Tinjau pembayaran" is fully visible. |
| `ios_checkout_dark.png` | Same structure. No element at < 3:1 control edge. |
| `ios_requote_light.png` and `ios_requote_light_200.png` (new, added by WP-B) | The consent sentence is the same size as the summary rows (15). "Bayar dengan" shows the method name in ink, with its detail smaller and muted beneath. The pay button sits 24 dp below the footnote. |
| `ios_authorize_light.png` (new, added by WP-B) | No tinted box. The title is ink, heading weight. The message is muted. There is one filled button. |
| `android_kit_checkout.png`, `ios_kit_checkout.png`, `ios_kit_checkout_200.png` | Merchant detail and step label are the same caption size. The balance (if in view) is 20 px and ≤ 32 px at 200%. The promo code tag is mono. The discount is not green. |

**Tests:**
- Extend `test/checkout_large_text_test.dart`:
  - (a) A `BalanceCard` balance at `textScale: 2` has height ≤ 1.6× its 1× height + 1.
  - (b) `AuthorizationPrompt(phase: ready)` has no `NoticeBanner` descendant; `phase: failed` has one.
  - (c) `PaymentConfirmation` with a changed quote: the consent `Text` style `fontSize == 15`.
- Run `flutter test test/checkout_large_text_test.dart`, `flutter test test/widgets_test.dart` (read-only regression run) and `flutter analyze`.

### WP-B: results path (status, VA, receipt, history) and the flow example

**Files (exclusive):**
- `lib/src/payment/payment_status.dart`
- `lib/src/receipt/payment_receipt.dart`
- `lib/src/payment/transactions.dart`
- `example/lib/screens/flow_screen.dart`
- `example/integration_test/screenshots_test.dart`
- `test/widgets_test.dart`

**Changes:**

1. **`PaymentInstructions`** (F8):
   - Prepend `SizedBox(height: theme.spacing * 0.5)`.
   - Provider `caption`.
   - VA number: `SelectableText` with `type.amountLarge.reference(theme)`, no `letterSpacing`, wrapped in `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.6)`.
   - `Divider(color: theme.outline, height: theme.spacing * 2)` (it had no height, `:71`).
   - "Jumlah dibayar": `InfoRow(emphasis: true, value: AmountText(amount, style: TextStyle(fontWeight: FontWeight.w600)))`, **not** `emphasis: true` on the `AmountText`.
   - Countdown style: `type.heading.tabular`.
   - Steps: put the step list inside the existing `ExpandableSection(title: l10n.howToPay, child: …)`. It is collapsed by default (`initiallyExpanded: false`) and is an existing symbol from `interaction.dart`. Inside it:
     - Replace the `CircleAvatar` with `SizedBox(width: 20, child: Text('${i + 1}.', style: type.body.tabular.copyWith(color: theme.textSecondary)))`.
     - The step text is `type.body`.
     - Row padding stays `spacing * 0.5`.

     The elapsed `NoticeBanner` stays outside the disclosure, above it.
2. **`_CopyButton`:**
   - Icon `size: 20`.
   - Feedback text `type.tag` in tone color (it was 11 px).
3. **`PaymentStatusView`:**
   - Add `final Widget? instructions;` (doc: "Manual payment instructions, shown after the explanation and before the actions, so the account to pay into comes before Check status.").
   - Placement (F9):
     - When `!PaymentType.isLarge(context)`: render it after the message and unavailable notice, as `SizedBox(spacing * 2)` + `instructions`, before the actions.
     - When large: render it after the action buttons and before the details divider, as `SizedBox(spacing)` + `instructions`.
     - Comment the reason: the action must stay on the first screen at large text.
   - The body uses `type.bodyFor(context)`; the lead uses `heading`-weight body (`bodyFor` + w600).
   - Divider before details: `spacing * 4` → `spacing * 3`.
   - Reference `MiddleEllipsisText` style: `type.label.reference(theme)`.
   - Before the refund: replace `SizedBox(spacing * 2)` with `Divider(color: theme.outline, height: theme.spacing * 3)`.
4. **`RefundSection`:**
   - Gap after the badge: `theme.spacing`, not a literal.
   - Prepend `SizedBox(spacing * 0.5)`.
   - Note `caption` (it had no color).
5. **`PaymentReceipt`:**
   - Merchant `label` + `textSecondary`; date `caption`.
   - Gaps: 4 → `spacing * 0.5`.
   - The Total value is w600 (renders 15).
   - Transaction ID `label.reference(theme)`.
   - Share footnote `caption`.
   - The gap before Share stays `spacing * 2`, which is 24 visible with the row padding.
6. **`TransactionListItem` / `_FilterTab` / `TransactionHistory` / `TransactionDetail`:**
   - List title: `type.heading` (F14).
   - Amount: `AmountText(record.amount, style: TextStyle(color: …, decoration: …))`, which now renders w400.
   - Meta: `caption`.
   - Tab label: `label` (it was 14 w500), keeping no weight change on selection.
   - Search field: `type.input`, plus the `border`/`accent` borders as in WP-A step 1.
   - Detail: body via `bodyFor`. The record title is `label` + `textSecondary`. The gap before actions is `spacing * 2` → `spacing * 3` (`:510`). Reference `label.reference`.
7. **`example/lib/screens/flow_screen.dart`:**
   - `_Checkout`: remove `SizedBox(height: 12)` between `PaymentSummary` and `PaymentMethodPicker` (`:610`), and between the top-up section and the next block (`:585`) → stack flush.
   - `_Authorize` (`:687-704`):
     - Replace the emphasis `InfoRow` with the display amount. Use `Text(l10n.totalLabel, caption)`, `SizedBox(spacing * 0.5)`, and `Align(start, AmountText(total, emphasis: true))`.
     - Keep the "Bayar dengan" `InfoRow`.
     - `SizedBox(16)` → `SizedBox(8)`, which gives 24 visible.
   - `_Payment`: pass `instructions: PaymentInstructions(...)` into `PaymentStatusView` when `instructions != null && c.showInstructions`, and delete the trailing block (`:744-752`).
   - `_HostTools` (F18):
     - `Material(color: devWorkbench(context), shape: RoundedRectangleBorder(borderRadius: theme.controlBorderRadius))` with no border side.
     - Remove `leading`.
     - Title `Text(s.hostTools, style: devMono(theme.textSecondary), textScaler: devScaler(context))`, and the subtitle the same in `textPrimary`.
     - Log lines `devMono` with `vertical: 4` (it was 2).
     - **Keep** keys `host-tools`, `host-stats`, `host-restart` and `host-background`; `flow_screen.dart` is their only definition site.
   - Literal gaps: 4 → 8 or 12 per §4.2. Match the library, using the page gutter 16.
8. **`example/integration_test/screenshots_test.dart`:** add three captures inside the existing looks loop:
   - **`status_va_pending`:** `runScenario(tester, app, 'P09')`, then `pumpUntil(tester, () => c.attempt?.status == PaymentStatus.pending)`, then `shot('status_va_pending', look)`.
   - **`requote`:** `runScenario(tester, app, 'P02', variant: 2)`, pump until the quote is ready, then `c.reviewOrder()`, `await c.confirm()`, `pumpUntil(() => c.quote?.revision == 2)`, then shot. This mirrors `flow_test.dart:232-238`.
   - **`authorize`:** `runScenario(tester, app, 'P06')`, pump until the quote is ready, then `c.reviewOrder()`, `await c.confirm()`, `pumpUntil(() => c.step == FlowStep.authorize)`, then shot.

**Acceptance:**

| Screenshot | Check |
| --- | --- |
| `ios_status_va_pending_light.png` (new) | Exactly **one** 32 px amount, under "Menunggu". The order is: band → title → amount → message → "Instruksi transfer" → VA number in mono, ~20 px, with a 20 dp copy icon → rule → "Jumlah dibayar" row at row size → countdown (not heavier than the headings) → collapsed "Cara bayar" row (no grey step circles visible) → "Cek status", fully visible above the bottom bar → rule → references. |
| `ios_status_va_pending_light_200.png` (new) | **"Cek status" is fully visible above the bottom bar with no scrolling**, directly after the message. The instructions follow it. The VA number is ≤ 32 px tall and not clipped. |
| `ios_status_va_pending_dark.png` (new) | The band is solid and the mono number is readable. |
| `ios_status_unknown_light.png`, `ios_status_pending_light.png`, `ios_refined_status_unknown_light.png` | Body text is no longer loosely tracked. The gap between the "Cek status" bottom and the rule equals the rule → "Referensi pembayaran" gap (20 dp each). |
| `ios_status_unknown_light_200.png`, `android_refined_status_unknown_light_200.png` | "Cek status" is fully visible above the bottom bar (no regression). |
| `ios_receipt_light.png` | The date is caption size. The ID is mono. The Total label and amount are one size. |
| `ios_kit_history.png`, `android_kit_history.png` | Row titles are semibold. Amounts are regular. Tabs are 15 px regular. Meta is 13. |
| `ios_kit_history_detail_unknown.png` | "Cek status" sits 24 dp below "…belum diterima." |
| `ios_checkout_light.png` | The host tools panel is grey workbench, has mono text and no icon, and is distinct from the method list. |
| `ios_authorize_light.png` | The total caption and display amount are left-aligned (there is no right-aligned 32 px figure in a row). |

**Tests:** add to `test/widgets_test.dart`:
- (a) `PaymentStatusView(instructions: …)` with a VA: exactly one `AmountText` whose effective `fontSize` is 32 (`find.byWidgetPredicate`). At `textScale: 1` the `Check status` top is below the VA number's top. At `textScale: 2` (360×624) it is above it, and `tester.getBottomLeft(find.text('Check status')).dy < 624`.
- (b) The VA number's `TextStyle.fontFamily` equals `PaymentTheme.of(context).referenceFontFamily`.
- (c) A pending `PaymentInstructions` contains no `CircleAvatar`.

Run `flutter test test/widgets_test.dart`, `flutter test test/kit_components_test.dart` (read-only regression run) and `flutter analyze`. Also do a compile check of the integration test: `cd example && flutter analyze`.

### WP-C: secondary components (token alignment only) and gallery chrome

**Files (exclusive):**
- `lib/src/interaction/interaction.dart`
- `lib/src/navigation/navigation.dart`
- `lib/src/overlay/sheets.dart`
- `lib/src/promo/promo.dart`
- `lib/src/media/video.dart`
- `lib/src/verification/verification_widgets.dart`
- `example/lib/screens/gallery_screen.dart`
- `example/lib/screens/gallery_kit.dart`
- `test/kit_components_test.dart`

**Changes. This is pure mapping; no layout or behavior change.**

| Old style | New style |
| --- | --- |
| `bodySmall` 12/13 | `caption` |
| `bodyMedium` 14 / 15 body | `body` (or `label` for single-line rows) |
| `titleSmall` 15 w600 | `heading` |
| `titleLarge` 17 | `title` |
| `labelSmall` 11 badge (`navigation.dart:228`) | `tag` |
| `labelLarge` 13 w500 nav group label (`navigation.dart:94`) | `caption` w600 |
| KYC requirement title w500 (`verification_widgets.dart:85`) | `heading` |
| `bodyLarge` 15 + `20/15` (ActionTile `interaction.dart:103`, nav `navigation.dart:196`) | `label` |
| dialog/sheet body (`interaction.dart:305`) | `bodyFor` |

Other changes:
- **Borders:** `verification_widgets.dart:322` → `theme.border`; KYC text field (`:272`) → `border` / `accent` as in WP-A step 1.
- **Radius:**
  - dialog 12 (`interaction.dart:294`) and sheet 12 (`sheets.dart:176`) → `theme.sheetBorderRadius`
  - literal 4 (`interaction.dart:560,581`) → `tagBorderRadius`
  - promo `radius * 0.5` (`promo.dart:200`) → `tagBorderRadius`
- **Spacing:**
  - `sheets.dart:34,115,117`: `spacing * 2.5` → `spacing * 2` (F17)
  - `promo.dart:130`: `top: 16` → `spacing * 2`
  - `video.dart:320`: `all(12)` → `all(spacing * 1.5)`
  - literal 4/8 gaps → multiples
- **Icons:** `verification_widgets.dart:118` 18 → 20. Sheet and dialog close icons → 20. Video 32/36 stay.
- **Gallery:**
  - `gallery_screen.dart`: replace `_workbench` and the two inline mono `TextStyle`s (`:225-232`, `:274-279`) and `_chromeScaler` with `devWorkbench`, `devMono` and `devScaler` from `example/lib/dev_chrome.dart`.
  - `gallery_kit.dart`: map any product-looking literal sizes to roles only where they style kit specimens. Gallery captions stay mono.

**Acceptance:**

| Screenshot | Check |
| --- | --- |
| `ios_kit_interaction.png`, `android_kit_interaction.png` | Subtitles are 13 px. Titles are untracked. Nothing else moves. |
| `ios_kit_sheet_pending.png`, `android_kit_sheet_pending.png` | Sheet side gutter is 16 dp (it was 20); the title aligns with the notice edge. |
| `ios_kit_navigation_drawer.png` | The count badge is ≥ 12 px. |
| `ios_kit_promo.png`, `ios_kit_promo_200.png` | The disclosure is caption size. The body is 15. No new clipping. |
| `ios_refined_kyc_review_light.png`, `_200.png` | The outlined controls' edge is visibly darker than the rules. Rows are unchanged otherwise. |
| `ios_kit_history.png` (header area) | Gallery class captions and the state selector are unchanged: mono, 12 px, capped at 1.2×. |

**Tests:** add to `test/kit_components_test.dart`:
- (a) The `showPaymentSheet` body's horizontal padding is 16.
- (b) The nav count badge's text `fontSize` ≥ 12.

Run `flutter test test/kit_components_test.dart`, `flutter test test/widgets_test.dart` (read-only regression run) and `flutter analyze`.

### After the wave (orchestrator)

1. Run every test file separately, then `flutter analyze` and `cd example && flutter analyze`.
2. Add the **style guard** as `test/style_guard_test.dart`. It is a source scan of `lib/src/**/*.dart`:
   - No `fontSize:` literal outside `payment_type.dart` and `payment_theme.dart`.
   - No `FontWeight.w500` or `FontWeight.w700`.
   - No `textTheme.` role access outside `payment_type.dart`. Allowlist `interaction.dart` if a Material dialog needs one.
   - Every `spacing * x` has x ∈ {0.5, 1, 1.5, 2, 3, 4}.
   - No `.withValues(alpha:` applied to `textSecondary`/`textPrimary`.
   - No `Color(0x` outside `payment_theme.dart`.
   - Allowlisted: strokes (`width: 1|1.5|2|3|6`), 48 dp targets, the 6 px band, video `Colors.*`.

   It lands after the wave because it would fail mid-wave or force edits to a shared file.
3. Regenerate the screenshots (both suites) and check each package's acceptance table.
4. Update `docs/decisions.md` (a Foundation table) and `CHANGELOG.md` with the API and visible changes in §5.
5. Update `docs/components.md`:
   - `PaymentStatusView.instructions`, including its large-text placement
   - `PaymentTheme.border`, `disabled` and `referenceFontFamily`
   - the three `BorderRadius` getters
   - the spacing usage table from §4.2

## 7. Out of scope

- No new components: no denomination chips for pulsa/token, no PIN pad, no landing page or docs site.
- Secondary components (KYC, interaction, sheets, navigation, promo, video, gallery chrome) get token alignment only. No layout or behavior redesign.
- No color-space migration (OKLCH is a web/CSS tool; Flutter `Color` stays sRGB hex). No new tones.
- No performance work, no physical-device checks, no fonts bundled (system sans and the platform mono only).
- Already done and not re-proposed: `StatusHeader`, `InfoRow.trailing` and wrapping, the focus ring, the 0.96 press scale, dropping the summary headline at large text, and the action-bar cap.
- Not changed:
  - checkout's 100% headline + Total row + bar total (owner-approved)
  - the receipt's lack of a filled primary
  - the Lumen preset's character

## 8. Owner questions (non-blocking; defaults chosen above)

1. **Promote `PaymentType` to public API now** instead of after screenshot review? The default is "after".
2. **Receipt primary.** Should "Selesai" become the filled primary on the receipt? It currently has none: Share is secondary and Done is quiet. The default is to keep it as is.
3. **Mono family.** Is the platform mono (Menlo / monospace) acceptable for VA numbers and references? The alternative is bundling an OFL mono, which the package currently avoids.
