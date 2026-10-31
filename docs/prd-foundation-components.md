# PRD: Design system — foundations, components, patterns

Date: 31 October 2026 (revision 3, owner decision "full Stripe parity")
Status: **revision 3, for owner review in PR #5.** Revision 2 was approved on 31 October 2026 (Q1–Q10). Later that day the owner decided **full Stripe Apps component parity** (§1). Every revision-2 decision not listed below stays approved. The adaptations D28–D44 and Q11–Q12 are accepted for Phase 1 implementation. Phase 1A foundation APIs are implemented; other items marked **New** remain planned.
Builds on: `PRD.md` §2, §4, §7, §10, §11 and §16a; `docs/decisions.md`; `docs/foundation-plan.md`; the docs catalog in PR #1; the charts and KYC capture work in PR #4; Stripe's component pages (`https://docs.stripe.com/stripe-apps/components/<slug>.md?app-sdk-version=9`, read 31 Oct 2026).
Tracked by: issue #2.

**Overridden by the parity decision** (each is marked "Superseded" where it appears):

| Revision-2 item | Replaced by |
| --- | --- |
| 21 "Refuse" rows; the "Not in the kit" list; the admission clause "'Stripe has it' is not evidence" (for Stripe entries only) | §5: every Stripe entry is Have, Adopt, Extract, In progress or Build. Admission clause (c) (D28) |
| D4 (no DateField, no Select) and Q1 | `PaymentDateField`, `PaymentSelect`; `IdentityFieldSpec` gains field kinds (D36) |
| D5 (PropertyList documented only) | `PaymentPropertyList` (§6.12) |
| D6 (no ButtonGroup) | `PaymentButtonGroup` (§6.12) |
| D7 (no TaskList) | `PaymentTaskList` (§6.12) |
| D8 (no Chip) | `PaymentChip`, `PaymentChipList` (§6.11) |
| D9 (no Img); its `errorBuilder` fix stays | `PaymentImage` (D42) |
| D13 (no FormFieldGroup, TextArea, DateRangePicker) | §6.11 |
| D16 (no `PaymentText`) | `PaymentInline` (D33) |
| D17 (one height) and Q7 | `PaymentSize` on `PaymentButton`, with the D29 hit-area rule |
| D19, in part (no `value` slot, no image leading, no density enum) and Q8 | `PaymentListItem` gains `value`, `image` and `size` (D41). Separate classes per semantics stay |
| D21, in part (no dismiss) | `PaymentBanner.onDismiss` (D38) |
| D26 (no spacing API) | `PaymentSpace` enum (D33) |
| §6.5 "no tristate" checkbox | `indeterminate` (§6.5) |
| §13 non-goals: matching Stripe's list, app shells, page templates, tables, a `Box` layout DSL | §13 (rewritten) |

## Ringkasan

Pemilik proyek melihat sidebar komponen Stripe dan memutuskan **paritas penuh dengan katalog Stripe Apps**. Ke-48 komponen Stripe wajib ada di kit sebagai komponen Tier 1, atau sebagai view/halaman bila sifatnya memang halaman. Setiap komponen memenuhi standar Button (B1–B13) dan punya halaman dokumentasi sendiri. Keputusan ini membatalkan 21 penolakan di revisi 2, beserta D4–D9, D13, D16, D17 dan D26, sebagian D19 dan D21, Q1, Q7 dan Q8, serta klausul "Stripe punya bukan bukti" (lihat tabel di atas). Pembatalan itu hanya berlaku untuk komponen di daftar Stripe. Komponen di luar daftar tetap tunduk pada aturan penerimaan lama.

Status 48 komponen: 10 Have, 5 Adopt, 4 Extract, 4 In progress, 25 Build. Props Stripe menjadi varian. Props khusus web (`css`, `href`, `target`, `aria-*`) diterjemahkan menjadi callback host atau tidak diikuti.

Batas yang tidak berubah:

- Hanya Flutter SDK, tanpa jaringan.
- Host memiliki keputusan, data, clipboard, URL, kamera dan aturan tanggal.
- Tidak ada field password, PIN atau OTP. Itu satu-satunya props Stripe yang ditolak (`TextField type: "password"`).
- `PaymentSignInView` hanyalah layar masuk tanpa input kredensial. Tombolnya memanggil host.

Keputusan utama yang baru:

- **Ukuran tanpa melanggar 48 dp (D29).** Ukuran small/medium/large hanya mengubah tampilan. Kotak layout dan area sentuh tetap ≥ 48 dp.
- **Tabel di ponsel (D30).** Pada lebar < 600 dp atau teks besar, setiap baris tabel menjadi baris daftar. Paginasi dan seleksi berjalan lokal atas baris dari host.
- **View dan halaman (D31).** View dan halaman adalah body tanpa `Scaffold` dan tanpa router. FocusView memakai sheet yang sudah ada.
- **Primitif token (D33).** `PaymentBox`, `PaymentInline`, `PaymentIcon` dan `PaymentImage` hanya menerima enum token.
- **Penamaan (D34).** Format `Payment<NamaStripe>`. Kelas di `main` yang berganti nama mendapat alias `@Deprecated` selama satu rilis minor.

Fase baru menambah Phase 4 (pembangunan paritas: 4A primitif layout, 4B form, 4C konten, 4D view dan halaman), Phase 5 (adopsi di contoh) dan Phase 6 (sidebar Components alfabetis seperti Stripe). Setiap komponen paritas wajib tampil di minimal satu layar contoh dengan pemakaian pembayaran yang nyata.

## 0. Branches and evidence

