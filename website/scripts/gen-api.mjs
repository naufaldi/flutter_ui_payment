// Extracts the public API of flutter_ui_payment from ../lib into
// src/data/api.json, so every props table on the site comes from the Dart
// source instead of hand-written copies. Runs before `astro build`.
//
// Deliberately small: it understands the shapes this package uses
// (`const Foo({...})` constructors, `final Type name;` fields, `///` docs,
// enums and top-level functions, including show-filtered exports). It fails loudly when it cannot match a
// constructor parameter to a field, so drift shows up as a broken build.

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const lib = resolve(here, '../../lib');
const out = resolve(here, '../src/data/api.json');

const barrel = readFileSync(join(lib, 'flutter_ui_payment.dart'), 'utf8');
const files = [...barrel.matchAll(/^export '([^']+)'(?:\s+show\s+([^;]+))?;/gm)].map((m) => ({ rel: m[1], show: m[2] ? new Set(m[2].split(',').map((n) => n.trim())) : null }));
if (files.length === 0) throw new Error('No exports found in the barrel file');

/** Removes // comments (not ///) and string contents, keeping line lengths. */
function stripForBraces(line) {
  let s = line.replace(/'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"/g, (m) => ' '.repeat(m.length));
  const i = s.indexOf('//');
  return i >= 0 ? s.slice(0, i) : s;
}

/** Index of the line that closes the brace block opened on line `start`. */
function blockEnd(lines, start) {
  let depth = 0;
  let opened = false;
  for (let i = start; i < lines.length; i++) {
    for (const ch of stripForBraces(lines[i])) {
      if (ch === '{') { depth++; opened = true; }
      if (ch === '}') depth--;
    }
    if (opened && depth === 0) return i;
    // `enum Foo { a, b }` on one line, or `class Foo;`-like forms.
  }
  return lines.length - 1;
}

/** `///` lines directly above `index` (skipping annotations). */
function docAbove(lines, index) {
  const doc = [];
  let i = index - 1;
  while (i >= 0 && /^\s*@\w+/.test(lines[i])) i--;
  while (i >= 0 && /^\s*\/\/\//.test(lines[i])) {
    doc.unshift(lines[i].replace(/^\s*\/\/\/ ?/, ''));
    i--;
  }
  return cleanDoc(doc.join('\n'));
}

function cleanDoc(text) {
  return text
    .replace(/\[([A-Za-z_][\w.]*)\]/g, '`$1`')
    .trim();
}

/** Text between the parenthesis that opens at `text[open]` and its match. */
function parenContent(text, open) {
  let depth = 0;
  for (let i = open; i < text.length; i++) {
    const ch = text[i];
    if (ch === '(') depth++;
    if (ch === ')') {
      depth--;
      if (depth === 0) return text.slice(open + 1, i);
    }
  }
  throw new Error('Unbalanced parenthesis');
}

/** Splits a parameter list on top-level commas. */
function splitTopLevel(text) {
  const parts = [];
  let depth = 0;
  let current = '';
  for (const ch of text) {
    if ('([{<'.includes(ch)) depth++;
    if (')]}>'.includes(ch)) depth--;
    if (ch === ',' && depth === 0) {
      parts.push(current);
      current = '';
    } else {
      current += ch;
    }
  }
  parts.push(current);
  return parts.map((p) => p.replace(/\s+/g, ' ').trim()).filter(Boolean);
}

/** Parses a Dart parameter list into named and positional parameters. */
function parseParams(raw) {
  const params = [];
  // Named section `{...}` and optional positional `[...]`.
  const namedStart = raw.indexOf('{');
  const optStart = raw.indexOf('[');
  let positional = raw;
  let named = '';
  let optional = '';
  if (namedStart >= 0 && (optStart < 0 || namedStart < optStart)) {
    positional = raw.slice(0, namedStart);
    named = raw.slice(namedStart + 1, raw.lastIndexOf('}'));
  } else if (optStart >= 0) {
    positional = raw.slice(0, optStart);
    optional = raw.slice(optStart + 1, raw.lastIndexOf(']'));
  }
  for (const p of splitTopLevel(positional)) params.push(parseParam(p, false, true));
  for (const p of splitTopLevel(optional)) params.push(parseParam(p, false, false));
  for (const p of splitTopLevel(named)) params.push(parseParam(p, true, false));
  // `super.key` is every widget's; a model's own `this.key` stays.
  return params.filter((p) => !(p.isSuper && p.name === 'key'));
}

function parseParam(text, named, positionalRequired) {
  let rest = text.replace(/^@\w+\s+/, '');
  const required = positionalRequired || /^required\s/.test(rest);
  rest = rest.replace(/^required\s+/, '');
  let def = null;
  const eq = indexOfTopLevel(rest, '=');
  if (eq >= 0) {
    def = rest.slice(eq + 1).trim();
    rest = rest.slice(0, eq).trim();
  }
  let name;
  let type = null;
  let fieldName = null;
  let viaThis = false;
  let isSuper = false;
  const thisMatch = rest.match(/^(?:(.+)\s+)?(this|super)\.(_?)(\w+)$/);
  if (thisMatch) {
    viaThis = thisMatch[2] === 'this';
    isSuper = thisMatch[2] === 'super';
    // Dart private named parameters: `this._border` is passed as `border:`.
    name = thisMatch[4];
    fieldName = thisMatch[3] + thisMatch[4];
    type = thisMatch[1] ?? null;
    // `super.value = const VideoPlaybackValue()`: the default names the type.
    if (!type && def) type = def.match(/^(?:const\s+)?([A-Z]\w*)/)?.[1] ?? null;
  } else {
    const m = rest.match(/^(.*\S)\s+(\w+)$/);
    if (!m) throw new Error(`Cannot parse parameter "${text}"`);
    type = m[1];
    name = m[2];
  }
  return { name, type, required, default: def, named, viaThis, isSuper, fieldName, doc: '' };
}

function indexOfTopLevel(text, char) {
  let depth = 0;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if ('([{<'.includes(ch)) depth++;
    if (')]}>'.includes(ch)) depth--;
    if (ch === char && depth === 0) return i;
  }
  return -1;
}

