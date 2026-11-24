// Enhancement only: the menu opens and closes without JavaScript. With it,
// Escape closes the menu and returns focus, and a click outside closes it.
// Every close goes through closeMenu(), which fades the panel out first when
// motion is on (D121) and closes at once otherwise.
import { fadeOut } from './motion.ts';

for (const menu of document.querySelectorAll<HTMLDetailsElement>('[data-fup-menu]')) {
  const summary = menu.querySelector('summary');
  const panel = menu.querySelector<HTMLElement>('.fup-menu-panel');
  let closing: ReturnType<typeof fadeOut>;

  function clearFadeStyles() {
    panel?.style.removeProperty('opacity');
    panel?.style.removeProperty('transform');
  }

  async function closeMenu() {
    if (!menu.open || closing) return;
    const fade = panel && fadeOut(panel);
    if (!fade) {
      menu.open = false;
      return;
    }
    closing = fade;
    try {
      await fade.finished;
    } finally {
      // Only the current exit may hide the panel or reset its styles.
      if (closing === fade) {
        closing = undefined;
        menu.open = false;
        clearFadeStyles();
      }
    }
  }

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && menu.open) {
      closeMenu();
      summary?.focus();
    }
  });
  document.addEventListener('click', (e) => {
    if (menu.open && e.target instanceof Node && !menu.contains(e.target)) closeMenu();
  });
  // Closing through the summary also fades. Opening stays native, so the
  // toggle, Enter and Space keep working without this script.
  summary?.addEventListener('click', (e) => {
    if (!menu.open) return;
    e.preventDefault();
    if (closing) {
      closing.stop();
      closing = undefined;
      clearFadeStyles();
    } else {
      closeMenu();
    }
  });
}
