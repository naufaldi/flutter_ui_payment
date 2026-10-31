// Copies the curated native screenshots into public/screens as WebP and
// records their sizes in src/data/screens.json. Run by hand after new
// captures (`node scripts/screens.mjs`); the build uses the committed output.
//
// Source: example/build/screenshots_hairline only (the shipped Hairline
// design). Never docs/design-research/refs (third-party captures) and never
// example/build/screenshots (the rejected earlier design).

import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync, existsSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const source = resolve(here, '../../example/build/screenshots_hairline');
const target = resolve(here, '../public/screens');
const manifest = resolve(here, '../src/data/screens.json');

// sharp ships with Astro; resolve it from there instead of adding a dependency.
const requireFromAstro = createRequire(createRequire(import.meta.url).resolve('astro/package.json'));
const sharp = requireFromAstro('sharp');

// name → what it shows (locale noted, because captures mix en and id).
const screens = {
  ios_refined_checkout_light: 'Checkout, light, English',
  ios_refined_checkout_dark: 'Checkout, dark, Indonesian',
  ios_refined_checkout_light_200: 'Checkout at 200% text, Indonesian',
  ios_refined_status_unknown_light: 'Unknown outcome, light, English',
  ios_refined_status_unknown_dark: 'Unknown outcome, dark, Indonesian',
  ios_refined_status_unknown_light_200: 'Unknown outcome at 200% text, Indonesian',
  ios_refined_kyc_review_light: 'KYC review, light, English',
  ios_refined_kyc_review_dark: 'KYC review, dark',
  ios_status_pending_light: 'Pending payment, Indonesian',
  ios_status_va_pending_light: 'Virtual account pending, Indonesian',
  ios_status_va_pending_dark: 'Virtual account pending, dark, Indonesian',
  ios_receipt_light: 'Receipt, Indonesian',
  ios_receipt_dark: 'Receipt, dark, Indonesian',
  ios_authorize_light: 'Host authorization, Indonesian',
  ios_requote_light: 'Changed total needs re-approval, Indonesian',
  ios_kit_checkout: 'Gallery: checkout components, Indonesian',
  ios_kit_checkout_dark: 'Gallery: checkout components, dark',
  ios_kit_checkout_lumen: 'Gallery: checkout in the Lumen brand',
  ios_kit_history: 'Gallery: transaction history, Indonesian',
  ios_kit_history_dark: 'Gallery: transaction history, dark',
  ios_kit_history_detail_unknown: 'Gallery: transaction detail, unknown outcome',
  ios_kit_interaction: 'Gallery: interaction components, Indonesian',
  ios_kit_interaction_200: 'Gallery: interaction at 200% text',
  ios_kit_navigation_drawer: 'Gallery: navigation drawer',
  ios_kit_sheets: 'Gallery: sheets',
  ios_kit_sheet_pending: 'Gallery: pending-payment sheet',
  ios_kit_sheet_confirm: 'Gallery: destructive confirmation',
  ios_kit_promo: 'Gallery: promotions, Indonesian',
  ios_kit_promo_200: 'Gallery: promotions at 200% text',
  ios_kit_video_ready: 'Gallery: video player',
  // English catalog captures (example/integration_test/catalog_screenshots_test.dart).
  ios_catalog_controls_buttons: 'Gallery: button variants, busy and disabled, English',
  ios_catalog_controls_buttons_dark: 'Gallery: button variants, dark, English',
  ios_catalog_controls_choices: 'Gallery: checkbox, radio and switch, English',
  ios_catalog_controls_choices_dark: 'Gallery: checkbox, radio and switch, dark, English',
  ios_catalog_controls_tabs: 'Gallery: tabs, divider, tooltip trigger and spinner, English',
  ios_catalog_controls_tabs_dark: 'Gallery: tabs, divider, tooltip trigger and spinner, dark, English',
  ios_catalog_controls_tooltip: 'Gallery: tooltip shown, English',
  ios_catalog_foundation: 'Gallery: foundation specimen (English formatting, Indonesian row labels)',
  ios_catalog_actions: 'Gallery: action tiles and the menu button, English',
  ios_catalog_menu_open: 'Gallery: action menu open, English',
  ios_catalog_confirm_dialog: 'Gallery: destructive confirmation, English',
  ios_catalog_snackbar: 'Gallery: neutral toast, English',
  ios_catalog_expandable: 'Gallery: expandable sections, English',
  ios_catalog_states: 'Gallery: loading skeleton, English',
  ios_catalog_states_empty: 'Gallery: empty state message, English',
  ios_catalog_states_error: 'Gallery: error state message with retry, English',
};

mkdirSync(target, { recursive: true });
// Captures are gitignored build output. When one is gone but its WebP is
// already committed, keep the committed image and its recorded size.
const previous = existsSync(manifest) ? JSON.parse(readFileSync(manifest, 'utf8')) : {};
const sizes = {};
for (const [name, caption] of Object.entries(screens)) {
  const input = join(source, `${name}.png`);
  if (!existsSync(input)) {
    if (previous[name] && existsSync(join(target, `${name}.webp`))) {
      sizes[name] = { ...previous[name], caption };
      continue;
    }
    throw new Error(`Missing screenshot ${input}`);
  }
  const info = await sharp(input)
    .resize({ width: 640 })
    .webp({ quality: 82 })
    .toFile(join(target, `${name}.webp`));
  sizes[name] = { width: info.width, height: info.height, caption };
}
mkdirSync(dirname(manifest), { recursive: true });
writeFileSync(manifest, JSON.stringify(sizes, null, 2) + '\n');
console.log(`screens: wrote ${Object.keys(sizes).length} images to public/screens`);
