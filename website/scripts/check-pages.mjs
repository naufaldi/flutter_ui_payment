import { readFileSync, readdirSync } from 'node:fs';
const dir = new URL('../src/content/docs/components/', import.meta.url);
const required = ['## Usage', '## Stripe → kit', '## Which variant when',
  "## Do and don't", '## Used in', '## API', 'Nothing else exists.',
  '**Do**', "**Don't**"];
let problems = 0;
let pages = 0;
for (const file of readdirSync(dir)) {
  if (!file.endsWith('.mdx') || file === 'index.mdx') continue;
  pages++;
  const text = readFileSync(new URL(file, dir), 'utf8');
  const prose = text.replace(/^```[^\n]*\n[\s\S]*?^```[ \t]*$/gm, '');
  const headings = new Set(prose.split('\n').filter((line) => line.startsWith('## ')));
  const missing = required.filter((part) => part.startsWith('## ')
    ? !headings.has(part) : !prose.includes(part));
  if (missing.length) {
    problems++;
    console.error(`${file}: missing ${missing.join(', ')}`);
  }
}

// Retired capture names must never return to docs pages.
function checkLegacyScreens(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = new URL(entry.name + (entry.isDirectory() ? '/' : ''), directory);
    if (entry.isDirectory()) checkLegacyScreens(path);
    else if (/\.mdx?$/.test(entry.name)) {
      const text = readFileSync(path, 'utf8');
      const names = [...new Set([...text.matchAll(/\b(?:name|dark)=["'](ios_[a-z0-9_]+)["']/g)].map(m => m[1]))];
      if (names.length) {
        problems++;
        console.error(path.pathname + ': retired iOS screens: ' + names.join(', '));
      }
    }
  }
}
checkLegacyScreens(new URL('../src/content/docs/', import.meta.url));
const screens = JSON.parse(readFileSync(new URL('../src/data/screens.json', import.meta.url), 'utf8'));
for (const name of Object.keys(screens)) {
  if (!name.startsWith('ios_')) continue;
  problems++;
  console.error('screens.json: retired iOS screen: ' + name);
}

console.log(`check-pages: ${pages} pages, ${problems} problems`);
process.exitCode = problems ? 1 : 0;
