import assert from 'node:assert/strict';
import { test } from 'node:test';
import { setImmediate } from 'node:timers/promises';

test('activating Menu during its close fade keeps the panel open', async () => {
  const summary = new EventTarget();
  const menu = { open: false, querySelector: (sel) => (sel === 'summary' ? summary : panel) };
  const animations = [];
  const panel = Object.assign(new EventTarget(), {
    style: { removeProperty(name) { delete this[name]; } },
    animate() {
      const animation = {
        playState: 'running',
        cancel() { this.playState = 'idle'; },
        finish() {
          if (this.playState !== 'running') return;
          this.playState = 'finished';
          this.onfinish();
        },
      };
      animations.push(animation);
      return animation;
    },
  });
  const root = { dataset: { fupMotion: '' }, hasAttribute: () => false };
  const document = Object.assign(new EventTarget(), {
    documentElement: root,
    querySelectorAll: (sel) => (sel === '[data-fup-menu]' ? [menu] : []),
  });
  Object.assign(globalThis, {
    window: globalThis,
    document,
    matchMedia: () => new EventTarget(),
    getComputedStyle: () => ({ opacity: '1', transform: 'none' }),
  });
  await import('../src/scripts/header-menu.ts');

  function activateMenu() {
    // Simulate the native details toggle only when the click isn't handled.
    if (summary.dispatchEvent(new Event('click', { cancelable: true }))) menu.open = !menu.open;
  }

  activateMenu();
  activateMenu();
  assert.ok(menu.open && animations.length > 0, 'the exit fade is in progress');
  activateMenu();
  animations.forEach((animation) => animation.finish());
  await setImmediate();

  assert.equal(menu.open, true, 'the panel is still open after the old fade would have ended');
  assert.equal(panel.style.opacity, undefined, 'the panel is not left transparent');
});
