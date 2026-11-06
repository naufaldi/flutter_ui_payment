// Writes the social preview image (og:image / twitter:image) as a JPEG copy of
// a committed docs capture, because some link-preview crawlers do not read
// WebP. Run by hand after that capture changes: `pnpm og:image`.

import { createRequire } from 'node:module';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const source = resolve(here, '../public/screens/android_tablet_checkout_en.webp');
const target = resolve(here, '../public/og-image.jpg');

// sharp ships with Astro; resolve it from there instead of adding a dependency.
const requireFromAstro = createRequire(createRequire(import.meta.url).resolve('astro/package.json'));
const sharp = requireFromAstro('sharp');

const info = await sharp(source)
  .flatten({ background: '#ffffff' })
  .jpeg({ quality: 82, mozjpeg: true })
  .toFile(target);
console.log(`public/og-image.jpg ${info.width}x${info.height}, ${info.size} bytes`);
