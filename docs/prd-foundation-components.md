# PRD: Design system — foundations, components, patterns

Date: 31 October 2026 (revision 2, after owner feedback)
Status: **approved by the owner on 31 October 2026.** All recommendations in §13 (Q1–Q10) were accepted. Nothing marked **New** is implemented yet. The §16a amendment row in §1 has been added to `PRD.md`.
Builds on: `PRD.md` §2, §4, §7, §10, §11 and §16a; `docs/decisions.md`; `docs/foundation-plan.md`; the docs catalog in PR #1; the charts and KYC capture work in PR #4.
Tracked by: issue #2.

## Ringkasan

Pemilik proyek menyetujui revisi pertama (tier, aturan penerimaan, inventaris Stripe, keputusan ekstraksi dan penolakan, fase) dan meminta lapisan design system: Button beserta variannya, Font beserta variannya, List beserta variannya, dan seterusnya. Dokumen ini sekarang membagi kit menjadi tiga lapisan. **Foundations** adalah token (warna, tipografi, spacing, radius, permukaan, ikon, motion, fokus, format uang). **Components** adalah komponen Tier 1. **Patterns** adalah pola pembayaran Tier 2. Setiap foundation punya tabel token. Setiap komponen Tier 1 punya matriks varian: anatomi, varian (nama enum yang ada dan yang **New**), ukuran, state, token per bagian, kapan dipakai, aturan konten, aksesibilitas, dan celah terhadap kode di `8a78eb1`.

Keputusan utama:

- `PaymentType` dijadikan API tipografi publik (disetujui pemilik, Q6).
- Tidak ada widget `PaymentText`.
- Button tetap satu tinggi (48 dp). "Ukuran" menjadi perilaku lebar: `fill` atau `hug`.
- Tombol ikon diekstrak menjadi `PaymentIconButton`. Ada 10 salinan dengan tiga perlakuan berbeda.
- Keluarga List memakai satu anatomi baris. Kelas tetap terpisah menurut semantik (aksi, pilihan, toggle, properti).
- Aturan tata kelola varian: varian baru butuh dua pemakaian nyata yang berbeda makna.

Aturan penerimaan tetap berlaku. Komponen baru hanya hasil ekstraksi atau kebutuhan pola Tier 2. "Stripe punya" bukan bukti.

## 0. Branches and evidence

