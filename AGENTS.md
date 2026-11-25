# Agent instructions

Machine-wide simulator and browser rules live in the owner's global instructions.

## What this is

- `lib/`: the Flutter payment UI kit. `example/`: the example app. `website/`: the Astro Starlight docs site, deployed to the Netlify site `rakit-ui` (id `4dbabf95-de04-4c30-aeae-e95069a73272`), canonical https://rakit-ui.netlify.app (D117). The old `flutter-ui-payment` site (id `d9b5f0fb-8ed1-44c4-8a89-d7daebdc6936`) only 301-redirects there; see `website/redirect-old-site/README.md`.
- Platform scope (D64): phase 1 targets iOS (iPhone, iPad) and Android (phones, tablets). Web is documentation only. Desktop is out of scope.
- Source of truth: `PRD.md` and `docs/prd-foundation-components.md` specs, plus its §8 register of current applicable decisions, including amendments and supersession. `docs/decisions.md` preserves rationale/history. Start with `docs/README.md` and the derived daily guide `docs/design-system.md` for navigation. Follow recorded decisions; don't reopen them. Propose a change as a new decision.

## Rules of the kit

Read the Button bar (PRD §2, B1–B13) before changing a component.

- Host ownership (B11): no network, no clipboard or platform-channel call, no URL launching, no polling timers, no secrets in `lib/`. Check with the boundary grep in PRD §12.
- Dependencies in `pubspec.yaml` stay `flutter` only (B11).
- Use semantic tokens per B2 and §3.0, including their documented raw-value exceptions (such as the scrims). Spacing follows §3.3, D33 and D46: `PaymentTheme.space(PaymentSpace.<role>)`.
- Design every state that applies, from the PRD §4 states vocabulary.
- Accessibility floor: 48 dp targets (B5) and 200% text at 320 dp with nothing clipped (B4).

## Workflow

- Branch from `origin/main` after `git fetch`. Don't branch from a local checkout that may be stale.
- Open a GitHub issue for every problem before work starts.
- Record every decision in the PRD decision table and in `docs/decisions.md`.
- Feature PRs don't edit `CHANGELOG.md` or its website mirror. Each PR writes its user-visible change as one bullet under a `## Changelog` heading in the PR body.
- Before each docs deploy, one release-notes PR collects those bullets into `CHANGELOG.md`. `website/src/content/docs/reference/changelog.md` mirrors `CHANGELOG.md` verbatim below its intro; update both in that PR.
- `website/src/content/docs/reference/compatibility.md` mirrors `docs/compatibility.md`; update both.
- After a public API change, regenerate `website/src/data/api.json` with `pnpm gen:api` in `website/`.
- A PR closes its issues with one `Closes #N` line per issue.

## Proof, scaled to risk

- **High risk** (payments, auth, permissions, migrations, data writes, concurrency): a regression test that fails before the fix and passes after, plus an integration test on the real affected flow. Use the actual example app and host boundary for kit flows; a fake host does not prove live provider behavior.
- **Normal product behavior:** one focused test of what a host developer or end user sees or can do. Extend an existing test when it covers the same story.
- **Low risk** (copy, styling, docs, config, or refactors covered by existing tests): run existing checks; add no new tests.
- **Every UI change, at any tier:** capture and inspect before and after screenshots of the same screen and steps at relevant sizes, and link them in the PR. Use a recording when proof depends on motion. Non-UI changes do not need screenshots.
- **Unrelated flaky test:** rerun it once. If it fails again, quarantine it with a skip and an issue link. Do not start a thread just for a flaky test unless it blocks all merges.
- **Release focus:** no standalone test-only, audit, or tooling work unless it blocks 0.3.0. At most one in four work lanes may be non-product work. Proof required for a product change stays in that change's PR.

## Testing scope

