# Ruang Bayar demo

Example app for `flutter_ui_payment`. Everything is simulated: synthetic identity, document fixtures, references and money. Nothing leaves the device.

```sh
flutter run            # Android emulator/device (API 24+) or iOS simulator
flutter run -d chrome  # web gallery
```

- **Demo** tab: the full KYC → checkout → authorization → status → receipt journey. Open **Host tools** at the bottom for the fake host log, submit/attempt/charge counters and restart or background simulation. The avatar switches accounts.
- **Scenarios** tab: every PRD edge case (K01–K08, P01–P15, X01–X04) and the main journeys as deterministic fixtures. Run one to reset the fake host and open it in the demo.
- **Gallery** tab: every component, grouped into sections behind the kit's `AdaptiveNavShell` (drawer on phones, sidebar on wide windows), each with a state selector and working actions. The Video section plays `assets/video/ruang_bayar_demo.mp4`, an 8 s synthetic clip generated with ffmpeg for this demo.
- Settings (tune icon): brand, light/dark, language, text size up to 200%, reduced motion.

Code map:

| Path | Role |
| --- | --- |
| `lib/coordinator/demo_coordinator.dart` | The single owner of demo state; discards responses from a previous account or session |
| `lib/adapters/fake_host.dart` | Simulated backend, provider and device capabilities, idempotent on request/attempt IDs |
| `lib/adapters/status_adapter.dart` | Provider JSON → library model; rejects unknown or malformed data |
| `lib/adapters/video_adapter.dart` | `video_player` → `PaymentVideoController`; the only media dependency in the repository |
| `lib/scenarios/` | Scenario fixtures for the picker |
| `lib/screens/` | Flow, scenario picker and gallery (`gallery_kit.dart` holds the interaction, navigation, sheet, video, promotion and history demos) |
| `integration_test/` | Flow, screenshot and profile tests (see the root README) |
