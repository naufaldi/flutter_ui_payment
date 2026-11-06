// Docs site motion (D121). Two jobs only: reveal landing sections once as they
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

/** The elements CSS hides until revealed: the marked element, or a group's children. */
const revealTargets = (el: HTMLElement) =>
  el.dataset.fupReveal === 'stagger' ? (Array.from(el.children) as HTMLElement[]) : [el];

function reveal(el: HTMLElement) {
  const targets = revealTargets(el);
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

const sections = motionOn()
  ? [
      ...document.querySelectorAll<HTMLElement>('[data-fup-reveal]'),
      ...(root.hasAttribute('data-has-hero')
        ? document.querySelectorAll<HTMLElement>('.sl-markdown-content > .sl-heading-wrapper.level-h2')
        : []),
    ]
  : [];

for (const el of sections) {
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

// Reduced motion turned on while the page is open: mark every section shown,
// drop the gate so no CSS motion starts, then jump every running animation
// to its end. A transition already under way keeps running when its rule goes
// away, so it is finished too. finish() also settles Motion's `finished`
// promise, so a pending menu close still runs; cancel() would leave it hanging.
// Turning reduced motion off again keeps this page still: putting the gate
// back would replay the entrance keyframes and hide content already on screen.
// The next page load picks the preference up again.
reduced.addEventListener('change', () => {
  if (!reduced.matches) return;
  for (const el of sections) for (const t of revealTargets(el)) t.dataset.fupRevealed = '';
  delete root.dataset.fupMotion;
  for (const a of document.getAnimations()) {
    try {
      a.finish();
    } catch {
      // An infinite animation cannot finish; none of ours are, so leave it.
    }
  }
});