| Short name | Ref | Contents |
| --- | --- | --- |
| `main` | `f74b882` | Released 0.1.0, plus this PRD (PR #3, merged). |
| `#1` | `docs/component-catalog` @ `ea78224`, open PR #1 | Per-component docs catalog. Public `PaymentCheckbox`, `PaymentRadio`, `PaymentSwitch`, `PaymentTabs`, `PaymentTooltip`, `PaymentSpinner`, `PaymentDivider`. Adds `PaymentButtonVariant.destructive`. |
| `#4` | `feat/charts-kyc-capture` @ `8a78eb1`, open PR #4, base `docs/component-catalog` (stacked on #1) | `PaymentLineChart`, `PaymentBarChart`, `PaymentMeterChart`, `PaymentSparkline`, `ChartModule`, `MoneyFormat.compact`, `showCaptureSourceSheet`, `KycCaptureGuide`, `CaptureFrameOverlay`, the `patterns/chart-layout` docs page, and inspected native catalog screenshots. |
| `#5` | `docs/design-system-prd`, open PR #5 | This PRD, revisions 2 and 3. |

**Release status** (drives D34). `CHANGELOG.md` on `main` says 0.1.0 is "unreleased … Not published". The public surface on `main` is still treated as released: the docs site and the example cite it. Names that exist only on #1 or #4 are unreleased and may change without deprecation.

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
- On revision 2, showing Stripe's component sidebar: "Do we have this? I already told you to check the Stripe docs for the components they have — we need to have them. Update the PRD."

**Decision (31 Oct 2026): full Stripe Apps component parity.**

- All 48 components in Stripe's sidebar must exist in the kit. Revision 2 counted 46; it missed DetailPagePropertyList and DetailPageTable.
- Each one is a Tier 1 component, or a view or page where it is inherently one. Each meets the Button bar (B1–B13) and has its own docs page.
- Stripe's props are the source for variant parity. They are translated per D28.
- The decision overrides the revision-2 refusals for Stripe entries. The admission rule still applies to anything not on Stripe's list.

**The tension.** PRD.md §2 prefers "five to ten components used in a full flow" to "a big catalog without real behavior". It names the biggest risk: "the library becomes only a screenshot gallery". Parity adds 25 Build components and raises that risk directly.

**Mitigation.**

- Every parity component appears in at least one example screen and in its own specimen.
- Every parity component meets B1–B13 before its docs page lists it as Have.
- Each one gets a real payment use where one is natural (table below). §11 Phase 5 builds those screens. B13 is checked against this table.

| Component | Payment use in the example |
| --- | --- |
| `PaymentDataTable` | Settlement statement (date, reference, description, status, amount) |
| `PaymentTable` | Fee schedule per payment method (method, fee, arrival) |
| `PaymentTaskList`, `PaymentOnboardingView` | KYC checklist: identity, documents (sub-tasks: KTP, selfie), review |
| `PaymentDateRangePicker`, `PaymentChip` | History date filter, shown as a closeable active-filter chip next to the status tabs; the applied promo code |
| `PaymentSelect`, `PaymentDateField`, `PaymentFormFieldGroup` | Identity field kinds: occupation (select), date of birth (date), place and date of birth (group) |
| `PaymentSearchField` | Province picker in KYC (38 options), bank picker for transfer instructions |
| `PaymentTextArea`, `PaymentFocusView` | "Report a problem" with a transaction, opened from its detail |
| `PaymentSettingsView` | Payment and notification settings: refund notifications (`PaymentSwitch`), default method (`PaymentRadio`) |
| `PaymentSignInView` | Example sign-in screen; "Sign in" and "Continue with bank app" call the host |
| `PaymentDetailPage`, `PaymentDetailPagePropertyList`, `PaymentDetailPageTable` | Transaction detail: a payment details module and an attempts table (`PaymentAttempt`) |
| `PaymentOverviewPage`, `PaymentPageModule` | Spending overview: `ChartModule` with bar and line charts, recent transactions |
| `PaymentCode` | VA number block with copy; transaction reference |
| `PaymentContextView`, `PaymentFullPageView` | Order context panel beside checkout on wide windows; history as a full page with tabs |
| `PaymentButtonGroup` | Receipt actions (share, download, report) |
| `PaymentPropertyList` | Payment details on status and receipt |
| `PaymentBox`, `PaymentInline`, `PaymentIcon`, `PaymentImage` | Layout and text in every new example screen; promo media, the KYC guide photo |

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
- All 48 Stripe entries ship. The docs overview maps each Stripe name to its kit class. The only Stripe props not mirrored are the web-only ones and the constraint conflicts in D28.

**PRD.md §16a amendment** (revision 2 row added 31 Oct 2026; revision 3 updates it in `PRD.md`):

| Kelompok | Komponen | Batas |
| --- | --- | --- |
| Design system (Fondasi + Tier 1), paritas penuh Stripe Apps (48 komponen) | Token publik `PaymentTheme`, `PaymentType`, `PaymentMotion` dan enum token baru; ke-48 komponen Stripe Apps sebagai Tier 1 atau view/halaman, masing-masing dengan halaman dokumentasi dan standar B1–B13; pola pembayaran wajib memakai komponen Tier 1. Spesifikasi lengkap di `docs/prd-foundation-components.md` | Props Stripe diterima sebagai varian; varian atau komponen di luar daftar Stripe tetap butuh dua pemakaian nyata atau kebutuhan pola Tier 2; tidak ada field password/PIN/OTP/rahasia (`PaymentSignInView` tanpa input kredensial); hanya Flutter SDK, tanpa jaringan; data, keputusan, clipboard, tautan, kamera dan aturan tanggal dijalankan host lewat callback; target sentuh ≥ 48 dp di semua ukuran |

## 2. Definitions

### Layers

| Layer | What it is | Public surface | Docs section |
| --- | --- | --- | --- |
| **Foundations** | Tokens and rules with no widget of their own | `PaymentTheme`, `ToneColors`, `StatusTone`, `PaymentMotion`, `MoneyFormat`, `Money`; `PaymentType` after D15 | `Foundations` |
| **Components** | Tier 1, including the views and pages of §6.13–6.14 | §6 matrices | `Components` (one alphabetical list, §11 Phase 6) |
| **Patterns** | Tier 2 | §7 | `Patterns` |

The layer rule:

- Components read only Foundations.
- **Views and pages** (D31) are Tier 1 components that lay out other components. They take host widgets in named slots and never take a Tier 2 type. A host or the example may put a pattern in a slot.
- Patterns read Foundations and render Components.
- Nothing reads a raw value that a token covers.

### Tier 1: foundation component

A single-purpose building block. Its parameters use only:

- Flutter types.
- Foundation types: `Money`, `StatusTone`, `AmountParseResult`, `HostError`.
- Its own small types: `ChartPoint`, `PaymentNavItem`, `PaymentVideoController`.
- Other Tier 1 components as typed slots, such as `PaymentButton` or `PaymentBanner`. Views, pages and groups use these (D31).

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
- **(c) Stripe parity** (owner decision, 31 Oct 2026; D28). It is one of the 48 Stripe Apps components in §5, or one of their sub-components. Its Stripe props are admitted as variants.

Anything else is refused and listed under "Not in the kit" with the Flutter alternative. For a component or variant that is not on Stripe's list, "Stripe has it" is still not evidence. For Stripe entries, that clause is superseded by (c).

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
| B5 | Every interactive target is at least 48×48 dp at every `PaymentSize`. A visual size may be smaller only under D29: the layout box, which is the hit area, stays ≥ 48 dp | Widget test on `tester.getSize` (pattern in `test/controls_test.dart:80`) for each size; a tap at the box edge outside the visual activates the control |
| B6 | Contrast: text ≥ 4.5:1; control edges and state marks ≥ 3:1, light and dark | `contrast()` helper (`test/controls_test.dart:32`) on resolved token pairs |
| B7 | Semantics: one node per control, with label, role and state (checked, selected, enabled, busy, value). State is never carried by color alone | Widget test with `matchesSemantics` or `getSemantics` |
| B8 | Keyboard: reachable with Tab, activates with Enter or Space. Focus shows as the `PaymentFocusRing` on controls, or as the 2 px `accent` border on text inputs, never both | Widget test in the style of `test/focus_press_test.dart` |
| B9 | Reduced motion: no animation runs when `MediaQuery.disableAnimations` is true | Widget test |
| B10 | Built-in strings live in `PaymentLocalizations`/`KitStrings` in en and id, and are overridable by parameter | Both locales pumped; long Indonesian strings at 200% |
| B11 | Host ownership: no network, no clipboard or platform-channel call, no URL launching, no timers that poll, no secret input | `grep -rn "Clipboard\|dart:io\|http\|launch" lib` stays empty; `pubspec.yaml` dependencies stay `flutter` only |
| B12 | Docs page in catalog order: purpose, specimen, usage, **variants (closed set) and which variant when**, states, do/don't pairs, content guidelines, accessibility, Props table, See also | `pnpm build`, `pnpm check:links`, `pnpm check:snippets` |
| B13 | Used by at least one Tier 2 pattern or example screen (§1 payment-use table), or recorded as owner-approved without one | Inventory, §5; the example screen is cited on the docs page |

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
  - There is **no tone border token**, and none is proposed. Banners and badges are tinted fills without borders.
  - The one tone-colored edge is Stripe's Box `keyline: "critical"`, admitted by parity as **New** `PaymentBox(keyline: PaymentKeyline.critical)` (D33). It draws 1 px of the existing `danger.foreground`, so no new token is needed.

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
- **Weight.** `PaymentType` has no weight modifier. Emphasis comes from choosing `heading` over `label`.
  - Today three Total rows do it with a literal `TextStyle(fontWeight: FontWeight.w600)`: `payment_status.dart:82`, `checkout.dart:212`, `payment_receipt.dart:118`.
  - D24 replaces those with an `AmountText` variant.
  - The one exception is **New** `PaymentInline.weight` (`regular` 400, `semibold` 600, `bold` 700), from Stripe's Inline `fontWeight` (D33). It is for emphasis inside running text only.

**Stripe text roles → kit roles** (`PaymentInline.role`, D35; Q11 confirms):

| Stripe `font` | Kit `PaymentTextRole` | Note |
| --- | --- | --- |
| `title` | `title` | |
| `subtitle`, `heading`, `subheading` | `heading` | One 15/20 w600 heading level in the kit |
| `lead`, `body` | `body` | `lead` is not larger; one body size keeps one display amount per screen |
| `bodyEmphasized` | `body` + `weight: semibold` | |
| `caption` | `caption` | |
| `kicker` | `tag` | |

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
| major | 32 | `spacing * 4` | Largest gap; no kit widget uses it today | — |

**Gaps.**

- `StateMessage` uses `spacing * 2`, not 4 (`interaction.dart:605`). Either the dartdoc or the code is wrong, so Phase 1 aligns the dartdoc to the code (16).
- Charts use literal 16, 8, 4 and 72 (`charts.dart:301, 313, 427, 443`), which fails B2. That is Phase 2.
- ~~No new public spacing API (D26)~~ Superseded by D33. **New** `PaymentSpace` names the six roles above plus `none`, for `PaymentBox` padding and gap. `PaymentTheme.space(PaymentSpace)` resolves a value. There are no other getters. Stripe's seven sizes map as follows: `xxsmall` → `inline`, `xsmall` → `related`, `small` → `block`, `medium` → `group`, `large` → `section`, and both `xlarge` and `xxlarge` → `major`.
- The multiples table is still the contract. A review grep for numeric `EdgeInsets`, `SizedBox(width|height: <number>)` and `spacing: <number>` in `lib/src` enforces it.

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

**New** `PaymentRadius` names these for `PaymentBox` and `PaymentImage` (D33): `none`, `tag`, `control`, `box` (`borderRadius`), `sheet` and `circle`. They map from Stripe's `none`, `xsmall`, `small`, `medium`, `large` and `rounded`.

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

Icons are Material `Icons` from the Flutter SDK, with no icon package. **New** `PaymentIcon` renders them with a `PaymentIconSize` and a `PaymentTextColor` (D33, §6.10).

| `PaymentIconSize` (Stripe) | Size | Use for | Color |
| --- | --- | --- | --- |
| `xsmall` (12) | 14 | Inside a badge (`primitives.dart:531`) or chip. 14, not 12, is the kit's smallest icon | Tone `foreground` |
| `small` (16) | 16 | Inside a `small` button, a small spinner slot, a `kbd` code | Label color |
| `medium` (20), default | 20, scales with text up to 1.6×, first-line centered | Beside 15/20 text: row leading, button icon, banner, status header, state message, chevron, close, copy | `textSecondary`; tone `foreground` for status; `accent` only for an icon that is the action itself (copy) |
| `large` (32) | 32 | Empty-state art, task status in an onboarding sidebar | `textSecondary` |
| `xlarge` (64) | 48 | `PrivacyMask` (`primitives.dart:844`) | `textSecondary` |
| — | 32 / 36 | Video overlay only (`video.dart:281, 325`); documented media exception | `Colors.white` on scrim |

**Semantic set.** **New** `PaymentIcons` exposes the tables below as `static const IconData` constants, and **New** `PaymentIcon.tone(StatusTone)` renders a tone icon. Tone icons are used by `NoticeBanner` (→ `PaymentBanner`), the toast and the **New** `StatusBadge` (→ `PaymentBadge`) default (D20):

| Tone | Icon |
| --- | --- |
| success | `check_circle_outline` |
| warning | `warning_amber_outlined` |
| danger | `error_outline` |
| info, neutral | `info_outline` |

**Fixed meanings:**

| Icon | Meaning |
| --- | --- |
| `chevron_right`; the SDK mirrors it | Opens something |
| `open_in_new` | Leaves the app |
| `close` | Dismiss UI only |
| `copy_rounded` → `check` | Copy, then copied |
| `cloud_off_outlined` | Load failed |
| `search_off` | No matches |
| `hourglass_top` | Busy under reduced motion |
| `lock_outline` | Hidden content |

**Rules.**

- An icon never carries meaning alone. It always sits beside words, or has a tooltip on an icon button.
- One family: outlined. The exceptions `copy_rounded` and `warning_amber_outlined` are audited in Phase 1, and either replaced or recorded.

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

**Dates** (D36). `PaymentLocalizations.formatDateTime` (`payment_localizations.dart:47`) already gives "30 Oct 2026, 14:05" and "30 Okt 2026, 14.05" from en and id month tables. **New** `formatDate(DateTime)` drops the time ("30 Okt 2026"). **New** `dateInputPattern` is the typed-entry pattern, `DD/MM/YYYY` by default (Q12). Dates are calendar dates in the host's zone. The kit does no time-zone or business-day arithmetic.

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

The states vocabulary is: default, hovered, pressed, focused, disabled (with reason), busy, error, selected, indeterminate, pending (a page or module loading host data), empty. Each entry lists only the states that apply. Depth follows the owner's request: Button, Text and List are specified in full, and the rest compactly. Parity components (§6.10–6.14) also give **Stripe → kit** for every Stripe prop and a Dart sketch.

## 5. Inventory: Stripe Apps catalog → kit (48)

Status values. Each Stripe entry has exactly one:

- **Have:** public today; parity adds variants or a rename (§6).
- **Adopt:** Have, but a Tier 2 pattern or another Tier 1 component bypasses it. Adoption comes first.
- **Extract:** a private or duplicated implementation exists in `lib/`.
- **In progress:** on PR #4 (unreleased).
- **Build:** nothing equivalent exists. Admitted by parity, clause (c) of the admission rule.

"Refuse" no longer applies to Stripe entries. Names follow D34: `Payment<StripeName>`. Renamed classes on `main` keep a `@Deprecated` alias for one minor release. The docs slug is the Stripe name in kebab case.

| # | Stripe | Kit class (was) | Status | Evidence / parity gap | Sub-components | Docs page |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Accordion | **New** `PaymentAccordion` + `PaymentAccordionItem` (was `ExpandableSection`) | Have | `interaction.dart:365`; adds `media`, `actions` and a group container | AccordionItem → `PaymentAccordionItem` | `components/accordion` (redirect from `expandable-section`) |
| 2 | Badge | **New** `PaymentBadge` (was `StatusBadge`) | Have | `primitives.dart:503`; adds `PaymentBadge.urgent` (D38) and the D20 icon default | — | `components/badge` (from `status-badge`) |
| 3 | Banner | **New** `PaymentBanner` (was `NoticeBanner`) | Have | `primitives.dart:548`; adds `onDismiss` (D38) | — | `components/banner` (from `notice-banner`) |
| 4 | BarChart | `PaymentBarChart` | In progress | `charts.dart:44`; adds `axis`, `grid`, `showLegend`, `series`, `unit` (D39) | — | `components/bar-chart` |
| 5 | Box | **New** `PaymentBox` | Build | Token-typed layout primitive (D33) | — | `components/box` |
| 6 | Button | `PaymentButton` | Have | `primitives.dart:262`; adds **New** `size` (D29), `width`, `autofocus` | — | `components/button` |
| 7 | ButtonGroup | **New** `PaymentButtonGroup` | Build | Three ad-hoc groups today (`payment_status.dart:400`, `primitives.dart:626`, `transactions.dart:382`) | — | `components/button-group` |
| 8 | Checkbox | `PaymentCheckbox` | Adopt | `controls.dart:13`; raw `CheckboxListTile` at `verification_widgets.dart:111`, `checkout.dart:492`; adds `indeterminate`, `errorText`, `required`, `hiddenElements` | — | `components/checkbox` |
| 9 | Chip | **New** `PaymentChip` + `PaymentChipList` | Extract | Private applied-promo tag plus a separate remove `IconButton` (`payment_extras.dart:477-516`) | ChipList → `PaymentChipList` | `components/chip` |
| 10 | Code | **New** `PaymentCode` | Build | VA number and references are styled ad hoc with `.reference` (`payment_receipt.dart:126`); copy through the extracted `PaymentCopyButton` | — | `components/code` |
| 11 | ContextView | **New** `PaymentContextView` | Build | View body (D31); side-sheet or full-screen host | — | `components/context-view` |
| 12 | CurrencyField | **New** `PaymentCurrencyField` (was `AmountInput`) | Have | `checkout.dart:19`; adds `size`, `description`, a host-allowlisted currency switch | — | `components/currency-field` (from `amount-input`) |
| 13 | DataTable | **New** `PaymentDataTable<T>` | Build | Host rows; local paging and selection; collapses on phones (D30, D43) | DataTableColumn → `PaymentDataColumn<T>`; row actions → `PaymentRowAction<T>`, `PaymentRowActionGroup<T>` | `components/data-table` |
| 14 | DateField | **New** `PaymentDateField` | Build | Date of birth is typed text today (`verification_models.dart:64`) | — | `components/date-field` |
| 15 | DateRangePicker | **New** `PaymentDateRangePicker` | Build | History has no date filter (`kit_strings.dart:219`) | `PaymentDateRange`, `PaymentDatePreset` | `components/date-range-picker` |
| 16 | DetailPage | **New** `PaymentDetailPage` | Build | Page layout (D31); content stays Tier 2 (`TransactionDetail`, `transactions.dart:378`) | PageModule → `PaymentPageModule`; BreadcrumbLink → `PaymentBreadcrumb` | `components/detail-page` |
| 17 | DetailPagePropertyList | **New** `PaymentDetailPagePropertyList` | Build | Module with pending, empty and error states | DetailPagePropertyListItem → `PaymentDetailProperty` | `components/detail-page-property-list` |
| 18 | DetailPageTable | **New** `PaymentDetailPageTable<T>` | Build | Module wrapping `PaymentDataTable` | — | `components/detail-page-table` |
| 19 | Divider | `PaymentDivider` | Adopt | `primitives.dart:487`; 11 raw dividers (`transactions.dart:318, 462`, `payment_status.dart:74, 418, 440`, `checkout.dart:206, 276`, `payment_receipt.dart:112, 159`, `interaction.dart:157`, `video.dart:367`). Stripe has no props | — | `components/divider` |
| 20 | FocusView | **New** `PaymentFocusView` + `showPaymentFocusView` | Build | Composes `showPaymentSheet` / `showPaymentSideSheet` (`sheets.dart:145, 180`) | ConfirmCloseMessages → `PaymentConfirmClose` | `components/focus-view` |
| 21 | FormFieldGroup | **New** `PaymentFormFieldGroup` | Build | — | — | `components/form-field-group` |
| 22 | FullPageView | **New** `PaymentFullPageView` | Build | Body for the `AdaptiveNavShell` content area (`navigation.dart:244`) | — | `components/full-page-view` |
| 23 | Icon | **New** `PaymentIcon` | Build | Raw `Icon` with literal sizes in every file; the tone→icon map is written twice (§3.6) | `PaymentIcons` constants | `components/icon` |
| 24 | Img | **New** `PaymentImage` | Build | `KycCaptureGuide` `Image` has no `errorBuilder` (`capture_widgets.dart:260`) | — | `components/image` |
| 25 | Inline | **New** `PaymentInline` | Build | Replaces D16 (D33) | `PaymentSpan` | `components/inline` |
| 26 | LineChart | `PaymentLineChart` | In progress | `charts.dart:18`; same additions as BarChart | — | `components/line-chart` |
| 27 | Link | **New** `PaymentLink` | Extract | Five private `TextButton`s (§6.1) | — | `components/link` |
| 28 | List | **New** `PaymentList` + `PaymentListItem` (were `ActionTileGroup`, `ActionTile`) | Adopt | `interaction.dart:22, 145`; raw divider in the group (`:157`); adds `value`, `image`, `size`, `onAction` (D41) | ListItem → `PaymentListItem` | `components/list` (from `action-tile`) |
| 29 | Menu | **New** `PaymentMenu` (was `ActionMenu`) | Have | `interaction.dart:188`; adds groups and a custom trigger | MenuItem → `PaymentMenuItem` (was `ActionMenuEntry`); MenuGroup → `PaymentMenuGroup` | `components/menu` (from `action-menu`) |
| 30 | MeterChart | `PaymentMeterChart` | In progress | `charts.dart:255`; adds `onSegmentPressed`, `unit` | — | `components/meter-chart` |
| 31 | OnboardingView | **New** `PaymentOnboardingView` | Build | Composes `PaymentTaskList`; the example wraps `VerificationIntro` (`verification_widgets.dart:16`) | Tasks → `PaymentTaskListItem` | `components/onboarding-view` |
| 32 | OverviewPage | **New** `PaymentOverviewPage` | Build | Page layout; hosts `ChartModule` | PageModule → `PaymentPageModule` | `components/overview-page` |
| 33 | PropertyList | **New** `PaymentPropertyList` | Build | Today `PaymentSection` + `InfoRow` by convention (`primitives.dart:141, 650`) | PropertyListItem → `PaymentPropertyListItem` | `components/property-list` |
| 34 | Radio | `PaymentRadio<T>` | Adopt | `controls.dart:91`; private `_Radio` at `checkout.dart:393`; adds `errorText`, `required`, `hiddenElements` | — | `components/radio` |
| 35 | SearchField | **New** `PaymentSearchField<T>`; `PaymentTextField.search` stays the list filter | Extract | History search decoration (`transactions.dart:330-360`); Stripe's SearchField is a combobox (D37) | `PaymentSearchOption<T>` | `components/search-field` |
| 36 | Select | **New** `PaymentSelect<T>` | Build | — | Option → `PaymentSelectOption<T>` | `components/select` |
| 37 | SettingsView | **New** `PaymentSettingsView` | Build | — | — | `components/settings-view` |
| 38 | SignInView | **New** `PaymentSignInView` | Build | No credential inputs (D32) | — | `components/sign-in-view` |
| 39 | Sparkline | `PaymentSparkline` | In progress | `charts.dart:68`; adds `inspectable`, `series` | — | `components/sparkline` |
| 40 | Spinner | `PaymentSpinner` | Adopt | `primitives.dart:445`; raw indicator at `video.dart:299`; `size` becomes `PaymentSize`, adds `delay` | — | `components/spinner` |
| 41 | Switch | `PaymentSwitch` | Have | `controls.dart:162`; adds `errorText`, `required`, `hiddenElements`. Gains a real use in the settings example | — | `components/switch` |
| 42 | Table | **New** `PaymentTable` | Build | Static composition; collapses on phones (D30) | TableHead/Body/Footer → `head`, `rows`, `footer` slots; TableRow → `PaymentTableRow`; TableHeaderCell → `PaymentTableHeaderCell`; TableCell → `PaymentTableCell` | `components/table` |
| 43 | Tabs | `PaymentTabs` | Have | `controls.dart:333`; adds `size`, `fitted`, per-tab `disabled` | Tab → **New** `PaymentTab`; TabList → `PaymentTabs`; TabPanels/TabPanel → **New** `PaymentTabPanels` | `components/tabs` |
| 44 | TaskList | **New** `PaymentTaskList` | Build | — | TaskListItem → `PaymentTaskListItem`; status → `PaymentTaskStatus` | `components/task-list` |
| 45 | TextArea | **New** `PaymentTextArea` | Build | Built on `PaymentTextField` | — | `components/text-area` |
| 46 | TextField | **New** `PaymentTextField` | Extract | Four copies: `checkout.dart:102-137`, `transactions.dart:330-360`, `payment_extras.dart:562-590`, `verification_widgets.dart:234-282` | — | `components/text-field` |
| 47 | Toast | **New** `showPaymentToast` → `PaymentToastController` (was `showPaymentSnackBar`) | Have | `interaction.dart:326`; adds `pending`, `update`, `dismiss` (D38); ink restyle (D22) | — | `components/toast` |
| 48 | Tooltip | `PaymentTooltip` | Have | `controls.dart:450`; adds `placement`, `type`, `delay` (D40) | — | `components/tooltip` |

### Counts (48 Stripe entries)

| Status | Count | Entries |
| --- | --- | --- |
| Have | 10 | Accordion, Badge, Banner, Button, CurrencyField, Menu, Switch, Tabs, Toast, Tooltip |
| Adopt | 5 | Checkbox, Divider, List, Radio, Spinner |
| Extract | 4 | Chip, Link, SearchField, TextField |
| In progress | 4 | BarChart, LineChart, MeterChart, Sparkline |
| Build | 25 | Box, ButtonGroup, Code, ContextView, DataTable, DateField, DateRangePicker, DetailPage, DetailPagePropertyList, DetailPageTable, FocusView, FormFieldGroup, FullPageView, Icon, Img, Inline, OnboardingView, OverviewPage, PropertyList, Select, SettingsView, SignInView, Table, TaskList, TextArea |

### Kit-specific (no Stripe entry; the admission rule applies)

| Kit | Status | Evidence | Docs page |
| --- | --- | --- | --- |
| **New** `PaymentIconButton` | Extract (D18) | 10 `IconButton` sites, 3 treatments (§1) | `components/icon-button` |
| **New** `PaymentCopyButton` | Extract (D3) | `_CopyButton` at `payment_status.dart:152`; inline `IconButton` at `payment_receipt.dart:136` | `components/copy-button` |
| `showPaymentConfirmDialog` | Adopt (D23) | `interaction.dart:259`; own buttons at `:290-314` | `components/dialog` |
| `PaymentSheet`, `PaymentSheetHeader`, `showPaymentSheet`, `showPaymentSideSheet` | Have; the base of `PaymentFocusView` | `sheets.dart:14, 90, 145, 180` | `components/sheets` |
| `PaymentSection` | Have | `primitives.dart:650` | `components/section` |
| `AdaptiveNavShell`, `NavSidebar` | Have; the host of `PaymentFullPageView` | `navigation.dart:49, 244` | `components/navigation` |
| `PaymentStepIndicator` | Have | `payment_extras.dart:260` | `components/step-indicator` |
| `AmountText`, `InfoRow`, `MiddleEllipsisText`, `CountdownText`, `PrivacyMask` | Have | `primitives.dart:15, 141, 63, 858, 825` | one page each |
| `PaymentActionBar` | Have | `payment_extras.dart:18` | `components/action-bar` |
| `PaymentVideoPlayer`, `PaymentVideoController` | Have | `video.dart:97` | `components/media` |
| `StatusHeader`, `StatusBand`, `LoadingSkeleton`, `StateMessage` | Have | `primitives.dart:700, 761`; `interaction.dart:498, 573` | one page each |
| `ChartModule` | In progress | `charts.dart:349` | `patterns/chart-layout` |

### Internal foundations (not exported)

| Kit | Status | Evidence |
| --- | --- | --- |
| `PaymentType` | Internal → public, approved (D15, Q6) | `foundation/payment_type.dart`; not in `lib/flutter_ui_payment.dart` |
| `PaymentFocusRing`, `PaymentPressScale` | Internal (Q3) | `foundation/focus_ring.dart`, not exported |
| `ChartPainter`, `MeterPainter`, hatch painter | Internal | `charts/chart_painters.dart:9, 257`, `foundation/hatch.dart` |

**New shared types** (D29, D33, §9 rule 4): `PaymentSize` (`small`, `medium`, `large`), `PaymentWidth` (`fill`, `hug`; replaces the unimplemented `PaymentButtonWidth`), `PaymentSpace`, `PaymentRadius`, `PaymentTextRole`, `PaymentTextColor`, `PaymentFontWeight`, `PaymentIconSize`, `PaymentFieldPart` (`label`, `description`, `error`), `PaymentChartAxis`, `PaymentChartUnit`.

## 6. Component specs

### 6.1 Button family

The family has three members, each with one press rule:

| Member | Shape | Press | Status |
| --- | --- | --- | --- |
| `PaymentButton` | Labeled; `PaymentSize` 36 / 48 / 56 visual in a ≥ 48 dp box (D29) | No scale (pressed layer) | Have |
| **New** `PaymentIconButton` | 48×48 icon-only | 0.96 scale | Extract |
| **New** `PaymentLink` | Inline text | 0.96 scale | Extract |

Which one:

```
Is it the action that ends or advances the screen, or an alternative to it? → PaymentButton
Is it a single icon whose meaning is common (close, copy, more, clear, play)? → PaymentIconButton (tooltip required)
Is it inline with text, or opens something secondary (policy, "Edit", "Why this ad")? → PaymentLink
Is it a row in a list?                                                      → PaymentListItem (§6.3)
```

#### PaymentButton (`primitives.dart:262`)

**Use / not.**

- Use it for actions: pay, continue, retry, check status, share, remove.
- Not for navigation inside text. That is `PaymentLink`.
- Not for icon-only actions. That is `PaymentIconButton`.
- Not for list rows. That is `PaymentListItem`.

**Anatomy.**

| Part | Detail |
| --- | --- |
| Container | Fill, outline or none |
| Leading icon | Optional, 20 px, spacing 8 |
| Label | `heading` 15/20 w600, centered, wraps at large text |
| Busy indicator | `PaymentSpinner` 16 for small and 20 for medium/large in the label color. The label keeps its space (`:326-347`) |
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

**Stripe → kit.**

| Stripe prop | Kit |
| --- | --- |
| `type`: primary / secondary / destructive | `variant`: `primary`, `secondary`, `destructive`; plus the kit-specific `quiet` (kept: four call sites) |
| `size`: small / medium / large | **New** `size: PaymentSize` (D29) |
| `width`, `alignX` | **New** `width: PaymentWidth.fill / .hug`; alignment is the parent's job |
| `pending` | `busy` (exists), or a `Future` from `onPressed` |
| `disabled` | `onPressed: null` |
| `onPress` | `onPressed` |
| `href`, `target` | Not mirrored. The host navigates in `onPressed`. An external destination is a `PaymentLink(external: true)` |
| Icon inside `children` | `icon` (leading) |

**Sizes** (**New** `size: PaymentSize`, D29; supersedes D17 and Q7). The size changes only the drawn container. The layout box, and so the hit area, is never below 48×48 dp.

| `PaymentSize` | Visual height | Side padding | Label | Icon | Use when |
| --- | --- | --- | --- | --- | --- |
| `small` | 36 (inside a 48 dp box) | 12 | `heading` | `PaymentIconSize.small` (16) | Inside a module header, a table row, a chip row; never the screen's main action |
| `medium` (default) | 48 (today's look, `:350`) | Material default (24; quiet 12), today's look | `heading` | 20 | Everything else |
| `large` | 56 | 24 | `heading` | 20 | The one primary action of a full-screen view on wide layouts (sign-in, onboarding) |

- **How B5 is preserved.** A `small` button lays out at 48 dp tall and at least 48 dp wide. The 36 dp container is centered inside it, as with Material's `MaterialTapTargetSize.padded`. A tap anywhere in the 48 dp box activates it, and the focus ring follows the visual container. In a row, two `small` buttons sit 8 dp apart visually, while their boxes still never overlap.
- The label role is the same at every size, so B4 (200%) behaves the same way: the label wraps and the container grows.
- **Width.** Today the button always fills its parent (`SizedBox(width: double.infinity)`, `:430-433`).
  - Three call sites fight that. `PaymentActionBar` wraps it in `IntrinsicWidth` with min 112 and max 240 (`payment_extras.dart:120-127`). `StateMessage` caps it at `maxWidth: 280` (`interaction.dart:633-634`). The dialog avoids `PaymentButton` entirely.
  - **New** `width: PaymentWidth.fill | PaymentWidth.hug`, default `fill`. `hug` sizes the button to its label, with min width 112. The label wraps rather than truncates.

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
- **No error state.** Errors belong to a `PaymentBanner` or the field.

**Icon.**

- Leading only (`icon`, `:280, 319-322`). Use it when the icon adds meaning (delete, download), not on every button.
- **No trailing icon.** An external destination is a `PaymentLink(external: true)`.

**Groups.** These rules are now enforced by **New** `PaymentButtonGroup` (§6.12; D6 superseded):

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

- (1) **New** `PaymentWidth`. The dialog uses it (D23). `PaymentActionBar` takes a host `action: Widget` (`payment_extras.dart:18-30`), so it cannot make that widget hug. The bar keeps its 112–240 constraint and `IntrinsicWidth` wrapper for compatibility, and its docs tell hosts to pass `width: PaymentWidth.hug`.
- (2) **New** `bool autofocus = false`. The dialog needs it to keep focusing the safe choice first (`interaction.dart:291, 302`; decisions.md, "Destructive confirmations put initial focus on the safe choice").
- (3) `StateMessage` keeps `fill` inside its 280 cap.
- (4) **New** `PaymentSize size = PaymentSize.medium`. `medium` is today's look, so no call site changes.

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
- **Variants:** **New** `PaymentLinkVariant`, mirroring Stripe's `type` (it replaces the unimplemented `PaymentLinkEmphasis`). Nothing else exists.

  | Value (Stripe) | Style | Use when | Where today |
  | --- | --- | --- | --- |
  | `primary` (default) | `heading` in `accent` | An action the user is likely to take | `verification_widgets.dart:100, 537`, `promo.dart:210`, `video.dart:386` |
  | `secondary` | `caption` in `textSecondary`, underlined | Disclosure next to content | `promo.dart:104` |

  Plus `external: bool` (Stripe `external`). It adds the trailing icon and the `opensExternally` hint. Stripe's `href`, `target` and `rel` become the host's `onPressed`. Stripe's `width` is not mirrored, because a link hugs its label.

- **States:** default, pressed, focused, disabled (Stripe `disabled` → `onPressed: null`).
- **Gap.** Five private `TextButton`s; two lack the ring (`verification_widgets.dart:100`, `video.dart:386`).

### 6.2 Text

~~D16, no `PaymentText` widget~~ Superseded by D33: Stripe's Inline ships as **New** `PaymentInline` (§6.10). Text is consumed in two ways:

- **`PaymentInline`** for any text that needs a role, color or weight token. This is the Stripe-parity text component.
- **Styles** (`PaymentType.of(context).caption`, D15) when a host builds its own widget.

The text components with behavior stay:

| Component | Behavior that justifies a widget |
| --- | --- |
| `AmountText` | Formats `Money`, speaks it, clamps and scales down instead of clipping |
| `MiddleEllipsisText` | Keeps both ends of an ID or file name, speaks the full text |
| `CountdownText` | Host clock, tabular, spoken remaining time, single elapsed callback |

#### AmountText (`primitives.dart:15`)

- **Use / not.** Use for every displayed `Money`. Not for amounts the user types (that is `PaymentCurrencyField`) or axis labels (`MoneyFormat.compact`).
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

Where it appears: `ActionTile` (`interaction.dart:71-131`, → **New** `PaymentListItem`), `_ControlRow` (`controls.dart:240-323`), and the shells of `TransactionListItem` (`transactions.dart:155-163`) and `ExpandableSection` (→ **New** `PaymentAccordionItem`).

The family members stay separate classes because their **semantics differ** (button, checked, toggled, read-only). One class with a mode enum would give one widget four semantics contracts. This part of D19 is kept.

**Stripe → kit** (D41; supersedes D19's refusals and Q8):

| Stripe | Kit |
| --- | --- |
| `List` | **New** `PaymentList` (was `ActionTileGroup`); full-bleed hairlines between rows |
| `List.onAction(id)` | `PaymentList.onAction: ValueChanged<String>?`; each item's `id` is passed. An item's own `onPressed` wins |
| `ListItem.title` / `secondaryTitle` | `title` / `secondaryTitle` (was `subtitle`) |
| `ListItem.value` | **New** `value: Widget?`, end-aligned on the first line; typically `AmountText` or `PaymentInline` |
| `ListItem.icon` / `image` | `icon: IconData?` / **New** `image: PaymentImage?` (40×40, radius `control`); `image` overrides `icon`, as in Stripe |
| `ListItem.size`: default / large | **New** `size: PaymentListItemSize.standard / .large` |
| `ListItem.id` | `id: String?` |
| kit-only | `destructive`, `disabledReason`, `trailing` (kept) |

| Member | Class | Semantics | Leading | Trailing | Use when |
| --- | --- | --- | --- | --- | --- |
| Navigation row | `PaymentListItem(onPressed)` | button | Icon or image (optional) | Chevron, default when tappable and no `trailing` (`interaction.dart:117-131`) | Opens a screen or sheet |
| Value row | `PaymentListItem(value: …)` | button, or read-only when there is no `onPressed` | Icon or image | `value` | A settings row showing its current value; a merchant with its amount |
| Action row | `PaymentListItem(onPressed, trailing: …)` | button | Icon | Host widget; keeps its own size | Runs something; trailing is a 48 dp control |
| Destructive row | `PaymentListItem(destructive: true)` | button | Danger icon | Chevron | Irreversible; confirm with a dialog first |
| Disabled row | `PaymentListItem(onPressed: null, disabledReason:)` | button, disabled | Muted icon | none | Visible but unavailable; the reason replaces `secondaryTitle` |
| Toggle row | `PaymentSwitch` | toggled | none | Switch at the end (gap 16) | Takes effect immediately |
| Multi-select row | `PaymentCheckbox` | checked | Box mark | none | Consent, opt-in; applied by a button |
| Single-select row | `PaymentRadio<T>` | checked, mutually exclusive | Ring mark | none | 2 to about 5 options, all visible |
| Property row | `InfoRow` / `PaymentPropertyListItem` | read-only, merged | none | Value; optional `trailing` action (copy) | Label/value facts (§6.12) |

Which row:

```
Can the user act on the row?
 ├── No  → PaymentPropertyList (label/value facts) or PaymentListItem without onPressed (a titled item with a value)
 └── Yes
      ├── Does it change a setting immediately?      → PaymentSwitch
      ├── Is it one of several exclusive options?    → PaymentRadio (≤ ~5) / PaymentSelect (more)
      ├── Is it an agree/opt-in applied later?       → PaymentCheckbox
      └── Default (opens or runs something)          → PaymentListItem
```

**Variants.** `PaymentListItem`: `size`, `value`, `icon` or `image`, `destructive`, `disabledReason`, `trailing`. Nothing else exists.

- **Still refused:** embedding a switch, checkbox or radio in `value` or `trailing`. That creates two tap targets and two semantics nodes. Stripe lists the same restriction ("Unsupported components").
- `ActionTile` and `ActionTileGroup` stay as `@Deprecated` wrappers for one minor release (D34), because `onTap` and `subtitle` were renamed.

**Size** (Stripe `size`). There is still no compact density, because Stripe has none and it would break B5.

| **New** `PaymentListItemSize` | Min height | Title | Leading | Use when |
| --- | --- | --- | --- | --- |
| `standard` (default) | 48, padding 12 | `label` | 20 icon | Settings, actions, menus of rows |
| `large` | 64, padding 12 | `heading` | 40 image or 20 icon | Rows with an image or a two-line identity (bank, merchant) |

**Grouping.**

- `PaymentList` puts a full-bleed 1 px `outline` hairline between rows and no box around them, like `ActionTileGroup` today (`interaction.dart:145`).
- **Inset dividers are refused.** The rows have no side padding, and icons are optional per group, so an inset would align to nothing consistent.
- The group currently draws a raw `Divider` (`:157`). Adopt `PaymentDivider()`.

**Icon rule.** Give every row in a group an icon, or none, so the titles align.

**Property list.** **New** `PaymentPropertyList` (§6.12) wraps `PaymentSection` and `InfoRow` (D5 superseded). Its rows are `InfoRow` (`primitives.dart:141`), whose variants are:

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
- `PaymentBadge` tags in a `Wrap`.

It is not a `PaymentListItem`, because its layout (an amount column and tags) is history-specific. The **New** internal helper `_RowShell` (Phase 2) gives `PaymentListItem`, `_ControlRow` and `TransactionListItem` one implementation of the shared metrics, so the family cannot drift.

### 6.4 Feedback

| Component | Use / not | Variants (closed; Stripe → kit) | States | Tokens | Gap → change |
| --- | --- | --- | --- | --- | --- |
| **New** `PaymentBadge` (was `StatusBadge`, `primitives.dart:503`) | Read-only state of an item / not for messages (Banner) or actions | `tone`: neutral→`neutral`, info→`info`, positive→`success`, negative→`danger`, warning→`warning`. **urgent → New `PaymentBadge.urgent(label)`**: solid `danger.foreground` fill, `surface` text, `error_outline` icon (D38). Pending and unknown share `warning` and differ by icon and word (`transactions.dart:81, 84`) | static | Fill `tone.container` (urgent: `danger.foreground`), radius `tag`, padding 8/4, icon `PaymentIconSize.xsmall`, `tag` text | D20: optional `icon` with the §3.6 tone default; icon scales to 1.6×. Rename with alias (D34) |
| **New** `PaymentBanner` (was `NoticeBanner`, `:548`) | Persistent inline message about a problem or required step / not the normal path, not transient feedback (Toast) | `tone`: default→`neutral` or `info`, caution→`warning`, critical→`danger`; `success` is kit-only. `title`, `message` (Stripe `description`), `actions`, **New** `onDismiss`, `announce` | static; announced when `announce`; dismissed (the host removes it) | Fill `tone.container`, radius `control`, padding 12, title `heading` in `tone.foreground`, message `bodyFor`, icon 20 (1.6×); dismiss is a `PaymentIconButton` (`close`, "Hide banner") | D21 in part superseded: `onDismiss` reports intent; the kit never hides the banner itself. Rule: no `onDismiss` on a `danger` banner that blocks the flow. `actions` stay `PaymentLink` or `hug` `PaymentButton` (asserted) |
| Toast: **New** `showPaymentToast` → `PaymentToastController` (was `showPaymentSnackBar`, `interaction.dart:326`) | Short outcome of an action the user just took ("Copied", "Refund requested") / not blocking errors (Banner) | Stripe `type`: success→`tone: success`, caution→`tone: warning`, none→`neutral`; **pending → New `pending: true`** (small spinner instead of the icon, no timeout). `actionLabel` + `onAction` | shown; updated (`update(message, {tone, pending})`); dismissed (`dismiss()`); auto-hides after 4 s, or 6 s with an action, never while pending. With `MediaQuery.accessibleNavigation`, a toast with an action waits for the user (Flutter `SnackBar` behavior) | D22 ink: fill `textPrimary`, text and icon `surface`, `label`, radius `control` | Stripe's 30-character limit is a content rule, not an assert, because Indonesian runs longer (B10). `showPaymentSnackBar` stays as a deprecated wrapper (D34) |
| `StatusHeader` / `StatusBand` (`:700, 761`) | Top of a status screen / not inside lists | `tone` ×5 × `hatched` (unknown outcome) | static | Band 6 px, radius 3, `tone.foreground`; title `heading` in tone; icon 20 (1.6×) | none |
| `StateMessage` (`interaction.dart:573`) | Replaces a list or module that is empty, has no matches, or failed / not page-level errors with no content (host) | By content and tone, see below | static; `danger` announces | Icon `textSecondary` 20 (1.6×), title `heading`, message `body` in `textSecondary`, action secondary `PaymentButton` ≤ 280 | Dartdoc says `major` (32) padding; the code uses 16 (§3.3) |
| `LoadingSkeleton` (`:498`) | Content loading into a known shape / not an action running (busy button) or an unknown wait (Spinner) | `rows`, `leading`. Shapes: list row and text block. **New** `table` shape (header bar + rows) for the table components' `pending` state | static (no shimmer) | `surfaceMuted`, radius `tag`, bars 14/10 | `table` shape is needed by §6.12 |
| `PaymentSpinner` (`primitives.dart:445`) | Unknown-length wait with no shape / not inside a button (use `busy`) | Stripe `size` → **New** `size: PaymentSize`: `small` 16 (chips, small buttons, a pending toast), `medium` 20 (default, inline), `large` 32 (standalone block). Stripe `delay` → **New** `delay: Duration` (default zero): the spinner stays invisible until the delay passes, so fast waits do not flash | waiting (delay), spinning; still hourglass under reduced motion | `textSecondary` default; stroke 12% of size | `double size` → `PaymentSize` (unreleased #1; no deprecation). The delay is one `Timer`, canceled on dispose; it never polls (B11). Adopt in `video.dart:299` |

**StateMessage variants.** These are by content. There is no enum, and nothing else exists:

| Case | Tone | Icon | Action | Example |
| --- | --- | --- | --- | --- |
| Empty | `neutral` | Domain icon | none, or a create action (tables, D43) | History empty `transactions.dart:310` |
| No results | `neutral` | `search_off` | none (clear search is in the field) | `transactions.dart:300` |
| Primary content failed | `danger` (announced) | `cloud_off_outlined` | Retry | History load `transactions.dart:290-291` |
| Secondary module failed | `warning` | `cloud_off_outlined` | Retry | Chart `charts.dart:403-404`, promo `promo.dart:373-374`, a page module (§6.14) |

- The different error tones are a rule, not drift (D25). `danger` is for the screen's main content. `warning` is for a module the user can ignore.
- Offline is not a separate variant. The host maps `HostErrorCategory.network` to copy.

**Which badge.** Did it already happen and fail? → `danger`. Must the user act now, or the payment or verification cannot continue? → `PaymentBadge.urgent` ("Action required"). Waiting on someone else? → `warning`. Default → `neutral`.

### 6.5 Forms

All fields take `size: PaymentSize` (D29). CurrencyField is the exception to the following visual-height table: medium retains its existing amountLarge layout, small subtracts 8 dp and large adds 8 dp. Description and limit helpers add their natural height. The visual heights are 40, 48 (default, today's look) and 56. The layout box is ≥ 48 dp at every size, and the input text stays `input` 16/24 at every size, which avoids iOS zoom. Stripe's `hiddenElements` becomes `hiddenElements: Set<PaymentFieldPart>`: a hidden part is not drawn but stays in semantics. `error` becomes `errorText`, and `invalid` is `errorText != null`.

| Component | Variants (closed; Stripe → kit) | States | Tokens | Gap → change |
| --- | --- | --- | --- | --- |
| `PaymentCheckbox` (`controls.dart:13`) | `description`, `disabledReason` (kit); **New** `indeterminate` (Stripe; mixed mark, spoken "mixed"; a tap sets checked), `errorText`, `required`, `hiddenElements` | unchecked, checked, indeterminate, error, disabled + reason, focused | Checked and indeterminate fill `accent`, mark `onAccent`; unchecked edge 2 px `border`; error icon + caption + unchecked/off edge `danger.foreground` | Adopt in `verification_widgets.dart:111`, `checkout.dart:492`. "No tristate" superseded; first use: the select-all header of `PaymentDataTable` |
| `PaymentRadio<T>` (`:91`) | same slots; **New** `errorText`, `required`, `hiddenElements` | unselected, selected, error, disabled + reason | as today | Adopt its mark in `PaymentMethodPicker` (D12) |
| `PaymentSwitch` (`:162`) | same slots; **New** `errorText`, `required`, `hiddenElements` | off, on (thumb check), error, disabled + reason | as today | Real use: `PaymentSettingsView` example (Q2) |
| **New** `PaymentTextField` (D1) | `size: PaymentSize`; **New** `type: PaymentTextFieldType` (`text`, `number`, `tel`, `url`, `email`, `search`), which sets keyboard, autofill and autocorrect. **No `password`** (D1a, the one refused Stripe value); `label`, `hint` (Stripe `placeholder`), `description` (was `helper`), `errorText`, `required` (spoken, plus an "(optional)" mark on optional fields when a group mixes them), `hiddenElements`, `width: PaymentWidth`, `readOnly`, `enabled`; kit `reference: bool`; named constructor `.search` (list filter, D2 kept) | empty, filled, focused (2 px `accent`), error, description (tone), read-only, disabled | Text `input`; label `label` in `textSecondary`; edge `border`; radius `control` | Sketch in §11 Phase 3A. The unimplemented `PaymentTextFieldSize.body/.amount` is dropped; the amount look is internal to `PaymentCurrencyField` |
| **New** `PaymentCurrencyField` (was `AmountInput`, `checkout.dart:19`) | `size`, `description`, `errorText`, `hiddenElements`; `currency` (kept); **New** `currencies: List<String>?` (Stripe `currencyAllowlist`, host-owned) + `onCurrencyChanged`, which adds a currency `PaymentSelect` before the amount; **New** `padFractionDigits` (Stripe `padAllFractionDigits`). Stripe `fractionDigitOffset` is refused (D28): `Money` is integer minor units | as text field + parse issues (`AmountIssue`) | `amountLarge`, clamped 1.6× | Rebuilt on `PaymentTextField`; `AmountInput` stays a deprecated typedef (D34) |
| **New** `PaymentCopyButton` (D3) | none (built on `PaymentIconButton` `accent`) | idle, pending (single call), copied (check + live "Copied"), failed (words under the icon) | Feedback `tag` in `success`/`danger` foreground | Sketch in §11 Phase 3B |

Which text-field variant:

| Variant | Use when |
| --- | --- |
| `.search` | Filtering a visible list (history) |
| `PaymentSearchField` (§6.11) | Picking one or more values from a long list |
| `PaymentCurrencyField` | Money entry |
| `type: number / tel / email / url` | That kind of value; sets the keyboard |
| `reference: true` | Codes people type digit by digit (promo code) |
| `PaymentTextArea` (§6.11) | More than one line of free text |
| default | Everything else |

There is no password, PIN or OTP variant (D1a).

### 6.6 Navigation and disclosure

| Component | Variants (Stripe → kit) | States | Tokens | Gap |
| --- | --- | --- | --- | --- |
| `PaymentTabs` (`controls.dart:333`) = Stripe TabList | **New** `tabs: List<PaymentTab>` (`label`, `disabledReason`; Stripe Tab `disabled`) replaces `labels` (unreleased #1); `size: PaymentSize` (label `caption` / `label` / `heading`, padding 8 / 12 / 16; target always ≥ 48); **New** `fitted: bool` (equal widths across the bar; default false = hug and scroll, as today); `selectedIndex` + `onSelected` (Stripe `selectedKey` + `onSelectionChange`) | unselected (`textSecondary`), selected (`accent` + 2 px underline, same weight), disabled, pressed (0.96), focused | `label`, padding 12 | **New** `PaymentTabPanels(selectedIndex, children)` = Stripe TabPanels/TabPanel: keeps each panel's state; hidden panels are offstage and not focusable |
| **New** `PaymentMenu` (was `ActionMenu`, `interaction.dart:188`) | **New** `entries: List<PaymentMenuEntry>` with **New** `PaymentMenuItem` (was `ActionMenuEntry`: `label`, `icon`, `onSelected`, `destructive`; **New** `id`) and **New** `PaymentMenuGroup(title, items)`; **New** `trigger` (a `PaymentButton` or `PaymentIconButton`; default `more_vert` icon button); **New** `onAction: ValueChanged<String>?` (Stripe `onAction(key)`) | closed, open (instant) | Floating surface (§3.5); entries `label` 48 dp min, 160 min width; group title `caption`, hairline between groups | Trigger becomes `PaymentIconButton`. Disabled item = `onSelected: null` (Stripe `disabled`) |
| **New** `PaymentAccordion` + `PaymentAccordionItem` (was `ExpandableSection`, `:365`) | Item: `title`, `subtitle`, `initiallyExpanded` (Stripe `defaultOpen`), `onExpandedChanged` (Stripe `onChange`), controlled `expanded`; **New** `media` (a `PaymentIcon` or 40×40 `PaymentImage`; replaces `leading`, which is deprecated); **New** `actions` (≤ 2 `PaymentLink` or `small` `PaymentButton`; more go in a `PaymentMenu`). `PaymentAccordion(children)` = hairlines between items | collapsed, expanded (chevron 150 ms, size 220/150 ms) | `heading` title, ruled bottom | Never holds fees (PRD §8). Disabled items keep their content readable and disable only `actions` (Stripe guidance) |
| `PaymentStepIndicator` (`payment_extras.dart:260`) | none | per step: reached or upcoming; spoken "step n of m" | — | Own docs page |
| `AdaptiveNavShell` / `NavSidebar` (`navigation.dart:244, 49`) | Wide (sidebar) or narrow (drawer) by width | selected, disabled + reason | — | Menu button becomes `PaymentIconButton` with `focusNode`; hosts `PaymentFullPageView` (§6.13) |

### 6.7 Content and layout

| Component | Variants | Rules |
| --- | --- | --- |
| `PaymentDivider` (`primitives.dart:487`) | Stripe Divider has no props. Kit `height`: **1** (between rows), **16** (inside a section), **24** (between sections). Thickness 1, color `outline`, full bleed. Nothing else | Decorative, so screen readers skip it |
| `PaymentSection` (`:650`) | `title?`, `trailing?` (an "Edit" `PaymentLink`) | Flat only; title `heading` with header semantics. Boxed surfaces are `PaymentBox` (§6.10) |
| `PaymentTooltip` (`controls.dart:450`) | **New** `placement: PaymentTooltipPlacement` (`side`: top, bottom, start, end × `align`: center, start, end), the 12 Stripe placements; flips when it does not fit. **New** `type: PaymentTooltipType.label / .description`: `label` names the trigger (it becomes the trigger's semantic label), `description` adds detail (a semantic hint). **New** `delay: Duration` (Stripe `delay`, default 500 ms) | Built on `OverlayPortal` from the SDK, because Flutter's `Tooltip` places only above or below (D40). Ink fill `textPrimary`, `caption` in `surface`, radius `control`. No interactive content inside (Stripe rule). Never the only place for a fee or error |
| `PrivacyMask` (`primitives.dart:825`) | `obscured` on/off | `surface` cover, `lock_outline` `PaymentIconSize.xlarge`, spoken "content hidden" |
| `PaymentActionBar` (`payment_extras.dart:18`) | With or without `total`; `updating` | Ruled top, total `amountLarge` clamped 1.6×; hosts pass a `hug` button; the bar keeps its 112–240 wrapper; stacks at large text |
| `PaymentVideoPlayer` (`video.dart:97`) | none | Scrim exceptions documented (§3.0); controls become `PaymentIconButton`/`PaymentLink`; loading uses `PaymentSpinner(size: PaymentSize.large, color: Colors.white)` on the black picture area (`video.dart:365`) |

### 6.8 Overlays

| Component | Variants (closed) | States | Tokens | Gap |
| --- | --- | --- | --- | --- |
| Sheet: `showPaymentSheet` (`sheets.dart:145`), `showPaymentSideSheet` (`:180`), `PaymentSheet` (`:90`), `PaymentSheetHeader` (`:14`) | **Placement:** bottom (content height, drag handle) or side (end edge, ≤ 420 or 88% width). **Header:** with or without close. **Footer:** optional, ruled | open, closing, not dismissible | `surface`, top radius 12, elevation 0, 280/200 ms `drawer`, title `title` | Close becomes `PaymentIconButton`. The base of `PaymentFocusView` (§6.13), which adds Stripe's size and close confirmation |
| Dialog: `showPaymentConfirmDialog` (`interaction.dart:259`) | `destructive: bool` | open, resolved true/false | `surface`, radius `sheet`, title `title`, message `bodyFor` in `textSecondary` | D23: actions become two `hug` `PaymentButton`s (2B), then a `PaymentButtonGroup` (4C). Also serves `PaymentFocusView.confirmClose` |

### 6.9 Charts (PR #4)

**Stripe → kit** (D39). These are unreleased, so they change without deprecation.

| Stripe prop | Kit |
| --- | --- |
| `data`, `x`, `y` | `points: List<ChartPoint>` (host-owned label and `Money`; the kit computes no totals) |
| `axis`: x / y / both / none | **New** `axis: PaymentChartAxis` (default `both`) |
| `grid`: x / y / both / none | **New** `grid: PaymentChartAxis` (default `y`) |
| `legend` | **New** `showLegend` (line and bar, when there is more than one series); Meter `legendEnabled` → `showLegend` (exists) |
| `tooltip` | `inspectable` (exists on line and bar; **New** on sparkline) |
| `color`, `z` (series) | **New** `series: List<PaymentChartSeries>`, at most 3 (2 on sparkline). Series differ by the accent→surface ramp **and** a dash pattern, never by status tone (decisions.md, charts). The first use is "this month vs last month" in the spending overview |
| `format`, `tickFormat`; Meter `unitFormat` | **New** `unit: PaymentChartUnit` (`money`, `percent`, `number`). `money` (default) reads `ChartPoint.value`; `percent` and `number` read **New** `ChartPoint.measure` (a host-computed `num`). Money axes use `MoneyFormat.compact`; inspection uses `MoneyFormat.format` |
| Meter `onSegmentClick` | **New** `onSegmentPressed`, exposed through the legend rows (48 dp list items), because a meter segment can be thinner than 48 dp |

| Component | Variants / parameters (closed) | States | Encoding |
| --- | --- | --- | --- |
| `PaymentLineChart` (`charts.dart:18`) | `zeroBased`, `inspectable`, **New** `axis`, `grid`, `showLegend`, `series`, `unit` | per point: settled, pending, unknown, missing | Settled solid; pending dashed or outlined; unknown hatched or dotted; missing is a gap; never pending-looking unknown (decisions.md) |
| `PaymentBarChart` (`:44`) | `inspectable`, same **New** set; series are grouped bars | same | same |
| `PaymentSparkline` (`:68`) | `width`/`height` (default 80×24); **New** `inspectable` (off by default; when on, the layout box grows to 48 dp tall under D29), `series` ≤ 2 | same | 1.5 px stroke |
| `PaymentMeterChart` (`:255`) | `showLegend`; ≤ 5 segments; **New** `onSegmentPressed`, `unit` | per segment status | Accent→surface ramp at ≥ 3:1 (`chart_geometry.dart:99-114`); tones never categories |
| `ChartModule` (`:349`) | Height `compactHeight` 180 / `featuredHeight` 320 (`:367-368`); `showHeadline`; `delta` + `deltaTone`; `trailing` | `ChartState`: loading, ready, empty, error (constant plot height) | Headline `amountLarge` (host `Money`), caption + delta in `caption` |

**Which chart:**

| Chart | Use when |
| --- | --- |
| Bar | Amounts per period (spending per month); grouped series to compare two periods |
| Line | One trend over time, or up to three compared trends |
| Sparkline | A trend beside a number, no reading of values |
| Meter | Parts of one total |

**Gaps (B1, B2).**

- No public chart class or parameter has dartdoc.
- The meter legend uses literal 16/8/4 spacing and a 10 px swatch (`charts.dart:301-313`). The headline box uses `scale(72)` (`:427`).
- `MeterSegment.color` (`chart_models.dart:28, 33`) is removed (Q9). Stripe's Meter has no per-segment color either.

### Parity conventions (§6.10–6.14)

Every component, sub-component and type named in §6.10–6.14 and in the Dart sketches is **New**. Each component is admitted by clause (c) and held to B1–B13. Stripe props are translated in the same way throughout (D28):

| Stripe | Kit |
| --- | --- |
| `children` | `child` or `children`, or typed slots (`List<PaymentButton>`) where Stripe expects a specific component |
| `onPress`, `onAction`, `onChange` | `onPressed`, `onAction`, `onChanged` |
| `href`, `target`, `rel`, `RouteDescriptor`, breadcrumb `route` | Host callback. The kit never navigates or launches |
| `type` (look) | `variant` enum (§9 rule 4), or `StatusTone` for status |
| `size`: small / medium / large | `size: PaymentSize` under D29 |
| `width` | `width: PaymentWidth.fill / .hug` |
| `pending` | `pending: bool`, which shows a `LoadingSkeleton` of the right shape |
| `error` / `invalid` / `required` / `hiddenElements` / `description` (fields) | `errorText` / derived / `required` / `hiddenElements` / `description` |
| `defaultValue`, `defaultChecked`, `defaultOpen`, `defaultSelected` | `initialValue` where the widget can keep its own state (text, accordion, search); selection controls stay controlled |
| `css`, `id`, `aria-*`, `tabIndex`, `name`, `form`, `autoComplete` and other DOM attributes | Not mirrored. Semantics come from B7; autofill comes from `type` |

### 6.10 Layout primitives (Phase 4A)

**`PaymentBox`** (Stripe Box; D33)

- **Anatomy:** a container with optional background, keyline and radius, padding, and children laid out in a stack.
- **Variants (Stripe → kit):**
  - `stack` x / y / z → `stack: PaymentStack.horizontal / .vertical / .layered`.
  - `padding`, `paddingX`, `paddingY` → `PaymentSpace`.
  - `gap` → `PaymentSpace`.
  - `distribute` packed / space-between → **New** `PaymentDistribute`.
  - `alignX`, `alignY` → **New** `PaymentAlign` (`start`, `center`, `end`, `stretch`; `baseline` on y only).
  - `wrap` → `bool`.
  - `backgroundColor` surface / container → `background: PaymentBoxBackground.none / .surface / .muted`.
  - `borderRadius` → `PaymentRadius`.
  - `keyline` / `borderColor` neutral / critical → `keyline: PaymentKeyline.none / .neutral (outline) / .critical (danger.foreground)`.
  - `width` → `PaymentWidth`.
  - **Refused (D28):** numeric sizes, `margin`/`bleed`, `boxShadow`/`topShadow` (§3.5: the kit is flat), `zIndex`, `overflow`, and every text prop (use `PaymentInline`).
- **States:** static, not focusable.
- **When:** grouping content with a token gap; a boxed surface (`muted` + `control` radius) for a highlighted block such as the VA block; a `critical` keyline around an error summary. Not for sections (use `PaymentSection`) or for anything interactive.
- **Payment use:** the VA instructions block, the sign-in brand row, the overview's metric tiles.
- **A11y:** no semantics of its own. It never merges its children.

**`PaymentInline`** (Stripe Inline; D33, D35)

- **Anatomy:** text, or a run of `PaymentSpan`s, in one role.
- **Variants:**
  - `font` → `role: PaymentTextRole`, mapped as in §3.2.
  - `fontWeight` regular / semibold / bold → `weight: PaymentFontWeight`.
  - `color` primary / secondary / disabled / brand / info / success / attention / critical → `color: PaymentTextColor` (`primary`, `secondary`, `disabled`, `accent`, `info`, `success`, `warning`, `danger`); the tone colors resolve to `tone.foreground`.
  - Kit modifiers: `tabular`, `reference`.
- **States:** static.
- **When:** any text the kit or the example draws with a token. Not for `Money` (`AmountText`), IDs that elide (`MiddleEllipsisText`) or countdowns.
- **Payment use:** helper copy, meta lines, an emphasized amount label in running text ("Pay **before 14:05**").
- **A11y:** status colors always come with words; a colored span is never the only signal.

**`PaymentIcon`** (Stripe Icon; D33)

- **Variants:**
  - `name` → `IconData` from the SDK's `Icons`, plus **New** `PaymentIcons` constants (§3.6).
  - `size` → `PaymentIconSize` (`xsmall`, `small`, `medium`, `large`, `xlarge`).
  - `css.fill` → `color: PaymentTextColor?` (default: inherit the surrounding text color, as Stripe does).
  - `PaymentIcon.tone(StatusTone)` draws the §3.6 tone icon in `tone.foreground`.
- **A11y:** decorative by default (Stripe `aria-hidden`). `semanticLabel` makes it a labeled image, which is only for the rare icon without words. `medium` scales with text and centers on the first line (`PaymentType.firstLineHeight`).

**`PaymentImage`** (Stripe Img; D42)

- **Variants:**
  - `src` / `srcSet` → `image: ImageProvider`, supplied by the host. The kit never constructs a `NetworkImage`, so `lib` stays network-free (B11).
  - `alt` → required `alt`; `''` marks the image decorative.
  - `width` / `height` → `width`, `height`.
  - Stripe's styling examples (borders, rounded corners) → `radius: PaymentRadius`, `bordered: bool` (1 px `outline`), `fit: BoxFit`.
- **States:** loading (a `surfaceMuted` block, or the host `placeholder`); loaded (a fade over `quick`, none under reduced motion); error (the `errorFallback`, or a muted block with `broken_image_outlined` and the alt text, spoken).
- **Payment use:** the `KycCaptureGuide` photo (closes D9's `errorBuilder` gap), `PromoContent.media`, a bank logo in a `large` `PaymentListItem`, the sign-in brand.

**`PaymentCode`** (Stripe Code)

- **Variants:**
  - `type` code / pre / samp / kbd → `kind: PaymentCodeKind`. `code` is inline monospace on a `surfaceMuted` tag. `pre` is a block that preserves whitespace. `samp` is output in `textSecondary` with no fill. `kbd` is a key cap: a 1 px `border` edge and radius `tag`.
  - `multiline` → `multiline`.
  - `noWrap` → `noWrap` (scrolls horizontally inside the block, never the page).
  - `size` → `PaymentSize`: `caption`, `label` or `amountLarge`, all with `.reference`.
  - Kit: `onCopy: Future<bool> Function(String)?` adds a trailing `PaymentCopyButton` (block kinds only; the host owns the clipboard).
- **States:** static; with copy: idle, pending, copied, failed (from `PaymentCopyButton`).
- **When:** `code` + `large` + `onCopy` for a VA number; `code` + `medium` for a transaction reference; `kbd` for a keyboard hint in the wide-layout docs; `pre` + `samp` for host-supplied technical output (a webhook error ID).
- **A11y:** a long run of digits is spoken in groups of four (the semantics label inserts spaces), so a VA number is not read as one large number. Selectable by default.

```dart
PaymentBox({Key? key, required List<Widget> children,
  PaymentStack stack = PaymentStack.vertical, PaymentSpace padding = PaymentSpace.none,
  PaymentSpace? paddingX, PaymentSpace? paddingY, PaymentSpace gap = PaymentSpace.none,
  PaymentDistribute distribute = PaymentDistribute.packed,
  PaymentAlign alignX = PaymentAlign.stretch, PaymentAlign alignY = PaymentAlign.start,
  bool wrap = false, PaymentBoxBackground background = PaymentBoxBackground.none,
  PaymentRadius radius = PaymentRadius.none, PaymentKeyline keyline = PaymentKeyline.none,
  PaymentWidth width = PaymentWidth.fill})

PaymentInline(String text, {Key? key, PaymentTextRole role = PaymentTextRole.body,
  PaymentFontWeight? weight, PaymentTextColor? color, bool tabular = false,
  bool reference = false, int? maxLines, TextAlign? textAlign})
PaymentInline.rich(List<PaymentSpan> spans, {Key? key, PaymentTextRole role = PaymentTextRole.body})
PaymentSpan(String text, {PaymentFontWeight? weight, PaymentTextColor? color, bool reference = false})

PaymentIcon(IconData icon, {Key? key, PaymentIconSize size = PaymentIconSize.medium,
  PaymentTextColor? color, String? semanticLabel})
PaymentIcon.tone(StatusTone tone, {Key? key, PaymentIconSize size = PaymentIconSize.medium})

PaymentImage({Key? key, required ImageProvider image, required String alt, double? width,
  double? height, BoxFit fit = BoxFit.cover, PaymentRadius radius = PaymentRadius.none,
  bool bordered = false, Widget? placeholder, Widget? errorFallback})

PaymentCode(String text, {Key? key, PaymentCodeKind kind = PaymentCodeKind.code,
  bool multiline = false, bool noWrap = false, PaymentSize size = PaymentSize.medium,
  Future<bool> Function(String value)? onCopy, String? semanticLabel})
```

`PaymentDivider` needs nothing for parity, because Stripe's Divider has no props. It is listed in 4A for its docs page.

### 6.11 Forms (Phase 4B)

**`PaymentTextArea`** (Stripe TextArea)

- **Anatomy:** `PaymentTextField` with several lines.
- **Variants:** the field set (`size`, `label`, `hint`, `description`, `errorText`, `required`, `hiddenElements`, `width`, `readOnly`, `enabled`); `rows` → `minLines` (default 3) and `maxLines`; Stripe "Resizeable" → `maxLines: null` grows with content up to the viewport; `maxLength` adds a counter in `caption` that is announced near the limit.
- **Payment use:** "Describe the problem" in a report-a-problem `PaymentFocusView` opened from transaction detail. Free text goes to the host, never to logs; the kit keeps no copy.
- **A11y:** Enter inserts a newline. The sheet's primary button submits.

**`PaymentSelect<T>`** (Stripe Select; supersedes D4 and Q1)

- **Anatomy:** a field-shaped trigger (label, value or hint, `expand_more` 20) that opens a sheet of options.
- **Variants:**
  - `children` (`<option>`) → `options: List<PaymentSelectOption<T>>` (`value`, `label`, `disabledReason`).
  - `multiple` → named constructor `PaymentSelect.multiple`, with `Set<T>` values. The sheet then uses `PaymentCheckbox` rows and an "Apply" button.
  - Plus the field set.
- **Behavior:** single select opens `showPaymentSheet` with `PaymentRadio` rows, and selecting one closes the sheet. With 7 or more options, the sheet adds a `PaymentTextField.search` filter.
- **Payment use:** occupation in `IdentityForm` via **New** `IdentityFieldSpec.kind` (`text`, `date`, `choice`; D36); the currency switch in `PaymentCurrencyField`.
- **A11y:** the trigger is a button with the value spoken ("Occupation, Employee"). Focus returns to the trigger on close.

**`PaymentDateField`** (Stripe DateField; D36)

- **Anatomy:** typed entry in `dateInputPattern` (`DD/MM/YYYY`) plus a trailing `PaymentIconButton` (`calendar_today_outlined`) that opens Flutter's `showDatePicker`.
- **Variants:** `value` → `DateTime?` (date only); the field set. Kit: `firstDate`, `lastDate` and `validator`, all host-owned rules (for example, "17 or older for KTP").
- **States:** empty, partial (still typing; no error), invalid date (kit error "Enter a valid date"), out of range or host rule (host `errorText`), filled.
- **Payment use:** date of birth in `IdentityForm`.

**`PaymentDateRangePicker`** (Stripe DateRangePicker; D36)

- **Anatomy:** a field showing "1–31 Okt 2026" that opens `showDateRangePicker`, with optional preset chips above the calendar.
- **Variants:**
  - `value` (range or preset) → `PaymentDateRange` (`start`, `end`, or a `PaymentDatePreset`).
  - `onChange` → `onChanged`.
  - `disableDatesBefore` / `After` ("today" or a date) → `firstDate` / `lastDate`.
  - `showDateGranularityToggle` + `granularity` day / week / month / year → `granularity: PaymentDateGranularity?` with a `PaymentTabs(size: small, fitted: true)` toggle.
  - Presets → `presets: List<PaymentDatePreset>` (label + range), supplied by the host.
  - `timeZone` is not a parameter: the host passes calendar dates already in its zone, and the kit does no zone math.
- **Payment use:** the history date filter. The applied range shows as a closeable `PaymentChip` beside the status tabs. The host filters, or the example filters locally. Granularity drives the spending overview's bucketing, which the host computes.

**`PaymentFormFieldGroup`** (Stripe FormFieldGroup)

- **Variants:** `legend`, `description`, `disabled` (disables every child), `layout: Axis` (Stripe horizontal / vertical). Horizontal falls back to vertical below 360 dp of available width or at large text (B4).
- **Payment use:** place and date of birth in `IdentityForm`; an expiry month and year pair in a specimen.
- **A11y:** the legend is a header and is read before the first field. A group error is a `PaymentBanner` above the fields, or each field's own error.

**`PaymentSearchField<T>`** (Stripe SearchField; D37)

- **Anatomy:** a `PaymentTextField(type: search)` plus a listbox of matching options below it, inline rather than in an overlay, so it works at 200% and with the keyboard up.
- **Variants:**
  - `data` → `options: List<PaymentSearchOption<T>>` (`value`, `label`). The kit filters them locally by case- and diacritic-insensitive substring. For remote search, the host passes `onQueryChanged` and replaces `options` (with `loading` while it fetches).
  - `selectionMode` single / multiple → `PaymentSearchField` / `PaymentSearchField.multiple`.
  - `onSelectionChange` → `onSelected` / `onSelectionChanged`; clearing the text clears the selection, as in Stripe.
  - `listboxSize` small / medium / large → `listboxSize: PaymentSize`, showing at most 4, 6 or 8 visible rows.
  - Plus the field set.
- **States:** idle, typing, results, no results (`search_off` line), loading (host), selected (single: the label fills the field; multiple: chips below the field).
- **Payment use:** the province picker in KYC (38 options); the bank picker for transfer instructions.
- **A11y:** results count is announced ("5 results"); arrow keys move through the list and Enter selects; each option is ≥ 48 dp.

**`PaymentChip`** + **`PaymentChipList`** (Stripe Chip, ChipList)

- **Anatomy:** a 32 dp pill (radius `circle`, 1 px `border`) inside a ≥ 48 dp box (D29), with label `caption` + value `caption` in `textPrimary`.
- **Variants** (by callback, as in Stripe; a closed set):
  - `onClose` → closeable, with a trailing `close` target 48×48.
  - `onDropdown` → dropdown, with a trailing `expand_more`; the whole chip opens it.
  - `onAddSuggestion` → suggested, with a dashed `border` edge and a leading `add`.
  - none → static.
  - `value` string or list → `value: String?` or `values: List<String>`, joined "A, B +2".
  - `PaymentChipList` wraps chips with `related` (8) gaps.
- **States:** default, pressed (0.96), focused, disabled.
- **Payment use:** the applied promo code (extracts the private tag at `payment_extras.dart:477-516`); active history filters (date range, method) next to the status tabs. Status filtering stays on the tabs, as decisions.md requires.
- **A11y:** one node per target: "Date: 1–31 Oct, button" and "Remove Date filter, button".

```dart
PaymentTextArea({Key? key, required String label, TextEditingController? controller,
  String? hint, String? description, String? errorText, bool required = false,
  Set<PaymentFieldPart> hiddenElements = const {}, int minLines = 3, int? maxLines = 8,
  int? maxLength, PaymentSize size = PaymentSize.medium, PaymentWidth width = PaymentWidth.fill,
  ValueChanged<String>? onChanged, bool enabled = true, bool readOnly = false})

PaymentSelect<T>({Key? key, required String label, required List<PaymentSelectOption<T>> options,
  required T? value, required ValueChanged<T>? onChanged, String? hint, String? description,
  String? errorText, bool required = false, PaymentSize size = PaymentSize.medium,
  PaymentWidth width = PaymentWidth.fill})
PaymentSelect<T>.multiple({..., required Set<T> values, required ValueChanged<Set<T>>? onChanged})

PaymentDateField({Key? key, required String label, required DateTime? value,
  required ValueChanged<DateTime?> onChanged, required DateTime firstDate,
  required DateTime lastDate, FormFieldValidator<DateTime>? validator, String? description,
  String? errorText, bool required = false, PaymentSize size = PaymentSize.medium})

PaymentDateRangePicker({Key? key, required String label, required PaymentDateRange? value,
  required ValueChanged<PaymentDateRange?> onChanged, required DateTime firstDate,
  required DateTime lastDate, List<PaymentDatePreset> presets = const [],
  PaymentDateGranularity? granularity, ValueChanged<PaymentDateGranularity>? onGranularityChanged})

PaymentFormFieldGroup({Key? key, required String legend, required List<Widget> children,
  String? description, bool disabled = false, Axis layout = Axis.vertical})

PaymentSearchField<T>({Key? key, required String label, required List<PaymentSearchOption<T>> options,
  required T? selected, required ValueChanged<T?> onSelected, ValueChanged<String>? onQueryChanged,
  bool loading = false, PaymentSize listboxSize = PaymentSize.medium, String? hint,
  String? description, String? errorText})
PaymentSearchField<T>.multiple({..., required Set<T> selected, required ValueChanged<Set<T>> onSelectionChanged})

PaymentChip({Key? key, required String label, String? value, List<String>? values,
  VoidCallback? onClose, VoidCallback? onDropdown, VoidCallback? onAddSuggestion})
PaymentChipList({Key? key, required List<PaymentChip> children})
```

### 6.12 Content (Phase 4C)

**`PaymentPropertyList`** + **`PaymentPropertyListItem`** (Stripe PropertyList; D5 superseded)

- **Variants:** `orientation: Axis`. `vertical` (default, Stripe's default) stacks `InfoRow`s with the label at the start and the value at the end. `horizontal` lays the items side by side, each with the label above the value. It wraps to more lines when the items do not fit, and becomes vertical below 360 dp or at large text.
- Items: `label` + `value` (a `String`, or a widget such as `AmountText`, `PaymentCode` or `PaymentBadge`), plus the kit's `emphasis`, `caption` and `trailing` from `InfoRow`.
- **Payment use:** payment details on status and receipt (`horizontal` for a three-fact summary: amount, method, date, on wide layouts).
- **A11y:** each item is merged ("Method, BCA virtual account").

**`PaymentTable`** (Stripe Table, TableHead, TableBody, TableFooter, TableRow, TableHeaderCell, TableCell; D30)

- **Anatomy:** a header row of `PaymentTableHeaderCell`s, body rows and an optional footer row. Cells take `numeric: true` for end alignment with tabular figures.
- **Narrow width** (< 600 dp available, or `PaymentType.isLarge`): each row becomes a list row. The header cell marked `rowHeader` (default: the first) is the row title, and the other cells are `caption` "Label: value" lines. A numeric cell is end-aligned on the title line. The footer becomes a Total row (`InfoRow(emphasis: true)`).
- **Payment use:** the fee schedule by method (method, fee, arrival time); a statement summary with a total footer.
- **A11y:** the wide layout uses table semantics (row and column headers spoken with each cell). The narrow layout uses one merged node per row.

**`PaymentDataTable<T>`** (Stripe DataTable; D30, D43)

- **Anatomy:** an optional batch header (select all + "n selected" + host actions), a column header, rows, a row-action menu per row, and a pagination bar.
- **Variants (Stripe → kit):**
  - `columns` → `List<PaymentDataColumn<T>>` (`key`, `label`, `cell`, `hideHeaderLabel`, `pinned`).
  - Cell types text / link / date / id / status / currency → **New** `PaymentCellType`. `status` maps a value to a `StatusTone` through the host's `statusMap` and renders a `PaymentBadge`. `currency` renders `AmountText` from the host's `Money`. `date` uses `formatDate`. `id` uses `MiddleEllipsisText` with `.reference`. `link` renders a `PaymentLink` that calls the host.
  - `onRowClick` → `onRowPressed`.
  - `rowActions` (actions or links, `default` / `destructive`, groups) → `rowActions: List<PaymentRowAction<T>>` and `PaymentRowActionGroup<T>`, rendered in a `PaymentMenu`.
  - `batchable.onBatchChange` → `selection: Set<String>` + `onSelectionChanged`. The header checkbox shows `indeterminate` for a partial selection.
  - `pagination` → **New** `PaymentPagination`. `.local(pageSize)` slices the host rows (Stripe's uncontrolled offset). `.offset(page, pageSize, totalItems, onPageChanged)` and `.cursor(page, pageSize, hasMore, onPageChanged)` are host-controlled, server-side paging; the host supplies the page's rows.
  - `loading` → `pending` (the `table` skeleton).
  - `emptyMessage` (text, or text + action) → **New** `PaymentEmptyMessage(message, actionLabel, onAction)`, rendered as a `StateMessage`.
  - `enableColumnReorder`, `enableColumnResize`, `onColumnOrderChange` → the same names. They act on the wide layout only. The pointer drags the header, and the keyboard uses a "Columns" `PaymentMenu` on each header (move left or right, wider or narrower).
  - **Not added:** sorting and filtering. Stripe's DataTable has neither, so the admission rule applies. Filtering stays with the host or `PaymentSearchField`.
- **Narrow width:** collapses like `PaymentTable`. The pinned column is the title, a `status` cell becomes a badge on the meta line, a `currency` cell sits end-aligned, and row actions become a trailing `PaymentIconButton` (`more_vert`). Batch selection becomes a leading `PaymentCheckbox` on each row.
- **States:** pending, empty, ready, selected (n), page n of m, error (the host passes `errorText` → `StateMessage(danger)` with retry).
- **Payment use:** a settlement statement (date, reference, description, status, amount) with local paging of 25 and "Download selected" (host).
- **Performance:** only the current page is built; `.local` paging of 1,000 host rows builds 25 rows; scrolling is lazy (`ListView.builder`) in the narrow layout.

**`PaymentTaskList`** + **`PaymentTaskListItem`** (Stripe TaskList)

- **Variants:** `status` not-started / in-progress / blocked / complete → `PaymentTaskStatus.notStarted / .inProgress / .blocked / .complete`; `onPress` → `onPressed`; `subTasks` → `subTasks: List<PaymentTaskListItem>` (one level). A connector line joins the status marks, as in Stripe's sequential example.
- **Marks** (status is always spoken, never color alone): not started, a 2 px `border` ring; in progress, a half-filled `accent` ring; blocked, `lock_outline` in `textSecondary`; complete, `check_circle` in `accent` with the title in `textSecondary`. Sub-tasks are hidden when the parent is complete (Stripe rule).
- **Payment use:** the KYC checklist: Identity, Documents (KTP, selfie), Review. The host decides every status; the kit never infers completion.
- **A11y:** each item is a button when `onPressed` is set: "Documents, in progress, 1 of 2 sub-tasks complete". Rows are ≥ 48 dp.

**`PaymentButtonGroup`** (Stripe ButtonGroup; D6 superseded)

- **Variants:** `direction: Axis` (Stripe row / column); `collapse: PaymentButtonGroupCollapse.auto / .none`. With `auto`, buttons that do not fit move into a `PaymentMenu`, from the end; the first button never collapses. With `none`, a row that does not fit stacks vertically. `menuTrigger` → `menuTrigger: PaymentIconButton?`.
- **Rules (asserted in debug):** one `primary`; no `destructive` beside a `primary`; domain order with primary first.
- **Payment use:** receipt actions (Share, Download, Report a problem); the status screen stack (`payment_status.dart:400`, column); dialog actions (D23); `PaymentDetailPage` actions.

```dart
PaymentPropertyList({Key? key, required List<PaymentPropertyListItem> items,
  Axis orientation = Axis.vertical, String? title})
PaymentPropertyListItem({required String label, String? valueText, Widget? value,
  bool emphasis = false, String? caption, Widget? trailing})

PaymentTable({Key? key, required List<PaymentTableHeaderCell> head,
  required List<PaymentTableRow> rows, PaymentTableRow? footer, String? caption})
PaymentTableRow(List<PaymentTableCell> cells)
PaymentTableHeaderCell(String label, {bool numeric = false, bool rowHeader = false})
PaymentTableCell(Widget child, {bool numeric = false})

PaymentDataTable<T>({Key? key, required List<PaymentDataColumn<T>> columns,
  required List<T> rows, required String Function(T row) rowKey,
  PaymentPagination pagination = const PaymentPagination.local(pageSize: 25),
  ValueChanged<T>? onRowPressed, List<PaymentRowActionEntry<T>> rowActions = const [],
  Set<String>? selection, ValueChanged<Set<String>>? onSelectionChanged,
  bool pending = false, PaymentEmptyMessage? emptyMessage, String? errorText, VoidCallback? onRetry,
  bool enableColumnReorder = false, bool enableColumnResize = false,
  ValueChanged<List<String>>? onColumnOrderChanged})
PaymentDataColumn<T>({required String key, required String label, required PaymentCellType cell,
  required Object? Function(T row) value, Map<String, StatusTone>? statusMap,
  bool hideHeaderLabel = false, bool pinned = false})

PaymentTaskList({Key? key, required List<PaymentTaskListItem> items})
PaymentTaskListItem({required String title, PaymentTaskStatus status = PaymentTaskStatus.notStarted,
  VoidCallback? onPressed, List<PaymentTaskListItem> subTasks = const []})

PaymentButtonGroup({Key? key, required List<PaymentButton> children,
  Axis direction = Axis.horizontal,
  PaymentButtonGroupCollapse collapse = PaymentButtonGroupCollapse.auto,
  PaymentIconButton? menuTrigger})
```

### 6.13 Views (Phase 4D)

**The rule (D31).** A view or page is a **Scaffold-free body**. It returns a column with a header region (title with header semantics, optional description and brand), a scrollable content region, and an optional ruled footer of actions, like `PaymentSheet`. The host puts it in its own `Scaffold`, route, tab or sheet. The kit adds no router, no `Navigator.push` and no app bar. The one exception is FocusView, which is presented with `showPaymentFocusView`. That function pushes a modal route through the existing sheet functions, as `showPaymentSheet` already does. Back navigation, deep links and URLs stay with the host.

| Stripe view | Kit | Mapped to existing pieces | Payment use |
| --- | --- | --- | --- |
| ContextView | `PaymentContextView` | Shown in `showPaymentSideSheet` beside host content on wide windows, or as a screen body on phones | Order context beside checkout: merchant, items, totals |
| FullPageView | `PaymentFullPageView` | The content area of `AdaptiveNavShell` (`navigation.dart:244`); Stripe recommends tabs, so it composes `PaymentTabs` + `PaymentTabPanels` | History as a full page with tabs |
| FocusView | `PaymentFocusView` + `showPaymentFocusView` | `showPaymentSheet` on phones; `showPaymentSideSheet` on wide | Report a problem; request a refund |
| SettingsView | `PaymentSettingsView` | A body with a Save footer | Payment and notification settings |
| SignInView | `PaymentSignInView` | A body; no fields | Example sign-in screen |
| OnboardingView | `PaymentOnboardingView` | Composes `PaymentTaskList`; the example puts `VerificationIntro` and the KYC steps in its content slot | KYC onboarding |

**`PaymentContextView`** (Stripe ContextView)

- **Variants (Stripe → kit):**
  - `title`, `description` → same.
  - `brandColor` + `brandIcon` (an SVG string) → `brand: Widget?`. The host passes a 40×40 logo (`PaymentImage` or `PaymentIcon`), because the SDK cannot render SVG and the kit takes no image package.
  - `actions` (≤ 3 buttons under the header) → `actions: List<PaymentButton>` in a `PaymentButtonGroup(collapse: auto)`.
  - `banner` → `banner: PaymentBanner?`.
  - `externalLink` (href + label) → `externalLink: PaymentLink?`, asserted `external: true`.
  - `primaryAction` / `secondaryAction` → `PaymentButton?` in the footer.
  - `footerContent` → `footer: Widget?`, beside the actions.
- **States:** default; footer `busy` through the buttons.

**`PaymentFullPageView`** (Stripe FullPageView)

- **Variants:** `title` (Stripe takes it from the manifest; the kit needs it for header semantics); `pageAction` (label + onPress) → `pageAction: PaymentButton?` (`size: small`, in the header row); `child`.
- **Narrow:** the page action moves under the title, full width.

**`PaymentFocusView`** + **`showPaymentFocusView`** (Stripe FocusView)

- **Variants:**
  - `title`, `child`.
  - `primaryAction` / `secondaryAction` → `PaymentButton?` in the sheet footer.
  - `footerContent` → `footer`.
  - `size` small / large → `size: PaymentFocusViewSize.small / .large`. On phones, small is a bottom sheet at content height and large is a bottom sheet at full height. On wide windows, small is a 420 dp side sheet and large is 720 dp.
  - `shown` / `setShown` → the imperative `showPaymentFocusView` returns a `Future<T?>`, and `Navigator.pop` closes it. That is the Flutter idiom for the same control.
  - `confirmCloseMessages` (title, description, exitAction, cancelAction) → `confirmClose: PaymentConfirmClose?`. Close, scrim tap and system back go through `PopScope` and `showPaymentConfirmDialog` (`destructive: true`, cancel focused first).
- **Payment use:** report a problem (a `PaymentTextArea` with a primary "Send" that calls the host), with confirm-close when text was entered.

**`PaymentSettingsView`** (Stripe SettingsView)

- **Variants:**
  - `children` → `child`.
  - `onSave(values)` → `onSave: Future<void> Function()?`, which adds a primary "Save" button that is busy while the future runs. The host holds the field state, so there is no values map.
  - `statusMessage` → `statusMessage: String?` + `statusTone: StatusTone`. It shows in the header ("Saved", "Couldn't save") and is a live region.
- **Payment use:** refund and promo notifications (`PaymentSwitch`, which resolves Q2); default payment method (`PaymentRadio`); statement language (`PaymentSelect`). These are host settings; the kit stores nothing.

**`PaymentSignInView`** (Stripe SignInView; D32)

Stripe's SignInView is a sign-in *screen*: brand, description and actions that send the user to sign in elsewhere. It has no credential props, and the kit's version has none either.

- **Variants:**
  - `brandColor` / `brandIcon` → `brand: Widget?`.
  - `description` → `description`.
  - `descriptionActionLabel` / `Title` / `Contents` → `learnMore: PaymentSignInLearnMore?` (label, title, builder). It opens a `PaymentFocusView`.
  - `primaryAction` / `secondaryAction` (label + href or onPress) → `primaryAction: PaymentButton` (required, `size: large` on wide) and `secondaryAction: PaymentButton?`. Both call the host, which signs the user in through its own screen, the system browser or a bank app.
  - `footerContent` → `legalLinks: List<PaymentLink>` and `footnote: String?`. **There is no free widget slot.** A host cannot inject a credential field through the kit's view.
  - Kit additions: `title` (required for header semantics; default copy "Sign in to continue" / "Masuk untuk melanjutkan"); `errorText` (a host error → `PaymentBanner(danger)` above the actions).
- **States:** default; busy (primary action `Future`); error (banner, announced, focus moves to the banner).
- **Security:** the view contains no `EditableText`. A widget test asserts `find.byType(EditableText)` finds nothing (B11).

**`PaymentOnboardingView`** (Stripe OnboardingView; D44)

- **Variants:**
  - `title`, `description`, `child` (the current step's content).
  - `tasks` (TaskListItem props) → `tasks: List<PaymentTaskListItem>`.
  - `pending` → `pending` (spinner + "Loading…").
  - `error` → `error: PaymentBanner?`.
  - `completed` → `completed: bool` + `onCompleted: VoidCallback?`. Stripe auto-closes after a delay; the kit shows the completion state and calls `onCompleted` once, and the host navigates. There is no kit timer.
- **Layout:** at ≥ 840 dp wide, the task list is a 280 dp start column next to the content. On narrower windows, a header "Step 2 of 4 · Documents" sits above the content, with the full `PaymentTaskList` inside a collapsed `PaymentAccordionItem`.
- **Payment use:** KYC onboarding: tasks Identity, Documents (KTP, selfie), Review; the content slot shows `VerificationIntro`, `IdentityForm` and the others. Verification stays optional (PRD §4).

```dart
PaymentContextView({Key? key, required String title, required Widget child,
  String? description, Widget? brand, List<PaymentButton> actions = const [],
  PaymentBanner? banner, PaymentLink? externalLink, PaymentButton? primaryAction,
  PaymentButton? secondaryAction, Widget? footer})

PaymentFullPageView({Key? key, required String title, required Widget child,
  PaymentButton? pageAction})

Future<T?> showPaymentFocusView<T>(BuildContext context, {required WidgetBuilder builder})
PaymentFocusView({Key? key, required String title, required Widget child,
  PaymentButton? primaryAction, PaymentButton? secondaryAction, Widget? footer,
  PaymentFocusViewSize size = PaymentFocusViewSize.small, PaymentConfirmClose? confirmClose})

PaymentSettingsView({Key? key, required String title, required Widget child,
  Future<void> Function()? onSave, String? statusMessage, StatusTone statusTone = StatusTone.neutral})

PaymentSignInView({Key? key, required PaymentButton primaryAction, String? title,
  String? description, Widget? brand, PaymentSignInLearnMore? learnMore,
  PaymentButton? secondaryAction, List<PaymentLink> legalLinks = const [],
  String? footnote, String? errorText}) // no child, no field, no free footer slot (D32)

PaymentOnboardingView({Key? key, required String title, required List<PaymentTaskListItem> tasks,
  required Widget child, String? description, bool pending = false, PaymentBanner? error,
  bool completed = false, VoidCallback? onCompleted})
```

### 6.14 Pages (Phase 4D)

Pages follow D31. Stripe uses them inside FullPageView or a tab, and so does the kit: a page goes in a `PaymentFullPageView`, a `PaymentTabPanels` panel or a host body.

**`PaymentPageModule`** (Stripe PageModule, the shared sub-component)

- **Variants:** `title`, `subtitle`, `extraActions` (label, onPress, disabled, type primary / secondary / destructive) → `extraActions: List<PaymentButton>`, drawn `small` and `hug` in the module header, with more than two collapsing into a `PaymentMenu`; `child`.
- **Surface:** flat `PaymentSection` look with a ruled top; no box (§3.5).

**`PaymentDetailPage`** (Stripe DetailPage)

- **Variants:**
  - `title`, `description`.
  - `breadcrumbs` (label + route) → `breadcrumbs: List<PaymentBreadcrumb>` (label + `onPressed`, host navigates).
  - `actions` (label, onPress, disabled, type) → `actions: List<PaymentButton>` in a `PaymentButtonGroup(collapse: auto)`.
  - `pending` → module skeletons.
  - `primaryColumn` / `secondaryColumn` → `primary: List<PaymentPageModule>` / `secondary: List<PaymentPageModule>?`.
- **Layout:** two columns (2:1) at ≥ 840 dp; below that, one column with the secondary modules after the primary ones. On narrow widths, breadcrumbs collapse to the parent only ("‹ Transactions", a `PaymentLink`).
- **Payment use:** transaction detail as a page: the amount and status header, a "Payment details" `PaymentDetailPagePropertyList` and an "Attempts" `PaymentDetailPageTable`. `TransactionDetail` stays the Tier 2 content and is not replaced.

**`PaymentOverviewPage`** (Stripe OverviewPage)

- **Variants:** `primaryColumn` / `secondaryColumn` → `primary` / `secondary` module lists; `pending`. Stripe's OverviewPage has no title, because its host view gives one; the kit's does the same.
- **Payment use:** the spending overview: `ChartModule` with a bar chart (this month vs last month), a line chart, and a recent-transactions `PaymentList`; the secondary column holds the balance and limits.

**`PaymentDetailPagePropertyList`** (Stripe DetailPagePropertyList)

- **Variants:**
  - `items` (label, values[] each with text or action, description) → `items: List<PaymentDetailProperty>`, where each value is text or a `PaymentLink`.
  - `orientation` → `orientation: Axis`.
  - `pending` (required in Stripe) → required `pending`.
  - `createAction` → `onCreate` (a `small` secondary button in the header).
  - `emptyMessage` (text, or text + action) → **New** `PaymentEmptyMessage`.
  - `error` (message + errorAction) → `errorText` + `onRetry` (`StateMessage(warning)`: a module is secondary, D25).
  - `extraActions` (link or action) → `extraActions: List<PaymentLink>`.
- **States:** pending, empty, error, ready.

**`PaymentDetailPageTable<T>`** (Stripe DetailPageTable)

- **Variants:** a `PaymentPageModule` around a `PaymentDataTable<T>`, with the same `columns`, `items` (→ `rows`), `onItemPress` (→ `onRowPressed`), `rowActions`, `pending`, `emptyMessage`, `error`, `createAction` and `extraActions` mapping as above. Stripe's DetailPageTable has no pagination or batch selection; neither does this one.
- **Payment use:** the attempts table on transaction detail (time, method, status, amount; `PaymentAttempt`).

```dart
PaymentPageModule({Key? key, required String title, required Widget child,
  String? subtitle, List<PaymentButton> extraActions = const []})

PaymentDetailPage({Key? key, required String title, required List<PaymentPageModule> primary,
  List<PaymentPageModule>? secondary, List<PaymentBreadcrumb> breadcrumbs = const [],
  String? description, List<PaymentButton> actions = const [], bool pending = false})

PaymentOverviewPage({Key? key, required List<PaymentPageModule> primary,
  List<PaymentPageModule>? secondary, bool pending = false})

PaymentDetailPagePropertyList({Key? key, required String title, required bool pending,
  List<PaymentDetailProperty> items = const [], Axis orientation = Axis.vertical,
  VoidCallback? onCreate, PaymentEmptyMessage? emptyMessage, String? errorText,
  VoidCallback? onRetry, List<PaymentLink> extraActions = const []})

PaymentDetailPageTable<T>({Key? key, required String title, required bool pending,
  required List<PaymentDataColumn<T>> columns, required List<T> rows,
  required String Function(T row) rowKey, ValueChanged<T>? onRowPressed,
  List<PaymentRowActionEntry<T>> rowActions = const [], VoidCallback? onCreate,
  PaymentEmptyMessage? emptyMessage, String? errorText, VoidCallback? onRetry,
  List<PaymentLink> extraActions = const []})
```

## 7. Patterns (Tier 2, composed from Tier 1)

| Pattern | Widgets | Built from | Docs |
| --- | --- | --- | --- |
| Checkout | `PaymentSummary`, `PaymentMethodPicker`, `PaymentConfirmation`, `AuthorizationPrompt`, `MerchantHeader`, `BalanceCard`, `PromoCodeInput` | `PaymentSection`, `PaymentPropertyList`, `AmountText`, `PaymentRadio` mark, `PaymentCheckbox`, `PaymentCurrencyField`, `PaymentTextField`, `PaymentChip` (applied promo), `PaymentButton`, `PaymentActionBar` | `patterns/checkout` |
| Status and receipt | `PaymentInstructions`, `PaymentStatusView`, `RefundSection`, `PaymentReceipt` | `StatusHeader`, `PaymentPropertyList`, `PaymentCode` (VA number), `PaymentCopyButton`, `CountdownText`, `PaymentButtonGroup`, `PaymentBanner` | `patterns/status-receipt` |
| Transaction history | `TransactionHistory`, `TransactionListItem`, `TransactionDetail` | `PaymentTextField.search`, `PaymentTabs`, `PaymentChip` (active filters), row shell, `PaymentBadge`, `StateMessage`, `LoadingSkeleton`; the example adds `PaymentDateRangePicker` and `ChartModule` | `patterns/history` |
| Verification (KYC) | `VerificationIntro`, `IdentityForm`, `DocumentUploadTile`, `VerificationReview`, `VerificationStatusView` | `PaymentCheckbox`, `PaymentTextField`, `PaymentSelect`, `PaymentDateField`, `PaymentFormFieldGroup`, `PaymentSearchField`, `PaymentLink`, `InfoRow`, `PaymentSection`; the example hosts them in `PaymentOnboardingView` | `patterns/verification` |
| KYC capture | `showCaptureSourceSheet`, `KycCaptureGuide`, `CaptureFrameOverlay` | `showPaymentSheet`, `PaymentListItem`, `PaymentButton`, `PaymentImage` | `patterns/kyc-capture` |
| Promotions | `PromoCard` (`PromoLayout.card` / `.banner`), `PromoSlot` | `PaymentLink`, `PaymentIconButton`, `PaymentImage`, `StateMessage`, `LoadingSkeleton` | `patterns/promotions` |

Cross-cutting pattern pages:

- **Loading:** skeleton vs spinner vs busy button vs `pending` pages.
- **Empty and error:** the `StateMessage` table, `ChartState`, `PromoSlotState`, module errors.
- **Forms:** labels, error timing, focus to the first error, no secret fields, `PaymentFormFieldGroup`.
- **Chart layout:** this page already exists.
- **New: Views and pages:** hosting a view in a `Scaffold`, a tab or a sheet without a router (D31).
- **New: Tables on phones:** the D30 collapse, with the statement example.

## 8. Decisions

Revision 1 (line references updated; superseded rows marked):

| ID | Decision | Reason |
| --- | --- | --- |
| D1 | Extract **`PaymentTextField`**, built on `TextFormField` so it works with or without a `Form`. Migrate all four copies. Focus is the 2 px `accent` border only; the history search drops its extra `PaymentFocusRing`. Parity adds `size`, `type`, `description`, `required` and `hiddenElements` (§6.5). | Four copies of one decoration that already drift. `IdentityForm` needs `validator` and `forceErrorText`. |
| D1a | `PaymentTextField` has **no `obscureText`** and no password, PIN or OTP mode. **Kept under parity:** Stripe's `type: "password"` is the one refused prop value (D28). | The kit never receives secrets (PRD §7, §11). |
| D2 | **Search is a named constructor, `PaymentTextField.search`.** Controlled (`query` + `onChanged`), no debounce. Kept as the list filter; Stripe's SearchField is the separate `PaymentSearchField` (D37). | One call site; a variant costs no extra API surface. Debounce is host policy. |
| D3 | **`PaymentCopyButton`** is the compact control (`value`, `onCopy: Future<bool> Function(String)`), with inline feedback. It is built on `PaymentIconButton` (D18). The receipt banner then reports only the share outcome. | Two call sites lay out differently; feedback next to the value; the host owns the clipboard. |
| D4 | ~~No DateField, no Select~~ **Superseded by D36 (parity).** | — |
| D5 | ~~PropertyList is documented, not built~~ **Superseded (parity):** `PaymentPropertyList` wraps `PaymentSection` + `InfoRow`. | — |
| D6 | ~~No ButtonGroup class~~ **Superseded (parity):** `PaymentButtonGroup` enforces the §6.1 group rules. | — |
| D7 | ~~No TaskList~~ **Superseded (parity):** `PaymentTaskList`, first used by the KYC checklist. | — |
| D8 | ~~No Chip~~ **Superseded (parity):** `PaymentChip` extracts the applied-promo tag and shows active filters. Status filters stay text tabs. | — |
| D9 | ~~No Img component~~ **Superseded by D42 (parity).** The `KycCaptureGuide` `errorBuilder` fix (`capture_widgets.dart:260`) stays and uses `PaymentImage`. | — |
| D10 | **Charts** are admitted at the owner's request. Phase 5 adds a spending summary above history. `BalanceCard` keeps its limit bar (`payment_extras.dart:386`). | History is the customer-facing summary; the limit bar is one ratio with a warning tone. |
| D11 | **`PaymentLink`** is a new compact component; `PaymentButton` keeps its no-scale press. Its variants follow Stripe's `type` (`primary`, `secondary`). | One class, one press rule. |
| D12 | **Adopt before extract.** The method picker uses `PaymentRadio`'s mark; a disabled method shows the disabled circle plus its reason. | One radio look; the reason, not an icon, is the non-color signal. |
| D13 | ~~No FormFieldGroup, TextArea or DateRangePicker~~ **Superseded (parity), §6.11.** | — |
| D14 | **`showCaptureSourceSheet` and `CaptureFrameOverlay` are Tier 2 (KYC capture).** | They take verification types and keep the no-camera boundary. |

Revision 2 (approved 31 Oct 2026; superseded rows marked):

| ID | Decision | Reason |
| --- | --- | --- |
| D15 | **Export `PaymentType`** (`show PaymentType`, not the extension) with `PaymentType.of(context)`. Add **New** `firstLineHeight(context)`, `tabular(style)` and `reference(style)`. Deprecate `amountStyle(large:)`. | A design system needs consumable type roles. It mirrors the public `PaymentMotion.of`. Exporting the extension risks name clashes. |
| D16 | ~~No `PaymentText` widget~~ **Superseded by D33 (parity):** `PaymentInline`. | — |
| D17 | ~~One height (48 dp)~~ **Superseded by D29 (parity):** `size: PaymentSize` with a 48 dp layout box. Kept: **New** `width` (now the shared `PaymentWidth.fill / .hug`), no press scale at any width, and the action bar's wrapper. | — |
| D18 | **Extract `PaymentIconButton`** (`neutral`, `accent`), with a required tooltip, the ring, the 0.96 press, 48 dp, and an optional `focusNode`. Migrate all 10 sites. | Admission rule (a) with 10 sites; three lack the focus ring (B8). |
| D19 | **List family = one row anatomy, separate classes by semantics**; no mode enum; full-bleed dividers only; `components/list`; internal `_RowShell`. ~~No `value` slot, no avatar leading, no density enum~~ **superseded by D41 (parity).** | The classes' semantics differ. The shared metrics should stay identical by construction. |
| D20 | **`PaymentBadge.icon` (was `StatusBadge.icon`) becomes optional**, defaulting to the §3.6 tone icon. Its icon scales to 1.6×. | Removes a required parameter for the common case. |
| D21 | **`PaymentBanner.actions`** accepts `PaymentLink` or `hug` quiet/secondary `PaymentButton` only (asserted in debug). ~~No dismiss~~ **superseded by D38 (parity).** | A full-width button in a `Wrap` breaks the layout. |
| D22 | **Toast uses kit tokens:** ink fill `textPrimary`, text and icon `surface`, radius `control`. Tone stays an icon. | B2. The tooltip already uses this inversion. |
| D23 | **The dialog adopts `PaymentButton`** (`hug`): quiet cancel + primary or destructive confirm (Phase 2B); Phase 4C wraps them in a `PaymentButtonGroup`. Needs **New** `PaymentButton.autofocus`. | Closes a B8 gap; one button implementation. |
| D24 | **`AmountText` gains New `variant: AmountTextVariant`** (`caption`, `row`, `total`, `large`, `display`). `emphasis` is deprecated. | Five looks already in use through ad-hoc styles. |
| D25 | **`StateMessage` tone rule:** `danger` only when the screen's primary content failed; `warning` for a secondary module (including page modules). | Codifies the history vs chart and promo split. |
| D26 | ~~No new spacing API~~ **Superseded by D33 (parity):** `PaymentSpace`. The multiples table and the review grep stay. | — |
| D27 | **Specimen captures replace the `controls_*` captures**; `screens.mjs` and the mdx references are updated in the same PR. | One name scheme (§10). |

New in revision 3 (parity; for review):

| ID | Decision | Reason |
| --- | --- | --- |
| D28 | **Parity rule.** All 48 Stripe entries and their sub-components ship (admission clause (c)). Their props are variants, translated by the §6 conventions table. **Not mirrored**, each with its reason: `TextField type: "password"` (D1a); CurrencyField `fractionDigitOffset` (`Money` is integer minor units); Box and Inline numeric sizes, `margin`/`bleed`, shadows, `zIndex`, `overflow` (B2, §3.5); DOM attributes; the SVG-string `brandIcon` (→ a host widget); DateRangePicker `timeZone` (host-owned dates); OnboardingView's auto-close delay (D44). Every `href` or route is a host callback. | The owner's decision, held inside the constraints that still apply: SDK only, no network, no secrets, host-owned decisions. |
| D29 | **Sizes keep a 48 dp hit area.** `PaymentSize` (`small`, `medium`, `large`) changes the drawn container and padding only. The layout box, which bounds Flutter hit-testing, stays ≥ 48×48 dp, with the visual centered, as Material's padded tap target does. `medium` is today's look and the default everywhere. | Stripe's sizes are visual. Flutter hit-tests within the layout box, so the only way to keep B5 with a 36 dp button is a 48 dp box. The cost is row height, which is accepted. |
| D30 | **Tables on phones collapse rows into list rows.** Below 600 dp of available width, or at `PaymentType.isLarge`, `PaymentTable` and `PaymentDataTable` render each row as a list row: the pinned or row-header cell is the title, numbers sit end-aligned, other cells become caption lines, and actions become a trailing menu. The wide layout keeps columns and scrolls horizontally, with pinned columns fixed. | Horizontal scrolling with a sticky column fails at 320 dp and 200% text (B4): two-axis scrolling, clipped headers, and cells read without their header. The collapse reuses the list anatomy and its semantics. |
| D31 | **Views and pages are Scaffold-free bodies** with header, scroll content and footer regions. The host supplies the `Scaffold`, route, tab or sheet. Only FocusView presents itself (`showPaymentFocusView`, through the existing sheet functions). No router, no app bar, no `Navigator.push` otherwise. | PRD §2 keeps routing with the host. One rule for all eleven layouts. It matches `PaymentSheet`, which already lays out header, content and footer. |
| D32 | **`PaymentSignInView` has no credential input and no free widget slot.** Actions call the host; the footer takes `PaymentLink`s and a footnote only; a test asserts no `EditableText`. | Stripe's SignInView is itself a redirect-to-sign-in screen. The kit never receives secrets (PRD §7, §11). |
| D33 | **Token primitives.** `PaymentBox`, `PaymentInline` and `PaymentIcon` accept only **New** token enums: `PaymentSpace`, `PaymentRadius`, `PaymentTextRole`, `PaymentTextColor`, `PaymentFontWeight`, `PaymentIconSize`, `PaymentKeyline`. Supersedes D16 and D26. `PaymentType` itself gains no roles. | Parity, without opening a raw-value escape hatch that would break B2. |
| D34 | **Naming.** Stripe entries are `Payment<StripeName>` (Img → `PaymentImage`). Renamed classes on `main` (`ExpandableSection`, `StatusBadge`, `NoticeBanner`, `ActionMenu`/`ActionMenuEntry`, `AmountInput`, `ActionTile`/`ActionTileGroup`, `showPaymentSnackBar`) stay for one minor release: as a `@Deprecated` typedef when the constructor is unchanged, otherwise as a deprecated wrapper. Names only on #1/#4 change freely. Kit-specific names (`InfoRow`, `PaymentSheet` …) stay. Docs slugs follow the Stripe name, with redirects. | One naming scheme that a reader can map to Stripe's sidebar; §9 rule 6 for anything on `main`. |
| D35 | **Inline roles map onto the nine `PaymentType` roles** (§3.2 table); no new roles. | D15 froze nine roles; `lead` and `kicker` would add looks with no second use. Q11 confirms. |
| D36 | **Dates.** `PaymentDateField` and `PaymentDateRangePicker` delegate the calendar to Flutter's `showDatePicker` / `showDateRangePicker` and offer typed entry. The kit formats (`formatDate`, en and id) and validates the date's form; the host supplies ranges, presets and rules. No time-zone math. `IdentityFieldSpec` gains **New** `kind` (`text`, `date`, `choice`). Supersedes D4 and Q1. | SDK-only, host-owned business rules; the date of birth gets a real date control. |
| D37 | **`PaymentSearchField<T>` is Stripe's combobox**: it filters host options locally, or the host searches remotely through `onQueryChanged`. Single and `.multiple` selection. `PaymentTextField.search` stays the list filter. | Stripe's SearchField picks values from a list; the history search filters a visible list. Two jobs, two names. |
| D38 | **Feedback parity.** Badge `urgent` → `PaymentBadge.urgent` (solid danger), with no new `StatusTone`. Banner types map to tones and gain `onDismiss` (host removes it). Toast gains `pending` and a controller with `update` and `dismiss`; the 30-character limit is guidance. | `StatusTone` stays five values, so every exhaustive switch is untouched. A named constructor makes "urgent but not danger" unrepresentable. |
| D39 | **Charts parity:** `axis`, `grid`, `showLegend`, `inspectable`, `series` (≤ 3; ramp + dash, never tones), `unit` (+ `ChartPoint.measure`), meter `onSegmentPressed` through the legend rows. | Stripe's chart props; the charts decisions (no tone categories, paint-only) still hold. |
| D40 | **Overlay parity.** `PaymentTooltip` gains 12 placements on `OverlayPortal`, plus `type` (label vs description semantics) and `delay`. `PaymentMenu` gains groups, a custom trigger and `onAction`. `PaymentFocusView` gains `size` and `confirmClose`. | Flutter's `Tooltip` only places above or below; `OverlayPortal` is in the SDK. |
| D41 | **`PaymentListItem` replaces `ActionTile`** and gains `value`, `image`, `size` (`standard` 48 / `large` 64) and `id`; **`PaymentList` replaces `ActionTileGroup`** and gains `onAction`. Still no compact density, and still separate classes for switch, checkbox and radio rows. Supersedes part of D19 and Q8. | One public action-row class, not two. Stripe's sizes are both ≥ 48 dp. |
| D42 | **`PaymentImage` takes a host `ImageProvider`.** The kit never constructs a network image. `alt` is required (`''` = decorative). Loading and error states are built in. | B11: no network in `lib`; the D9 error-state gap becomes impossible. |
| D43 | **`PaymentDataTable` works on host rows.** Local paging and selection only; offset and cursor paging are host callbacks; no sorting or filtering (not in Stripe's props); column reorder and resize on wide layouts only, with a keyboard menu. | Host owns data and queries; nothing the kit computes changes a total. |
| D44 | **`PaymentOnboardingView.completed`** shows a completion state and calls `onCompleted` once. There is no kit timer. Phone layout: a step header plus a collapsible task list. | B11 (no kit timers that act on their own); the host owns navigation. |

## 9. Variant governance

0. **Parity admission (new).** A prop on the Stripe component's page is admitted as a variant under the parity decision (clause (c)). The PR cites the Stripe page and the §6 mapping row. It still meets B1–B13, and a constraint conflict is recorded in D28 instead of being built.
1. **Admission for everything else.** A variant that is not a Stripe prop (enum value, boolean mode or named constructor) needs **two real uses that differ in meaning**, in `lib/` or in the example's Tier 2 screens. Looks alone do not count. Each use is cited in the PR.
2. **No per-screen variants.** A variant named after a screen or pattern (`checkoutPrimary`) is refused. The pattern composes existing variants.
3. **Brand differences are tokens, not variants.** Corner radius, fonts, weights and colors go through `PaymentTheme.copyWith`. A request like "a rounder primary for brand X" is a token change.
4. **Naming.**
   - One enum per component for emphasis or look: `<Component>Variant` (`PaymentButtonVariant`, **New** `PaymentIconButtonVariant`, **New** `PaymentLinkVariant`, **New** `AmountTextVariant`).
   - Shared axis enums when Stripe shares the scale: **New** `PaymentSize` (small / medium / large), **New** `PaymentWidth` (fill / hug). Otherwise `<Component><Axis>` (**New** `PaymentListItemSize`, **New** `PaymentFocusViewSize`).
   - Status color always uses the shared `StatusTone`, never a per-component tone enum.
   - A single binary meaning stays a `bool` named for the meaning (`destructive`, `hatched`, `external`, `reference`, `indeterminate`, `fitted`).
5. **Closed sets.** Every docs page lists the variants and says "nothing else exists". `switch` statements over variant enums are exhaustive, with no `default:`.
6. **Deprecation in 0.x.**
   - A replaced parameter, value or class on `main` is marked `@Deprecated('Use … — removed in 0.<n+1>.0')` for one minor release, with a CHANGELOG entry and a migration snippet on the docs page (D34).
   - Removal happens in the next minor release.
   - Names that were never on `main` (PR #1, PR #4 before merge) may change without deprecation.
7. **Removal.** A variant with no remaining use is deprecated by the same rule. A Stripe-parity variant is kept while Stripe lists the prop.

## 10. Docs and specimen requirements

**Foundation pages** (`website/src/content/docs/foundations/`):

| Page | Must contain |
| --- | --- |
| `color.mdx` | Full §3.1 table, both flowcharts from §3.0, the scrim exceptions, `PaymentTextColor` |
| `typography.mdx` | §3.2 role table, modifiers, 200% rules, `PaymentType` API, the Stripe role mapping |
| `spacing.mdx` | §3.3 and §3.4 tables, `PaymentSpace`, `PaymentRadius` |
| New `surfaces.mdx` | §3.5 table, `PaymentBox` recipes |
| New `iconography.mdx` | §3.6 sizes, `PaymentIconSize`, `PaymentIcons`, payment-status icons |
| `motion.mdx` | §3.7 table |
| `focus.mdx` | §3.8 table, the D29 hit-area rule |
| `money.mdx` | §3.9 table and dates |

**Component pages** add the following to B12:

- **Specimen screenshot** showing every variant × the key states, in light and dark, plus 200% where the component is text-heavy.
  - Name: `ios_catalog_<component>_variants`, `_variants_dark`, `_variants_200`. In `catalog_screenshots_test.dart`, `shot('<component>_variants$look')`, since `shot()` adds the `${platform}_catalog_` prefix.
- A **"Stripe → kit"** table and a **"Which variant when"** table, copied from §6.
- **Do / don't pairs:** one correct and one incorrect snippet from real call sites.
- A **closed-set sentence:** "Variants: …. Nothing else exists."
- The **example screen** that uses it (B13), with its §1 payment use.

**Specimen captures.** There is one set per component. `<component>` is the snake-case slug:

| Group | Components (slug) | `_200` required |
| --- | --- | --- |
| Stripe parity (48) | `accordion`, `badge`, `banner`, `bar_chart`, `box`, `button`, `button_group`, `checkbox`, `chip`, `code`, `context_view`, `currency_field`, `data_table`, `date_field`, `date_range_picker`, `detail_page`, `detail_page_property_list`, `detail_page_table`, `divider`, `focus_view`, `form_field_group`, `full_page_view`, `icon`, `image`, `inline`, `line_chart`, `link`, `list`, `menu`, `meter_chart`, `onboarding_view`, `overview_page`, `property_list`, `radio`, `search_field`, `select`, `settings_view`, `sign_in_view`, `sparkline`, `spinner`, `switch`, `table`, `tabs`, `task_list`, `text_area`, `text_field`, `toast`, `tooltip` | All except `box`, `divider`, `icon`, `image`, `spinner`, `sparkline` |
| Kit-specific | `icon_button`, `copy_button`, `dialog`, `sheets`, `section`, `navigation`, `step_indicator`, `amount_text`, `info_row`, `countdown`, `privacy_mask`, `action_bar`, `media`, `status_header`, `loading_skeleton`, `state_message`, `chart_module` | `dialog`, `sheets`, `info_row`, `action_bar`, `state_message`, `chart_module` |

- **Phone vs wide.** The captures are phone-width (iPhone 16 simulator) and show the narrow layout of tables, views and pages. Wide layouts (two columns, table columns, side-sheet FocusView, onboarding sidebar) are verified by widget tests at a 1024 dp `tester.view` size. They are captured only if an iPad simulator is available; a missing one does not block a phase.
- **Example gallery.** `example/lib/screens/gallery_kit.dart` gets one **New** `_Specimen` per component. Each one is a grid of variants × states with synthetic data only: no real names, no unmasked NIK, no real bank account numbers. The capture test drives each entry in light, dark and, where required, `TextScaler.linear(2)`. Captures are registered in `website/scripts/screens.mjs`. The docs use only `example/build/screenshots_hairline`.

## 11. Phased plan

Per the owner's standing rule, every PR stops before merge, and a merge needs the owner to name the destination. Each PR is small, and §12 gives its acceptance criteria. A Phase 4 group may be split further if a PR passes about 1,500 changed lines in `lib/`.

### Phase 0: land what exists

- PR #3 (revision 1) is merged to `main` (`f74b882`).
- **Merge PR #1, then PR #4, then PR #5 (this PRD) to `main`.** That is the owner's decision, after each PR's own verification.
- Phase 1 branches from `main` once they are merged. While they are open, Phase 1 stacks on `feat/charts-kyc-capture` and never edits files those PRs are still changing.

### Phase 1: foundations public API and token docs (two PRs)

**1A: type and token API.**

- Export `PaymentType` (D15); add `firstLineHeight` and replace its 8 copies; add `tabular(style)` and `reference(style)`; deprecate `amountStyle(large:)`.
- **New** token enums (D29, D33): `PaymentSize`, `PaymentWidth`, `PaymentSpace` + `PaymentTheme.space`, `PaymentRadius`, `PaymentTextRole`, `PaymentTextColor`, `PaymentFontWeight`, `PaymentIconSize`, `PaymentFieldPart`.
- **New** `PaymentIcons` and the internal tone→icon helper, replacing the two copies.
- **New** `PaymentLocalizations.formatDate` and `dateInputPattern` (D36).
- Align the `StateMessage` padding dartdoc; fix the Contrast brand radius comment; audit the icon family.
- Tests: role values at scale 1; `firstLineHeight` at 1× and 2×; each enum resolves to the §3 value; `formatDate` in en and id; the export surface.

**1B: foundation pages.** Token tables for all §3 pages; new `surfaces` and `iconography` pages; the Stripe role and size mappings.

### Phase 2: adopt and variant gaps (five PRs)

**2A: adopt.** No public API change beyond D12's visual change:

- `PaymentCheckbox` in `VerificationIntro` and `PaymentConfirmation`; the `PaymentRadio` mark in `PaymentMethodPicker`.
- `PaymentDivider` for the 11 raw dividers, `ActionTileGroup` included.
- `PaymentSpinner` in video loading (on the black picture area, `video.dart:365`).
- The `KycCaptureGuide` `errorBuilder` (D9; switches to `PaymentImage` in 4A).
- The internal `_RowShell` (D19).

**2B: Button and Text variants.**

- **New** `PaymentButton.size` (D29) with the 48 dp layout box; **New** `width: PaymentWidth`; **New** `autofocus`.
- The dialog adopts `PaymentButton` with `hug` and `autofocus` (D23).
- **New** `AmountTextVariant` (D24); the three literal-w600 Total rows migrate.
- The `CountdownText` default style.

**2C: feedback renames and variants** (D34, D38).

- `StatusBadge` → **New** `PaymentBadge` (+ `.urgent`, optional icon, 1.6× icon, D20); `NoticeBanner` → **New** `PaymentBanner` (actions assert, D21). `onDismiss` waits for 3B, because its control is a `PaymentIconButton`.
- `showPaymentSnackBar` → **New** `showPaymentToast` + `PaymentToastController` (`pending`, `update`, `dismiss`) on ink tokens (D22).
- `PaymentSpinner.size` → `PaymentSize`, + `delay`; `PaymentTooltip` + `placement`, `type`, `delay` (D40).
- Deprecated aliases or wrappers for every renamed class.

**2D: navigation, list and control parity** (D34, D40, D41).

- `ActionMenu` → **New** `PaymentMenu` with `PaymentMenuItem`, `PaymentMenuGroup` and `onAction`. The custom `trigger` comes in 3B.
- `ExpandableSection` → **New** `PaymentAccordionItem` (+ `actions`) and **New** `PaymentAccordion`. `media` comes in 4A.
- `ActionTile`/`ActionTileGroup` → **New** `PaymentListItem`/`PaymentList` (+ `value`, `size`, `id`, `onAction`). `image` comes in 4A.
- `PaymentTabs` + `tabs: List<PaymentTab>`, `size`, `fitted`; **New** `PaymentTabPanels`.
- `PaymentCheckbox` + `indeterminate`; Checkbox, Radio and Switch + `errorText`, `required`, `hiddenElements`.
- `AmountInput` → **New** `PaymentCurrencyField` (+ `size`, `description`, `padFractionDigits`). `currencies` comes in 4B, with `PaymentSelect`.

**2E: chart parity** (D39). `axis`, `grid`, `showLegend`, `series`, `unit` + `ChartPoint.measure`, sparkline `inspectable`, meter `onSegmentPressed`; chart dartdoc (B1) and token spacing (B2); remove `MeterSegment.color` (Q9). If PR #4 is still open, these can go into PR #4 if the owner prefers.

Screenshots to re-take and inspect in Phase 2: `controls_choices` (light and dark), KYC intro (light and `_200`), `requote`, video loading, the confirm dialog, the toast, history list, the action bar, every renamed component's specimen.

### Phase 3: extract (two PRs)

**3A: text fields.** **New** `PaymentTextField` with `.search` and the parity props; migrate `PaymentCurrencyField`, `PromoCodeInput`, `IdentityForm` and `TransactionHistory`.

```dart
PaymentTextField({
  Key? key,
  required String label,
  TextEditingController? controller,
  FocusNode? focusNode,
  String? hint,                               // Stripe placeholder
  String? description,                        // Stripe description (was helper)
  StatusTone descriptionTone = StatusTone.neutral, // IdentityForm "needs update" = warning
  String? errorText,                          // host/server error (forceErrorText)
  FormFieldValidator<String>? validator,      // runs inside a Form
  bool required = false,
  Set<PaymentFieldPart> hiddenElements = const {},
  PaymentTextFieldType type = PaymentTextFieldType.text, // no password (D1a)
  PaymentSize size = PaymentSize.medium,      // D29: 40/48/56 visual, ≥ 48 box
  PaymentWidth width = PaymentWidth.fill,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  TextInputAction? textInputAction,
  List<TextInputFormatter> inputFormatters = const [],
  TextCapitalization textCapitalization = TextCapitalization.none,
  Iterable<String>? autofillHints,            // overrides the type default
  bool enabled = true,
  bool readOnly = false,
  bool reference = false,                     // referenceFontFamily (promo code)
  String? prefixText,
  Widget? prefixIcon,
  Widget? suffix,
}) // no obscureText (D1a)

PaymentTextField.search({
  Key? key,
  required String query,
  required ValueChanged<String> onChanged,
  String? label,            // default: new generic l10n.search
})
```

- **Tests** (`test/text_field_test.dart`): B3–B10 at each `PaymentSize`; a server error clears after an edit; focus moves to the first invalid field; the search clear button resets `query`; the ring and the border never show together; `hiddenElements` keeps the hidden label in semantics; no `type` value produces `obscureText`.

**3B: icon button, link and copy.** **New** `PaymentIconButton` (D18), `PaymentLink` (D11, `PaymentLinkVariant`) and `PaymentCopyButton` (D3). Migrate the 10 icon buttons, the 5 inline actions and the 2 copy sites. With `PaymentIconButton` available, add `PaymentBanner.onDismiss` and `PaymentMenu.trigger`.

```dart
PaymentLink({
  Key? key,
  required String label,
  required VoidCallback? onPressed,      // host opens URLs; the kit never launches
  bool external = false,                 // trailing open_in_new + "opens outside the app" hint
  PaymentLinkVariant variant = PaymentLinkVariant.primary, // .secondary = caption, underlined
  String? semanticLabel,
})

PaymentCopyButton({
  Key? key,
  required String value,
  required Future<bool> Function(String value) onCopy, // host owns the clipboard
  String? tooltip,                                     // default l10n.copy
})
```

- **New strings** (en and id): `opensExternally`, a generic `search`, `hideBanner`, `moreActions`, `selected(n)`, `pageOf(n, m)`, `mixed`, `optional`, `enterValidDate`, `noResults`, `resultsCount(n)`.
- **Tests** (`test/link_copy_test.dart`): as in revision 2 (48 dp, one node, tooltip spoken, external hint, copy outcome announced, single call while pending, B6 for `secondary` links, the three formerly ring-less sites show the ring).

### Phase 4: parity build-out (four groups, 2–4 PRs each)

Each component lands with its dartdoc, a widget test file covering B3–B10 and its D-decision, a `_Specimen`, captures, and a docs page (B12). The order follows dependencies: later groups compose earlier ones.

**4A: layout primitives.** `PaymentBox`, `PaymentInline` + `PaymentSpan`, `PaymentIcon`, `PaymentImage`, `PaymentCode`; `PaymentDivider` docs (no Stripe props). Migrations: `KycCaptureGuide` photo → `PaymentImage`; the VA number → `PaymentCode(size: large, onCopy:)`; raw `Icon` sites with literal sizes → `PaymentIcon`. Deferred props that need these: `PaymentListItem.image`, `PaymentAccordionItem.media`.

**4B: forms.** `PaymentTextArea`, `PaymentSelect` (+ `.multiple`), `PaymentDateField`, `PaymentDateRangePicker`, `PaymentFormFieldGroup`, `PaymentSearchField` (+ `.multiple`), `PaymentChip` + `PaymentChipList`. Migrations: the applied-promo tag → `PaymentChip(onClose:)`; **New** `IdentityFieldSpec.kind` (D36); `PaymentCurrencyField.currencies` on `PaymentSelect`.

**4C: content.** `PaymentPropertyList`, `PaymentTable`, `PaymentDataTable`, `PaymentTaskList`, `PaymentButtonGroup`; the `table` skeleton shape. Migrations: the status-screen action stack and dialog actions → `PaymentButtonGroup`; status and receipt detail sections → `PaymentPropertyList`.

**4D: views and pages.** `PaymentContextView`, `PaymentFullPageView`, `PaymentFocusView` + `showPaymentFocusView`, `PaymentSettingsView`, `PaymentSignInView`, `PaymentOnboardingView`; `PaymentPageModule`, `PaymentDetailPage`, `PaymentOverviewPage`, `PaymentDetailPagePropertyList`, `PaymentDetailPageTable`.

### Phase 5: pattern adoption (example screens)

Every parity component reaches its §1 payment use in the example, reachable from the scenario picker:

- KYC onboarding (`PaymentOnboardingView` + `PaymentTaskList`), with `IdentityForm` using `PaymentSelect`, `PaymentDateField`, `PaymentFormFieldGroup` and a `PaymentSearchField` province.
- History as a `PaymentFullPageView` with tabs, a `PaymentDateRangePicker` filter and active-filter chips; the spending overview (`PaymentOverviewPage` + `ChartModule`, two-series bar chart) (D10).
- Transaction detail as a `PaymentDetailPage` (property list module + attempts table), with "Report a problem" (`PaymentFocusView` + `PaymentTextArea`) and `TransactionDetail.onCopyReference` (Q5).
- Settlement statement (`PaymentDataTable`); fee schedule (`PaymentTable`).
- Settings (`PaymentSettingsView`); sign-in (`PaymentSignInView`); order context beside checkout on wide windows (`PaymentContextView`).

### Phase 6: docs information architecture

- **Sidebar.** `Start`, `Concepts`, `Foundations` (Color, Typography, Spacing and radius, Surfaces, Iconography, Motion, Focus and press, Money and dates, Localization). Then **`Components`, one alphabetical list like Stripe's sidebar**: the 48 Stripe names plus the kit-specific components, each under its kit display name (Accordion, Action bar, Amount text, Badge, Banner, Bar chart, Box, Button, Button group, Chart module, Checkbox, Chip, Code, Context view, Copy button, Countdown, Currency field, Data table, …). Then `Patterns`, then `Reference`.
- **Components overview page** keeps the grouping (Layout, Actions and navigation, Content, Forms, Charts, Feedback, Overlays, Views and pages), with a "Stripe Apps name → kit class" column and a status column.
- **Patterns.** "Payment flows" becomes Patterns; KYC capture absorbs `components/capture-source-sheet` (D14); new Views and pages, and Tables on phones.
- **Redirects** through the existing mechanism (`astro.config.mjs` `redirects`, `public/_redirects`, `netlify.toml`): `expandable-section` → `accordion`, `status-badge` → `badge`, `notice-banner` → `banner`, `action-menu` → `menu`, `amount-input` → `currency-field`, `action-tile` → `list`.
- **Specimens.** One `_Specimen` per component and `<component>_variants[_dark|_200]` captures (§10); the `controls_*` captures are renamed (D27).
- The "Not in the kit" page lists only the D28 non-mirrored props, with reasons.

## 12. Acceptance and verification

### Every phase

These are local commands; the repo has no CI.

- **Format and analyze.** `dart format --output=none --set-exit-if-changed .`, then `flutter analyze` in the package and in `example/`.
- **Package tests.** Run file by file: `flutter test --no-pub test/<file>.dart`. The full suite intermittently fails to load on this machine with a `flutter_tester` WebSocket error (`docs/decisions.md`).
- **Integration flow.** `cd example && flutter test --no-pub integration_test/flow_test.dart -d <iPhone 16 / iOS 18.1 simulator>`; all existing tests pass.
- **Screenshots.** `catalog_screenshots_test.dart` on the same simulator. Each new or changed capture is opened and inspected: light, dark, and 200% where required.
- **Docs.** In `website/`: `pnpm build`, `pnpm check:links` (0 broken), `pnpm check:snippets` (0 problems).
- **Identifier check.** Every backticked PascalCase identifier on a changed docs page exists in `lib/`, or is marked **New**.
- **Boundary grep (B11).** `grep -rn "Clipboard\|dart:io\|http\|launch\|NetworkImage(\|obscureText:" lib` stays empty (the dartdoc may name them; calls and arguments may not); `pubspec.yaml` dependencies stay `flutter` only.

### Phase-specific acceptance

| Phase | Happy flow | Edge states | Security | Performance |
| --- | --- | --- | --- | --- |
| 0 | `main` builds and passes the above with #1, #4 and #5 merged | — | Unchanged | Unchanged |
| 1A | A host styles text with `PaymentType.of(context).caption` and spacing with `PaymentTheme.space(PaymentSpace.group)`; the kit renders unchanged | Roles at 1× and 2×; `firstLineHeight` matches the old formula; `formatDate` en/id; deprecated `amountStyle(large:)` compiles | Export surface grows only by the listed types; no new dependency | No new rebuilds |
| 1B | Every foundation page shows its full token table and Stripe mapping | 320 px pages do not scroll sideways | Synthetic values only | WebP only |
| 2A | KYC → checkout → pay → receipt unchanged in `flow_test` | Disabled method reason; re-quote checkbox aligned at 100% and 200%; video loading under reduced motion; KYC photo error shows the frame | No behavior change | Widget count equal or lower |
| 2B | Every size of `PaymentButton` presses from anywhere in its 48 dp box; dialog, action bar and Total rows render as before | `small` button: `getSize` ≥ 48×48 and a tap 4 dp outside the visual activates it; dialog at 200% stacks; destructive dialog focuses cancel; `hug` wraps, never truncates | No behavior change | No added layout passes; `size` adds no `LayoutBuilder` |
| 2C | Badges, banners and toasts keep their meaning with icon + words under the new names; old names compile with a deprecation warning | `urgent` badge contrast ≥ 4.5:1 light and dark; pending toast never times out, `update` replaces it, `dismiss` closes it; tooltip flips at screen edges; spinner `delay` shows nothing for a 100 ms wait | No user data in new strings | One `Timer` per delayed spinner, canceled on dispose |
| 2D | Menu groups, accordion items, list items with values, fitted tabs, indeterminate checkbox and currency field sizes work by touch and keyboard | Disabled tab skipped by arrow keys; `PaymentTabPanels` keeps offstage panels unfocusable; `large` list item at 200%; select-all checkbox toggles from mixed | Old names compile with a deprecation warning; no new data enters the kit | Tab panels keep state without rebuilding hidden panels |
| 2E | Two-series spending chart is readable with legend and inspection | Series distinguishable in grayscale (dash + ramp); `axis: none`; percent unit; meter segment pressed through the legend; sparkline `inspectable` box ≥ 48 dp | Values are host `Money` or `measure`; the kit computes no totals | Paint-only (no `AnimationController` in `lib/src/charts`) |
| 3A | Identity form submits; amount parses; promo applies; search filters | P01 (empty, zero, over limit, pasted formatted amount); K02 (non-ASCII name, server error clears on edit, focus to first error); every `size` at 200%; hidden label still spoken | NIK still masked in review; no `obscureText`, no `password` type; no new dependency | No extra rebuilds per keystroke |
| 3B | Copy VA number and receipt ID; open policy; edit from review; close sheets; dismiss promo; clear search | P15 (clipboard fails → "copy failed"); double tap while pending; external hint spoken; all 10 icon buttons show the ring on Tab; banner dismiss reports once and the host removes it; custom menu trigger opens the menu | Copy only receives host-passed values, never NIK; no `Clipboard`, `url_launcher` or `dart:io` in `lib` | Static press scale only (100 ms; 0 under reduced motion) |
| 4A | VA block renders as `PaymentCode` with copy; KYC photo, promo media and bank logo render through `PaymentImage`; a Box/Inline specimen matches §3 tokens | Image loading → error fallback with alt text; `kbd`/`samp`/`pre` at 200%; `noWrap` scrolls inside the block only; decorative icon not in semantics | No `NetworkImage` constructed in `lib`; VA digits spoken in groups, never logged | Image fade uses `quick` and is 0 under reduced motion; no image decoding in `build` |
| 4B | Date of birth by typing and by picker; occupation by select; province by search; history date range applied and shown as a chip | Partial date shows no error; invalid date; out-of-range host error; 38-option search at 200% with the keyboard up; no results; multi-select apply; chip close is its own 48 dp target | Date rules, ranges, presets and the currency list are host-supplied; search runs locally or through the host callback; no free text logged | Local filtering of 1,000 options stays under one frame (16 ms) in a profile-mode widget benchmark |
| 4C | Statement table pages, selects and runs a row action; fee table shows a total footer; KYC task list reflects host statuses; receipt actions group | Narrow collapse at 320 dp and 200%; select-all indeterminate; empty with create action; error with retry; cursor paging calls the host; blocked task spoken; button group collapses into a menu | Rows, totals and statuses come from the host; the kit sums nothing | `.local` paging of 1,000 rows builds only 25; narrow layout is a lazy list |
| 4D | Each view hosts in a plain `Scaffold` body, a tab and (FocusView) a sheet; sign-in calls the host; settings save shows busy then "Saved"; onboarding completes and calls `onCompleted` once | Phone vs 1024 dp layouts (widget tests); FocusView confirm-close on back, scrim and close; sign-in error banner gets focus; pending pages show skeletons; breadcrumbs collapse to the parent | `PaymentSignInView` subtree has no `EditableText`; no router or `Navigator.push` outside `showPaymentFocusView`; no kit timer in onboarding | One rebuild per host state change; two-column layout switches by constraints, not `MediaQuery` polling |
| 5 | Every §1 payment use is reachable from the scenario picker; `flow_test` covers sign-in → KYC onboarding → checkout → detail page → report a problem | Each new screen in light, dark and 200%; Indonesian strings at 200% | Synthetic data only (no real names, NIK, bank accounts) | The existing perf harness checkout workload is unchanged |
| 6 | Every component has a page that meets B12 with a specimen; the sidebar lists all components alphabetically | Redirects resolve; 320 px pages do not scroll sideways | Docs screenshots use synthetic data only | `dist/` size noted; WebP only |

**Done for this initiative:**

- Every foundation page has its full token table.
- All 48 Stripe entries and the kit-specific components are Have, with B1–B13 checked, a variant specimen and a docs page.
- No Tier 2 file contains a private copy of a Tier 1 control. Review grep: no `CheckboxListTile`, `_Radio`, `OutlineInputBorder`, raw `Divider(`, `IconButton(`, `TextButton(` or `CircularProgressIndicator` outside `lib/src/controls` and `lib/src/foundation`.
- The deprecated names from D34 are removed in the following minor release.
- "Not in the kit" lists only the D28 non-mirrored props.

## 13. Non-goals, risks, open questions

### Non-goals

- Mirroring the props listed as not mirrored in D28: password inputs, sub-minor-unit amounts, raw CSS and numeric layout props, DOM attributes, SVG strings, kit-side time zones, kit timers that navigate.
- Components or variants that are not on Stripe's list, unless they pass the admission rule and §9 rule 1 (for example: a compact list density, table sorting, inset dividers).
- A router, deep links, URL launching, or an app bar owned by the kit (D31).
- PIN, OTP or password fields, or any secret input. A photo-grid gallery browser.
- New dependencies, network calls, camera or clipboard access inside `lib`.
- Bundled fonts, an icon package or an SVG renderer.
- Exporting `PaymentFocusRing` or `PaymentPressScale` without owner approval.

### Risks

| Risk | Mitigation |
| --- | --- |
| **Catalog filler** (PRD.md §2): 25 Build components could become a screenshot gallery | Every parity component has a §1 payment use, is reachable in Phase 5, and meets B13 before its page says Have |
| Public API grows from about 40 to about 90 types in 0.x | Sketches are reviewed before code; constructors take only Stripe props and existing call-site needs; §9 rule 0 requires the Stripe citation |
| Renames break hosts that track `main` | D34 aliases or wrappers for one minor release; CHANGELOG migration snippets; redirects for docs slugs |
| D29 makes small controls take 48 dp of layout | Documented on the Button and Focus pages; specimens show small buttons in a module header, where 48 dp is already the row height |
| Tables on phones read worse than a real table for wide statements | The D30 collapse keeps every cell with its header label; the wide layout is unchanged; the statement example is inspected at 320 dp and 200% |
| Tooltip on `OverlayPortal` diverges from Flutter's `Tooltip` behavior (long-press, hover, dismiss) | Widget tests for hover, long-press, focus and Escape; reduced motion; keep `PaymentTooltip`'s current 500 ms default |
| Visible changes: receipt copy feedback; method picker disabled icon; dialog buttons; toast colors; history search focus; icon recolors (D18); renamed docs URLs | Listed in CHANGELOG per PR; before and after screenshots inspected |
| Variant creep after the system is public | §9 on the components overview page; reviewers check the Stripe citation or the two-use citation |
| `IdentityForm` regression from field kinds: server errors, focus order, autofill | Existing K02/K07 tests, plus per-kind tests in 4B |
| Branch churn: #1, #4 and #5 unmerged | Phase 1 waits for Phase 0 or stacks on #4; it never edits files those PRs are changing |
| Machine limits (8 GB, flaky full-suite loads) slow a 48-specimen capture run | Per-file test runs; captures per phase, not all at once; one simulator session |

### Owner decisions (resolved 31 Oct 2026)

The owner accepted every recommendation below on 31 Oct 2026. The parity decision later that day superseded some of them, as marked.

1. **Date of birth / field kinds.** ~~Decided: no (D4).~~ **Superseded by parity: yes.** `IdentityFieldSpec.kind` (`text`, `date`, `choice`) with `PaymentDateField` and `PaymentSelect` (D36).
2. **Switch and Tooltip have no Tier 2 consumer.** Decided: keep. **Resolved by parity:** the `PaymentSettingsView` example gives `PaymentSwitch` a real use; `PaymentTooltip` is used for the fee info icon in the fee table.
3. **Export `PaymentFocusRing` and `PaymentPressScale`?** **Decided: keep them internal.** Unchanged.
4. **Sidebar wording.** **Decided: "Patterns".** Unchanged. The Components list is now alphabetical (Phase 6).
5. **`TransactionDetail` reference copy.** **Decided: yes** (`onCopyReference`), in Phase 5.
6. **Export `PaymentType`** (D15). **Decided: yes.** Unchanged.
7. **Button sizes.** ~~Decided: `hug` only.~~ **Superseded by parity:** `PaymentSize` small / medium / large plus `PaymentWidth`, with the D29 rule that the layout box stays ≥ 48 dp.
8. **List density variant?** ~~Decided: no.~~ **Superseded in part:** Stripe's ListItem has `size: default | large`, so **New** `PaymentListItemSize.standard / .large` ships (both ≥ 48 dp). A compact density is still refused, because Stripe has none and it would break B5.
9. **`MeterSegment.color`.** **Decided: remove it.** Unchanged; Stripe's Meter has no per-segment color.
10. **Toast restyle** (D22). **Decided: yes.** Unchanged.

### Open questions (revision 3)

11. **Stripe text roles.** Stripe's Inline has nine `font` roles, and five of them (`subtitle`, `subheading`, `lead`, `bodyEmphasized`, `kicker`) have no matching `PaymentType` role. Map them onto the existing nine roles (§3.2 table), or add roles to `PaymentType`? **Resolved: map (D35).** D15 just froze nine roles as public API. `lead` and `kicker` would add looks with no second use, and a larger `lead` would compete with the one display amount per screen.
12. **Typed date order in English.** `MoneyFormat.en` follows US separators. Should `PaymentDateField` typed entry use `MM/DD/YYYY` in `en`, or `DD/MM/YYYY` in both locales? **Resolved: `DD/MM/YYYY` in both, overridable by the host, with the pattern always shown as the hint and the picker as the primary path.** The kit's users are in Indonesia even when the UI is in English. A per-locale order would make the same date of birth type differently after a language switch.

## 14. Issue checklist

```markdown
### Design system: full Stripe Apps parity (docs/prd-foundation-components.md, revision 3)

**Phase 0: land what exists**
- [x] PR #3 merged: foundation PRD on main (f74b882)
- [x] Owner answers Q1–Q10 (31 Oct 2026)
- [x] Owner decision: full Stripe Apps parity, 48 components (31 Oct 2026)
- [x] Owner reviews revision 3 (D28–D44) and answers Q11–Q12
- [ ] Merge PR #1 (docs/component-catalog) to main (owner)
- [ ] Merge PR #4 (feat/charts-kyc-capture, stacked on #1) to main (owner)
- [ ] Merge PR #5 (docs/design-system-prd) to main (owner)
- [ ] Record Q1–Q12 and D28–D44 in docs/decisions.md

**Phase 1A: type and token API**
- [x] Export PaymentType; firstLineHeight (replace 8 copies); tabular/reference; deprecate amountStyle(large:) (D15)
- [x] Token enums: PaymentSize, PaymentWidth, PaymentSpace + PaymentTheme.space, PaymentRadius, PaymentTextRole, PaymentTextColor, PaymentFontWeight, PaymentIconSize, PaymentFieldPart
- [x] PaymentIcons + internal tone→icon helper (replace 2 copies)
- [x] PaymentLocalizations.formatDate + dateInputPattern (D36)
- [x] StateMessage padding dartdoc; Contrast radius comment; icon family audit

**Phase 1B: foundation pages**
- [x] Token tables + Stripe mappings: color, typography, spacing and radius, motion, focus, money and dates
- [x] New pages: Surfaces, Iconography

**Phase 2A: adopt**
- [x] PaymentCheckbox in VerificationIntro + PaymentConfirmation; PaymentRadio mark in PaymentMethodPicker (D12)
- [x] 11 raw dividers (incl. ActionTileGroup) → PaymentDivider
- [x] Video loading → PaymentSpinner; KycCaptureGuide errorBuilder (D9)
- [x] Internal _RowShell (D19)

**Phase 2B: Button and Text variants**
- [x] PaymentButton size (small/medium/large, 48 dp box, D29), width (PaymentWidth), autofocus
- [x] showPaymentConfirmDialog uses PaymentButton (hug + autofocus) (D23)
- [x] AmountTextVariant; deprecate emphasis; migrate total rows (D24); CountdownText default style

**Phase 2C: feedback renames and variants**
- [x] StatusBadge → PaymentBadge (+ .urgent, optional icon, 1.6× icon) (D20, D38)
- [x] NoticeBanner → PaymentBanner (actions assert) (D21, D38)
- [x] showPaymentSnackBar → showPaymentToast + PaymentToastController (pending/update/dismiss), ink tokens (D22, D38)
- [x] PaymentSpinner PaymentSize + delay; PaymentTooltip placement/type/delay on OverlayPortal (D40)
- [x] Deprecated aliases/wrappers + CHANGELOG migration (D34)

**Phase 2D: navigation, list and control parity**
- [x] ActionMenu → PaymentMenu (+ PaymentMenuItem, PaymentMenuGroup, onAction)
- [x] ExpandableSection → PaymentAccordionItem (+ actions) + PaymentAccordion
- [x] ActionTile/ActionTileGroup → PaymentListItem/PaymentList (+ value, size, id, onAction) (D41)
- [x] PaymentTabs (tabs: PaymentTab, size, fitted) + PaymentTabPanels
- [x] Checkbox indeterminate; Checkbox/Radio/Switch errorText, required, hiddenElements
- [x] AmountInput → PaymentCurrencyField (+ size, description, padFractionDigits)

**Phase 2E: chart parity**
- [x] axis, grid, showLegend, series (≤3), unit + ChartPoint.measure; sparkline inspectable; meter onSegmentPressed (D39)
- [x] Chart dartdoc (B1), token spacing (B2), remove MeterSegment.color (Q9)

**Phase 3A: text fields**
- [ ] PaymentTextField (size, type without password, description, required, hiddenElements) + .search; docs, tests, specimen
- [ ] Migrate PaymentCurrencyField, PromoCodeInput, IdentityForm, TransactionHistory

**Phase 3B: icon button, link and copy**
- [ ] PaymentIconButton; migrate 10 sites (D18)
- [ ] PaymentLink (PaymentLinkVariant primary/secondary, external); migrate 5 inline actions
- [ ] PaymentCopyButton; migrate 2 copy sites
- [ ] PaymentBanner.onDismiss and PaymentMenu.trigger on PaymentIconButton

**Phase 4A: layout primitives**
- [ ] PaymentBox (D33)
- [ ] PaymentInline + PaymentSpan (D33, D35)
- [ ] PaymentIcon (+ .tone); migrate literal-size Icon sites
- [ ] PaymentImage (D42); KycCaptureGuide photo, promo media; PaymentListItem.image, PaymentAccordionItem.media
- [ ] PaymentCode (+ copy); VA number block
- [ ] Divider docs page (no Stripe props)

**Phase 4B: forms**
- [ ] PaymentTextArea
- [ ] PaymentSelect (+ .multiple); IdentityFieldSpec.kind (D36); PaymentCurrencyField.currencies
- [ ] PaymentDateField (D36)
- [ ] PaymentDateRangePicker (presets, granularity) (D36)
- [ ] PaymentFormFieldGroup
- [ ] PaymentSearchField (+ .multiple) (D37)
- [ ] PaymentChip + PaymentChipList; migrate the applied-promo tag

**Phase 4C: content**
- [ ] PaymentPropertyList + PaymentPropertyListItem
- [ ] PaymentTable (+ row, header cell, cell; narrow collapse) (D30)
- [ ] PaymentDataTable (columns, cell types, row actions, selection, pagination, reorder/resize) (D30, D43)
- [ ] PaymentTaskList + PaymentTaskListItem
- [ ] PaymentButtonGroup; migrate status stack and dialog actions (D23)
- [ ] LoadingSkeleton table shape

**Phase 4D: views and pages**
- [ ] PaymentContextView, PaymentFullPageView (D31)
- [ ] PaymentFocusView + showPaymentFocusView (size, confirmClose) (D31, D40)
- [ ] PaymentSettingsView
- [ ] PaymentSignInView (no credential inputs, no EditableText test) (D32)
- [ ] PaymentOnboardingView (onCompleted, phone layout) (D44)
- [ ] PaymentPageModule, PaymentDetailPage, PaymentOverviewPage
- [ ] PaymentDetailPagePropertyList, PaymentDetailPageTable

**Phase 5: pattern adoption (example)**
- [ ] KYC onboarding with task list and field kinds
- [ ] History full page + date range filter + active-filter chips; spending overview (D10)
- [ ] Transaction detail page (property list + attempts table); report a problem focus view; onCopyReference (Q5)
- [ ] Settlement statement (DataTable); fee schedule (Table)
- [ ] Settings view; sign-in view; order context view on wide checkout
- [ ] flow_test: sign-in → KYC onboarding → checkout → detail page → report a problem

**Phase 6: docs IA**
- [ ] Sidebar: Foundations; Components as one alphabetical list (48 Stripe + kit-specific); Patterns; Reference
- [ ] Components overview: groups + Stripe name → kit class + status
- [ ] Redirects: expandable-section, status-badge, notice-banner, action-menu, amount-input, action-tile
- [ ] Every component page: Stripe → kit table, closed variant set, which-variant-when, do/don't, example screen
- [ ] `_Specimen` per component; captures `<component>_variants[_dark|_200]`; rename controls_* (D27)
- [ ] Patterns: loading, empty and error, forms, views and pages, tables on phones
- [ ] "Not in the kit": D28 non-mirrored props only
- [x] PRD.md §16a row updated to full Stripe parity (revision 3)
```

### Phase 2E implementation notes

Series use solid, long-dash (8/4), and dash-dot (8/3/2/3) encoding. MeterSegment.measure supports percentage and number readings. Inspectable sparklines use press-and-hold tooltips. The headline region derives from the amount line, caption line and section gap.
