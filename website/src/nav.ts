// Primary site links shared by the header, its menu and the mobile docs menu
// (D110). `section` decides which link marks the reader's current section,
// from the Starlight route id (for example 'components/button').

export interface PrimaryLink {
  label: string;
  href: string;
  section: (id: string) => boolean;
}

const under = (id: string, root: string) => id === root || id.startsWith(`${root}/`);

export const GET_STARTED_HREF = '/start/quick-start/';

export const primaryLinks: PrimaryLink[] = [
  {
    label: 'Docs',
    href: '/start/quick-start/',
    section: (id) =>
      ['start', 'concepts', 'foundations', 'patterns', 'reference'].some((root) => under(id, root)) &&
      id !== 'reference/changelog',
  },
  { label: 'Components', href: '/components/', section: (id) => under(id, 'components') },
  { label: 'Blocks', href: '/blocks/', section: (id) => under(id, 'blocks') },
  { label: 'Changelog', href: '/reference/changelog/', section: (id) => id === 'reference/changelog' },
];

const trimSlash = (path: string) => path.replace(/\/+$/, '');

/**
 * `page` when the link is the page being read, `true` when the page sits in
 * the link's section, otherwise undefined (no attribute).
 */
export function currentState(link: PrimaryLink, id: string, pathname: string): 'page' | 'true' | undefined {
  if (trimSlash(pathname) === trimSlash(link.href)) return 'page';
  return link.section(id) ? 'true' : undefined;
}
