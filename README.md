# Rakit UI

Rakit UI provides Flutter components for checkout, payment status, receipts and optional identity verification (KYC). Build screens for pending, failed and unknown payment results, with host-owned authorization and recovery. The kit also includes navigation, forms, charts, sheets, feedback and transaction history.

Adopt selected controls in your own branded app while keeping your theme, router and state: [existing-app guide](https://rakit-ui.netlify.app/start/existing-app/).

> **Ringkasan.** Library komponen UI Flutter untuk KYC opsional dan pembayaran. Komponen hanya merender data terstruktur dari host dan melaporkan aksi lewat callback. Host/backend tetap memutuskan KYC, harga, otorisasi, idempotency, status, dan refund. Library tidak memproses uang, tidak melakukan network call, dan tidak memerlukan router, state manager, kamera, atau SDK payment. Keputusan produk ada di [PRD.md](https://github.com/naufaldi/flutter_ui_payment/blob/main/PRD.md).

Targets iOS and Android, phones and tablets. The web build is a documentation preview.

**Docs:** https://rakit-ui.netlify.app

**Release:** `0.2.0`. Install with `flutter pub add rakit_ui`. All data in the example is synthetic. See [What is verified](#what-is-verified) for exactly what has been checked.

## Start here

**See it run with synthetic data.** Open an Android emulator or iOS Simulator, then:

```sh
git clone https://github.com/naufaldi/flutter_ui_payment.git
cd flutter_ui_payment/example
flutter pub get
flutter run -t lib/checkout_block_demo.dart   # one checkout, with its recovery states
flutter run                                   # the full example app: Demo, Scenarios, Gallery
```

Trying it for the first time? [Try it](https://rakit-ui.netlify.app/start/try-it/) has a short trial and a feedback checklist.

To build an app, [install the package](#install) and follow the [Quick start](https://rakit-ui.netlify.app/start/quick-start/). It starts with a complete `lib/main.dart`, then covers checkout through receipt. Use the [catalog](https://rakit-ui.netlify.app/components/) for individual widgets or copy a complete screen from [Blocks](https://rakit-ui.netlify.app/blocks/). The [host integration guide](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/integration.md) explains how to connect your backend.

Coding agents and maintainers should start with [AGENTS.md](https://github.com/naufaldi/flutter_ui_payment/blob/main/AGENTS.md), the [documentation map](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/README.md) and the [daily design-system guide](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/design-system.md). Use this table for task-specific references.

| Question | Where to look |
| --- | --- |
| Which rule wins? | [PRD.md](https://github.com/naufaldi/flutter_ui_payment/blob/main/PRD.md) and the [foundation PRD](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/prd-foundation-components.md), including its [§8 decision register](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/prd-foundation-components.md#8-decisions). [decisions.md](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/decisions.md) holds rationale and history only. |
| What is exported, with which parameters? | [lib/rakit_ui.dart](lib/rakit_ui.dart) and the generated [website/src/data/api.json](https://github.com/naufaldi/flutter_ui_payment/blob/main/website/src/data/api.json). Don't invent API names. |
| How do I style something? | The [adoption order](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/design-system.md#customization-today-versus-approved-migration): theme, then a family theme, then a host preset, then a one-off `style`. Some families, such as fields, have no instance `style`; check the component's Props table. |
| What must stay in the host? | [Host boundary](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/design-system.md#host-boundary): no network, clipboard, URL launching, platform channels, polling timers or secrets in `lib/`. Flutter SDK is the only dependency (B11). |
| Before changing a component? | The [Button bar (B1–B13)](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/prd-foundation-components.md#the-button-bar-tier-1-quality-checklist), the component's spec section, and [Testing scope](https://github.com/naufaldi/flutter_ui_payment/blob/main/AGENTS.md#testing-scope). |
| Which checks run? | [AGENTS.md → Checks](https://github.com/naufaldi/flutter_ui_payment/blob/main/AGENTS.md#checks). |

**Docs:** [components](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/components.md) (inventory, API, what the host owns) · [integration](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/integration.md) · [compatibility](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/compatibility.md) (Android 7.0+/API 24 declared, what was actually run) · [decisions](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/decisions.md) (design and engineering tradeoffs, performance findings).

## Why

When a payment request times out, the server may already have accepted it. The screen needs to offer a status check for that attempt, block another payment while the result is unresolved, and ignore stale responses. This kit provides those presentation rules while your app and backend decide the payment result.

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

Add the package from pub.dev:

```sh
flutter pub add rakit_ui
```

Or declare the dependency directly:

```yaml
dependencies:
  rakit_ui: ^0.2.0
```

Requires Dart `^3.12.0` and Flutter `>=3.44.0` (tested with Flutter 3.44.6 stable). The only dependency is the Flutter SDK.

## Migrating from flutter_ui_payment

Rakit UI continues the same UI kit under the `rakit_ui` package name. Replace the old dependency and update imports:

```yaml
dependencies:
  rakit_ui: ^0.2.0
```

```dart
import 'package:rakit_ui/rakit_ui.dart';
```

Remove `flutter_ui_payment` from your dependencies, then run `flutter pub get`. Widget names, theme APIs, models and host callbacks are unchanged. Code that names the `KitStrings` or `PaymentStatusLabel` extensions needs the 0.2.0 migration in [CHANGELOG.md](CHANGELOG.md). Replace private `package:flutter_ui_payment/src/...` imports with the public Rakit UI API where possible.

The old package and its published versions remain available for existing apps. Use one package identity throughout an app: types from the two separately published packages are distinct. The compatibility filename `package:rakit_ui/flutter_ui_payment.dart` forwards to the new library, but does not redirect old-package imports.

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
| Foundation | `PaymentTheme`, `PaymentType`, `PaymentLocalizations` (+ `KitStrings`), `PaymentMotion`, `Money`, `MoneyFormat`, `AmountText`, `InfoRow`, `MiddleEllipsisText`, `PaymentButton`, `PaymentBadge`, `PaymentBanner`, `PaymentSection`, `PrivacyMask`, `CountdownText`, `HostError` |
| Controls | `PaymentCheckbox`, `PaymentRadio`, `PaymentSwitch`, `PaymentTabs`, `PaymentTooltip`, `PaymentSpinner`, `PaymentDivider` |
| Interaction | `PaymentListItem`, `PaymentList`, `PaymentMenu`, `PaymentMenuItem`, `showPaymentConfirmDialog`, `showPaymentToast`, `PaymentAccordion`, `PaymentAccordionItem`, `LoadingSkeleton`, `StateMessage` |
| Navigation | `AdaptiveNavShell`, `NavSidebar`, `PaymentNavItem`, `PaymentNavSection` |
| Sheets | `PaymentSheet`, `PaymentSheetHeader`, `showPaymentSheet`, `showPaymentSideSheet` |
| Media | `PaymentVideoPlayer`, `PaymentVideoController`, `VideoPlaybackValue` |
| Promotions | `PromoCard`, `PromoSlot`, `PromoContent` |
| Verification | `VerificationIntro`, `IdentityForm`, `DocumentUploadTile`, `VerificationReview`, `VerificationStatusView`, models and `checkDocumentLimits` |
| Checkout | `PaymentCurrencyField`, `PaymentSummary`, `PaymentMethodPicker`, `PaymentConfirmation`, `AuthorizationPrompt`, `PaymentActionBar`, `MerchantHeader`, `PaymentStepIndicator`, `BalanceCard`, `PromoCodeInput` |
| Status | `PaymentInstructions`, `PaymentStatusView`, `RefundSection`, `PaymentAttempt`, `PaymentStatusSnapshot` |
| History | `TransactionHistory`, `TransactionListItem`, `TransactionDetail`, `TransactionRecord` |
| Receipt | `PaymentReceipt`, `PaymentReceiptData`, `ReceiptShareData` |

### Charts and capture

| Public API | Purpose |
| --- | --- |
| `ChartPoint`, `ChartPointStatus`, `MeterSegment`, `ChartState` | Host-owned money and rendering states. |
| `PaymentLineChart`, `PaymentBarChart` | Ordered trends and zero-baseline comparisons. |
| `PaymentMeterChart`, `PaymentSparkline`, `ChartModule` | Category snapshot, compact trend and stable state container. |
| `CaptureSource`, `CaptureKind`, `showCaptureSourceSheet` | Source intent before host permission. |
| `CaptureFrameOverlay`, `KycCaptureGuide` | Passive framing, review and host upload state. |

Usage, states and host responsibilities for each: [docs/components.md](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/components.md).

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

`example/` is one app with three tabs, all in Bahasa Indonesia or English, three brands (Ruang Bayar, Lumen, Soft), light/dark, text size up to 200% and reduced motion (settings icon in the app bar). Phones get a bottom bar; windows 840 dp and wider get a side rail.

- **Demo:** the full journey for the fictional brand Ruang Bayar: consent → identity → document fixtures → review → in review → verified → checkout (Paket Belajar, Rp100.000 + Rp2.500 = Rp102.500, total and action pinned at the bottom) → host challenge → one submit → status → receipt. The virtual account path shows instructions, a host-clock countdown and status checks without a new payment.
- **Scenarios:** every row of the PRD edge matrix (K01–K08, P01–P15, X01–X04) plus three main journeys, each a deterministic fake-host fixture with variants.
- **Gallery:** every component, grouped in sections (Fondasi, Interaksi, Navigasi, Sheet & drawer, Video, Promosi, Checkout, Status & struk, Riwayat, Verifikasi) behind the kit's own `AdaptiveNavShell`. Controls work: dialogs, snack bars, sheets and side panels open; the video plays a bundled 8 s synthetic clip; promotions dismiss and restore; history searches and filters, and opens details.

The expandable **Host tools** panel on the demo screen shows the fake host log, submit/attempt/charge counters, and buttons to simulate a restart or background/resume. The account avatar switches between account A and B to show that responses for the previous account are discarded.

```sh
cd example
flutter run                       # Android emulator/device (API 24+) or iOS simulator
flutter run -d chrome             # web gallery (documentation preview)
flutter build web --release       # static build in example/build/web
```

The fake host (`example/lib/adapters/`) simulates the backend, provider, idempotency and device capabilities. It proves the UI and coordinator contract against a fake host only, not against a real provider.

## Development

```sh
dart format --output=none --set-exit-if-changed lib test example/lib example/test example/integration_test example/test_driver
flutter analyze
flutter test                                        # package tests
cd example
flutter test --no-pub integration_test/flow_test.dart -d <device>
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

**Historical v0.1 baseline, 30 October 2026 (Flutter 3.44.6).** The results and pending items below describe that snapshot, not current-head verification or release readiness. For later evidence and remaining limits, read [compatibility](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/compatibility.md) and the [decision record](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/decisions.md#performance).

- Formatter and analyzer clean (package and example). The full 54-test package run passed. After review, the component suite passed 14/14, including an added regression that prevents autoplay when loading finishes in the background. Unchanged package test evidence is reused.
- `flow_test.dart` (12 tests) passes on an Android 11 arm64 emulator (API 30, 60 Hz) after this pass's UI changes. The earlier iPhone 16 simulator (iOS 18.1) flow run predates them. The new component/screenshot journey was subsequently run successfully on that iOS simulator: video advanced to 4.5 s and paused on tab change, and refined screens, drawer, sheet and gallery captures were inspected (`ios_refined_*`, `ios_kit_*`).
- `kit_screenshots_test.dart` passes on the same Android emulator: refined KYC review, checkout and unknown-status screens in light, dark and 200% text; gallery sections in light, dark, 200% and the Lumen brand; drawer, sheet, confirmation and history detail. The bundled video played to 4.7 s and paused when its tab was hidden. All captures were inspected (`example/build/screenshots/android_refined_*`, `android_kit_*`). Earlier captures from both platforms are kept alongside them.
- Android build: debug, profile and release APKs build. The merged manifest declares `minSdkVersion 24`, and the release APK contains `armeabi-v7a`, `arm64-v8a` and `x86_64`. Only API 30 arm64 was run; see [compatibility](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/compatibility.md).
- Web: `flutter build web --release` succeeds and serves locally. No browser check was done (the only automation-capable Chrome belonged to the user/another task).
- Performance (Android emulator, profile, Impeller/OpenGL ES, 30 s warm-up + 30 s measured): the last profile run reported checkout p95 build 2.02 ms and raster 20.41 ms. The plain Material control also missed the raster budget. This suggests a substantial environment effect; it does not prove that kit rendering has no cost. The raster requirement remains unmet. Measurement and artifact limitations are in [decisions](https://github.com/naufaldi/flutter_ui_payment/blob/main/docs/decisions.md#performance). Earlier: status updates p95 build 2.55 / raster 6.15 ms; 10 document replace cycles left 2 slots and 10 stale uploads ignored, RSS 236–249 MB. No physical device was profiled.

At that historical snapshot, external developer onboarding, web gallery browser checks, Android 7–10 runtime tests and the D64 mobile review were still pending. Later evidence is recorded in the compatibility guide and decision history linked above; these historical results are not a claim of current release verification.

## License

MIT. See [LICENSE](LICENSE).
