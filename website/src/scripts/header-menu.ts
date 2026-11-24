// Enhancement only: the menu opens and closes without JavaScript. With it,
// Escape closes the menu and returns focus, and a click outside closes it.
// Every close goes through closeMenu(), which fades the panel out first when
// motion is on (D121) and closes at once otherwise.
import { fadeOut } from './motion.ts';

for (const menu of document.querySelectorAll<HTMLDetailsElement>('[data-fup-menu]')) {
  const summary = menu.querySelector('summary');
  const panel = menu.querySelector<HTMLElement>('.fup-menu-panel');
  let closing: Animation | undefined;

  function closeMenu() {
    if (!menu.open || closing) return;
    const animation = panel ? fadeOut(panel) : undefined;
    if (!animation) {
      menu.open = false;
      return;
    }
    closing = animation;
    animation.addEventListener(
      'finish',
      () => {
        if (closing !== animation) return;
        closing = undefined;
        menu.open = false;
        animation.cancel();
      },
      { once: true },
    );
  }

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && menu.open) {
      closeMenu();
      summary?.focus();
    }
  });
  document.addEventListener('click', (e) => {
    if (e.target instanceof Node && !menu.contains(e.target)) closeMenu();
  });
  // Closing through the summary also fades. Opening stays native, so the
  // toggle, Enter and Space keep working without this script.
  summary?.addEventListener('click', (e) => {
    if (!menu.open) return;
    e.preventDefault();
    if (closing) {
      // The details stays open during the fade. This activation reopens it.
      const animation = closing;
      closing = undefined;
      animation.cancel();
    } else {
      closeMenu();
    }
  });
}
