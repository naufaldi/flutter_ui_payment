# Agent instructions

Machine-wide simulator and browser rules live in the owner's global instructions.

## What this is

- `lib/`: the Flutter payment UI kit. `example/`: the example app. `website/`: the Astro Starlight docs site, deployed to Netlify.
- Platform scope (D64): phase 1 targets iOS (iPhone, iPad) and Android (phones, tablets). Web is documentation only. Desktop is out of scope.
- Source of truth: `docs/prd-foundation-components.md` (decision table D1–D76) and `docs/decisions.md`. Follow recorded decisions; don't reopen them. Propose a change as a new decision.

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

## Review and verification

- Merge gate: only medium or higher review findings block a merge. Put low findings and nits in a follow-up GitHub issue and merge the PR.
- Small follow-ups: text-only fixes or a few lines with no behaviour change do not need another review round. The orchestrator checks the diff and merges.
- Treat a rebase that only resolves `CHANGELOG.md` or decision-table conflicts the same way. Check code identity: the PR's code diff must equal the approved one.
- Checks run once: the executor runs the full suite once on the final head: format, both analyzers, root `flutter test`, example tests, and website checks when docs or dartdoc change.
- The reviewer runs `flutter analyze` and only tests relevant to the change, then reads the executor's results. Re-run the full suite only when code changed after the last full run.
- Flow test: run it once on the final head for each PR that affects its path. Do not repeat it in review when the head has not changed.
- Batch related small fixes in one PR instead of several.
- Parallel work: use up to 3 delegates at once. Device runs stay one at a time behind the device lock.

## Checks

On Windows, formatting `.` fails on Android build output under `example/build`.

```sh
dart format --output=none --set-exit-if-changed lib test example/lib example/test example/integration_test example/test_driver
flutter analyze                       # root
(cd example && flutter analyze)
flutter test                          # package tests
(cd example && flutter test test/)
(cd example && flutter test --no-pub integration_test/flow_test.dart -d <device>)
cd website && pnpm build && pnpm check:pages && pnpm check:links && pnpm check:snippets
```

The flow test runs on a device: take the device lock (Screenshots) first and follow the owner's global device rules.

A full `flutter test` sometimes fails to load a file with "Unable to connect to flutter_tester process: WebSocketException". Re-run that file alone (`flutter test --no-pub test/<file>.dart`) and report both results.

## Screenshots

Docs captures come from Android only (D81): the phone AVD `FlutterPayment_API37_2` (360×640 dp, dpr 2) and, for wide layouts, `PixelTablet_API37` (1280×800 dp). One emulator at a time; follow the owner's global device rules. iOS captures are retired.

- Take the device lock first: `New-Item -ItemType Directory C:\DevTools\locks\flutter-ui-payment-device.lock`. If it exists, retry every 60 s. Remove it when done, including on failure.
- Capture from `example/` into the directory the docs read:
  `$env:SCREENSHOT_DIR='build/screenshots_hairline'; flutter drive --no-pub --driver=test_driver/integration_driver.dart --target=integration_test/<catalog_screenshots|screenshots|kit_screenshots>_test.dart -d <serial>`
- The tests render the Flutter layer in-app (`capture()` in `integration_test/support.dart`). Don't call `convertFlutterSurfaceToImage`; it stalls on the API 37 image.
- Catalog specimens render at phone width on a tall virtual view and are cropped to the keyed specimen, capped at 1200 dp (D82). Overlay and state captures (dialogs, sheets, toasts, tooltips) are full-screen at the real size.
- Selective runs: `--dart-define=CAPTURE_ONLY=…` with a matching `--dart-define=CAPTURE_LOOKS=…`, one session per look group. `node scripts/catalog-entries.mjs light,dark` (in `website/`) prints the entries. Tablet sets: `--dart-define=CAPTURE_DEVICE=tablet`.
- Convert with `pnpm screens` in `website/`: WebP into `website/public/screens`, registry in `website/src/data/screens.json`. After a rebase, re-run it; never hand-merge `screens.json`.
- Names: `android_catalog_<component>_variants{,_dark,_200,_id,_id_200}`, state captures `android_catalog_<state>`, flow `android_<screen>_<look>`, `android_refined_*`, `android_kit_*`, tablet `android_tablet_*`. `pnpm check:pages` fails on any `ios_` name.
- Place a component's specimen right after its intro, light and dark paired with `dark=`, with alt text that says what the image shows.
- Open and look at every capture before claiming a visual result.

## Don'ts

- Don't merge your own PR. Review and merge are separate steps.
- Don't hand-edit `website/src/data/api.json` or WebP files; regenerate them.
- Don't commit raw PNGs.
