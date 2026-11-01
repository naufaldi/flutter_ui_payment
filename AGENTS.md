# Agent instructions

Machine-wide simulator and browser rules live in the owner's global instructions.

## What this is

- `lib/`: the Flutter payment UI kit. `example/`: the example app. `website/`: the Astro Starlight docs site, deployed to Netlify.
- Platform scope (D64): phase 1 targets iOS (iPhone, iPad) and Android (phones, tablets). Web is documentation only. Desktop is out of scope.
- Source of truth: `docs/prd-foundation-components.md` (decision table D1–D64) and `docs/decisions.md`. Follow recorded decisions; don't reopen them. Propose a change as a new decision.

## Rules of the kit

Read the Button bar (PRD §2, B1–B13) before changing a component.

- Host ownership (B11): no network, no clipboard or platform-channel call, no URL launching, no polling timers, no secrets in `lib/`. Check with the boundary grep in PRD §12.
- Dependencies in `pubspec.yaml` stay `flutter` only (B11).
- Use semantic tokens per B2 and §3.0, including their documented raw-value exceptions (such as the scrims). Spacing follows §3.3, D33 and D46: `PaymentTheme.space(PaymentSpace.<role>)`.
- Design every state that applies, from the PRD §4 states vocabulary.
- Accessibility floor: 48 dp targets (B5) and 200% text at 320 dp with nothing clipped (B4).

## Workflow

- Open a GitHub issue for every problem before work starts.
- Record every decision in the PRD decision table and in `docs/decisions.md`.
- Add a `CHANGELOG.md` entry for every user-visible change. `website/src/content/docs/reference/changelog.md` mirrors `CHANGELOG.md` verbatim below its intro; update both.
- `website/src/content/docs/reference/compatibility.md` mirrors `docs/compatibility.md`; update both.
- After a public API change, regenerate `website/src/data/api.json` with `pnpm gen:api` in `website/`.
- A PR closes its issues with one `Closes #N` line per issue.

## Checks

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze                       # root
(cd example && flutter analyze)
flutter test                          # package tests
(cd example && flutter test test/)
(cd example && flutter test --no-pub integration_test/flow_test.dart -d <device>)
cd website && pnpm build && pnpm check:pages && pnpm check:links && pnpm check:snippets
```

The flow test runs on a simulator: take the simulator lock (Screenshots) first and follow the owner's global device rules.

On this Mac a full `flutter test` sometimes fails to load a file with "Unable to connect to flutter_tester process: WebSocketException". Re-run that file alone (`flutter test --no-pub test/<file>.dart`) and report both results.

## Screenshots

- Capture from `example/` with `flutter drive` and the driver, into the directory the docs read:
  `SCREENSHOT_DIR=build/screenshots_hairline flutter drive --driver=test_driver/integration_driver.dart --target=integration_test/catalog_screenshots_test.dart -d <device>`
  Capture tests live in `example/integration_test/`. The driver's default `build/screenshots` is not used by the docs.
- Selective runs: `--dart-define=CAPTURE_ONLY=…` with a matching `--dart-define=CAPTURE_LOOKS=…`, one session per look group. `node scripts/catalog-entries.mjs light,dark` (in `website/`) prints the entries for those looks.
- Convert with `pnpm screens` in `website/` (`scripts/screens.mjs`): WebP into `website/public/screens`, registry in `website/src/data/screens.json`.
- Names: `ios_catalog_<component>_variants{,_dark,_200,_id,_id_200}`, plus flow captures such as `ios_se_*_200` and `ios_ipad_*`.
- Simulator lock: every agent uses the one path `/tmp/flutter-ui-payment-sim.lock`. Take it with `mkdir /tmp/flutter-ui-payment-sim.lock`; if that fails, retry every 60 s. Release it with `rmdir /tmp/flutter-ui-payment-sim.lock` when done, including on failure. Machine-wide simulator capacity is set by the owner's global instructions.
- Open and look at every capture before claiming a visual result.

## Don'ts

- Don't merge your own PR. Review and merge are separate steps.
- Don't hand-edit `website/src/data/api.json` or WebP files; regenerate them.
- Don't commit raw PNGs.
