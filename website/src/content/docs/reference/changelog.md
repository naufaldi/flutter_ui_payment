---
title: Changelog
description: Changes in Rakit UI, copied from CHANGELOG.md in the repository.
---

Copied verbatim from `CHANGELOG.md`.

## 0.8.0

- Import `PaymentCollection` for lazy, host-built rows and a custom pager. The host controls page replacement, refresh, retry, and empty states, and can keep Previous available on an empty page (#388, D144).
- Opt into record card styling and content-sized trailing controls. Async confirmation can update its action and spoken busy labels while open, so a host can offer Check status after an unconfirmed action without asking the user to send it again (#387, D143).
- Both changes came from the Annota Documents pilot. The Gallery uses a simulated host, not the Annota backend. Native Android checks for collection paging, refresh and retry, record card actions, and async confirmation recovery have not been run. TalkBack announcements for paging states and changing confirmation labels have not been checked.

## 0.7.0

- Added a copyable e-wallet handoff and return block. The host opens the wallet and checks the original payment attempt after return, cancellation, a missing app, or no return. The demo uses a simulated host; no wallet provider has been verified (#376, D138).
- Added a copyable Collection block with host-built rows and paging. Retrying a failed page keeps the earlier results visible (#378, D139).
- Added themeable record cards with separate body, trailing, and footer actions, plus async confirmation that stays open when the host needs to recover from a failed action (#377, D140).
- Added a copyable Find block with cancellable search, match context, and retry (#382).
- `PaymentSheet` can now use an optional height and a bounded, caller-owned scrollable body for lazy content (#381, D141).
- Android device flows, the native keyboard, TalkBack, and the e-wallet sandbox have not been checked yet.

## 0.6.0

- Use **Report a problem** in transaction details to report a duplicate charge, wrong amount, or missing purchase. The sheet prefills the transaction reference, keeps the draft when a send fails, and blocks overlapping sends. It shows the case ID only after the host confirms the submitted report (#370, #367, D137).
- Android device flows, the native keyboard, and TalkBack have not been checked yet.

## 0.5.0

- The mobile Transaction History block now searches and filters the full host dataset. Load more appends results, and retry keeps previously loaded transactions visible. Try it in the example Gallery under **Paged history** (#366, #364, D136).
- The Android demo uses a synthetic data source. No live backend or TalkBack audio on a real device has been checked.

## 0.4.0

- Added a copyable QRIS checkout instructions block with source in the docs and a demo in the example Gallery (#362, #359, D135). It displays the QR image, payee, amount, and expiry supplied by the host app. Check status asks about the same payment attempt; the host app owns payment handoff and confirmation.
- Verified the demo on Android with a non-payment QR code. No live QRIS provider, banking-app handoff, or iOS check has been run.

## 0.3.1

- Android TalkBack announces the sign-in cancellation error without requiring the user to scroll. The banner sits above the pinned actions; in short, large-text layouts, long errors can scroll without clipping the permissions or pushing Continue offscreen (#356, #311).
- The cancellation and retry flow was checked with Android TalkBack. iPhone VoiceOver has not been checked yet.

## 0.3.0

Requires Dart ^3.12.0 and Flutter >=3.44.0. Flutter SDK remains the only runtime dependency.

### Package

- Keep the current checkout total readable during re-quotes. The old total's fade ends immediately if Reduce Motion is enabled mid-fade, including on iOS (#300, #319).
- Checkout authorization phases use a short fade that respects reduced motion (#304).
- Accordions reverse smoothly when tapped again before they finish opening or closing (#306).
- Radio and payment-method selection rings animate without delaying selection and respect reduced motion. Keyboard selection shows the method outline immediately (#309, #321).
- Sign-in and document-upload errors fade in and out without blocking recovery actions. Visible error banners are in Flutter's semantics tree from the first fade-in frame (#312).
- The APIs deprecated in 0.1.0 still compile. Their removal is deferred; new integrations should use the documented replacements.

### Docs site

These update https://rakit-ui.netlify.app.

- The homepage is now a product page, with a hero, a checkout recovery flow, benefits, an ownership table, checkable proof, an FAQ and a clear "Build your checkout" path. It adds a descriptive title with schema.org data, a JPEG social preview, robots.txt with the sitemap and an up-to-date llms.txt.
- A new Try it page and a corrected `../flutter_ui_payment` path-dependency example.
- The homepage lets you switch between success, pending, unknown and changed-total payment screens, shows real component specimens and compares the Hairline and Soft looks.
- A header with section links and Get started, a homepage footer and contact section, and a copy button for the install command. The contact link opens a new GitHub issue, the footer attribution link has a 44 px tap target, and header buttons don't animate under reduced motion.
- The homepage is about 30% shorter on phones: the recovery demo is a sideways strip, the brand looks sit side by side, and repeated copy is gone.
- The documentation site moves to https://rakit-ui.netlify.app. Links to https://flutter-ui-payment.netlify.app redirect to the same page.
- A new guide for adopting Rakit in an existing branded app, with copy-runnable component snippets.
- Buttons and links respond to presses, landing sections fade in, and menus, search and the phone sidebar animate open and closed; everything stays still with reduced motion or without JavaScript, including when reduced motion is turned on while a page is open.
- Component pages drop Stripe prop-mapping tables and Stripe names in API descriptions, repeated host-ownership callouts and internal example-scenario codes; component behavior, API and example screens remain.
- Preview the same checkout and recovery flow in invoice and wallet designs, with re-quotes, replay and a reduced-motion control (#302).
- Wallet checkout shows the merchant, order reference and host-provided verification. Updated Android captures show the payee (#348).
- The docs header menu stays open when activated again during its close fade (#357).

### Contributor tooling and verification

- Keep decision records in order, pin the Flutter and pnpm setup for Amp orbs, and cover method-picker rows at 200% text on a 320 dp screen (#314, #317, #323).
- Require deterministic Flutter widget tests and use local checks as the merge gate instead of GitHub Actions (D129). Scale the proof required to the risk of each change (#355).
- Exercise duplicate checkout submits and account switches with controlled response ordering (#350). Consolidate widget tests around reachable controls, accessible feedback and reduced motion (#346).
- Detect stale docs API metadata and report which requested screenshots and continuation images were captured in the current run (#344). Clarify the wallet checkout capture comment without changing any screenshots (#353).
- The example profile report says whether checkout and status meet the frame budget and explains when the evidence is inconclusive (#347).

## 0.2.0

Requires Dart ^3.12.0 and Flutter >=3.44.0. Flutter SDK remains the only runtime dependency.

- PaymentSettingsView can show a disabled Save with a reason.
- PaymentSearchField shows the host's error above selectable results in the open search sheet, with Retry for host-driven queries.
- Apps can translate Rakit strings and chart numbers through a `PaymentLocalizations` subclass, including the new `formatNumber` member. **Breaking:** exported `KitStrings` and `PaymentStatusLabel` extension names were removed, affecting code that explicitly names them or imports with `show KitStrings` / `show PaymentStatusLabel`; ordinary `PaymentLocalizations.of(context).x` calls keep working.
- Improve disabled Save accessibility, protect kit button sizing from host themes, fix narrow large-text docs layouts and flow-strip focusability, and provide runnable localization examples.
- Names deprecated in 0.1.0 (for example `StatusBadge`, `NoticeBanner`, `ActionTile`, `ActionMenu`, `AmountInput`, `ExpandableSection`, `showPaymentSnackBar`, `pageAction`, `learnMore`, `AmountText.emphasis` and the DataTable reorder/resize flags) still compile in 0.2.0. Their removal moves to 0.3.0 (D123).

### Migrating from 0.1.0

The kit strings are now instance members of `PaymentLocalizations`, so a call on the localizations object compiles unchanged. Only code that names the removed extensions needs an edit:

```dart
// 0.1.0
import 'package:rakit_ui/rakit_ui.dart' show PaymentLocalizations, KitStrings, PaymentStatusLabel;
final label = PaymentStatusLabel(PaymentLocalizations.of(context)).paymentStatusShort(status);
final save = KitStrings(PaymentLocalizations.of(context)).save;

// 0.2.0
import 'package:rakit_ui/rakit_ui.dart' show PaymentLocalizations;
final label = PaymentLocalizations.of(context).paymentStatusShort(status);
final save = PaymentLocalizations.of(context).save;
```

## 0.1.0

First Rakit UI release, continuing the previously published flutter_ui_payment 0.1.0.

- Rename the package to `rakit_ui`, with canonical import `package:rakit_ui/rakit_ui.dart`. Existing widget/model names and runtime behavior are unchanged; replace the old dependency and imports.

First public release. Requires Dart ^3.12.0 and Flutter >=3.44.0; targets Android and iOS phones and tablets.

- Composable checkout, method selection, quote-change approval, payment instructions, pending/unknown/failed status, receipts, refunds and transaction history.
- Optional identity verification UI for consent, document capture guidance, upload recovery, review and correction. Hosts own camera access, uploads and KYC decisions.
- Foundation components for buttons, forms, selection, navigation, overlays, feedback, tables, charts, loading and empty states.
- Semantic theme tokens, scoped component themes, typed styles and slots for host customization, with light/dark examples and English/Indonesian localization.
- Accessible interaction targets, large-text layouts and reduced-motion behavior, with focused widget and host story tests. See the compatibility guide for tested environments and remaining limits.
- Copyable mobile blocks, a runnable synthetic example app, API documentation and backend integration guidance at https://flutter-ui-payment.netlify.app.
- Flutter SDK is the only runtime dependency. Network, authorization, secrets, payment processing, polling and platform operations belong to the host.

Pre-release implementation history is preserved in the repository's Git history and decision records.
