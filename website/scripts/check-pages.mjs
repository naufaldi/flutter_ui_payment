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
  const missing = required.filter((part) => !text.includes(part));
  if (missing.length) {
    problems++;
    console.error(`${file}: missing ${missing.join(', ')}`);
  }
}
console.log(`check-pages: ${pages} pages, ${problems} problems`);
process.exitCode = problems ? 1 : 0;
