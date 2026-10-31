// Checks the Dart code blocks in src/content/docs against the real API in
// src/data/api.json: every kit constructor or function call must exist, and
// every named argument passed to it must be one of its parameters. Flutter
// and host names (anything not in api.json) are skipped.
// Usage: node scripts/check-snippets.mjs (after gen-api).

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..');
const api = JSON.parse(readFileSync(join(root, 'src/data/api.json'), 'utf8'));

function walk(dir) {
  return readdirSync(dir).flatMap((n) => {
    const p = join(dir, n);
    return statSync(p).isDirectory() ? walk(p) : /\.mdx?$/.test(n) ? [p] : [];
  });
}

function closeParen(text, open) {
  let depth = 0;
  for (let i = open; i < text.length; i++) {
    if (text[i] === '(') depth++;
    if (text[i] === ')' && --depth === 0) return i;
  }
  return -1;
}

function topLevelNamedArgs(args) {
  const names = [];
  let depth = 0;
  let start = 0;
  const parts = [];
  for (let i = 0; i < args.length; i++) {
    const ch = args[i];
    if ('([{'.includes(ch)) depth++;
    if (')]}'.includes(ch)) depth--;
    if (ch === ',' && depth === 0) {
      parts.push(args.slice(start, i));
      start = i + 1;
    }
  }
  parts.push(args.slice(start));
  for (const p of parts) {
    const m = p.replace(/\/\/.*$/gm, '').trim().match(/^([a-zA-Z_]\w*)\s*:/);
    if (m) names.push(m[1]);
  }
  return names;
}

function paramsFor(callee) {
  const [base, named] = callee.split('.');
  const e = api[base];
  if (!e) return null;
  if (e.kind === 'function') return e.params;
  if (named === 'copyWith') return (e.copyWith ?? []).map((name) => ({ name }));
  const ctorName = named ? `${base}.${named}` : base;
  const ctor = (e.constructors ?? []).find((c) => c.name === ctorName);
  if (!ctor) return undefined;
  return ctor.params;
}

const problems = [];
let calls = 0;
const copyWithOwners = Object.entries(api).filter(([, e]) => e.copyWith);

for (const file of walk(join(root, 'src/content/docs'))) {
  const text = readFileSync(file, 'utf8');
  for (const block of text.matchAll(/```dart[^\n]*\n([\s\S]*?)```/g)) {
    const code = block[1];
    for (const m of code.matchAll(/\b([A-Za-z_]\w*(?:\.[a-zA-Z_]\w*)?)(?:<[^>()]*>)?\(/g)) {
      let callee = m[1];
      // `PaymentTheme.fromColorScheme(scheme).copyWith(` → check copyWith on PaymentTheme.
      if (callee.endsWith('copyWith') || callee === 'copyWith') {
        const before = code.slice(0, m.index);
        const owner = copyWithOwners.find(([n]) => new RegExp(`\\b${n}\\b[^;]*$`).test(before));
        if (!owner && !/attempt\.copyWith|value\.copyWith/.test(code.slice(m.index - 10, m.index + 10))) continue;
        const ownerName = owner ? owner[0] : /value\.copyWith/.test(code.slice(m.index - 10, m.index + 10)) ? 'VideoPlaybackValue' : 'PaymentAttempt';
        callee = `${ownerName}.copyWith`;
      }
      const base = callee.split('.')[0];
      if (!api[base] || /^[a-z]/.test(base) && api[base].kind !== 'function') continue;
      const params = paramsFor(callee);
      // Static methods and getters (for example `PaymentLocalizations.of`) are not constructors.
      if (params === undefined) {
        const member = callee.split('.')[1];
        const e = api[base];
        if (member && (e.statics?.includes(member) || e.getters?.some((g) => g.name === member))) continue;
        if (member === 'of' || member === 'where' || member === 'tryParse' || member === 'register' || member === 'validSelection' || member === 'fadeScale') continue;
        problems.push(`${relative(root, file)}: ${callee}(…) is not a constructor of ${base}`);
        continue;
      }
      calls++;
      const open = m.index + m[0].length - 1;
      const close = closeParen(code, open);
      const named = topLevelNamedArgs(code.slice(open + 1, close).replace(/\/\/[^\n]*/g, ''));
      const allowed = new Set(params.map((p) => p.name));
      for (const n of named) {
        if (!allowed.has(n)) problems.push(`${relative(root, file)}: ${callee}(${n}: …) is not a parameter`);
      }
      // Required named parameters must be present.
      for (const p of params) {
        if (p.required && p.named && !named.includes(p.name) && !callee.endsWith('copyWith')) {
          problems.push(`${relative(root, file)}: ${callee}(…) is missing required ${p.name}:`);
        }
      }
    }
  }
}

// Enum values and static members: `PaymentAction.checkStatus`, `PaymentMotion.easeOut`.
for (const file of walk(join(root, 'src/content/docs'))) {
  const text = readFileSync(file, 'utf8');
  for (const block of text.matchAll(/```dart[^\n]*\n([\s\S]*?)```/g)) {
    for (const m of block[1].matchAll(/\b([A-Z]\w+)\.([a-z]\w*)\b/g)) {
      const e = api[m[1]];
      if (!e) continue;
      calls++;
      const known = [
        ...(e.values ?? []).map((v) => v.name),
        ...(e.statics ?? []),
        ...(e.getters ?? []).map((g) => g.name),
        ...(e.constructors ?? []).map((c) => c.name.split('.')[1]).filter(Boolean),
        // Instance fields, mentioned in comments like `IdentityFieldSpec.key`.
        ...(e.constructors ?? []).flatMap((c) => c.params.map((p) => p.name)),
        ...(e.kind === 'enum' ? ['values', 'name', 'tryParse'] : []),
      ];
      if (!known.includes(m[2])) problems.push(`${relative(root, file)}: ${m[1]}.${m[2]} does not exist`);
    }
  }
}

console.log(`check-snippets: ${calls} kit calls and members checked`);
if (problems.length) {
  console.error(`check-snippets: ${problems.length} problems\n  ${problems.join('\n  ')}`);
  process.exit(1);
}
console.log('check-snippets: every kit class and named argument exists in lib/');