/** Joins lines from `start` until the parameter list closes. */
function collectSignature(lines, start) {
  let text = '';
  let depth = 0;
  let seen = false;
  for (let i = start; i < lines.length; i++) {
    const line = stripForBraces(lines[i]);
    text += lines[i].replace(/\/\/.*$/, '') + '\n';
    for (const ch of line) {
      if (ch === '(') { depth++; seen = true; }
      if (ch === ')') depth--;
    }
    if (seen && depth === 0) return text;
  }
  return text;
}

const api = {};

let shown = null;
let found = new Set();
function add(name, entry) {
  if (shown && !shown.has(name)) return;
  found.add(name);
  if (api[name]) throw new Error(`Duplicate public name ${name}`);
  api[name] = entry;
}

for (const {rel, show} of files) {
  shown = show;
  found = new Set();
  const path = join(lib, rel);
  const source = readFileSync(path, 'utf8');
  const lines = source.split('\n');
  const file = `lib/${rel}`;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    const enumMatch = line.match(/^enum ([A-Z]\w*)/);
    if (enumMatch) {
      const end = blockEnd(lines, i);
      const body = lines.slice(i, end + 1).join('\n');
      const inner = body.slice(body.indexOf('{') + 1, body.lastIndexOf('}'));
      const values = [];
      let pending = [];
      for (const raw of inner.split('\n')) {
        if (/^\s*\/\/\//.test(raw)) {
          pending.push(raw.replace(/^\s*\/\/\/ ?/, ''));
          continue;
        }
        const code = stripForBraces(raw);
        const stop = code.indexOf(';');
        const part = stop >= 0 ? code.slice(0, stop) : code;
        for (const m of part.matchAll(/\b([a-z]\w*)\b/g)) {
          values.push({ name: m[1], doc: cleanDoc(pending.join('\n')) });
        }
        if (part.trim()) pending = [];
        if (stop >= 0) break;
      }
      add(enumMatch[1], { kind: 'enum', file, doc: docAbove(lines, i), values });
      i = end;
      continue;
    }

    const extMatch = line.match(/^extension ([A-Z]\w*) on (\w+)/);
    if (extMatch) {
      const end = blockEnd(lines, i);
      const members = [];
      for (let j = i + 1; j < end; j++) {
        const m = lines[j].match(/^  (?:String|bool|int)\s+(?:get\s+)?([a-z]\w*)/);
        if (m) members.push(m[1]);
      }
      add(extMatch[1], { kind: 'extension', file, on: extMatch[2], doc: docAbove(lines, i), members });
      i = end;
      continue;
    }

    const classMatch = line.match(/^(abstract )?class ([A-Z]\w*)(?:<[^>]+>)?(.*)$/);
    if (classMatch) {
      const name = classMatch[2];
      const end = blockEnd(lines, i);
      // Superclass text may continue onto the next lines before `{`.
      let header = classMatch[3];
      for (let j = i + 1; !header.includes('{') && j <= end; j++) header += ' ' + lines[j].trim();
      const ext = header.match(/extends\s+([\w<>, ]+?)\s*(?:with|implements|\{)/);
      const fields = {};
      const constructors = [];
      const statics = [];
      const members = [];
      let copyWith = null;
      for (let j = i + 1; j < end; j++) {
        const l = lines[j];
        // Only direct class members, never locals or body statements.
        if (/^  (?! )/.test(l) && !/^  @/.test(l) && !/^\s*@override/.test(lines[j - 1] ?? '')) {
          const match = l.match(/^  (static )?(?:(?:late )?final |const )?([\w<>?,]+)\s+(get )?([a-z]\w*)\s*([(;=]|=>|\{)/);
          if (match && !['copyWith', 'lerp'].includes(match[4])) {
            const [, st, type, getter, memberName, tail] = match;
            const method = tail === '(';
            let value;
            if (/^  static const /.test(l)) {
              let declaration = l;
              for (let k = j + 1; !declaration.includes(';') && k < end; k++) declaration += ' ' + lines[k].trim();
              value = declaration.slice(declaration.indexOf('=') + 1, declaration.indexOf(';')).trim();
            }
            members.push({ name: memberName, kind: getter ? 'getter' : st ? 'static' : method ? 'method' : 'field', static: Boolean(st), type, ...(method ? {signature: (() => { const sig = collectSignature(lines, j); const open = sig.indexOf('('); return (sig.slice(0, open) + '(' + parenContent(sig, open) + ')').replace(/\s+/g, ' ').trim(); })()} : {}), ...(value ? {value} : {}), doc: docAbove(lines, j) });
          }
        }

        const field = l.match(/^  (?:final|late final)\s+(.+?)\s+(_?\w+)(?:\s*=.*)?;\s*$/);
        if (field) fields[field[2]] = { type: field[1], doc: docAbove(lines, j) };
        const getter = l.match(/^  ([\w<>?, ]+?)\s+get\s+(\w+)\s*(?:=>|\{)/);
        if (getter && !getter[2].startsWith('_')) {
          fields[`get:${getter[2]}`] = { type: getter[1], doc: docAbove(lines, j) };
        }
        const ctor = l.match(new RegExp(`^  (const |factory )?${name}(\\.\\w+)?\\(`));
        if (ctor && ctor[2] !== '._') {
          const sig = collectSignature(lines, j);
          const raw = parenContent(sig, sig.indexOf('('));
          constructors.push({
            name: ctor[2] ? `${name}${ctor[2]}` : name,
            factory: ctor[1]?.trim() === 'factory',
            params: parseParams(raw),
            doc: docAbove(lines, j),
          });
        }
        if (new RegExp(`^  ${name} copyWith\\(`).test(l)) {
          const sig = collectSignature(lines, j);
          copyWith = parseParams(parenContent(sig, sig.indexOf('('))).map((p) => p.name);
        }
        const stat = l.match(/^  static (?:const |final )?([\w<>?, ]+?)\s+([a-z]\w*)\s*[(=]/);
        if (stat && !stat[2].startsWith('_')) statics.push(stat[2]);
      }
      for (const c of constructors) {
        for (const p of c.params) {
          if (!p.viaThis) continue;
          const f = fields[p.fieldName];
          if (!f) throw new Error(`${name}: parameter ${p.name} has no field ${p.fieldName}`);
          p.type = f.type;
          // A private field's doc usually sits on its public getter.
          p.doc = f.doc || fields[`get:${p.name}`]?.doc || '';
        }
      }
      const getters = Object.entries(fields)
        .filter(([k]) => k.startsWith('get:'))
        .map(([k, v]) => ({ name: k.slice(4), type: v.type, doc: v.doc }));
      add(name, {
        kind: classMatch[1] ? 'abstract class' : 'class',
        file,
        doc: docAbove(lines, i),
        extends: ext ? ext[1].trim() : null,
        constructors,
        getters,
        statics,
        members,
        copyWith,
      });
      i = end;
      continue;
    }

    const fnMatch = line.match(/^([A-Z][\w<>?, ]*?|\w+)\s+([a-z]\w*)(<\w+>)?\($/) ||
      line.match(/^([A-Z][\w<>?, ]*?)\s+([a-z]\w*)(<\w+>)?\(/);
    if (fnMatch && !line.startsWith(' ') && !fnMatch[2].startsWith('_') &&
        !/^(import|export|library|part|return)\b/.test(line)) {
      const sig = collectSignature(lines, i);
      const raw = parenContent(sig, sig.indexOf('('));
      add(fnMatch[2], {
        kind: 'function',
        file,
        doc: docAbove(lines, i),
        returns: fnMatch[1].trim(),
        typeParams: fnMatch[3] ?? '',
        params: parseParams(raw),
      });
    }
  }
  for (const name of show ?? []) {
    if (!found.has(name)) throw new Error(`Unmatched shown name ${name} in ${rel}`);
  }
}

mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, JSON.stringify(api, null, 2) + '\n');
console.log(`gen-api: ${Object.keys(api).length} public declarations from ${files.length} files`);
