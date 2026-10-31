# flutter_ui_payment

Composable Flutter UI for optional identity verification (KYC), checkout, host-owned authorization, manual payment instructions, payment status and receipts. It stays clear when a payment is pending, failed, or its result is not known yet. Around that core it ships the pieces a payment app is built from: action rows and menus, confirmations and feedback, a responsive sidebar/drawer shell, sheets, a host-driven video player, labeled promotions, and transaction history.

> **Ringkasan.** Library komponen UI Flutter untuk KYC opsional dan pembayaran. Komponen hanya merender data terstruktur dari host dan melaporkan aksi lewat callback. Host/backend tetap memutuskan KYC, harga, otorisasi, idempotency, status, dan refund. Library tidak memproses uang, tidak melakukan network call, dan tidak memerlukan router, state manager, kamera, atau SDK payment. Keputusan produk ada di [PRD.md](PRD.md).

**Docs:** https://flutter-ui-payment.netlify.app

**Status:** `0.1.0`. Install from this GitHub repository; it is not published to pub.dev yet, and the package name is unverified. All data in the example is synthetic. See [What is verified](#what-is-verified) for exactly what has been checked.

**Docs:** [components](docs/components.md) (inventory, API, what the host owns) · [integration](docs/integration.md) · [compatibility](docs/compatibility.md) (Android 7.0+/API 24 declared, what was actually run) · [decisions](docs/decisions.md) (design and engineering tradeoffs, performance findings).

## Why

Payment UIs are mostly happy-path screenshots. Real flows have to answer harder questions: what does the screen say when the submit timed out after the server accepted it? Can the user pay twice? What if an older status arrives after a newer one? This kit makes those states first-class and keeps the business decisions with the host.

| Concern | Owner | What the kit does |
| --- | --- | --- |
| Input, focus, local validation | Widget | Interaction and presentation-level validation |
| Identity rules, consent policy | Host | Renders the host's fields, validators and reasons |
| KYC decision, document validation | Host/backend | Shows progress, structured errors and the result |
| Price, fees, limits, quote expiry | Host/backend | Renders the snapshot; asks for re-approval when terms change |
| PIN/OTP/biometric challenge | Host auth SDK | Shows the challenge state; never receives the secret |
| Payment status, idempotency, refund | Host/backend/provider | Renders authoritative snapshots; never infers success |
| Polling, recovery, lifecycle | Host coordinator | Exposes callbacks; widgets never poll on their own |

## Install

The package is not on pub.dev yet. Depend on it by path or git:

```yaml
dependencies:
  flutter_ui_payment:
    path: ../flutter-ui-payment
```

Requires Dart `^3.12.0` and Flutter `>=3.44.0` (tested with Flutter 3.44.6 stable). The only dependency is the Flutter SDK.

## Quick start

1. Add the localization delegate (English `en` and Indonesian `id`):

```dart
MaterialApp(
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('id'), Locale('en')],
  theme: ThemeData(
    colorScheme: scheme,
    // Optional: your brand. Without it the kit derives tokens from the scheme.
    extensions: [
      PaymentTheme.fromColorScheme(scheme).copyWith(accent: brand, radius: 12),
    ],
  ),
  home: const CheckoutPage(),
);
```

2. Render a host quote and methods, then confirm:

```dart
Column(
  children: [
    PaymentSummary(quote: quote),
    PaymentMethodPicker(
      methods: methods,
      selectedId: selectedId,
      onChanged: (method) => requote(method.id),
    ),
    PaymentConfirmation(
      quote: quote,
      method: selectedMethod,
      // After a re-quote, pass the old one: the customer must accept the
      // new total before onConfirm becomes reachable.
      previousQuote: previousQuote,
      onConfirm: () => host.revalidateAndAuthorize(quote),
    ),
  ],
);
```

3. Hand authorization to your own auth SDK and show its state:

```dart
AuthorizationPrompt(
  phase: phase, // ready, inProgress, approved, canceled, failed, expired
  onStart: host.startChallenge,
  onBackToReview: backToReview,
);
```

4. Track one attempt and render its status:

```dart
// Create once per legitimate attempt; attemptId is your idempotency key and
// stays the same for every retry or status check of this attempt.
var attempt = PaymentAttempt(
  attemptId: attemptId,
  quoteId: quote.id,
  quoteRevision: quote.revision,
  methodId: method.id,
  submission: SubmissionState.sending,
);

// On a timeout, keep the attempt: the server may have charged.
attempt = attempt.copyWith(submission: SubmissionState.outcomeUnknown);

// Every status response goes through reconcile: stale revisions, another
// attempt's data and success downgrades (without a provider correction)
// are rejected.
final result = attempt.reconcile(snapshotFromYourAdapter);
attempt = result.attempt;

PaymentStatusView(
  attempt: attempt,
  amount: quote.total,
  onAction: (action) => switch (action) {
    PaymentAction.checkStatus => host.checkStatus(attempt.attemptId),
    PaymentAction.viewReceipt => openReceipt(),
    _ => host.handle(action),
  },
);
```

`PaymentStatusView` only offers actions from `attempt.availableActions`. While the outcome is unknown that is `checkStatus` alone; `startNewAttempt` appears only when the host allows it and the previous attempt is final and not a success.

5. Show the receipt and share only allowlisted fields:

```dart
PaymentReceipt(
  data: receiptData,
  onShare: (share) => myShare(share.text), // returns ShareOutcome
  onCopyTransactionId: (id) => myClipboard(id), // returns bool
);
```

KYC is optional and composes the same way: `VerificationIntro`, `IdentityForm`, `DocumentUploadTile`, `VerificationReview` and `VerificationStatusView`. The host supplies field specs, validators, document limits and the status snapshot. See `example/lib/screens/flow_screen.dart` for a complete composition.

## Components

| Module | Components |
| --- | --- |
| Foundation | `PaymentTheme`, `PaymentLocalizations` (+ `KitStrings`), `PaymentMotion`, `Money`, `MoneyFormat`, `AmountText`, `InfoRow`, `MiddleEllipsisText`, `PaymentButton`, `StatusBadge`, `NoticeBanner`, `PaymentSection`, `PrivacyMask`, `CountdownText`, `HostError` |
| Controls | `PaymentCheckbox`, `PaymentRadio`, `PaymentSwitch`, `PaymentTabs`, `PaymentTooltip`, `PaymentSpinner`, `PaymentDivider` |
| Interaction | `ActionTile`, `ActionMenu`, `showPaymentConfirmDialog`, `showPaymentSnackBar`, `ExpandableSection`, `LoadingSkeleton`, `StateMessage` |
| Navigation | `AdaptiveNavShell`, `NavSidebar`, `PaymentNavItem`, `PaymentNavSection` |
| Sheets | `PaymentSheet`, `PaymentSheetHeader`, `showPaymentSheet`, `showPaymentSideSheet` |
| Media | `PaymentVideoPlayer`, `PaymentVideoController`, `VideoPlaybackValue` |
| Promotions | `PromoCard`, `PromoSlot`, `PromoContent` |
| Verification | `VerificationIntro`, `IdentityForm`, `DocumentUploadTile`, `VerificationReview`, `VerificationStatusView`, models and `checkDocumentLimits` |
| Checkout | `AmountInput`, `PaymentSummary`, `PaymentMethodPicker`, `PaymentConfirmation`, `AuthorizationPrompt`, `PaymentActionBar`, `MerchantHeader`, `PaymentStepIndicator`, `BalanceCard`, `PromoCodeInput` |
| Status | `PaymentInstructions`, `PaymentStatusView`, `RefundSection`, `PaymentAttempt`, `PaymentStatusSnapshot` |
| History | `TransactionHistory`, `TransactionListItem`, `TransactionDetail`, `TransactionRecord` |
| Receipt | `PaymentReceipt`, `PaymentReceiptData`, `ReceiptShareData` |

Usage, states and host responsibilities for each: [docs/components.md](docs/components.md).

Money is an integer number of minor units plus a currency code. `MoneyFormat.parse` rejects input that could be read two ways (for example `100,000` for IDR in `id`) instead of guessing.

## Invariants the kit helps keep

- `verified` comes only from the host, never from a finished upload.
- One active submit per attempt. `PaymentButton` locks while its callback runs; this is interaction protection, not a replacement for server-side deduplication.
- Timeouts, offline refreshes and an elapsed countdown never become "failed" or "paid".
- Older or duplicate snapshots cannot overwrite newer ones; a success changes only through an official provider correction.
- A changed total or method requires review and a new authorization.
- Refunds are a separate lifecycle shown beside the original payment.
- No KYC documents, PINs or credentials in public models; the host stores only an opaque attempt reference for recovery.

## Accessibility and motion

- Status is always icon + label + copy; color only supports it.
- Touch targets are at least 48 logical pixels. Rows stack vertically at large text scales; amounts never break across lines.
- Labels, live regions for status changes, spoken amounts, and `PrivacyMask` to hide sensitive content in the app switcher (OS-level screenshot protection remains the host's job).
- Motion is feedback only and follows `PaymentMotion`: strong ease-out, 120–220 ms enters, faster exits, status swaps scale in from 0.95 rather than from nothing, press feedback from Material's pressed state (full-width buttons do not scale), sheets 280/200 ms on a drawer curve, and implicit animations that retarget when interrupted. Navigation selection, menus and anything keyboard-driven are instant. Everything collapses to zero under `MediaQuery.disableAnimations` (reduced motion), which also blocks video autoplay. The countdown, which ticks every second, is never animated, and loading skeletons are static.
- Drawers and sheets close with the scrim, Back or Escape and return focus to what opened them; hidden navigation is not in the focus order. Disabled actions stay visible with a reason.

## Example app

`example/` is one app with three tabs, all in Bahasa Indonesia or English, two brands (Ruang Bayar, Lumen), light/dark, text size up to 200% and reduced motion (settings icon in the app bar). Phones get a bottom bar; windows 840 dp and wider get a side rail.

- **Demo:** the full journey for the fictional brand Ruang Bayar: consent → identity → document fixtures → review → in review → verified → checkout (Paket Belajar, Rp100.000 + Rp2.500 = Rp102.500, total and action pinned at the bottom) → host challenge → one submit → status → receipt. The virtual account path shows instructions, a host-clock countdown and status checks without a new payment.
- **Scenarios:** every row of the PRD edge matrix (K01–K08, P01–P15, X01–X04) plus three main journeys, each a deterministic fake-host fixture with variants.
- **Gallery:** every component, grouped in sections (Fondasi, Interaksi, Navigasi, Sheet & drawer, Video, Promosi, Checkout, Status & struk, Riwayat, Verifikasi) behind the kit's own `AdaptiveNavShell`. Controls work: dialogs, snack bars, sheets and side panels open; the video plays a bundled 8 s synthetic clip; promotions dismiss and restore; history searches and filters, and opens details.

The expandable **Host tools** panel on the demo screen shows the fake host log, submit/attempt/charge counters, and buttons to simulate a restart or background/resume. The account avatar switches between account A and B to show that responses for the previous account are discarded.

```sh
cd example
flutter run                       # Android emulator/device (API 24+) or iOS simulator
flutter run -d chrome             # web gallery
flutter build web --release       # static build in example/build/web
```

The fake host (`example/lib/adapters/`) simulates the backend, provider, idempotency and device capabilities. It proves the UI and coordinator contract against a fake host only, not against a real provider.

## Development

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test                                        # package tests
cd example
flutter test integration_test/flow_test.dart -d <device>
flutter drive --driver=test_driver/integration_driver.dart \
  --target=integration_test/screenshots_test.dart -d <device>
flutter drive --driver=test_driver/integration_driver.dart \
  --target=integration_test/kit_screenshots_test.dart -d <device>
flutter drive --profile --driver=test_driver/integration_driver.dart \
  --target=integration_test/perf_test.dart -d <android-emulator-or-device>
# only the checkout workload, its 100% text diagnostic and a plain-list control:
#   add --dart-define=PERF_ONLY=checkout
```

`flow_test.dart` covers the happy flow, double tap, submit accepted with a lost response, pending → success with an offline refresh, quote change, KYC actionRequired, KYC submit timeout, background/restart recovery and account switching. `kit_screenshots_test.dart` captures the refined flow screens and the gallery sections, and checks that the bundled video really plays (position advances) and pauses when its tab is hidden. Screenshots land in `example/build/screenshots`, the performance summary in `example/build/perf/summary.json`.

## What is verified

Checked on 30 October 2026 with Flutter 3.44.6:

- Formatter and analyzer clean (package and example). The full 54-test package run passed. After review, the component suite passed 14/14, including an added regression that prevents autoplay when loading finishes in the background. Unchanged package test evidence is reused.
- `flow_test.dart` (12 tests) passes on an Android 11 arm64 emulator (API 30, 60 Hz) after this pass's UI changes. The earlier iPhone 16 simulator (iOS 18.1) flow run predates them. The new component/screenshot journey was subsequently run successfully on that iOS simulator: video advanced to 4.5 s and paused on tab change, and refined screens, drawer, sheet and gallery captures were inspected (`ios_refined_*`, `ios_kit_*`).
- `kit_screenshots_test.dart` passes on the same Android emulator: refined KYC review, checkout and unknown-status screens in light, dark and 200% text; gallery sections in light, dark, 200% and the Lumen brand; drawer, sheet, confirmation and history detail. The bundled video played to 4.7 s and paused when its tab was hidden. All captures were inspected (`example/build/screenshots/android_refined_*`, `android_kit_*`). Earlier captures from both platforms are kept alongside them.
- Android build: debug, profile and release APKs build. The merged manifest declares `minSdkVersion 24`, and the release APK contains `armeabi-v7a`, `arm64-v8a` and `x86_64`. Only API 30 arm64 was run; see [compatibility](docs/compatibility.md).
- Web: `flutter build web --release` succeeds and serves locally. No browser check was done (the only automation-capable Chrome belonged to the user/another task).
- Performance (Android emulator, profile, Impeller/OpenGL ES, 30 s warm-up + 30 s measured): the last profile run reported checkout p95 build 2.02 ms and raster 20.41 ms. The plain Material control also missed the raster budget. This suggests a substantial environment effect; it does not prove that kit rendering has no cost. The raster requirement remains unmet. Measurement and artifact limitations are in [decisions](docs/decisions.md#performance). Earlier: status updates p95 build 2.55 / raster 6.15 ms; 10 document replace cycles left 2 slots and 10 stale uploads ignored, RSS 236–249 MB. No physical device was profiled.

Not done yet: an external developer integrating a checkout from this README (the ≤30 minute goal is unproven), a browser check of the web gallery, Android 7–10 runtime tests, package name availability, `flutter pub publish --dry-run`, and a public repository. Publication remains deferred.

## License

MIT. See [LICENSE](LICENSE).