- **This repo is a design system, not an app.** Tests prove what a host developer and an end user rely on. Don't test every internal combination.
- **Prove affected kit rules within the risk tier.** Use existing coverage or the focused story test for semantic tokens, 48 dp targets (B5), 200% text at 320 dp with nothing clipped (B4), reduced motion (B9/D66), and host ownership (B11). Avoid a matrix.
- **Control test inputs.** Set the date/clock, locale, viewport, platform, and random seed explicitly when the assertion depends on them. Use fixed fixtures or host fakes, not live network or device services, in unit and widget tests. Reset any overridden state with `addTearDown`.
- **Control async completion.** Advance widget time with `tester.pump(Duration)`; use a `Completer` to drive pending, success, and failure. For real engine work such as image decoding, await the operation inside `tester.runAsync`; do not sleep or poll the wall clock for readiness. Unexpected missed taps fail both widget suites. Tap the actual hit-testable control; use `warnIfMissed: false` only when the test proves that the target must not receive the tap.
- **Own every future.** The package and example test directories lint dropped futures in both sync and async callbacks. Await them or retain them until the relevant assertion. Use `unawaited` only when waiting would block the interaction the test needs to drive, such as opening a dialog whose future resolves on close.
- **Prefer behavior assertions to goldens.** If a pixel golden is needed, pin the Flutter version, renderer/platform, fonts, fixture data, viewport, DPR, locale, theme and animation frame. Inspect the diff before updating any baseline; don't regenerate goldens to make a failure pass.
- **Avoid:**
  - exhaustive matrices, such as every state × size × locale × theme × nav mode;
  - pixel or rect-identity sweeps;
  - throwaway probe batteries;
  - new integration or end-to-end tests for kit internals.
- **Plans and reviews use the same scale.** Judge the proof against the affected user story and risk tier.

## Review and verification

- Mechanical rebases: when a rebase conflicts only on `CHANGELOG.md`, the decision table or the decision docs, the orchestrator resolves it directly. The code diff must still equal the approved one.
- Reviewers don't use devices. They read the executor's captures and logs. Device runs belong to the executor, or to a dedicated device-check task.
- Put review findings in the PR, not in new threads. Only medium or higher findings block a merge; record low findings and nits in the PR.
- Small follow-ups: text-only fixes or a few lines with no behaviour change do not need another review round. The merge operator checks the diff before merging.
- Treat a rebase that only resolves `CHANGELOG.md` or decision-table conflicts the same way. Check code identity: the PR's code diff must equal the approved one.
- **Local merge gate (D129):** rebase onto the latest `origin/main` and run the full local suite once on that head: format, both analyzers, root and example Flutter tests, and website checks when docs or dartdoc change. If `main` moves after that run, rebase again. Rerun the full suite only if the new `main` commits touch the same packages or areas as the PR; otherwise rerun the affected checks and carry forward the rest. Do not add or wait for GitHub Actions workflows or required CI status checks.
- Reviewers reuse applicable executor evidence and run only relevant checks not already covered. Run the device flow test when its path changes or the high-risk proof needs it; reuse applicable results.
- Batch related small fixes in one PR instead of several.
- Parallel work: use up to 3 delegates at once. Device runs stay one at a time behind the device lock.

## Checks

Run the checks relevant to the changed user stories and kit rules.

On Windows, formatting `.` fails on Android build output under `example/build`.

```sh
dart format --output=none --set-exit-if-changed lib test example/lib example/test example/integration_test example/test_driver
flutter analyze --fatal-infos        # root
(cd example && flutter analyze --fatal-infos)
flutter test --concurrency=1 --test-randomize-ordering-seed=7305
(cd example && flutter test --concurrency=1 --test-randomize-ordering-seed=7305 test/)
(cd example && flutter test --no-pub integration_test/flow_test.dart -d <device>)
cd website && pnpm check:api && pnpm test:api && pnpm build && pnpm check:pages && pnpm check:links && pnpm check:snippets && pnpm test:motion && pnpm test:screens
```

The flow test runs on a device: take the device lock (Screenshots) first and follow the owner's global device rules.

Keep the seed in the proof so test ordering is replayable. For an order-dependent failure, record the failing seed and rerun with it before isolating the file.

Run `pnpm check:api` before the build or snippet check. Both commands regenerate `api.json` and can hide stale metadata in the checkout.

A full `flutter test` sometimes fails to load a file with "Unable to connect to flutter_tester process: WebSocketException". Rerun that file alone once on the same revision (`flutter test --no-pub --concurrency=1 test/<file>.dart`). Report the original suite outcome and the isolated retry outcome. Classify the result as a recovered infrastructure failure only when the matching startup error was the suite's sole failure and the retry passed. Quarantine only a confirmed unrelated flaky test, not a runner startup failure.

Worked examples:

- The suite fails only because `test/controls_test.dart` hits the matching startup error. Its same-revision retry passes. Report the suite failure and the retry pass as a recovered infrastructure failure.
- The suite reports a test assertion failure. That failure remains unresolved even if an isolated rerun passes.
- The suite reports the matching startup error in `test/controls_test.dart` and a failure in another file. A passing retry of `test/controls_test.dart` leaves the other failure unresolved.
- The suite reports only the matching startup error, and the isolated retry fails. Report both failures and keep the result unresolved.

