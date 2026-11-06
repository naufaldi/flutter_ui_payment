# Launch kit (DRAFT, NOT POSTED)

> **Status: draft for review. Nothing below has been posted anywhere.** The owner decides if, when and where to post. Before posting, re-check every claim against [compatibility.md](compatibility.md), which is the source of truth for what was run, and confirm the docs site shows the current release.

## One-sentence pitch

Rakit UI is an MIT-licensed Flutter UI kit for checkout, payment status and receipts built so that, after a lost response, the customer checks the status of the same payment attempt instead of paying twice.

## Community post (about 80 words)

I published Rakit UI 0.1.0 on pub.dev. It's a Flutter UI kit for checkout, payment status, receipts and optional KYC. The part I care about most is the unknown result. If the submit times out after the server accepted it, the screen says not to pay again and offers one action, check status for the same attempt. The widgets make no network calls. Your app and backend still own pricing, auth and idempotency. There's a demo with a fake host, and I'd like feedback.

Links: try it at https://flutter-ui-payment.netlify.app/start/try-it/ and the package is at https://pub.dev/packages/rakit_ui.

## Short social post

Rakit UI 0.1.0 is on pub.dev. Flutter widgets for checkout, payment status and receipts, built around the hard case. The response is lost, so the screen checks the same attempt instead of offering pay again. Synthetic demo, no real money. Feedback welcome.

https://flutter-ui-payment.netlify.app/start/try-it/

## Links

- Package: https://pub.dev/packages/rakit_ui
- Source: https://github.com/naufaldi/flutter_ui_payment
- Try it and feedback checklist: https://flutter-ui-payment.netlify.app/start/try-it/
- Recovery demo: https://flutter-ui-payment.netlify.app/blocks/checkout-recovery/
- Feedback: https://github.com/naufaldi/flutter_ui_payment/issues/new

## Claims we can make

- Version 0.1.0 of `rakit_ui` is published on pub.dev, MIT licensed.
- The package depends only on the Flutter SDK. `lib/` makes no network, clipboard, URL-launching or platform-channel calls (B11).
- The widgets display host data and report actions through callbacks. The host owns pricing, authorization, payment status, idempotency, refunds and KYC decisions.
- The example app and block demos use synthetic data and a fake host. No money moves.
- Current documentation captures come from Android emulators (API 37 phone and tablet).

## Limits to state, not hide

- **Android:** declared for API 24+. The runtime baseline is an Android 11 emulator, and docs captures are on API 37. Android 7 to 10 and 32-bit ARM devices have not been runtime-tested.
- **iOS:** targeted, with minimum iOS 13.0. The flow test and a component and screenshot journey passed earlier on the iPhone 16 simulator (iOS 18.1). The flow run predates the newer components, current docs captures are Android-only, and there are no iOS performance numbers. Do not say iOS was never checked, and do not say the current release was fully verified on iOS.
- **Web:** documentation preview only, not a supported product target. Desktop is out of scope.
- **Adoption:** there are no known production users yet. Do not imply adopters, payment volume or results.
- **Trial time:** "30 minutes from empty app to rendered checkout" is a target, not a measured result.
- **Security:** the kit avoids handling secrets and money, but it is not a security certification. Do not claim PCI compliance or audits.
- **Docs site:** if the live site still shows old branding or lacks the Try it page, it has not been redeployed since these docs merged. Wait for the deploy before posting site links.
