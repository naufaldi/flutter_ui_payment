// Regression for #284: a reader who turns reduced motion on while a page is
// open gets a still page at once, and turning it off again never hides content
// that is already on screen. Runs src/scripts/motion.ts in Node with a minimal
// stand-in for the page and a media query whose preference the test flips.
import { test } from 'node:test';
import assert from 'node:assert/strict';

class Target extends EventTarget {
  dataset = {};
  children = [];
  offsetHeight = 100;
  constructor(reveal) {
    super();
    if (reveal) this.dataset.fupReveal = reveal;
  }
}

class Query extends EventTarget {
  matches = false;
  set(matches) {
    this.matches = matches;
    this.dispatchEvent(new Event('change'));
  }
}

const query = new Query();
const root = { dataset: { fupMotion: '' }, hasAttribute: () => false };
const single = new Target('');
const group = new Target('stagger');
group.children = [new Target(), new Target()];
// A reveal or transition still under way, and an endless one that cannot finish.
const fade = { finished: false, finish() { this.finished = true; } };
const spinner = { finish() { throw new Error('InvalidStateError'); } };

Object.assign(globalThis, {
  window: globalThis,
  innerHeight: 800,
  matchMedia: () => query,
  document: {
    documentElement: root,
    querySelectorAll: (sel) => (sel === '[data-fup-reveal]' ? [single, group] : []),
    getAnimations: () => [spinner, fade],
  },
  // Sections never scroll into view here; only the preference changes.
  IntersectionObserver: class {
    observe() {}
    unobserve() {}
    disconnect() {}
  },
});

await import('../src/scripts/motion.ts');

const hidden = () =>
  [single, ...group.children].filter((t) => !('fupRevealed' in t.dataset));

test('turning reduced motion on mid-page stops motion and shows every section', () => {
  assert.ok('fupMotion' in root.dataset, 'motion starts on');
  assert.equal(hidden().length, 3, 'sections start waiting for their reveal');

  query.set(true);

  assert.ok(!('fupMotion' in root.dataset), 'the gate that drives CSS motion is gone');
  assert.deepEqual(hidden(), [], 'every reveal target is shown');
  assert.ok(fade.finished, 'a running animation jumps to its end state');
});

test('turning reduced motion off again keeps visible content visible', () => {
  query.set(false);

  assert.ok(!('fupMotion' in root.dataset), 'entrance keyframes are not replayed');
  assert.deepEqual(hidden(), []);
});
