import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { copyFileSync, cpSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { test } from 'node:test';

for (const mode of ['all LF', 'mixed LF and CRLF', 'all CRLF']) {
  test(`checks the committed API against Dart sources with ${mode} without writing it`, (t) => {
    const root = mkdtempSync(join(tmpdir(), 'rakit-api-'));
    t.after(() => rmSync(root, { recursive: true, force: true }));
    const lib = join(root, 'lib');
    const script = join(root, 'website/scripts/gen-api.mjs');
    const output = join(root, 'website/src/data/api.json');
    cpSync(new URL('../../lib/', import.meta.url), lib, { recursive: true });
    mkdirSync(dirname(script), { recursive: true });
    mkdirSync(dirname(output), { recursive: true });
    copyFileSync(new URL('./gen-api.mjs', import.meta.url), script);
    const committed = readFileSync(new URL('../src/data/api.json', import.meta.url));
    writeFileSync(output, committed);

    for (const entry of readdirSync(lib, { recursive: true, withFileTypes: true })) {
      if (!entry.isFile() || !entry.name.endsWith('.dart')) continue;
      const path = join(entry.parentPath, entry.name);
      const crlf = mode === 'all CRLF' || (mode === 'mixed LF and CRLF' && entry.name === 'primitives.dart');
      writeFileSync(path, readFileSync(path, 'utf8').replace(/\r?\n/g, crlf ? '\r\n' : '\n'));
    }

    const result = spawnSync(process.execPath, [script, '--check'], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.deepEqual(readFileSync(output), committed);
  });
}
