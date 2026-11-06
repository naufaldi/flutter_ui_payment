---
title: Changelog
description: Changes in Rakit UI, copied from CHANGELOG.md in the repository.
---

Copied verbatim from `CHANGELOG.md`.

## Unreleased

### Docs site

No package changes; these update https://rakit-ui.netlify.app.

- The homepage is now a product page, with a hero, a checkout recovery flow, benefits, an ownership table, checkable proof, an FAQ and a clear "Build your checkout" path. It adds a descriptive title with schema.org data, a JPEG social preview, robots.txt with the sitemap and an up-to-date llms.txt.
- A new Try it page and a corrected `../flutter_ui_payment` path-dependency example.
- The homepage lets you switch between success, pending, unknown and changed-total payment screens, shows real component specimens and compares the Hairline and Soft looks.
- A header with section links and Get started, a homepage footer and contact section, and a copy button for the install command. The contact link opens a new GitHub issue, the footer attribution link has a 44 px tap target, and header buttons don't animate under reduced motion.
- The homepage is about 30% shorter on phones: the recovery demo is a sideways strip, the brand looks sit side by side, and repeated copy is gone.
- The documentation site moves to https://rakit-ui.netlify.app. Links to https://flutter-ui-payment.netlify.app redirect to the same page.

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