| Short name | Ref | Contents |
| --- | --- | --- |
| `main` | `f74b882` | Released 0.1.0, plus this PRD (PR #3, merged). |
| `#1` | `docs/component-catalog` @ `ea78224`, open PR #1 | Per-component docs catalog. Public `PaymentCheckbox`, `PaymentRadio`, `PaymentSwitch`, `PaymentTabs`, `PaymentTooltip`, `PaymentSpinner`, `PaymentDivider`. Adds `PaymentButtonVariant.destructive`. |
| `#4` | `feat/charts-kyc-capture` @ `8a78eb1`, open PR #4, base `docs/component-catalog` (stacked on #1) | `PaymentLineChart`, `PaymentBarChart`, `PaymentMeterChart`, `PaymentSparkline`, `ChartModule`, `MoneyFormat.compact`, `showCaptureSourceSheet`, `KycCaptureGuide`, `CaptureFrameOverlay`, the `patterns/chart-layout` docs page, and inspected native catalog screenshots. |

**How evidence is cited.**

- Every `file:line` refers to commit `8a78eb1`, read with `git show 8a78eb1:<path>`. File names are under `lib/src/` unless a path is given.
- Between `5550bfa` (revision 1) and `8a78eb1`, `lib` changed in three files:
  - `charts.dart` lines after ~312 moved by +13.
  - `capture_widgets.dart` lines after ~91 moved.
  - `primitives.dart` reordered its imports.
- Every other line cited in revision 1 is unchanged.

## 1. Problem and goal

**Owner requests.**

- 31 Oct 2026: "a reusable component foundation, Button, Chart and so on, like Stripe, where each single component is a foundation with its own level and page."
- On revision 1: "That's good, but it needs more: Button and its variants; Font and its variants; List and its variants — like we're making a design system. Update the PRD."

**The tension.** PRD.md §2 assumes that "five to ten components used in a full flow" make a stronger portfolio than "a big catalog without real behavior". It also names the biggest risk: "the library becomes only a screenshot gallery".

A design system meets the owner's request without that risk only if every variant traces to code or to a pattern's need. A variant table copied from Stripe would create the risk.

**The evidence.** The kit already has a design system in code. It is partly undocumented, partly internal, and partly duplicated:

- **Tokens exist but are only half public.**
  - Color, spacing and radius live on `PaymentTheme` (`foundation/payment_theme.dart:29`). Motion lives on `PaymentMotion` (`foundation/payment_motion.dart:10`). Both are exported.
  - The type scale `PaymentType` (`foundation/payment_type.dart:14`) is internal. Hosts cannot use the kit's "Font and its variants".
- **Variants exist but are not stated as closed sets.**
  - `PaymentButtonVariant` has four values (`primitives.dart:240`).
  - `StatusTone` has five (`payment_theme.dart:7`), and `PromoLayout` has two (`promo.dart:57`).
  - Row variants are expressed through slots (`ActionTile.trailing`, `destructive`, `disabledReason`, `interaction.dart:22`), but no page names them as a family.
- **Public controls the kit's own patterns bypass.**
  - Raw `CheckboxListTile` at `verification_widgets.dart:111` and `checkout.dart:492`.
  - A private `_Radio` (`checkout.dart:393`).
  - A raw `CircularProgressIndicator` (`video.dart:299`).
  - 11 raw `Divider(… theme.outline)` calls, one of them inside the Tier 1 `ActionTileGroup` (`interaction.dart:157`).
  - The confirm dialog builds its own `TextButton`/`FilledButton` instead of `PaymentButton` (`interaction.dart:290-314`). Neither has the focus ring.
- **Duplicates that already drift.**
  - Four text-field decorations (§5 Forms).
  - Two copy controls with different feedback.
  - Five inline text actions.
  - **Ten `IconButton`s with three treatments.** This was missed in revision 1:
    - Six have the focus ring, the 0.96 press scale and a 48 dp target: `sheets.dart:66`, `promo.dart:159`, `video.dart:462, 488`, `payment_status.dart:175`, `payment_receipt.dart:136`.
    - One has the ring only: `interaction.dart:219`.
    - Three have neither: `transactions.dart:340`, `payment_extras.dart:512`, `navigation.dart:307`.

**Goal.**

- Three layers, each with one docs section:
  - **Foundations:** token tables and the public API that exposes them.
  - **Components:** Tier 1, each with a variant matrix and a specimen screenshot.
  - **Patterns:** Tier 2, composed only from Tier 1.
- Every variant name in the docs traces to code. Proposed ones are marked **New** until they ship.
- Every Stripe entry the kit does not ship is listed under "Not in the kit" with the reason and the Flutter alternative.

**PRD.md §16a amendment** (approved 31 Oct 2026, added to `PRD.md`):

| Kelompok | Komponen | Batas |
| --- | --- | --- |
| Design system (Fondasi + Tier 1) | Token publik `PaymentTheme`, `PaymentType`, `PaymentMotion`; komponen baru `PaymentTextField` (termasuk `.search`), `PaymentIconButton`, `PaymentCopyButton`, `PaymentLink`; pola pembayaran wajib memakai komponen Tier 1 | Varian baru hanya dengan dua pemakaian nyata yang berbeda makna; komponen baru hanya hasil ekstraksi atau kebutuhan pola Tier 2; tidak ada field PIN/OTP/rahasia; clipboard, tautan, kamera dijalankan host lewat callback |

## 2. Definitions

### Layers

| Layer | What it is | Public surface | Docs section |
| --- | --- | --- | --- |
| **Foundations** | Tokens and rules with no widget of their own | `PaymentTheme`, `ToneColors`, `StatusTone`, `PaymentMotion`, `MoneyFormat`, `Money`; `PaymentType` after D15 | `Foundations` |
| **Components** | Tier 1 | §6 matrices | `Components` |
| **Patterns** | Tier 2 | §7 | `Patterns` |

The layer rule:

- Components read only Foundations.
- Patterns read Foundations and render Components.
- Nothing reads a raw value that a token covers.

### Tier 1: foundation component

A single-purpose building block. Its parameters use only:

- Flutter types.
- Foundation types: `Money`, `StatusTone`, `AmountParseResult`, `HostError`.
- Its own small types: `ChartPoint`, `PaymentNavItem`, `PaymentVideoController`.

A Tier 1 component may be money-aware, such as `AmountText`, `AmountInput` or `CountdownText`.

### Tier 2: payment pattern

A widget that meets either of these:

- It takes a host verdict, status or content type defined in `lib/src/payment`, `verification`, `receipt` or `promo`. Examples: `PaymentQuote`, `PaymentAttempt`, `BalanceState`, `PromoCodeStatus`, `PromoContent`, `CaptureKind`, `DocumentSlotState`, `TransactionRecord`, and `MerchantHeader.verified`.
- It enforces a rule from PRD §8, §11 or §16a "Batas". Examples: consent starts unchecked, fees are never folded, promotions are always labeled.

A Tier 2 widget may only render interactive controls through Tier 1 components. It must not keep private copies of them.

### Admission rule for a new Tier 1 component

A new Tier 1 component is admitted only if one of these is true:

- **(a) Extract.** A private or duplicated implementation already exists in `lib/`. Either it has two or more call sites, or a public Tier 2 API currently forces hosts to reimplement it.
- **(b) Needed by a pattern.** A Tier 2 pattern in the example app needs it. The need is shown by a concrete screen, field or scenario ID from PRD §9.

Anything else is refused and listed under "Not in the kit" with the Flutter alternative. "Stripe has it" is not evidence.

The **Adopt** status covers existing public Tier 1 components that a Tier 2 pattern, or another Tier 1 component, bypasses. Adoption work comes before any new component.

New variants follow §9, Variant governance.

### The Button bar (Tier 1 quality checklist)

Each item is testable. "Widget test" means a test in `test/`, run per file with `flutter test --no-pub`.

| # | Requirement | How it is checked |
| --- | --- | --- |
| B1 | Exported from `lib/flutter_ui_payment.dart`; dartdoc on the class and on every parameter | `flutter analyze` (`public_member_api_docs` where enabled); appears in `website/src/data/api.json` after `pnpm gen:api` |
| B2 | Color, radius, spacing, type and motion come only from `PaymentTheme`, `PaymentType` and `PaymentMotion`. No `Color(0x…)` or `Colors.*` literals, except a documented scrim like the camera overlay. No literal spacing outside the §3.3 multiples. | Review grep on the new file; renders under both example brands: Hairline (`DemoBrand.ruangBayar`) and Contrast (`DemoBrand.lumen`) (`example/lib/themes.dart:5`) |
| B3 | Light and dark | Widget test pumps both; specimen screenshot pair (§10) |
| B4 | 200% text at 320 dp width: no overflow, nothing clipped, primary action reachable | Widget test with `TextScaler.linear(2)` and no `FlutterError`; `_200` specimen when text-heavy |
| B5 | Every interactive target is at least 48×48 dp | Widget test on `tester.getSize` (pattern in `test/controls_test.dart:80`) |
| B6 | Contrast: text ≥ 4.5:1; control edges and state marks ≥ 3:1, light and dark | `contrast()` helper (`test/controls_test.dart:32`) on resolved token pairs |
| B7 | Semantics: one node per control, with label, role and state (checked, selected, enabled, busy, value). State is never carried by color alone | Widget test with `matchesSemantics` or `getSemantics` |
| B8 | Keyboard: reachable with Tab, activates with Enter or Space. Focus shows as the `PaymentFocusRing` on controls, or as the 2 px `accent` border on text inputs, never both | Widget test in the style of `test/focus_press_test.dart` |
| B9 | Reduced motion: no animation runs when `MediaQuery.disableAnimations` is true | Widget test |
| B10 | Built-in strings live in `PaymentLocalizations`/`KitStrings` in en and id, and are overridable by parameter | Both locales pumped; long Indonesian strings at 200% |
| B11 | Host ownership: no network, no clipboard or platform-channel call, no URL launching, no timers that poll, no secret input | `grep -rn "Clipboard\|dart:io\|http\|launch" lib` stays empty; `pubspec.yaml` dependencies stay `flutter` only |
| B12 | Docs page in catalog order: purpose, specimen, usage, **variants (closed set) and which variant when**, states, do/don't pairs, content guidelines, accessibility, Props table, See also | `pnpm build`, `pnpm check:links`, `pnpm check:snippets` |
| B13 | Used by at least one Tier 2 pattern, or recorded as owner-approved without one | Inventory, §5 |

## 3. Foundations

Each foundation lists:

- Its tokens: the name, the value or rule, where it is used, and do and don't.
- The public API that exposes it.
- The gap against today's code.

Light and dark values are the Hairline brand (`example/lib/themes.dart:10-37`). Hosts set their own.

### 3.0 Token layer rule

- Components use semantic tokens, never raw values. The allowed raw exceptions are the camera and video scrims (`Colors.black54`, `Colors.white` in `capture_widgets.dart:116, 158`, `video.dart:282-365`) and the side-sheet barrier (`sheets.dart:192`). Each one is documented on the Color page.
- A brand is a token change through `PaymentTheme.copyWith` (`payment_theme.dart:184`), never a variant (§9).

Which text color:

```
Is the control disabled?            → disabled
Is it a status word or status icon? → tone(t).foreground
Is it on an accent fill?            → onAccent
Is it a label, caption or muted icon? → textSecondary
Default                             → textPrimary
```

Which line:

```
Is the line how someone finds a control (input, secondary button, unchecked box)? → border (≥ 3:1)
Is it the selected or focused edge?  → accent (selected) / textPrimary ring (focus, §3.8)
Default (separates content only)     → outline (may be < 3:1)
```

### 3.1 Color

| Token | Light | Dark | Rule / derivation | Used for | Don't |
| --- | --- | --- | --- | --- | --- |
| `surface` | #FFFFFF | #131417 | `scheme.surface` | Page, sheets, dialogs, flat sections | Tint sections; they sit flat on it |
| `surfaceMuted` | #F5F6F8 | #1C1E23 | `scheme.surfaceContainerHighest` | Disabled fills, skeleton blocks, selected nav item | Use as a card background for normal content |
| `outline` | #E3E6EC | #2C2E35 | `scheme.outlineVariant` (`payment_theme.dart:90-92`) | Dividers, method-list edge, action-bar top, sheet footer | Use for a control edge |
| `border` | #868C9A | #7E838E | Default `textSecondary` lerped 25% to `surface` (`:125`) | Inputs, secondary buttons, unchecked boxes, switch track | Go below 3:1 on `surface` |
| `textPrimary` | #1A1F36 | #ECEDF0 | `scheme.onSurface` | Titles, values, body; also the focus ring and tooltip fill | Use for a muted label |
| `textSecondary` | #5E6678 | #A2A8B5 | `scheme.onSurfaceVariant` | Labels, captions, icons beside text, unselected radio | Use for body paragraphs |
| `disabled` | #A6ABB5 | #62656E | Default `textSecondary` lerped 45% to `surface` (`:129`) | Disabled label, icon, mark | Use opacity instead |
| `accent` | #1A1F36 | #ECEDF0 | `scheme.primary` | Primary fill, selected radio/tab/checkbox, link text, focused input border | Use for status; use for focus ring |
| `onAccent` | #FFFFFF | #131417 | `scheme.onPrimary` | Text and icons on `accent` | Fall below 4.5:1 on `accent` |
| `neutral` | scheme | scheme | `onSurfaceVariant` / `surfaceContainerHigh` | Neutral badge, toast, canceled/expired status | — |
| `info` / `success` / `warning` / `danger` `.foreground` | #2A55A8 / #1D6B45 / #8A5300 / #A8231C | #93B2F0 / #6FC79B / #E3A64C / #F2897F | Fixed (`:78-81`); ≥ 5.8:1 on white, ≥ 7.6:1 on #131417 | Status icon and words; `danger.foreground` is the destructive fill | Use a tone as a chart category (decisions.md, charts) |
| `….container` | computed | computed | foreground lerped 90% (light) / 84% (dark) to `surface` (`:62`) | Badge and banner fill | Use without the matching foreground and icon |

- **Public API:** `PaymentTheme.of(context)`, `.tone(StatusTone)` (`:146`), `ToneColors`, `StatusTone`, `copyWith`, `fromColorScheme`.
- **Brand override:** `PaymentTheme.fromColorScheme(scheme).copyWith(accent: …, border: …)`. Unset `border` and `disabled` re-derive from a later `textSecondary` or `surface` (`:222-226`).
- **Tone families:** a tone is a pair, `foreground` and `container`.
  - There is **no tone border token**, and none is proposed. No kit component draws a tone-colored edge. Banners and badges are tinted fills without borders.
  - A future bordered tone surface needs §9's two-use test first.

**Gaps.**

- Neutral and info share `Icons.info_outline` in both `NoticeBanner` (`primitives.dart:638-644`) and the toast (`interaction.dart:334-339`). The words still differ, so this is accepted. The duplicated map is a §3.6 item.
- The toast's background is not a kit token. It uses Material's `SnackBar` defaults (`interaction.dart:342`), which fails B2. See D22.

### 3.2 Typography ("Font and its variants")

The scale is `PaymentType` (`payment_type.dart:14`). It has 9 roles on 7 sizes and 2 weights (400 and 600), with explicit leading and zero tracking except `display`. The family is always the host's: every role copies `textTheme.bodyMedium.fontFamily` (`:29, 42-43`).

| Role | Size / line | Weight | Tracking | Color default | Use for | Don't |
| --- | --- | --- | --- | --- | --- | --- |
| `display` | 32 / 36 | `amountWeight` (600) | −0.32 | `textPrimary` | The one display amount per screen (`AmountText(emphasis: true)`) | Two per screen |
| `amountLarge` | 20 / 28 | `amountWeight` | 0 | `textPrimary` | Action-bar total, balance, VA number, entered amount, chart headline | Row amounts |
| `title` | 17 / 24 | 600 | 0 | `textPrimary` | Sheet, dialog, app-bar titles | Section titles |
| `heading` | 15 / 20 | 600 | 0 | `textPrimary` | Section and status titles, Total row label, button labels, list-item titles in history | Paragraphs |
| `body` | 15 / 22 | 400 | 0 | `textPrimary` | Paragraphs; use `bodyFor(context)` (1.3 leading above 1.5×) | Single-line rows |
| `label` | 15 / 20 | 400 | 0 | `textPrimary` | Row text, labels, values, tab labels, row amounts | Multi-line paragraphs |
| `caption` | 13 / 18 | 400 | 0 | `textSecondary` | Supporting lines, helper text, meta lines, legends, tooltip | Anything the user must read to act |
| `tag` | 12 / 16 | 600 | 0 | none (the tone sets it) | Badges, copy feedback | Any text over three words |
| `input` | 16 / 24 | 400 | 0 | `textPrimary` | Text inside fields (16 avoids iOS zoom) | Labels around the field |

**Modifiers** (`payment_type.dart:102-112`). Nothing else exists.

- `.tabular` adds tabular figures. Use it for every number that changes or aligns: amounts, countdown, axis labels.
- `.reference(theme)` adds tabular figures in `referenceFontFamily` (Menlo → `monospace` → Courier, `payment_theme.dart:133-138`). Use it for VA numbers, transaction and attempt IDs, and promo codes.
- **Weight.** There is no weight modifier, and none is proposed. Emphasis comes from choosing `heading` over `label`.
  - Today three Total rows do it with a literal `TextStyle(fontWeight: FontWeight.w600)`: `payment_status.dart:82`, `checkout.dart:212`, `payment_receipt.dart:118`.
  - D24 replaces those with an `AmountText` variant.

**Brand knobs** on `PaymentTheme`: the host font (via `textTheme`), `amountWeight`, `amountFontFamily`, `referenceFontFamily`. The Contrast brand sets `amountWeight: FontWeight.w700` (`themes.dart:61`).

**Rules.**

- **Minimum size.** 12 (`tag`). No kit text is smaller. Chart axis labels use `caption.tabular` (13).
- **200% text.**
  - `PaymentType.isLarge(context)` is true above 1.5× (`:66`). Rows then wrap the value under the label (`InfoRow`, `primitives.dart:186-200`), and paragraphs use 1.3 leading.
  - Amounts of 20 px and up are clamped at 1.6× and then scale down rather than clip (`primitives.dart:38-40, 44-46`).
  - Icons beside text grow up to 1.6× and center on the first line of a 15/20 role. That calculation, `scale(15) * 20 / 15`, is copied in 8 places (`interaction.dart:61, 599`, `primitives.dart:575, 722`, `controls.dart:262`, `navigation.dart:139`, `verification_widgets.dart:48`, `payment_extras.dart:178`). D15 makes it one helper.
- **Indonesian length.** Indonesian strings run longer than English, for example "Give consent to continue." against "Berikan persetujuan untuk melanjutkan." (`payment_localizations.dart:338-339`).
  - Rules: put the key words first; let titles wrap rather than truncate; reserve `maxLines` for list titles (2) and meta lines (2), as in `transactions.dart:125-130, 186-194`.
  - Checked by B4 and B10, not by a stated ratio.
- **One display amount per screen** (decisions.md, Hairline table).

**Public API today.** Only `PaymentTheme.amountStyle(context, {large})` (`payment_theme.dart:168`) is public. `PaymentType` is internal, and decisions.md says it "stays internal until owner approves".

**Gaps.**

- Hosts cannot use the scale. The docs page tells them to copy sizes by hand (`foundations/typography.mdx`, "The roles are internal").
- `amountStyle(large: false)` returns 15/20 at `amountWeight` (w600). But row amounts in `AmountText` use `label`, which is w400 (`primitives.dart:30-32`). The public helper contradicts the "only totals are heavy" rule, and no call site uses `large: false`.

**Decision D15 (approved, Q6).** Export `PaymentType` as the type foundation.

- **API:**
  - `PaymentType.of(context)` with the nine roles, plus `isLarge` and `bodyFor`.
  - **New** `PaymentType.firstLineHeight(context)`. It replaces the 8 copies of the first-line calculation.
  - **New** instance methods `type.tabular(TextStyle)` and `type.reference(TextStyle)`.
  - The export is `export 'src/foundation/payment_type.dart' show PaymentType;`, so the `PaymentTypeStyle` extension stays internal.
- **Why `PaymentType.of` and not `PaymentTheme.textStyles(context)`.** The second name is the one recorded in `foundation-plan.md:305`.
  - `PaymentMotion.of(context)` is already public with the same shape: a private constructor and an `of` factory (`payment_motion.dart:11-14`).
  - The class already exists with this API, so exporting it changes no call site.
  - `textStyles(context)` would still have to return a public role type, so it would expose the same class under a second name.
- **Why not export the extension.** A public `TextStyle.tabular` getter collides with any host extension of the same name wherever both are imported.
- **Deprecate `amountStyle(large:)`.** `amountStyle(context)` stays as an alias of `display`.
- **If the owner keeps it internal:** the token table above still ships on the Typography page as the documented contract, and the gap stays open.

### 3.3 Spacing

`PaymentTheme.spacing` (default 8) is used only in these multiples. The role names are already in dartdoc (`payment_theme.dart:105-113`).

| Role | Value | Expression | Use for | Don't |
| --- | --- | --- | --- | --- |
| inline | 4 | `spacing * 0.5` | Label → caption, title → meta, icon → badge text | Between rows |
| related | 8 | `spacing` | `InfoRow` vertical padding, between stacked buttons, section padding | — |
| block | 12 | `spacing * 1.5` | Row vertical padding (`ActionTile`, controls), icon → row text, notice padding, band → title | — |
| group | 16 | `spacing * 2` | Screen and sheet gutter, label ↔ value gap, sheet footer inset | A gutter other than 16 at any width |
| section | 24 | `spacing * 3` | Content → primary action, ruled section gap (divider in the middle) | — |
| major | 32 | `spacing * 4` | Reserved for `StateMessage` padding by the dartdoc | — |

**Gaps.**

- `StateMessage` uses `spacing * 2`, not 4 (`interaction.dart:605`). Either the dartdoc or the code is wrong, so Phase 1 aligns the dartdoc to the code (16).
- Charts use literal 16, 8, 4 and 72 (`charts.dart:301, 313, 427, 443`), which fails B2. That is Phase 2.
- No new public spacing API is proposed (D26). The multiples table is the contract. A review grep for numeric `EdgeInsets`, `SizedBox(width|height: <number>)` and `spacing: <number>` in `lib/src` enforces it.

### 3.4 Radius

Derived from `PaymentTheme.radius` (default 8; `payment_theme.dart:154-163`).

| Getter | Value at 8 | Use for | Don't |
| --- | --- | --- | --- |
| `tagBorderRadius` | 4 | Badges, tags, skeleton blocks | Buttons |
| `controlBorderRadius` | 6 | Buttons, inputs, notices, menus, tooltip, toast | Sheets |
| `borderRadius` | 8 | Selectable boxes (method list), the promo `card` layout | Nested inside another 8 box |
| `sheetBorderRadius` | 12 | Top of bottom sheets, dialogs | Inline content |
| circle (24) | fixed | Focus ring of 48 dp icon buttons | — |
| band (3) / meter bar (2) | fixed | `StatusBand` (`primitives.dart:775`), `BalanceCard` limit bar | — |

Nested radii are concentric. The inner radius is smaller.

**Gap.** The Contrast brand's "tighter corners everywhere" comment (`themes.dart:40`) is not true. It sets `radius: 8`, the default (`:60`). Fix the comment or set 4, as a Phase 1 example fix.

### 3.5 Surfaces and elevation

The kit is flat. Edges are hairlines, not shadows.

| Surface | Recipe | Where | Don't |
| --- | --- | --- | --- |
| Flat (default) | On `surface`, no box | `PaymentSection` (`primitives.dart:647-650`), rows, lists | Box a section; it nests inside host cards |
| Ruled | `outline` 1 px top or bottom | `ExpandableSection`, `PaymentTabs`, action bar, sheet footer | Use `border` |
| Bordered box | `outline` 1 px + `borderRadius` 8 | Method list, `PromoCard` card layout (`promo.dart:231-234`) | Use for non-selectable content |
| Tinted | `tone.container` fill, no edge | `NoticeBanner`, `StatusBadge` | Use for the normal path (decisions.md: "tinted boxes are for problems") |
| Muted | `surfaceMuted` fill | Disabled fill, skeleton, selected nav item | — |
| Floating | `surface` + `outline` edge + elevation 2 | `ActionMenu` only (`interaction.dart:211`) | Add a shadow anywhere else |
| Overlay | `surface`, elevation 0, top radius 12, scrim | Bottom sheet (`sheets.dart:163`), side sheet with `Colors.black54` barrier (`:192`), dialog | Tint the surface (`surfaceTintColor` is transparent everywhere) |

### 3.6 Iconography

Icons are Material `Icons` from the Flutter SDK, with no icon package.

| Size | Use for | Color |
| --- | --- | --- |
| 20 (scales with text up to 1.6×, first-line centered) | Default beside 15/20 text: row leading, button icon, banner, status header, state message, chevron, close, copy | `textSecondary`; tone `foreground` for status; `accent` only for an icon that is the action itself (copy) |
| 14 | Inside a badge (`primitives.dart:531`) | Tone `foreground` |
| 32 / 36 | Video overlay only (`video.dart:281, 325`) | `Colors.white` on scrim |
| 48 | `PrivacyMask` only (`primitives.dart:844`) | `textSecondary` |

**Semantic set.** Tone icons are used by `NoticeBanner`, the toast and the **New** `StatusBadge` default (D20):

| Tone | Icon |
| --- | --- |
| success | `check_circle_outline` |
| warning | `warning_amber_rounded` |
| danger | `error_outline` |
| info, neutral | `info_outline` |

**Fixed meanings:**

| Icon | Meaning |
| --- | --- |
| `chevron_right`/`chevron_left` (RTL) | Opens something |
| `open_in_new` | Leaves the app |
| `close` | Dismiss UI only |
| `copy_rounded` → `check` | Copy, then copied |
| `cloud_off_outlined` | Load failed |
| `search_off` | No matches |
| `hourglass_top` | Busy under reduced motion |
| `lock_outline` | Hidden content |

**Rules.**

- An icon never carries meaning alone. It always sits beside words, or has a tooltip on an icon button.
- One family: outlined. The exceptions `copy_rounded` and `warning_amber_rounded` are audited in Phase 1, and either replaced or recorded.

**Gaps.**

- The tone→icon map is written twice (`primitives.dart:638`, `interaction.dart:334`). Phase 1 makes it one internal helper.
- `StatusBadge`'s 14 px icon does not scale with text, though its label does. Phase 2 clamps it at 1.6× like other icons.
- Payment-status icons are mapped privately per pattern (`transactions.dart:80-95`, `_StatusLook` in `payment_status.dart:210`). That stays Tier 2, but it is listed on the Iconography page.

### 3.7 Motion

`PaymentMotion` (`payment_motion.dart`, public). Motion is feedback only.

| Token | Value | Use for | Don't |
| --- | --- | --- | --- |
| `press` | 100 ms | Press scale, color on press | — |
| `quick` | 150 ms | Selection, border/color change, button busy cross-fade, chevron rotation | — |
| `enter` / `exit` | 220 / 150 ms | Content and status swaps, disclosure size | Exits slower than enters |
| `sheetEnter` / `sheetExit` | 280 / 200 ms | Bottom and side sheets | — |
| `easeOut` | `Cubic(0.23, 1, 0.32, 1)` | Everything that enters or responds | — |
| `easeInOut` | `Cubic(0.77, 0, 0.175, 1)` | On-screen size or position change | — |
| `drawer` | `Cubic(0.32, 0.72, 0, 1)` | Sheets | — |
| `pressedScale` | 0.96 | Compact controls only (§3.8) | Full-width buttons, rows |
| `fadeScale`, `fadeRise`, `topLayout` | from 0.95 / 8 px rise | Swaps; `topLayout` keeps leaving widgets untappable | Animate from nothing |

**Reduced motion** (`MediaQuery.disableAnimations`): every duration is 0 and the scale is 1. The spinner becomes a still hourglass, and video does not autoplay. There is no motion for navigation selection, menus or drawers (decisions.md).

### 3.8 Focus and press

| Token / rule | Value | Source |
| --- | --- | --- |
| Focus ring | 2 px stroke, 2 px outside the control, radius +3, in `textPrimary` (white on pictures), keyboard highlight mode only | `focus_ring.dart:6-12, 101-110` |
| Text input focus | 2 px `accent` border, never also the ring (B8) | D1 |
| Press, compact controls (≤ 48 dp wide icon buttons, links, tabs) | `PaymentPressScale` → 0.96 over `press` | `focus_ring.dart:118-162`, `controls.dart:398` |
| Press, full-width buttons and rows | Material pressed layer, no scale | `primitives.dart:423-426` |
| Hover/focus fill | Removed by `PaymentFocusRing.withoutFocusFill`; pressed and hovered layers are kept | `focus_ring.dart:32-44` |
| Clearance | ≥ 4 px between a focusable control and any clipping ancestor | `focus_ring.dart:11-12`, `PaymentTabs` side clip `controls.dart:353-361` |

`PaymentFocusRing` and `PaymentPressScale` stay internal (Q3).

### 3.9 Money formatting

`MoneyFormat` (`money.dart:100`). It has `id` and `en` separators only.

| Function | Output | Use for | Don't |
| --- | --- | --- | --- |
| `format(money, {withSymbol})` (`:109`) | `Rp102.500` / `$1,025.00` | Every displayed amount | Format by hand |
| `spoken(money)` (`:171`) | Words for screen readers | `AmountText` semantics, chart summaries | Show it |
| `compact(money)` (`:133`) | `1,2 jt` / `1.2M` (NBSP) | **Chart axes only** (decisions.md, charts) | Totals, buttons, confirmations |
| `AmountParseResult` / `AmountIssue` (`:263-276`) | Strict parse | `AmountInput` | Accept floats |

## 4. Components: how to read the matrices

Each Tier 1 entry gives the following, in this order:

- **Use / not.** When to use it, and the alternative when not.
- **Anatomy.** The named parts.
- **Variants.** The closed set. An unlisted value is a bug. **New** marks proposed values.
- **Sizes.**
- **States.**
- **Tokens per part.**
- **Content.**
- **A11y.**
- **Gap → API change.**

The states vocabulary is: default, hovered, pressed, focused, disabled (with reason), busy, error, selected. Each entry lists only the states that apply. Depth follows the owner's request: Button, Text and List are specified in full, and the rest compactly.

## 5. Inventory: Stripe Apps catalog → kit

Status values:

- **Have:** public, meets or is close to the Button bar.
- **Adopt:** public, but a Tier 2 pattern or another Tier 1 component bypasses it.
- **Extract:** private or duplicated today.
- **In progress:** on PR #4.
- **Refuse:** not in the kit.
- **Internal:** exists but is deliberately not exported.

### Views and layout

| Stripe | Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- | --- |
| ContextView, FullPageView, SettingsView | none | Refuse | App shells; the host owns `Scaffold` and routing (PRD §2: no router). Shell need covered by `AdaptiveNavShell` (`navigation.dart:244`) | Not in the kit |
| OnboardingView | none | Refuse | Kit onboarding is Tier 2 `VerificationIntro` (`verification_widgets.dart:16`) | Not in the kit → Verification |
| SignInView | none | Refuse | The kit never receives credentials (PRD §4, §7, §11) | Not in the kit |
| Box | none | Refuse | Flutter `Container`/`Padding`/`DecoratedBox` with tokens | Not in the kit |
| DetailPage, OverviewPage | none | Refuse | Page templates; content is Tier 2 (`TransactionDetail` `transactions.dart:378`, `PaymentStatusView`) | Not in the kit |
| Divider | `PaymentDivider` | Have + **Adopt** | `primitives.dart:487`; 11 raw dividers: `transactions.dart:318, 462`, `payment_status.dart:74, 418, 440`, `checkout.dart:206, 276`, `payment_receipt.dart:112, 159`, `interaction.dart:157` (Tier 1 `ActionTileGroup`), `video.dart:367` | `components/divider` |
| (kit) Section | `PaymentSection` | Have | `primitives.dart:650` | `components/section` |

### Navigation and actions

| Stripe | Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- | --- |
| Button | `PaymentButton` (primary, secondary, quiet, destructive) | Have; **New** width (D17) | `primitives.dart:240, 262` | `components/button` |
| (Button with icon only) | **New** `PaymentIconButton` | **Extract** (D18) | 10 `IconButton` sites, 3 treatments (§1) | new `components/icon-button` |
| ButtonGroup | none | Refuse (D6) | `PaymentActionBar` is a total plus one action (`payment_extras.dart:18`). The real groups differ: a domain-ordered stack (`payment_status.dart:400`), a `Wrap` (`primitives.dart:626`), a host `List<Widget>` (`transactions.dart:382`) | Rules on the Button page |
| Link | **New** `PaymentLink` | **Extract** (D11) | Five private `TextButton`s: `verification_widgets.dart:100` (no focus ring), `:537`, `promo.dart:104, 210`, `video.dart:386` (no focus ring) | new `components/link` |
| Menu | `ActionMenu` | Have | `interaction.dart:188` | `components/action-menu` |
| Tabs | `PaymentTabs` | Have | `controls.dart:333` | `components/tabs` |
| (kit) Navigation shell | `AdaptiveNavShell`, `NavSidebar` | Have | `navigation.dart:49, 244` | `components/navigation` |
| (kit) Step indicator | `PaymentStepIndicator` | Have | `payment_extras.dart:260` | new `components/step-indicator` |

### Content

| Stripe | Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- | --- |
| Accordion | `ExpandableSection` | Have | `interaction.dart:365` | `components/expandable-section` |
| Badge | `StatusBadge` | Have; **New** default icon (D20) | `primitives.dart:503` | `components/status-badge` |
| Banner | `NoticeBanner` | Have | `primitives.dart:548` | `components/notice-banner` |
| Chip | none | Refuse (D8) | Pill chips replaced by text tabs (decisions.md); applied-promo tag is one private use (`payment_extras.dart:477-505`) | Not in the kit |
| Code | **New** `PaymentCopyButton` | **Extract** (D3) | `_CopyButton` `payment_status.dart:152`; inline `IconButton` `payment_receipt.dart:136` | new `components/copy-button` |
| DataTable, Table | none | Refuse | Row lists are `TransactionHistory` and `InfoRow` groups | Not in the kit |
| FocusView | `PaymentSheet`, `showPaymentSheet`, `showPaymentSideSheet` | Have | `sheets.dart:90, 145, 180` | `components/sheets` |
| Icon | none | Refuse | Flutter `Icon`; rules in §3.6 | Not in the kit → Foundations/Iconography |
| Img | none | Refuse (D9) | `PromoContent.media` is a host slot (`promo.dart:51`); `KycCaptureGuide`'s `Image` still has no `errorBuilder` (`capture_widgets.dart:260`) | Not in the kit |
| Inline | none | Refuse (D16) | Flutter `Text`/`Text.rich` with `PaymentType` roles | Not in the kit → Foundations/Typography |
| List | `ActionTile`, `ActionTileGroup` (+ selection rows, §6.3) | Have + **Adopt** (divider) | `interaction.dart:22, 145` | `components/list` (renamed from `action-tile`, D19) |
| PropertyList | `PaymentSection` + `InfoRow` | Have (D5) | `primitives.dart:141, 650` | `components/info-row` "Property list" section |
| Spinner | `PaymentSpinner` | Have + **Adopt** | `primitives.dart:445`; raw indicator `video.dart:299` | `components/spinner` |
| TaskList | none | Refuse (D7) | No per-item completion anywhere | Not in the kit |
| Toast | `showPaymentSnackBar` | Have; restyle (D22) | `interaction.dart:326` | `components/toast` |
| Tooltip | `PaymentTooltip` | Have (owner-approved, no Tier 2 use) | `controls.dart:450` | `components/tooltip` |
| (kit) Amount text | `AmountText` | Have; **New** variant (D24) | `primitives.dart:15` | `components/amount-text` |
| (kit) Info row | `InfoRow`, `MiddleEllipsisText` | Have | `primitives.dart:63, 141` | `components/info-row` |
| (kit) Countdown | `CountdownText` | Have | `primitives.dart:858` | `components/countdown` |
| (kit) Privacy mask | `PrivacyMask` | Have | `primitives.dart:825` | `components/privacy-mask` |
| (kit) Action bar | `PaymentActionBar` | Have | `payment_extras.dart:18` | new `components/action-bar` |
| (kit) Video | `PaymentVideoPlayer`, `PaymentVideoController` | Have | `video.dart:97` | `components/media` |

### Forms

| Stripe | Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- | --- |
| TextField | **New** `PaymentTextField` | **Extract** (D1) | Four copies: `checkout.dart:102-137` (`AmountInput`), `transactions.dart:330-360` (search), `payment_extras.dart:562-590` (promo), `verification_widgets.dart:234-282` (`IdentityForm`) | new `components/text-field` |
| SearchField | **New** `PaymentTextField.search` | **Extract** (D2) | `transactions.dart:330-360` | new `components/search-field` |
| CurrencyField | `AmountInput` | Have; rebuilt on `PaymentTextField` | `checkout.dart:19` | `components/amount-input` |
| Checkbox | `PaymentCheckbox` | Have + **Adopt** | `controls.dart:13`; raw `CheckboxListTile` `verification_widgets.dart:111`, `checkout.dart:492` | `components/checkbox` |
| Radio | `PaymentRadio` | Have + **Adopt** | `controls.dart:91`; private `_Radio` `checkout.dart:393` | `components/radio` |
| Switch | `PaymentSwitch` | Have (owner-approved, no Tier 2 use) | `controls.dart:162` | `components/switch` |
| DateField, DateRangePicker, Select, FormFieldGroup, TextArea | none | Refuse (D4, D13) | No field kinds (`verification_models.dart:64`), no date filter (`kit_strings.dart:219`), no free text | Not in the kit |

### Charts (PR #4)

| Stripe | Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- | --- |
| LineChart | `PaymentLineChart` | In progress | `charts.dart:18` | `components/line-chart` |
| BarChart | `PaymentBarChart` | In progress | `charts.dart:44` | `components/bar-chart` |
| Sparkline | `PaymentSparkline` | In progress | `charts.dart:68` | `components/sparkline` |
| MeterChart | `PaymentMeterChart` | In progress | `charts.dart:255` | `components/meter-chart` |
| (kit) Chart module | `ChartModule` | In progress | `charts.dart:349` | `patterns/chart-layout` |

### Feedback and overlays (kit-specific)

| Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- |
| `showPaymentConfirmDialog` | Have + **Adopt** (D23) | `interaction.dart:259`; own buttons `:290-314` | `components/dialog` |
| `StatusHeader`, `StatusBand` | Have | `primitives.dart:700, 761` | `components/status-header` |
| `LoadingSkeleton` | Have | `interaction.dart:498` | `components/loading-skeleton` |
| `StateMessage` | Have | `interaction.dart:573` | `components/state-message` |

### Internal foundations (not exported)

| Kit | Status | Evidence |
| --- | --- | --- |
| `PaymentType` | Internal → public, approved (D15, Q6) | `foundation/payment_type.dart`; not in `lib/flutter_ui_payment.dart` |
| `PaymentFocusRing`, `PaymentPressScale` | Internal (Q3) | `foundation/focus_ring.dart`, not exported |
| `ChartPainter`, `MeterPainter`, hatch painter | Internal | `charts/chart_painters.dart:9, 257`, `foundation/hatch.dart` |

### Counts (46 Stripe entries)

| Status | Count | Entries |
| --- | --- | --- |
| Have | 17 | Divider, Button, Menu, Tabs, Accordion, Badge, Banner, FocusView, List, PropertyList, Spinner, Toast, Tooltip, CurrencyField, Checkbox, Radio, Switch |
| ...of which Adopt work | 5 | Divider, Spinner, Checkbox, Radio, List (its divider) |
| Extract | 4 | Link, Code (as copy button), TextField, SearchField |
| Build | 0 | none |
| In progress | 4 | LineChart, BarChart, Sparkline, MeterChart |
| Refuse | 21 | 5 Views, Box, DetailPage, OverviewPage, ButtonGroup, Chip, DataTable, Icon, Img, Inline, Table, TaskList, DateField, DateRangePicker, Select, FormFieldGroup, TextArea |

Kit-specific work with no Stripe entry:

- **Extract:** `PaymentIconButton`.
- **Adopt:** the dialog adopts `PaymentButton`.
- **Have:** `PaymentSection`, `AdaptiveNavShell`/`NavSidebar`, `PaymentStepIndicator`, `AmountText`, `InfoRow`/`MiddleEllipsisText`, `CountdownText`, `PrivacyMask`, `PaymentActionBar`, `PaymentVideoPlayer`, `ChartModule`, `showPaymentConfirmDialog`, `StatusHeader`/`StatusBand`, `LoadingSkeleton`, `StateMessage`.

## 6. Component specs

### 6.1 Button family

The family has three members, each with one press rule:

| Member | Shape | Press | Status |
| --- | --- | --- | --- |
| `PaymentButton` | Labeled, 48 dp tall | No scale (pressed layer) | Have |
| **New** `PaymentIconButton` | 48×48 icon-only | 0.96 scale | Extract |
| **New** `PaymentLink` | Inline text | 0.96 scale | Extract |

Which one:

```
Is it the action that ends or advances the screen, or an alternative to it? → PaymentButton
Is it a single icon whose meaning is common (close, copy, more, clear, play)? → PaymentIconButton (tooltip required)
Is it inline with text, or opens something secondary (policy, "Edit", "Why this ad")? → PaymentLink
Is it a row in a list?                                                      → ActionTile (§6.3)
```

#### PaymentButton (`primitives.dart:262`)

**Use / not.**

- Use it for actions: pay, continue, retry, check status, share, remove.
- Not for navigation inside text. That is `PaymentLink`.
- Not for icon-only actions. That is `PaymentIconButton`.
- Not for list rows. That is `ActionTile`.

**Anatomy.**

| Part | Detail |
| --- | --- |
| Container | Fill, outline or none |
| Leading icon | Optional, 20 px, spacing 8 |
| Label | `heading` 15/20 w600, centered, wraps at large text |
| Busy indicator | `PaymentSpinner` 20 in the label color. The label keeps its space (`:326-347`) |
| Focus ring | At the control radius |

**Variants** (`PaymentButtonVariant`, `:240-255`). These four, and nothing else exists:

| Variant | Container | Label / icon | Edge | Disabled | Use when | Not when |
| --- | --- | --- | --- | --- | --- | --- |
| `primary` (default) | `accent` | `onAccent` | none | `surfaceMuted` fill, `disabled` label | The one action that advances the screen (Pay, Continue, Check status) | A second action in the same view |
| `secondary` | none | `accent` | 1 px `border` (`disabled` when disabled) | `surfaceMuted` fill, `disabled` label and edge | An alternative to the primary (Change method, Share receipt, Retry in `StateMessage`) | Low-stakes dismissals |
| `quiet` | none | `accent` | none | `disabled` label | Low emphasis (Not now, Cancel, Contact support) | The only action on a screen |
| `destructive` | `danger.foreground` | `surface` | none | `surfaceMuted` fill, `disabled` label | Cannot be undone, usually the confirm step after `showPaymentConfirmDialog` | The pay button; anything reversible |

Hierarchy:

```
Does it advance or complete the screen's job?                 → primary (one per view or sheet)
Does it destroy something that cannot be undone?              → destructive (label names the object)
Is it an equal alternative the user may need?                 → secondary
Default                                                       → quiet
```

**Sizes.**

- **Height:** one, 48 dp minimum (`:350`). There is no small/medium/large; D17 records why.
- **Width:** today the button always fills its parent (`SizedBox(width: double.infinity)`, `:430-433`).
  - Three call sites fight that. `PaymentActionBar` wraps it in `IntrinsicWidth` with min 112 and max 240 (`payment_extras.dart:120-127`). `StateMessage` caps it at `maxWidth: 280` (`interaction.dart:633-634`). The dialog avoids `PaymentButton` entirely.
  - **New** `width: PaymentButtonWidth.fill | PaymentButtonWidth.hug`, default `fill`. `hug` sizes the button to its label, with min width 112 and the 48 dp height. The label wraps rather than truncates.

**States.**

| State | Behavior | Source |
| --- | --- | --- |
| default | As the variant table | |
| hovered / pressed | Material state layer darkens the fill; **no scale at any width** | `:423-426` |
| focused | Neutral ring; Material focus fill removed | `:432`, `focus_ring.dart:32` |
| disabled | `onPressed: null`; every variant uses `disabled` | `:309, 361-415` |
| busy | `onPressed` returned a `Future` or `busy: true`. Further taps are ignored, the spinner shows, and the button is a live region whose value is `busyLabel` (default `working`) | `:287-302, 427-429` |

- The disabled reason is not part of the button. Put a caption under it, as `VerificationIntro` does (`verification_widgets.dart:131-135`).
- **Not added:** a `disabledReason` parameter. There is one call site, so it fails §9 rule 1. Revisit at a second use.
- **No error state.** Errors belong to a `NoticeBanner` or the field.

**Icon.**

- Leading only (`icon`, `:280, 319-322`). Use it when the icon adds meaning (delete, download), not on every button.
- **No trailing icon.** An external destination is a `PaymentLink(external: true)`.

**Groups** (D6, no class). Rules for the Button page:

- One `primary` per view or sheet.
- Stack vertically, full width, `spacing` (8) apart, in domain order: primary first, quiet last (`payment_status.dart:400-417`).
- `destructive` never sits next to `primary`. It appears alone or in a confirm dialog.
- In a dialog, use two `hug` buttons in a row: quiet cancel at the start, primary or destructive confirm at the end. They stack when they do not fit, because `AlertDialog` lays actions out in an `OverflowBar`.

**Content.**

- Verb + object, sentence case, no end punctuation: "Pay Rp102.500", "Remove card".
- Put the amount in the pay button, formatted with `MoneyFormat`.

**A11y.**

- B5: 48 dp. B7: button role, enabled, busy value. B8: the ring.
- Color is never the only signal: the destructive label must name what is destroyed.

**Gap → API change.**

- (1) **New** `PaymentButtonWidth`. The dialog uses it (D23). `PaymentActionBar` takes a host `action: Widget` (`payment_extras.dart:18-30`), so it cannot make that widget hug. The bar keeps its 112–240 constraint and `IntrinsicWidth` wrapper for compatibility, and its docs tell hosts to pass `width: PaymentButtonWidth.hug`.
- (2) **New** `bool autofocus = false`. The dialog needs it to keep focusing the safe choice first (`interaction.dart:291, 302`; decisions.md, "Destructive confirmations put initial focus on the safe choice").
- (3) `StateMessage` keeps `fill` inside its 280 cap.

#### PaymentIconButton (**New**, D18)

- **Use / not.**
  - Use for a single common action: close, dismiss, copy, more, clear, menu, play.
  - Not when the action needs words to be understood. Use `PaymentLink` or `PaymentButton` then.
- **Anatomy.** A 48×48 target; a 20 px icon (not scaled with text); a circular focus ring (radius 24); a required `tooltip`, which is also the semantic label.
- **Variants:** **New** `PaymentIconButtonVariant`. Nothing else exists.

  | Variant | Icon color | Use when | Where today |
  | --- | --- | --- | --- |
  | `neutral` (default) | `textSecondary` | Close, dismiss, clear, remove, more, menu, video controls | Matches today: `sheets.dart:73`, `promo.dart:165`, `payment_extras.dart:516`. Recolored (visible change, listed in Risks): `ActionMenu` and the search clear button use the Material default icon color (`interaction.dart:222`, `transactions.dart:342`); the nav menu uses the app-bar foreground (`navigation.dart:309`); video controls use `textPrimary` (`video.dart:339`) |
  | `accent` | `accent` | The icon is the main affordance of a value (copy) | `payment_status.dart:182`, `payment_receipt.dart:148` |

- **States:**
  - default; pressed (0.96 scale); focused (ring); disabled (`onPressed: null`, icon `disabled`).
  - No busy state. `PaymentCopyButton` owns its own pending, copied and failed states.
- **Gap.** Migrate all 10 sites. Three of them gain the focus ring they lack today (B8): `transactions.dart:340`, `payment_extras.dart:512`, `navigation.dart:307`.
  - `navigation.dart:307` is an `AppBar.leading` that keeps its `focusNode`, so the API takes an optional `focusNode`.

```dart
PaymentIconButton({
  Key? key,
  required IconData icon,
  required String tooltip,                 // spoken label; never empty
  required VoidCallback? onPressed,
  PaymentIconButtonVariant variant = PaymentIconButtonVariant.neutral,
  FocusNode? focusNode,
})
```

#### PaymentLink (**New**, D11)

- **Use / not.**
  - Use inline or beside a section title: "Read the privacy policy", "Edit", "Why am I seeing this?", "Retry".
  - Not for the screen's main action.
- **Anatomy:** a label (`heading`, or `caption` when muted); an optional trailing `open_in_new` 20 px when `external`; a 48 dp target; the ring; the 0.96 press.
- **Variants:** **New** `PaymentLinkEmphasis`. Nothing else exists.

  | Value | Style | Use when | Where today |
  | --- | --- | --- | --- |
  | `accent` (default) | `heading` in `accent` | An action the user is likely to take | `verification_widgets.dart:100, 537`, `promo.dart:210`, `video.dart:386` |
  | `muted` | `caption` in `textSecondary`, underlined | Disclosure next to content | `promo.dart:104` |

  Plus `external: bool`. It adds the trailing icon and the `opensExternally` hint.

- **States:** default, pressed, focused, disabled.
- **Gap.** Five private `TextButton`s; two lack the ring (`verification_widgets.dart:100`, `video.dart:386`).

### 6.2 Text (D16)

**Decision: no `PaymentText` widget.**

- A role-based text widget would wrap `Text(style:)` with no behavior of its own. That is the refused Stripe `Inline` under another name.
- The design system is consumed as **styles**: `Text('…', style: PaymentType.of(context).caption)`, after D15.
- The kit's text *components* are the ones with behavior, and only those:

| Component | Behavior that justifies a widget |
| --- | --- |
| `AmountText` | Formats `Money`, speaks it, clamps and scales down instead of clipping |
| `MiddleEllipsisText` | Keeps both ends of an ID or file name, speaks the full text |
| `CountdownText` | Host clock, tabular, spoken remaining time, single elapsed callback |

#### AmountText (`primitives.dart:15`)

- **Use / not.** Use for every displayed `Money`. Not for amounts the user types (that is `AmountInput`) or axis labels (`MoneyFormat.compact`).
- **Anatomy:** one line, tabular, end-aligned, with a semantics label of `spoken(money)`.
- **Variants today:** `emphasis: bool` (`display`), otherwise `label` tabular, plus a free `style`. Call sites pass five looks:

| Look | Call sites | **New** `AmountTextVariant` |
| --- | --- | --- |
| 13 caption | Meter legend `charts.dart:323-325` | `caption` |
| 15 regular | Row amounts `checkout.dart:198, 204`, `payment_receipt.dart:111` | `row` (default) |
| 15 w600 | Total rows `payment_status.dart:80-82`, `checkout.dart:210-212`, `payment_receipt.dart:116-118` | `total` |
| 20 `amountLarge` | Action bar `payment_extras.dart:79`, balance `:369`, chart headline `charts.dart:432` | `large` |
| 32 `display` | `emphasis: true` ×4 (`checkout.dart:178`, `payment_status.dart:363`, `payment_receipt.dart:101`, `transactions.dart:413`) | `display` |

- **States** are expressed through `style` color and decoration only:
  - Muted (`textSecondary`): any amount whose money has not moved.
  - Struck: failed or canceled only, never refunded (`transactions.dart:118-138`).
- **Gap → API.**
  - **New** `variant` parameter. Deprecate `emphasis` in favor of `variant: AmountTextVariant.display`.
  - `style` is documented as color and decoration only.

#### CountdownText, MiddleEllipsisText

| Component | Variants | States | Gap |
| --- | --- | --- | --- |
| `CountdownText` (`primitives.dart:858`) | none (style override) | running, elapsed (calls `onElapsed` once) | Uses a literal `TextStyle()` base (`:949`). Default it to `label.tabular` |
| `MiddleEllipsisText` (`primitives.dart:63`) | `textAlign` only | fits, elided (full text spoken) | none |

### 6.3 List family ("List and its variants")

**One anatomy, several classes.** The rows already share one layout:

| Shared metric | Value |
| --- | --- |
| Minimum height | 48 dp |
| Vertical padding | `spacing * 1.5` |
| Leading slot | 20 wide, centered on the first line |
| Leading → text gap | `spacing * 1.5` |
| Title | `label` |
| Detail line | `caption` |
| Trailing | Centered on the first line |
| Side padding | None, so rows align with section titles (decisions.md) |
| Focus ring | Radius 0 |
| Press | Material pressed layer, no scale |

Where it appears: `ActionTile` (`interaction.dart:71-131`), `_ControlRow` (`controls.dart:240-323`), and the shells of `TransactionListItem` (`transactions.dart:155-163`) and `ExpandableSection`.

The family members are separate classes because their **semantics differ** (button, checked, toggled, read-only). One class with a mode enum would give one widget four semantics contracts (D19).

| Member | Class | Semantics | Leading | Trailing | Use when |
| --- | --- | --- | --- | --- | --- |
| Navigation row | `ActionTile(onTap)` | button | Icon (optional) | Chevron, default when tappable and no `trailing` (`interaction.dart:117-131`) | Opens a screen or sheet |
| Action row | `ActionTile(onTap, trailing: …)` | button | Icon | Host widget (`trailing`); keeps its own size | Runs something; trailing shows current value or a 48 dp control |
| Destructive row | `ActionTile(destructive: true)` | button | Danger icon | Chevron | Irreversible; confirm with a dialog first |
| Disabled row | `ActionTile(onTap: null, disabledReason:)` | button, disabled | Muted icon | none | Visible but unavailable; reason replaces subtitle |
| Toggle row | `PaymentSwitch` | toggled | none | Switch at the end (gap 16) | Takes effect immediately |
| Multi-select row | `PaymentCheckbox` | checked | Box mark | none | Consent, opt-in; applied by a button |
| Single-select row | `PaymentRadio<T>` | checked, mutually exclusive | Ring mark | none | 2 to about 5 options, all visible |
| Property row | `InfoRow` | read-only, merged | none | Value; optional `trailing` action (copy) | Label/value facts (property list) |

Which row:

```
Can the user act on the row?
 ├── No  → InfoRow (property list, §6.3 below)
 └── Yes
      ├── Does it change a setting immediately?      → PaymentSwitch
      ├── Is it one of several exclusive options?    → PaymentRadio (≤ ~5) / sheet of PaymentRadio rows (more)
      ├── Is it an agree/opt-in applied later?       → PaymentCheckbox
      └── Default (opens or runs something)          → ActionTile
```

**Variants.**

- `ActionTile`: `destructive: bool`, `disabledReason: String?`, `trailing: Widget?`, `icon: IconData?`. Nothing else exists.
- **Refused:**
  - A `value` text slot. There are zero `trailing` call sites in `lib` or `example/lib`. Use `trailing: Text(…, style: type.label)` until two real uses exist.
  - An avatar or logo leading slot. There is no call site: method tiles dropped icons, and `MerchantHeader` draws its own initials.
  - Embedding a switch, checkbox or radio in `ActionTile.trailing`. That creates two tap targets and two semantics nodes.

**Density.**

- There is one density for actionable rows: 48 dp minimum and 12 vertical padding.
- `InfoRow` uses `spacing` (8) vertical padding (`primitives.dart:224`). It is read-only, so it has no target to protect.
- **No density enum** (Q8). A compact actionable row would only change looks, which fails §9 rule 1, and it risks B5.

**Grouping.**

- `ActionTileGroup` (`interaction.dart:145`) puts a full-bleed 1 px `outline` hairline between rows and no box around them.
- **Inset dividers are refused.** The rows have no side padding, and icons are optional per group, so an inset would align to nothing consistent.
- The group currently draws a raw `Divider` (`:157`). Adopt `PaymentDivider()`.

**Icon rule.** Give every row in a group an icon, or none, so the titles align.

**Property list = `PaymentSection(title:) + InfoRow…`** (D5). `InfoRow` (`primitives.dart:141`):

| Variant (by parameter) | Rendering | Use when |
| --- | --- | --- |
| default (`valueText`) | Label `label` in `textSecondary`, value `label` in `textPrimary`, end-aligned, ≤ 60% width | Facts |
| `emphasis: true` | Label in `heading` | The Total row |
| amount (`value: AmountText`) | Keeps natural width | Money; amounts never squeeze |
| reference (`value: MiddleEllipsisText(style: label.reference)`) | Monospace, middle-elided | IDs, file names (`transactions.dart:451`, `payment_status.dart:420`) |
| selectable reference (`value: SelectableText`) | Monospace, selectable | VA number and receipt ID, where the user copies by hand (`payment_receipt.dart:126`) |
| with action (`trailing:`) | 48 dp action centered on the first line | Copy (D3) |
| `caption:` | `caption` under the label | Qualifier ("incl. tax") |

- **Large text:** the value wraps under the label only if they do not fit (`:186-200`).
- **Masking is not an `InfoRow` variant.** `VerificationReview` masks NIK values marked `maskInReview` before it passes `valueText` (`verification_widgets.dart:570`). Masking stays a pattern rule, so the row never receives the full value.

**How `TransactionListItem` is built** (Tier 2, `transactions.dart:103`). It is the row shell plus:

- title: `heading`, 2 lines;
- `AmountText` in the `row` variant, muted unless settled, struck if failed or canceled;
- meta: `caption`, merchant · date, 2 lines;
- `StatusBadge` tags in a `Wrap`.

It is not an `ActionTile`, because its layout (an amount column and tags) is history-specific. The **New** internal helper `_RowShell` (Phase 2) gives `ActionTile`, `_ControlRow` and `TransactionListItem` one implementation of the shared metrics, so the family cannot drift.

### 6.4 Feedback

| Component | Use / not | Variants (closed) | States | Tokens | Gap → change |
| --- | --- | --- | --- | --- | --- |
| `StatusBadge` (`primitives.dart:503`) | Read-only state of an item / not for messages (Banner) or actions | `tone`: 5 `StatusTone`s. Stripe mapping: positive→`success`, negative and urgent→`danger`, warning→`warning`, info→`info`, neutral→`neutral`. Pending and unknown share `warning` and differ by icon and word (`transactions.dart:81, 84`) | static | Fill `tone.container`, radius `tag`, padding 8/4, icon 14 and `tag` text in `tone.foreground` | D20: **New** `icon` optional with the §3.6 tone default; icon scales to 1.6× |
| `NoticeBanner` (`:548`) | Persistent, inline message about a problem or required step / not the normal path, not transient feedback (Toast) | `tone` ×5; optional `message`; optional `actions`; `announce` | static; announced when `announce` | Fill `tone.container`, radius `control`, padding 12, title `heading` in `tone.foreground`, message `bodyFor`, icon 20 (1.6×) | D21: no dismiss; `actions` limited to `PaymentLink` or `hug` quiet/secondary `PaymentButton`. No kit call site passes `actions` today |
| Toast `showPaymentSnackBar` (`interaction.dart:326`) | Short outcome of an action the user just took ("Copied", "Share canceled") / not errors that block (Banner) | `tone` ×5 (icon only); optional action | shown, replaced (hides current) | Today: Material `SnackBar` colors | D22: kit tokens. Ink fill `textPrimary`, text `surface`, `caption`/`label`, radius `control`, like `PaymentTooltip` |
| `StatusHeader` / `StatusBand` (`:700, 761`) | Top of a status screen / not inside lists | `tone` ×5 × `hatched` (unknown outcome) | static | Band 6 px, radius 3, `tone.foreground`; title `heading` in tone; icon 20 (1.6×) | none |
| `StateMessage` (`interaction.dart:573`) | Replaces a list or module that is empty, has no matches, or failed / not for page-level errors with no content (host) | By content and tone, see below | static; `danger` announces | Icon `textSecondary` 20 (1.6×), title `heading`, message `body` in `textSecondary`, action secondary `PaymentButton` ≤ 280 | Dartdoc says `major` (32) padding, code uses 16 (§3.3) |
| `LoadingSkeleton` (`:498`) | Content loading into a known shape / not an action running (busy button) or an unknown wait (Spinner) | `rows`, `leading` (icon square). Shapes: list row (leading + 2 bars) and text block (no leading). Nothing else | static (no shimmer) | `surfaceMuted`, radius `tag`, bars 14/10 | none |
| `PaymentSpinner` (`primitives.dart:445`) | Unknown-length wait with no shape / not inside a button (use `busy`) | `size`: **20** (inline, buttons) and **32** (standalone block). No other values | spinning; still hourglass under reduced motion | `textSecondary` default; stroke 12% of size | Adopt in `video.dart:299` |

**StateMessage variants.** These are by content. There is no enum, and nothing else exists:

| Case | Tone | Icon | Action | Example |
| --- | --- | --- | --- | --- |
| Empty | `neutral` | Domain icon | none | History empty `transactions.dart:310` |
| No results | `neutral` | `search_off` | none (clear search is in the field) | `transactions.dart:300` |
| Primary content failed | `danger` (announced) | `cloud_off_outlined` | Retry | History load `transactions.dart:290-291` |
| Secondary module failed | `warning` | `cloud_off_outlined` | Retry | Chart `charts.dart:403-404`, promo `promo.dart:373-374` |

- The different error tones are a rule, not drift (D25). `danger` is for the screen's main content. `warning` is for a module the user can ignore.
- Offline is not a separate variant. The host maps `HostErrorCategory.network` to copy.

### 6.5 Forms

| Component | Variants (closed) | States | Tokens | Gap → change |
| --- | --- | --- | --- | --- |
| `PaymentCheckbox` (`controls.dart:13`) | none; `description`, `disabledReason` | unchecked, checked, disabled + reason, focused. No tristate | Checked fill `accent`, check `onAccent`; unchecked edge 2 px `border`; disabled `disabled` | Adopt in `verification_widgets.dart:111`, `checkout.dart:492` (fixes the ~11 dp gutter offset) |
| `PaymentRadio<T>` (`:91`) | none; same slots | unselected (1.5 px ring `textSecondary`), selected (6 px ring `accent`), disabled + reason | as listed | Adopt its mark in `PaymentMethodPicker`, replacing `_Radio` and `Icons.block` (D12) |
| `PaymentSwitch` (`:162`) | none; same slots | off, on (thumb check), disabled + reason | Track `accent`/`surface`, outline `border`, thumb `onAccent`/`border` | No Tier 2 use (Q2) |
| **New** `PaymentTextField` (D1) | `size`: **New** `PaymentTextFieldSize.body` / `.amount`; `reference: bool`; named constructor `.search` | empty, filled, focused (2 px `accent`), error (`danger.foreground` caption), helper (tone), disabled | Text `input` (16/24) or `amountLarge` for `.amount`; label `label` in `textSecondary`; edge `border`; radius `control` | Sketch in §11, Phase 3A |
| `AmountInput` (`checkout.dart:19`) | none | as text field + parse issues (`AmountIssue`) | `amountLarge`, clamped 1.6× | Rebuilt on `PaymentTextField.amount` |
| **New** `PaymentCopyButton` (D3) | none (built on `PaymentIconButton` `accent`) | idle, pending (single call), copied (check + live "Copied"), failed (words under the icon) | Feedback `tag` in `success`/`danger` foreground | Sketch in §11, Phase 3B |

Which text-field variant:

| Variant | Use when |
| --- | --- |
| `.search` | Filtering a visible list |
| `size: amount` | Money entry |
| `reference: true` | Codes people type digit by digit (promo code) |
| default | Everything else |

There is no password, PIN or OTP variant (D1a).

### 6.6 Navigation and disclosure

| Component | Variants | States | Tokens | Gap |
| --- | --- | --- | --- | --- |
| `PaymentTabs` (`controls.dart:333`) | One: text tabs on a hairline | unselected (`textSecondary`), selected (`accent` + 2 px underline, same weight), pressed (0.96), focused | `label`, 48 dp, padding 12 | none |
| `ActionMenu` (`interaction.dart:188`) | Entries: default / destructive / disabled (`onSelected: null`) | closed, open (instant) | Floating surface (§3.5), entries `label` 48 dp min, 160 min width | Trigger becomes `PaymentIconButton` |
| `ExpandableSection` (`:365`) | Controlled or uncontrolled; optional `leading`, `subtitle` | collapsed, expanded (chevron 150 ms, size 220/150 ms) | `heading` title, ruled bottom | Never holds fees (PRD §8) |
| `PaymentStepIndicator` (`payment_extras.dart:260`) | none | per step: reached (`i <= current`, `accent` bar) or upcoming (`outline` bar); spoken "step n of m" | — | Own docs page (Phase 5) |
| `AdaptiveNavShell` / `NavSidebar` (`navigation.dart:244, 49`) | Wide (sidebar) or narrow (drawer) by width | selected (`surfaceMuted` fill, no bar), disabled + reason | — | Menu button becomes `PaymentIconButton` with `focusNode` |

### 6.7 Content and layout

| Component | Variants | Rules |
| --- | --- | --- |
| `PaymentDivider` (`primitives.dart:487`) | `height`: **1** (between rows), **16** (`spacing * 2`, inside a section, e.g. above a Total row), **24** (`spacing * 3`, between sections). Thickness always 1, color `outline`. Full bleed only. Nothing else | Decorative, so screen readers skip it |
| `PaymentSection` (`:650`) | `title?`, `trailing?` (an "Edit" `PaymentLink`) | Flat only; title `heading` with header semantics. **No card variant**: boxed surfaces are §3.5 recipes owned by patterns |
| `PaymentTooltip` (`controls.dart:450`) | One | Ink fill `textPrimary`, `caption` in `surface`, radius `control`, 500 ms wait. Only repeats or names; never the only place for a fee or error |
| `PrivacyMask` (`primitives.dart:825`) | `obscured` on/off | `surface` cover, `lock_outline` 48, spoken "content hidden" |
| `PaymentActionBar` (`payment_extras.dart:18`) | With or without `total`; `updating` | Ruled top, total `amountLarge` clamped 1.6×; hosts pass a `hug` button (D17), the bar keeps its 112–240 wrapper; stacks at large text |
| `PaymentVideoPlayer` (`video.dart:97`) | none | Scrim exceptions documented (§3.0); controls become `PaymentIconButton`/`PaymentLink`; loading uses `PaymentSpinner(size: 32, color: Colors.white)`, a documented scrim exception, because it sits on `Colors.black` (`video.dart:365`) |

### 6.8 Overlays

| Component | Variants (closed) | States | Tokens | Gap |
| --- | --- | --- | --- | --- |
| Sheet: `showPaymentSheet` (`sheets.dart:145`), `showPaymentSideSheet` (`:180`), `PaymentSheet` (`:90`), `PaymentSheetHeader` (`:14`) | **Placement:** bottom (content height, drag handle) or side (end edge, ≤ 420 or 88% width). **Header:** with or without close (`onClose: null` while a host call runs). **Footer:** optional, ruled | open, closing, not dismissible (`isDismissible: false`) | `surface`, top radius 12, elevation 0, 280/200 ms `drawer`, title `title` | Close becomes `PaymentIconButton` |
| Dialog: `showPaymentConfirmDialog` (`interaction.dart:259`) | `destructive: bool`: default (confirm `primary`) or destructive (confirm `destructive`, cancel focused first) | open, resolved true/false | `surface`, radius `sheet`, title `title`, message `bodyFor` in `textSecondary` | D23: actions become two `hug` `PaymentButton`s (quiet + primary/destructive), gaining the focus ring |

### 6.9 Charts (PR #4)

| Component | Variants / parameters (closed) | States | Encoding |
| --- | --- | --- | --- |
| `PaymentLineChart` (`charts.dart:18`) | `zeroBased`, `inspectable` | per point: settled, pending, unknown, missing | Settled solid; pending dashed or outlined; unknown hatched or dotted; missing is a gap; never pending-looking unknown (decisions.md) |
| `PaymentBarChart` (`:44`) | `inspectable` | same | same |
| `PaymentSparkline` (`:68`) | `width`/`height` (default 80×24); never inspectable | same | 1.5 px stroke |
| `PaymentMeterChart` (`:255`) | `showLegend`; ≤ 5 segments | per segment status | Accent→surface ramp at ≥ 3:1 (`chart_geometry.dart:99-114`); tones never categories |
| `ChartModule` (`:349`) | Height `compactHeight` 180 / `featuredHeight` 320 (`:367-368`); `showHeadline`; `delta` + `deltaTone`; `trailing` | `ChartState`: loading, ready, empty, error (constant plot height) | Headline `amountLarge` (host `Money`), caption + delta in `caption` |

**Which chart:**

| Chart | Use when |
| --- | --- |
| Bar | Amounts per period (spending per month) |
| Line | One trend over time |
| Sparkline | A trend beside a number, no reading of values |
| Meter | Parts of one total |

There is no multi-series chart.

**Gaps (B1, B2).**

- No public chart class or parameter has dartdoc.
- The meter legend uses literal 16/8/4 spacing and a 10 px swatch (`charts.dart:301-313`). The headline box uses `scale(72)` (`:427`).
- `MeterSegment.color` (`chart_models.dart:28, 33`) lets a host bypass the ramp, including with status tones, which the charts decisions forbid. See Q9.

## 7. Patterns (Tier 2, composed from Tier 1)

| Pattern | Widgets | Built from | Docs |
| --- | --- | --- | --- |
| Checkout | `PaymentSummary`, `PaymentMethodPicker`, `PaymentConfirmation`, `AuthorizationPrompt`, `MerchantHeader`, `BalanceCard`, `PromoCodeInput` | `PaymentSection`, `InfoRow`, `AmountText`, `PaymentRadio` mark, `PaymentCheckbox`, `PaymentTextField`, `PaymentButton`, `PaymentActionBar` | `patterns/checkout` |
| Status and receipt | `PaymentInstructions`, `PaymentStatusView`, `RefundSection`, `PaymentReceipt` | `StatusHeader`, `InfoRow`, `PaymentCopyButton`, `CountdownText`, `PaymentButton` stack, `NoticeBanner` | `patterns/status-receipt` |
| Transaction history | `TransactionHistory`, `TransactionListItem`, `TransactionDetail` | `PaymentTextField.search`, `PaymentTabs`, row shell, `StatusBadge`, `StateMessage`, `LoadingSkeleton`; Phase 4 adds `ChartModule` + `PaymentBarChart` | `patterns/history` |
| Verification (KYC) | `VerificationIntro`, `IdentityForm`, `DocumentUploadTile`, `VerificationReview`, `VerificationStatusView` | `PaymentCheckbox`, `PaymentTextField`, `PaymentLink`, `InfoRow`, `PaymentSection` | `patterns/verification` |
| KYC capture | `showCaptureSourceSheet`, `KycCaptureGuide`, `CaptureFrameOverlay` | `showPaymentSheet`, `ActionTile`, `PaymentButton` | `patterns/kyc-capture` |
| Promotions | `PromoCard` (`PromoLayout.card` / `.banner`), `PromoSlot` | `PaymentLink`, `PaymentIconButton`, `StateMessage`, `LoadingSkeleton` | `patterns/promotions` |

Cross-cutting pattern pages:

- **Loading:** skeleton vs spinner vs busy button.
- **Empty and error:** the `StateMessage` table, `ChartState`, `PromoSlotState`.
- **Forms:** labels, error timing, focus to the first error, no secret fields.
- **Chart layout:** this page already exists.

## 8. Decisions

Revision 1, kept (only line references updated):

| ID | Decision | Reason |
| --- | --- | --- |
| D1 | Extract **`PaymentTextField`**, built on `TextFormField` so it works with or without a `Form`. Migrate all four copies. Focus is the 2 px `accent` border only; the history search drops its extra `PaymentFocusRing`. | Four copies of one decoration that already drift. `IdentityForm` needs `validator` and `forceErrorText`. |
| D1a | `PaymentTextField` has **no `obscureText`** and no PIN or OTP mode. | The kit never receives secrets (PRD §7, §11). |
| D2 | **Search is a named constructor, `PaymentTextField.search`.** Controlled (`query` + `onChanged`), no debounce. Own docs page. | One call site; a variant costs no extra API surface. Debounce is host policy. |
| D3 | **`PaymentCopyButton`** is the compact control (`value`, `onCopy: Future<bool> Function(String)`), with inline feedback. It is built on `PaymentIconButton` (D18). The receipt banner then reports only the share outcome. | Two call sites lay out differently; feedback next to the value; the host owns the clipboard. |
| D4 | **No DateField, no Select** for now. | No options field; date of birth is typed text. Revisit with Q1. |
| D5 | **PropertyList** is documented, not built: `PaymentSection` + `InfoRow`. | Existing behavior. |
| D6 | **No ButtonGroup class.** The Button page states the group rules (§6.1). | The three groups differ; a class would only wrap a `Column`. |
| D7 | **No TaskList.** | No per-item completion anywhere. |
| D8 | **No Chip.** | One private use; chips were rejected for filters. |
| D9 | **No Img component.** Phase 2 gives `KycCaptureGuide`'s photo an `errorBuilder` that falls back to the frame overlay (`capture_widgets.dart:260`). | The only kit-drawn image lacks an error state; that is a pattern bug. |
| D10 | **Charts** are admitted at the owner's request. Phase 4 adds a spending summary above history. `BalanceCard` keeps its limit bar (`payment_extras.dart:386`). | History is the customer-facing summary; the limit bar is one ratio with a warning tone. |
| D11 | **`PaymentLink`** is a new compact component; `PaymentButton` keeps its no-scale press. | One class, one press rule. |
| D12 | **Adopt before extract.** The method picker uses `PaymentRadio`'s mark; a disabled method shows the disabled circle plus its reason. | One radio look; the reason, not an icon, is the non-color signal. |
| D13 | **No FormFieldGroup, TextArea or DateRangePicker.** | No use exists. |
| D14 | **`showCaptureSourceSheet` and `CaptureFrameOverlay` are Tier 2 (KYC capture).** | They take verification types and keep the no-camera boundary. |

New in revision 2:

| ID | Decision | Reason |
| --- | --- | --- |
| D15 | **Export `PaymentType`** (`show PaymentType`, not the extension) with `PaymentType.of(context)`. Add **New** `firstLineHeight(context)`, `tabular(style)` and `reference(style)`. Deprecate `amountStyle(large:)`. Approved (Q6). | A design system needs consumable type roles. It mirrors the public `PaymentMotion.of`. Exporting the extension risks name clashes. `large: false` contradicts the weight rule. |
| D16 | **No `PaymentText` widget.** Type is consumed as styles. Text components exist only with behavior (`AmountText`, `MiddleEllipsisText`, `CountdownText`). | A style wrapper is the refused `Inline`. |
| D17 | **`PaymentButton` keeps one height (48 dp)** and gains **New** `width: PaymentButtonWidth.fill / .hug`. It never scales on press, at any width. Approved (Q7). | Stripe's small/medium/large are heights. Under B5 and one label role, a height scale either breaks the 48 dp floor or looks identical. Width is what the three conflicting call sites need. One press rule per class (D11). `PaymentActionBar` keeps its wrapper because it receives a host widget. |
| D18 | **Extract `PaymentIconButton`** (`neutral`, `accent`), with a required tooltip, the ring, the 0.96 press, 48 dp, and an optional `focusNode`. Migrate all 10 sites. | Admission rule (a) with 10 sites; three lack the focus ring (B8). |
| D19 | **List family = one row anatomy, separate classes by semantics.** No mode enum on `ActionTile`; no `value` slot; no avatar leading; no density enum; full-bleed dividers only. Rename the docs page to `components/list`. Add an internal `_RowShell`. | Each refused option has zero call sites. The classes' semantics differ. The shared metrics are already identical and should stay so by construction. |
| D20 | **`StatusBadge.icon` becomes optional**, defaulting to the §3.6 tone icon. Its icon scales to 1.6×. | Removes a required parameter for the common case. History still passes its own icons (pending vs unknown). |
| D21 | **`NoticeBanner` has no dismiss.** `actions` accepts `PaymentLink` or `hug` quiet/secondary `PaymentButton` only (documented, asserted in debug). | Banners mirror host state and leave when the state changes. A full-width button in a `Wrap` breaks the layout. |
| D22 | **Toast uses kit tokens:** ink fill `textPrimary`, text and icon `surface`, radius `control`. Tone stays an icon. Approved (Q10). | B2. The tooltip already uses this inversion, so the kit has one "ink" overlay. |
| D23 | **The dialog adopts `PaymentButton`** (`hug`): quiet cancel + primary or destructive confirm. Needs **New** `PaymentButton.autofocus` so cancel keeps initial focus for destructive dialogs and confirm keeps it otherwise (`interaction.dart:291, 302`). | Closes a B8 gap (no focus ring today); one button implementation. |
| D24 | **`AmountText` gains New `variant: AmountTextVariant`** (`caption`, `row`, `total`, `large`, `display`). `emphasis` is deprecated. `style` is for color and decoration only. | Five looks are already in use through ad-hoc styles, including literal `FontWeight.w600`. |
| D25 | **`StateMessage` tone rule:** `danger` only when the screen's primary content failed (announced); `warning` for a secondary module. | Codifies the existing history vs chart and promo split. |
| D26 | **No new spacing API.** The §3.3 multiples are the contract, enforced by review grep. | Six roles on one token already exist in dartdoc; named getters would add API for no new capability. |
| D27 | **Specimen captures replace the `controls_*` captures** (`controls_buttons` → `button_variants`, and so on). `screens.mjs` and the mdx references are updated in the same PR; no duplicate captures. | One name scheme (§10). |

## 9. Variant governance

1. **Admission.** A new variant (enum value, boolean mode or named constructor) needs **two real uses that differ in meaning**, in `lib/` or in the example's Tier 2 screens. Looks alone do not count. Each use is cited in the PR.
2. **No per-screen variants.** A variant named after a screen or pattern (`checkoutPrimary`) is refused. The pattern composes existing variants.
3. **Brand differences are tokens, not variants.** Corner radius, fonts, weights and colors go through `PaymentTheme.copyWith`. A request like "a rounder primary for brand X" is a token change.
4. **Naming.**
   - One enum per component: `<Component>Variant` for emphasis or look (`PaymentButtonVariant`, **New** `PaymentIconButtonVariant`, **New** `AmountTextVariant`).
   - A size or width enum is `<Component><Axis>` (**New** `PaymentButtonWidth`, **New** `PaymentTextFieldSize`).
   - Status color always uses the shared `StatusTone`, never a per-component tone enum.
   - A single binary meaning stays a `bool` named for the meaning (`destructive`, `hatched`, `external`, `reference`).
5. **Closed sets.** Every docs page lists the variants and says "nothing else exists". `switch` statements over variant enums are exhaustive, with no `default:`.
6. **Deprecation in 0.x.**
   - A replaced parameter or value is marked `@Deprecated('Use … — removed in 0.<n+1>.0')` for one minor release, with a CHANGELOG entry and a migration snippet on the docs page.
   - Removal happens in the next minor release.
   - Parameters that were never released (PR #4 before merge) may change without deprecation.
7. **Removal.** A variant with no remaining use is deprecated by the same rule.

## 10. Docs and specimen requirements

**Foundation pages** (`website/src/content/docs/foundations/`):

| Page | Must contain |
| --- | --- |
| `color.mdx` | Full §3.1 table, both flowcharts from §3.0, the scrim exceptions |
| `typography.mdx` | §3.2 role table, modifiers, 200% rules, `PaymentType` API (after D15) or the "internal" note |
| `spacing.mdx` | §3.3 and §3.4 tables |
| New `surfaces.mdx` | §3.5 table |
| New `iconography.mdx` | §3.6 sizes, semantic set, payment-status icons |
| `motion.mdx` | §3.7 table |
| `focus.mdx` | §3.8 table |
| `money.mdx` | §3.9 table |

**Component pages** add the following to B12:

- **Specimen screenshot** showing every variant × the key states, in light and dark, plus 200% where the component is text-heavy.
  - Name: `ios_catalog_<component>_variants`, `_variants_dark`, `_variants_200`. In `catalog_screenshots_test.dart`, `shot('<component>_variants$look')`, since `shot()` adds the `${platform}_catalog_` prefix.
- A **"Which variant when"** table, copied from §6.
- **Do / don't pairs:** one correct and one incorrect snippet from real call sites. Example: correct `PaymentButton(variant: PaymentButtonVariant.quiet, label: 'Not now')`; incorrect, a second `primary` in the same sheet.
- A **closed-set sentence:** "Variants: …. Nothing else exists."

**Example gallery.**

- `example/lib/screens/gallery_kit.dart` gets one **New** `_Specimen` entry per component.
- Each entry is a grid of variants × states with synthetic data only. No real names, no unmasked NIK.
- The capture test drives each entry in light, dark and, where text-heavy, `TextScaler.linear(2)`.
- New captures are registered in `website/scripts/screens.mjs`. The docs use only `example/build/screenshots_hairline`.

Text-heavy components (need `_200`):

- Button, Link, List family, `InfoRow`
- `NoticeBanner`, Toast, `StateMessage`
- Text field, Dialog, Sheet, `ChartModule`

## 11. Phased plan

Per the owner's standing rule, every PR stops before merge, and a merge needs the owner to name the destination. Each PR is small and has its own acceptance criteria (§12).

### Phase 0: land what exists

- PR #3 (this PRD, revision 1) is merged to `main` (`f74b882`).
- **Merge PR #1, then PR #4, to `main`.** That is the owner's decision, after each PR's own verification.
- Phase 1 branches from `main` once both are merged. While they are open, Phase 1 stacks on `feat/charts-kyc-capture` and never edits files those PRs are still changing.

### Phase 1: foundations public API and token docs (two PRs)

**1A: type and token API.**

- Export `PaymentType` (D15, approved).
- Add `firstLineHeight` and replace its 8 copies.
- Add `tabular(style)` and `reference(style)`.
- Deprecate `amountStyle(large:)`.
- Add the internal tone→icon helper and replace the two copies.
- Align the `StateMessage` padding dartdoc.
- Fix the Contrast brand radius comment.
- Audit the icon family.
- Tests: role values at scale 1; `firstLineHeight` at 1× and 2×; the export surface.

**1B: foundation pages.**

- Token tables for all §3 pages.
- New `surfaces` and `iconography` pages.

### Phase 2: adopt and variant gaps (three PRs)

**2A: adopt.** No public API change beyond D12's visual change:

- `PaymentCheckbox` in `VerificationIntro` and `PaymentConfirmation`.
- The `PaymentRadio` mark in `PaymentMethodPicker`.
- `PaymentDivider` for the 11 raw dividers, `ActionTileGroup` included.
- `PaymentSpinner(size: 32, color: Colors.white)` in video loading (on the black picture area, `video.dart:365`).
- The `KycCaptureGuide` `errorBuilder` (D9).
- The internal `_RowShell` (D19).

**2B: Button and Text variants.**

- **New** `PaymentButtonWidth` (D17); the action bar docs recommend `hug` (the bar keeps its wrapper).
- **New** `PaymentButton.autofocus`.
- The dialog adopts `PaymentButton` with `hug` and `autofocus` (D23).
- **New** `AmountTextVariant` (D24); the three literal-w600 Total rows migrate.
- The `CountdownText` default style.

**2C: feedback and chart variants.**

- `StatusBadge` optional icon and icon scaling (D20).
- Toast tokens (D22).
- The `NoticeBanner` actions assert (D21).
- Chart dartdoc and token spacing.
- Remove `MeterSegment.color` (Q9, decided). If PR #4 is still open, the chart items can go into PR #4 instead, if the owner prefers.

Screenshots to re-take and inspect in Phase 2:

- `controls_choices` (light and dark)
- KYC intro (light and `_200`)
- `requote`
- video loading
- the confirm dialog
- the toast
- history list
- the action bar

### Phase 3: extract (two PRs)

**3A: text fields.** New `PaymentTextField` with `.search`; migrate `AmountInput`, `PromoCodeInput`, `IdentityForm` and `TransactionHistory`.

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
  bool reference = false,                     // referenceFontFamily (promo code)
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

- **States:** empty, filled, focused, error, helper, disabled, `reference`, `amount`.
- **Tests** (`test/text_field_test.dart`):
  - B3–B10.
  - A server error clears after an edit.
  - Focus moves to the first invalid field.
  - The search clear button resets `query` and has the `clearSearch` label.
  - The ring and the border never show at the same time.

**3B: icon button, link and copy.** New `PaymentIconButton` (D18), `PaymentLink` (D11) and `PaymentCopyButton` (D3). Migrate the 10 icon buttons, the 5 inline actions and the 2 copy sites.

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

- **New strings** (en and id): `opensExternally` and a generic `search`. `copy`, `copied`, `copyFailed` and `retry` already exist.
- **Tests** (`test/link_copy_test.dart`):
  - 48 dp targets.
  - One semantics node with the button role.
  - The tooltip is required and spoken.
  - `external` adds the hint.
  - Copy success and failure are announced.
  - A double tap while `onCopy` is pending calls it once.
  - B6 for muted links and `neutral` icons in dark.
  - The three formerly ring-less sites now show the ring.

### Phase 4: pattern adoption

- **Spending summary (D10):** `ChartModule` + `PaymentBarChart` above `TransactionHistory` in the example. Totals are host-owned, and all four `ChartState`s are reachable from the scenario picker.
- **`TransactionDetail` reference copy**, (Q5, decided: yes).
- No builds from Q1 or Q2: both were decided as no new components (no DateField/Select; Switch and Tooltip kept as catalog entries).

### Phase 5: docs information architecture and specimens

- **Sidebar.** `Start`, `Concepts`, `Foundations` (Color, Typography, Spacing and radius, Surfaces, Iconography, Motion, Focus and press, Money, Localization). Then `Components` in Stripe groups:
  - **Layout:** Divider, Section
  - **Actions and navigation:** Button, Icon button, Link, Action menu, Tabs, Navigation shell, Step indicator
  - **Content:** Amount text, List, Info row (with property list), Copy button, Expandable section, Tooltip, Countdown, Privacy mask, Action bar, Video
  - **Forms:** Text field, Search field, Amount input, Checkbox, Radio, Switch
  - **Charts:** Line, Bar, Meter, Sparkline
  - **Feedback:** Status badge, Notice banner, Toast, Status header, Spinner, Loading skeleton, State message
  - **Overlays:** Dialog, Sheet
  - Then `Patterns` (including Loading, Empty and error, Forms, Chart layout), then `Reference`.
- **Patterns.** "Payment flows" becomes Patterns. KYC capture absorbs `components/capture-source-sheet` (D14).
- **Redirects** go through the existing mechanism (`astro.config.mjs` `redirects`, `public/_redirects`, `netlify.toml`). `components/action-tile` redirects to `components/list`.
- **Specimens.** One `_Specimen` per component and `<component>_variants[_dark|_200]` captures. The `controls_*` captures are renamed (D27).
- **Overview page:** a "Stripe Apps name → kit" column.
- **"Not in the kit":** one row per refusal.

## 12. Acceptance and verification

### Every phase

These are local commands; the repo has no CI.

- **Format and analyze.** `dart format --output=none --set-exit-if-changed .`, then `flutter analyze` in the package and in `example/`.
- **Package tests.** Run file by file: `flutter test --no-pub test/<file>.dart`. The full suite intermittently fails to load on this machine with a `flutter_tester` WebSocket error (`docs/decisions.md`).
- **Integration flow.** `cd example && flutter test --no-pub integration_test/flow_test.dart -d <iPhone 16 / iOS 18.1 simulator>`; all existing tests pass.
- **Screenshots.** `catalog_screenshots_test.dart` on the same simulator. Each new or changed capture is opened and inspected: light, dark, and 200% where text-heavy.
- **Docs.** In `website/`: `pnpm build`, `pnpm check:links` (0 broken), `pnpm check:snippets` (0 problems).
- **Identifier check.** Every backticked PascalCase identifier on a changed docs page exists in `lib/`, or is marked **New**.

### Phase-specific acceptance

| Phase | Happy flow | Edge states | Security | Performance |
| --- | --- | --- | --- | --- |
| 0 | `main` builds and passes the above with #1 and #4 merged | — | Unchanged | Unchanged |
| 1A | A host can style a `Text` with `PaymentType.of(context).caption`; the kit renders unchanged (screenshot diff by inspection) | Roles at 1× and 2×; `firstLineHeight` matches the old formula; deprecated `amountStyle(large:)` still compiles | Export surface grows by `PaymentType` only; no new dependency | No new rebuilds (`PaymentType.of` cost unchanged) |
| 1B | Every foundation page shows its full token table | 320 px pages do not scroll sideways | Synthetic values only | WebP only |
| 2A | KYC → checkout → pay → receipt unchanged in `flow_test` | Disabled method shows reason + disabled circle; re-quote checkbox aligned at 100% and 200%; video loading under reduced motion; KYC guide photo error shows the frame | No behavior change | Widget count equal or lower |
| 2B | Action bar, dialog and total rows render as before with the new API | Dialog at 200% stacks its buttons; destructive dialog focuses cancel; `hug` label wraps, never truncates | No behavior change | No added layout passes; the action bar keeps its existing wrapper |
| 2C | Badges, toasts and banners keep their meaning with icon + words | Badge icon scales to 1.6×; toast contrast ≥ 4.5:1 in both brands, light and dark; chart legends at 200% | No new strings with user data | Charts stay paint-only (no `AnimationController` in `lib/src/charts`) |
| 3A | Identity form submits; amount parses; promo applies; search filters | P01 (empty, zero, over limit, pasted formatted amount); K02 (non-ASCII name, server error clears on edit, focus to first error); search clear at 200%; Indonesian helper at 200% | NIK still masked in review (`maskInReview`); no `obscureText` in the public API; no new dependency | One fewer focus layer in history; no extra rebuilds per keystroke |
| 3B | Copy VA number and receipt ID; open policy; edit from review; close sheets; dismiss promo; clear search | P15 (clipboard fails → "copy failed" visible); double tap while pending; external hint spoken; all 10 icon buttons show the ring on Tab | Copy only receives host-passed values (VA number, transaction ID), never NIK; no `Clipboard`, `url_launcher` or `dart:io` in `lib` | Static press scale only (100 ms; 0 under reduced motion) |
| 4 | History shows a spending summary from host data | Loading, empty, error with retry, pending and unknown bars (hatched, never like pending); 200% | Values are host `Money`; the kit computes no totals | Paint-only charts |
| 5 | Every Tier 1 component has a page that meets B12 with a specimen | Redirects resolve; 320 px pages do not scroll sideways | Docs screenshots use synthetic data only | `dist/` size noted; WebP only |

**Done for this initiative:**

- Every foundation page has its full token table.
- Every Tier 1 row is Have, with B1–B13 checked and a variant specimen.
- No Tier 2 file contains a private copy of a Tier 1 control. Review grep: no `CheckboxListTile`, `_Radio`, `OutlineInputBorder`, raw `Divider(`, `IconButton(`, `TextButton(` or `CircularProgressIndicator` outside `lib/src/controls` and `lib/src/foundation`.
- "Not in the kit" lists all 21 refusals.

## 13. Non-goals, risks, open questions

### Non-goals

- Matching Stripe's list or its variant props one to one, or building anything because Stripe has it. Examples: Button `size`, Banner `onDismiss`, ListItem `image`.
- App shells, page templates, tables, rich text, a `Box`-style layout DSL.
- PIN, OTP or password fields, or any secret input. A photo-grid gallery browser.
- New dependencies, network calls, URL launching, camera or clipboard access inside `lib`.
- Bundled fonts or an icon package.
- Exporting `PaymentFocusRing` or `PaymentPressScale` without owner approval.

### Risks

| Risk | Mitigation |
| --- | --- |
| Exporting `PaymentType` freezes 9 roles as public API in 0.x | Roles are unchanged since the large-text pass and documented; changes follow §9 rule 6 |
| Visible changes: receipt copy feedback moves beside the button; the method picker's disabled icon; dialog buttons; toast colors; history search loses its double focus indicator; `ActionMenu`, search clear, nav menu and video control icons recolor to `textSecondary` (D18) | Listed in CHANGELOG per PR; before and after screenshots inspected |
| Variant creep after the system is public | §9 rules on the components overview page; reviewers check the two-use citation |
| A new public API is hard to change after 0.1.x | Sketches reviewed before code; constructors take only what current call sites use |
| Maintenance: four new public widgets (`PaymentTextField`, `PaymentIconButton`, `PaymentLink`, `PaymentCopyButton`) | They replace 19 private copies (4 text fields, 10 icon buttons including the 2 copy controls, 5 inline links), so total code goes down |
| `IdentityForm` regression: server errors, focus order, autofill | Existing K02/K07 tests plus new per-field tests in 3A |
| Branch churn: #1 and #4 unmerged | Phase 1 waits for Phase 0 or stacks on #4; it never edits files those PRs are changing |

### Owner decisions (resolved 31 Oct 2026)

The owner accepted every recommendation below on 31 Oct 2026. Each line is now a decision; the reasoning is kept for the record.

1. **Date of birth.** Should `IdentityFieldSpec` gain field kinds (`text`, `date`, `choice`)? That would admit a `PaymentDateField` and a `PaymentSelect` (a sheet of `PaymentRadio` rows). **Decided: no (D4).**
2. **Switch and Tooltip have no Tier 2 consumer.** Keep them as owner-approved, or give each a real use, for example a refund-notification `PaymentSwitch` in a settings example? **Decided: keep; add the settings example only if Phase 4 has room.**
3. **Export `PaymentFocusRing` and `PaymentPressScale`?** **Decided: keep them internal.** With `PaymentIconButton` and `PaymentLink` public, hosts get the kit's focus and press by using those components. Revisit if a host must build a custom control.
4. **Sidebar wording.** "Patterns" as Stripe does, or "Payment patterns"? **Decided: "Patterns", with the tier explained on the overview page.**
5. **`TransactionDetail` reference copy.** Revision 1 said the reference was `SelectableText`. That was wrong: it is a `MiddleEllipsisText` (`transactions.dart:451`). It can be neither selected nor copied, and a long reference is elided. Should `TransactionDetail` accept an optional `onCopyReference` that renders `PaymentCopyButton` in `InfoRow.trailing`? **Decided: yes, in Phase 4. A reference people cannot read in full or copy is a support dead end.**
6. **Export `PaymentType`** (D15)? **Decided: yes, as `PaymentType.of(context)` without the extension.**
7. **Button sizes** (D17): add `PaymentButtonWidth.hug` and keep one height, or add Stripe-style heights? **Decided: `hug` only.** Heights below 48 dp break B5, and taller buttons would be a per-screen look. The alternative of no new parameter means documenting the `IntrinsicWidth` wrapper, but the dialog would still need it.
8. **List density variant?** **Decided: no.** Actionable rows keep 48 dp and 12 dp padding; read-only `InfoRow` is already tighter.
9. **`MeterSegment.color`.** Remove it before PR #4 merges, or keep it as an escape hatch? **Decided: remove it.** It is unreleased and lets status tones become categories, which the charts decisions forbid.
10. **Toast restyle** (D22) to the ink overlay? **Decided: yes,** for B2. The alternative is to document that the toast follows the host `SnackBarTheme`, as the example sets it (`themes.dart:119-122`).

## 14. Issue checklist

```markdown
### Design system: foundations, components, patterns (docs/prd-foundation-components.md)

**Phase 0: land what exists**
- [x] PR #3 merged: foundation PRD on main (f74b882)
- [ ] Merge PR #1 (docs/component-catalog) to main (owner)
- [ ] Merge PR #4 (feat/charts-kyc-capture, head 8a78eb1, stacked on #1) to main (owner)
- [x] Owner answers Q1–Q10 (all recommendations accepted, 31 Oct 2026)
- [ ] Record Q1–Q10 in docs/decisions.md

**Phase 1A: type and token API**
- [ ] Export PaymentType (show PaymentType) with of/isLarge/bodyFor (D15, Q6)
- [ ] New PaymentType.firstLineHeight; replace 8 copies
- [ ] New type.tabular(style) / type.reference(style); keep extension internal
- [ ] Deprecate PaymentTheme.amountStyle(large:)
- [ ] Internal tone→icon helper; replace NoticeBanner and toast copies
- [ ] StateMessage padding dartdoc; Contrast brand radius comment; icon family audit

**Phase 1B: foundation pages**
- [ ] Token tables: color, typography, spacing and radius, motion, focus, money
- [ ] New pages: Surfaces, Iconography

**Phase 2A: adopt**
- [ ] VerificationIntro + PaymentConfirmation consent → PaymentCheckbox
- [ ] PaymentMethodPicker `_Radio` → PaymentRadio mark (D12)
- [ ] 11 raw dividers (incl. ActionTileGroup) → PaymentDivider
- [ ] Video loading → PaymentSpinner(size: 32, color: Colors.white)
- [ ] KycCaptureGuide photo errorBuilder (D9)
- [ ] Internal _RowShell for ActionTile, controls, TransactionListItem (D19)

**Phase 2B: Button and Text variants**
- [ ] New PaymentButtonWidth (fill/hug) (D17); action bar docs recommend hug
- [ ] New PaymentButton.autofocus
- [ ] showPaymentConfirmDialog uses PaymentButton (hug + autofocus on cancel when destructive) (D23)
- [ ] New AmountTextVariant; deprecate emphasis; migrate total rows (D24)
- [ ] CountdownText default style (label.tabular)

**Phase 2C: feedback and chart variants**
- [ ] StatusBadge optional icon + 1.6× icon scaling (D20)
- [ ] Toast on kit tokens (D22)
- [ ] NoticeBanner actions rule + debug assert (D21)
- [ ] Charts: dartdoc (B1), token spacing (B2), remove MeterSegment.color (Q9)

**Phase 3A: text fields**
- [ ] PaymentTextField (no obscureText) + docs + tests + specimen
- [ ] PaymentTextField.search + docs + tests + specimen
- [ ] Migrate AmountInput, PromoCodeInput, IdentityForm, TransactionHistory

**Phase 3B: icon button, link and copy**
- [ ] PaymentIconButton (neutral/accent) + docs + tests + specimen; migrate 10 sites (D18)
- [ ] PaymentLink + docs + tests + specimen; migrate 5 inline actions
- [ ] PaymentCopyButton on PaymentIconButton; migrate 2 copy sites

**Phase 4: pattern adoption**
- [ ] History spending summary (ChartModule + PaymentBarChart) in the example (D10)
- [ ] TransactionDetail onCopyReference (Q5)

**Phase 5: docs IA and specimens**
- [ ] Sidebar: Foundations (+Surfaces, Iconography); Components in Stripe groups; Payment flows → Patterns (with redirects)
- [ ] components/action-tile → components/list (redirect)
- [ ] Every component page: closed variant set, which-variant-when table, do/don't pair
- [ ] `_Specimen` gallery entry per component; captures `<component>_variants[_dark|_200]`; rename controls_* (D27)
- [ ] Patterns: loading, empty and error, forms (chart layout exists)
- [ ] New pages: Icon button, Link, Copy button, Text field, Search field, Step indicator, Action bar
- [ ] Overview: Stripe name → kit column; "Not in the kit" table with 21 refusals
- [x] PRD.md §16a amendment row (added 31 Oct 2026)
```
