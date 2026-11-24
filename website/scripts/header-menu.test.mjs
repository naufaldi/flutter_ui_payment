import { test } from 'node:test';
import assert from 'node:assert/strict';

test('the last summary activation wins while the menu is fading out', async () => {
  const animations = [];
  function createMenu(open) {
    const summary = new EventTarget();
    const panel = {
      animate() {
        const animation = new EventTarget();
        animation.cancel = () => { animation.cancelled = true; };
        animations.push(animation);
        return animation;
      },
    };
    return { open, summary, querySelector: (selector) => (selector === 'summary' ? summary : panel) };
  }
  const menu = createMenu(false);
  const otherMenu = createMenu(true);
  Object.assign(globalThis, {
    window: globalThis,
    matchMedia: () => Object.assign(new EventTarget(), { matches: false }),
    document: Object.assign(new EventTarget(), {
      documentElement: { dataset: { fupMotion: '' }, hasAttribute: () => false },
      querySelectorAll: (selector) => (selector === '[data-fup-menu]' ? [menu, otherMenu] : []),
    }),
  });

  await import('../src/scripts/header-menu.ts');

  function activateSummary(target = menu) {
    const click = new Event('click', { cancelable: true });
    if (target.summary.dispatchEvent(click)) target.open = !target.open;
  }

  activateSummary();
  assert.equal(menu.open, true);
  activateSummary();
  const [firstClose] = animations;
  assert.equal(menu.open, true, 'the panel stays open during the fade');

  activateSummary();
  assert.equal(firstClose.cancelled, true, 'reopening stops the fade');
  assert.equal(menu.open, true);
  activateSummary();
  const [, latestClose] = animations;
  activateSummary(otherMenu);
  const [, , otherClose] = animations;
  firstClose.dispatchEvent(new Event('finish'));
  assert.equal(menu.open, true, 'a stale finish cannot close the menu');
  latestClose.dispatchEvent(new Event('finish'));
  assert.equal(menu.open, false, 'the current close can still finish');
  assert.equal(otherMenu.open, true, 'another menu still owns its close');
  otherClose.dispatchEvent(new Event('finish'));
  assert.equal(otherMenu.open, false);
});