## Emulator ownership and lifetime

- Keep one Android emulator open in the T3 Device panel during active Flutter UI work, including related edits, checks, delegate handoffs, and temporary review waits while the parent task remains unsettled and expects more device work. Do not start a device for work that needs none.
- The parent orchestrator owns the shared device reservation and lock. Record the parent task/thread, hostId, device id/serial, and current operator in `owner.md` inside the device lock directory. Include these details and the lock path in device-work briefs. Serialize device control; reuse only within the owning task or after explicit handoff.
- Delegates return control to the parent when finished. They stop their runners and recorders, but do not shut down the shared emulator or remove its lock. Delegate completion, a recoverable check failure, or a turn ending does not mean the parent task is finished.
- Stop recordings promptly after each bounded capture. Keeping the emulator open never authorizes repeated checks while waiting for review.
- The parent closes the task-owned device with `device_close` and `shutdown: true` and removes the lock when the task settles, is cancelled or terminally fails, no further device work is expected, or actual resource pressure requires release. Coordinate release or explicit handoff when another task needs the slot. Confirm cleanup and preserve unrelated/user-owned devices. Follow the owner's global device rules for all device operations.

## Screenshots

Docs captures come from Android only (D81): the phone AVD `FlutterPayment_API37_2` (360×640 dp, dpr 2) and, for wide layouts, `PixelTablet_API37` (1280×800 dp). One emulator at a time; follow the owner's global device rules. iOS captures are retired.

- Take the device lock first: `New-Item -ItemType Directory C:\DevTools\locks\flutter-ui-payment-device.lock`. Add the owner note described above. An explicitly assigned operator in the owning parent task uses the existing reservation rather than acquiring it again. For another task's lock, coordinate with its owner and retry every 60 s; never remove an unknown/stale lock without resolving ownership. Retain the lock across the parent task's device session and remove it at final cleanup or explicit handoff as described above.
- Capture from `example/` into the directory the docs read:
  `$env:SCREENSHOT_DIR='build/screenshots_hairline'; flutter drive --no-pub --driver=test_driver/integration_driver.dart --target=integration_test/<catalog_screenshots|screenshots|kit_screenshots>_test.dart -d <serial>`
- The tests render the Flutter layer in-app (`capture()` in `integration_test/support.dart`). Don't call `convertFlutterSurfaceToImage`; it stalls on the API 37 image.
- Catalog specimens render at phone width on a tall virtual view and are cropped to the keyed specimen, capped at 1200 dp (D82). Overlay and state captures (dialogs, sheets, toasts, tooltips) are full-screen at the real size.
- Selective runs: `--dart-define=CAPTURE_ONLY=…` with a matching `--dart-define=CAPTURE_LOOKS=…`, one session per look group. `node scripts/catalog-entries.mjs light,dark` (in `website/`) prints the entries. Tablet sets: `--dart-define=CAPTURE_DEVICE=tablet`.
- Before a selective capture, record the start time with `$captureStart = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()`. After capture, run `pnpm screens "--requested=android_catalog_button_variants,android_catalog_button_variants_dark" "--since=$captureStart"` from `website/`, using the registered base filenames you requested. The read-only report exits 1 when a requested fresh PNG is missing, even when an older PNG or existing WebP can be reused.
- Convert with `pnpm screens` in `website/`: WebP into `website/public/screens`, registry in `website/src/data/screens.json`. After a rebase, re-run it; never hand-merge `screens.json`.
- Names: `android_catalog_<component>_variants{,_dark,_200,_id,_id_200}` (a specimen over the 1200 dp cap adds `_part2`, `_part3`, … per D90; never register parts in `screens.mjs`), state captures `android_catalog_<state>`, flow `android_<screen>_<look>`, `android_refined_*`, `android_kit_*`, tablet `android_tablet_*`. `pnpm check:pages` fails on any `ios_` name.
- Place a component's specimen right after its intro, light and dark paired with `dark=`, with alt text that says what the image shows.
- Open and look at every capture before claiming a visual result.

## Don'ts

- Don't merge your own PR. The separate merge operator handles merges.
- Don't hand-edit `website/src/data/api.json` or WebP files; regenerate them.
- Don't commit raw PNGs.
