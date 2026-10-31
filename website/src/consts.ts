// The one place the repository URL lives. Set REPO_IS_PLACEHOLDER back to
// true if the URL ever becomes provisional again; pages then show the note.
export const REPO_URL = 'https://github.com/naufaldi/flutter_ui_payment';
export const REPO_IS_PLACEHOLDER = false;
export const REPO_PLACEHOLDER_NOTE =
  'Repository URL is a placeholder until the public repo is created.';

export const PACKAGE_VERSION = '0.1.0';

/** A file in the repository's main branch, e.g. repoFile('docs/decisions.md'). */
export const repoFile = (path: string) => `${REPO_URL}/blob/main/${path}`;
