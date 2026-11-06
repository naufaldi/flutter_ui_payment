// Docs site motion (D118). Two jobs only: reveal landing sections once as they
// scroll into view, and fade a panel out before it closes. Everything else is
// CSS. The pre-paint gate in astro.config.mjs sets data-fup-motion on <html>
// only when JavaScript runs and reduced motion is off; every hide in
// hairline.css hangs on it, so a failure here leaves all content visible.
import { animate } from 'motion/mini';
import { inView } from 'motion';

declare global {
  interface Window {
    __fupMotionReady?: boolean;
  }
}

const ease = [0.23, 1, 0.32, 1] as const;
const root = document.documentElement;
const reduced = matchMedia('(prefers-reduced-motion: reduce)');

// Tell the failsafe timer the module loaded.
window.__fupMotionReady = true;

/** True while the gate is present and reduced motion is off. */
export const motionOn = () => 'fupMotion' in root.dataset && !reduced.matches;

/** Fades and shrinks a panel out in 140 ms. The caller closes it afterwards. */
export async function fadeOut(el: HTMLElement): Promise<void> {
  if (!motionOn()) return;
  await animate(el, { opacity: 0, transform: 'scale(0.97)' }, { duration: 0.14, ease }).finished;
}

function reveal(el: HTMLElement) {
  const stagger = el.dataset.fupReveal === 'stagger';
  const targets = stagger ? (Array.from(el.children) as HTMLElement[]) : [el];
  if (!motionOn()) {
    // The gate went away while we waited: show everything, animate nothing.
    for (const t of targets) t.dataset.fupRevealed = '';
    return;
  }
  targets.forEach((t, i) => {
    const delay = Math.min(i, 6) * 0.05;
    animate(
      t,
      { opacity: [0, 1], transform: ['translateY(12px)', 'none'] },
      { duration: 0.36, ease, delay },
    ).finished.then(
      () => {
        t.dataset.fupRevealed = '';
        t.style.removeProperty('opacity');
        t.style.removeProperty('transform');
      },
      () => {
        t.dataset.fupRevealed = '';
      },
    );
  });
}

if (motionOn()) {
  const targets = [
    ...document.querySelectorAll<HTMLElement>('[data-fup-reveal]'),
    ...(root.hasAttribute('data-has-hero')
      ? document.querySelectorAll<HTMLElement>('.sl-markdown-content > .sl-heading-wrapper.level-h2')
      : []),
  ];
  for (const el of targets) {
    // A group taller than the viewport can never show 20% at once.
    const amount = el.offsetHeight > innerHeight * 4 ? 'some' : 0.2;
    // inView fires once per entry; the callback returns nothing, so the
    // element is unobserved after the first reveal.
    inView(
      el,
      () => {
        reveal(el);
      },
      { amount },
    );
  }
}
