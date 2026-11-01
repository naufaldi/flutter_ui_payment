// Prints the CAPTURE_ONLY entries (`slug@look`) that refresh every catalog
// capture registered in screens.mjs for the given looks, for
// example/integration_test/catalog_screenshots_test.dart:
//
//   node scripts/catalog-entries.mjs light,dark      # also: 200, id,id_200
//   node scripts/catalog-entries.mjs --rest          # names only the full session shoots
//
// Pass the output as --dart-define=CAPTURE_ONLY=… with the same
// --dart-define=CAPTURE_LOOKS=…, one session per look group.

import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const registry = readFileSync(resolve(here, 'screens.mjs'), 'utf8');
const harness = readFileSync(
  resolve(here, '../../example/integration_test/catalog_screenshots_test.dart'),
  'utf8',
);
// Slugs are the keys of the harness's `specimens` map, plus the tooltip.
const map = harness.slice(harness.indexOf('final specimens'), harness.indexOf('final chartStates'));
const slugs = new Set([...map.matchAll(/^ {12,14}'([a-z_0-9]+)': \(/gm)].map((m) => m[1]));
slugs.add('tooltip');

const arg = process.argv[2] ?? '';
const looks = new Set(arg.split(','));
const entries = [];
const rest = [];
for (const [, name] of registry.matchAll(/^\s+ios_catalog_([a-z0-9_]+):/gm)) {
  const [, base, suffix = ''] = name.match(/^(.*?)(_dark|_200|_id_200|_id)?$/);
  const look = suffix ? suffix.slice(1) : 'light';
  const slug = base.endsWith('_variants') ? base.slice(0, -'_variants'.length) : base;
  if (!slugs.has(slug)) rest.push(`ios_catalog_${name}`);
  else if (looks.has(look)) entries.push(`${slug}@${look}`);
}
console.log(arg === '--rest' ? rest.join('\n') : entries.join(','));
