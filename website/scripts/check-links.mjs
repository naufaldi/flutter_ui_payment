// Crawls dist/**/*.html and checks every internal href and src (and #anchors
// on internal links) against the built files. Exits non-zero on any broken
// reference. Usage: node scripts/check-links.mjs [distDir]

import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join, resolve, dirname, relative, posix } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const dist = resolve(process.argv[2] ?? join(here, '../dist'));
if (!existsSync(dist)) {
  console.error(`No build output at ${dist}. Run pnpm build first.`);
  process.exit(1);
}

function walk(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });
}

const files = walk(dist);
const pages = files.filter((f) => f.endsWith('.html'));
const idCache = new Map();

function idsOf(file) {
  if (!idCache.has(file)) {
    const html = readFileSync(file, 'utf8');
    idCache.set(file, new Set([...html.matchAll(/\sid="([^"]+)"/g)].map((m) => m[1])));
  }
  return idCache.get(file);
}

/** Maps a site path to the built file that serves it, or null. */
function target(sitePath) {
  const clean = decodeURIComponent(sitePath);
  const candidates = clean.endsWith('/')
    ? [join(dist, clean, 'index.html')]
    : [join(dist, clean), join(dist, clean, 'index.html'), join(dist, `${clean}.html`)];
  return candidates.find((c) => existsSync(c) && statSync(c).isFile()) ?? null;
}

const broken = [];
let checked = 0;
const attr = /\s(href|src|srcset)="([^"]*)"/g;

for (const page of pages) {
  const html = readFileSync(page, 'utf8');
  const pagePath = '/' + posix.join(...relative(dist, page).split(/[\\/]/));
  for (const [, name, raw] of html.matchAll(attr)) {
    const values = name === 'srcset' ? raw.split(',').map((s) => s.trim().split(/\s+/)[0]) : [raw];
    for (const value of values) {
      if (!value || /^(https?:|mailto:|tel:|data:|javascript:|\/\/)/.test(value)) continue;
      const [pathPart, hash] = value.split('#');
      const pathOnly = pathPart.split('?')[0];
      // Same-page anchor.
      if (!pathOnly) {
        if (hash && !idsOf(page).has(decodeURIComponent(hash))) {
          broken.push(`${pagePath}: #${hash} (no such id on this page)`);
        }
        checked++;
        continue;
      }
      const sitePath = pathOnly.startsWith('/')
        ? pathOnly
        : posix.join(posix.dirname(pagePath), pathOnly);
      const file = target(sitePath);
      checked++;
      if (!file) {
        broken.push(`${pagePath}: ${value}`);
        continue;
      }
      if (hash && file.endsWith('.html') && !idsOf(file).has(decodeURIComponent(hash))) {
        broken.push(`${pagePath}: ${value} (missing anchor)`);
      }
    }
  }
}

console.log(`check-links: ${pages.length} pages, ${checked} internal references checked`);
if (broken.length) {
  console.error(`check-links: ${broken.length} broken\n  ${broken.join('\n  ')}`);
  process.exit(1);
}
console.log('check-links: no broken internal links or images');
