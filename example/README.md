# Ruang Bayar demo

Example app for `rakit_ui`. Everything is simulated: synthetic identity, document fixtures, references and money. Nothing leaves the device.

Clone the [repository](https://github.com/naufaldi/flutter_ui_payment) to run the
example with its Android/iOS projects. The pub.dev archive includes example source
and synthetic assets; to run that copy, generate the platform projects first:

```sh
flutter create --platforms=android,ios .
flutter pub get
```

## Checkout and recovery demo

Start here. One checkout pays once, loses the response, checks the same attempt's
status and only then shows the receipt:

```sh
flutter run -t lib/checkout_block_demo.dart
```

The top-bar demo menu selects lost response, pending/offline or receipt-load retry;
status checks keep the same attempt. See the
[composition guide](lib/compositions/README.md).

## Full example app

```sh
flutter run            # Android emulator/device (API 24+) or iOS simulator
flutter run -d chrome  # web gallery
```

- **Demo** tab: the full KYC → checkout → authorization → status → receipt journey. Open **Host tools** at the bottom for the fake host log, submit/attempt/charge counters and restart or background simulation. The avatar switches accounts.
- **Scenarios** tab: every PRD edge case (K01–K08, P01–P15, X01–X04) and the main journeys as deterministic fixtures. Run one to reset the fake host and open it in the demo.
- **Gallery** tab: every component, grouped into sections behind the kit's `AdaptiveNavShell` (drawer on phones, sidebar on wide windows), each with a state selector and working actions. The Video section plays `assets/video/ruang_bayar_demo.mp4`, an 8 s synthetic clip generated with ffmpeg for this demo.
- Settings (tune icon): brand, light/dark, language, text size up to 200%, reduced motion.

## Other blocks

Mobile blocks: `flutter run -t lib/<demo>.dart` with `history_block_demo`,
`kyc_review_demo`, `manual_transfer_demo`, `method_quote_demo`,
`refund_detail_demo`, `kyc_onboarding_demo`, `kyc_capture_demo` or
`payment_preferences_demo`. The developer menus select synthetic states. No real
payment or identity data is used.

For the copyable mobile Merchant Overview block, see
[the composition guide](lib/compositions/README.md). Run it with
`flutter run -t lib/merchant_demo.dart`.

## Code map

| Path | Role |
| --- | --- |
| `lib/coordinator/demo_coordinator.dart` | The single owner of demo state; discards responses from a previous account or session |
| `lib/adapters/fake_host.dart` | Simulated backend, provider and device capabilities, idempotent on request/attempt IDs |
| `lib/adapters/status_adapter.dart` | Provider JSON → library model; rejects unknown or malformed data |
| `lib/adapters/video_adapter.dart` | `video_player` → `PaymentVideoController`; the only media dependency in the repository |
| `lib/scenarios/` | Scenario fixtures for the picker |
| `lib/screens/` | Flow, scenario picker and gallery (`gallery_kit.dart` holds the interaction, navigation, sheet, video, promotion and history demos) |
| `integration_test/` | Flow, screenshot and profile tests (see the root README) |
