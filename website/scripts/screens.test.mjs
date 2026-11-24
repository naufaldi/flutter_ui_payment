import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, rmSync, utimesSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { test } from 'node:test';

test('selective reports include the stale tail but accept a fresh shorter recapture', async (t) => {
  const root = mkdtempSync(join(tmpdir(), 'rakit-screens-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const script = join(root, 'website/scripts/screens.mjs');
  const manifest = join(root, 'website/src/data/screens.json');
  const captureDir = join(root, 'example/build/screenshots_hairline');
  const outputDir = join(root, 'website/public/screens');
  for (const dir of [dirname(script), dirname(manifest), captureDir, outputDir]) {
    mkdirSync(dir, { recursive: true });
  }
  copyFileSync(new URL('./screens.mjs', import.meta.url), script);

  const since = Date.UTC(2025, 10, 1);
  const name = 'android_catalog_data_table_variants';
  const unrequested = `${name}_dark`;
  const size = { width: 640, height: 120 };
  const registry = JSON.stringify({
    [name]: { ...size, parts: [size, size] },
    [unrequested]: size,
  });
  writeFileSync(manifest, registry);
  for (const image of [name, `${name}_part2`, `${name}_part3`, unrequested]) {
    writeFileSync(join(outputDir, `${image}.webp`), image);
  }
  const capture = (image, time) => {
    const file = join(captureDir, `${image}.png`);
    writeFileSync(file, image);
    utimesSync(file, new Date(time), new Date(time));
  };
  const report = () => spawnSync(process.execPath,
    [script, `--requested=${name}`, `--since=${since}`], { encoding: 'utf8' });

  capture(name, since - 1000);
  capture(`${name}_part2`, since - 1000);
  const stale = report();
  assert.equal(stale.status, 1, stale.stderr);
  assert.doesNotMatch(stale.stdout, new RegExp(unrequested));
  assert.ok(stale.stdout.includes(`  ${name}_part3\n`), stale.stdout);
  assert.ok(!stale.stdout.includes(`  ${name}_part3 (existing WebP)\n`), stale.stdout);
  assert.ok(stale.stdout.includes(`  ${name}_part2 (older PNG)\n`), stale.stdout);

  rmSync(join(captureDir, `${name}_part2.png`));
  for (const [label, offset] of [['older', -1000], ['fresh', 1000]]) {
    await t.test(`orphan after a gap (${label} PNG) is missing, not fresh or reusable`, () => {
      capture(`${name}_part3`, since + offset);
      const orphan = report();
      assert.equal(orphan.status, 1, orphan.stderr);
      assert.match(orphan.stdout, /Fresh PNGs \(0\)/);
      assert.ok(orphan.stdout.includes(`  ${name}_part3\n`), orphan.stdout);
      assert.ok(!orphan.stdout.includes(`  ${name}_part3 (`), orphan.stdout);
    });
  }

  rmSync(join(captureDir, `${name}.png`));
  capture(`${name}_part2`, since - 1000);
  const committed = report();
  assert.equal(committed.status, 1, committed.stderr);
  assert.match(committed.stdout, /Fresh PNGs \(0\)/);
  assert.ok(committed.stdout.includes(`  ${name}_part2 (existing WebP)\n`), committed.stdout);
  assert.ok(!committed.stdout.includes(`  ${name}_part2 (older PNG)\n`), committed.stdout);
  assert.ok(committed.stdout.includes(`  ${name}_part3\n`), committed.stdout);
  assert.ok(committed.stdout.includes(`  ${name}_part3 (existing WebP)\n`), committed.stdout);

  rmSync(join(outputDir, `${name}.webp`));
  const noFallback = report();
  assert.equal(noFallback.status, 1, noFallback.stderr);
  assert.ok(noFallback.stdout.includes(`  ${name}_part3\n`), noFallback.stdout);
  assert.ok(noFallback.stdout.includes('Existing assets available for reuse (0)'), noFallback.stdout);

  rmSync(join(captureDir, `${name}_part3.png`));
  capture(name, since + 1000);
  capture(`${name}_part2`, since + 1000);
  const fresh = report();
  assert.equal(fresh.status, 0, fresh.stdout + fresh.stderr);
  assert.ok(fresh.stdout.includes(`  ${name}_part2\n`), fresh.stdout);
  assert.doesNotMatch(fresh.stdout, new RegExp(`${name}_part3`));
  assert.equal(readFileSync(manifest, 'utf8'), registry);
  assert.equal(readFileSync(join(outputDir, `${name}_part3.webp`), 'utf8'), `${name}_part3`);
});
