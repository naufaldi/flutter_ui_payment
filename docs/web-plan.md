# Website plan: landing, documentation and Flutter gallery

Date: 30 October 2026. Scope: a static website for `flutter_ui_payment` under `website/`, built into one deployable folder. Authorized: local, ready-to-deploy output. Not authorized: hosting, a domain, a public repository, pub.dev publication or deployment. `publish_to: none` stays.

## 1. Benchmark and gap

Benchmark: [forui.dev](https://forui.dev/) and [its docs](https://forui.dev/docs), read from the server-rendered HTML fetched with curl (not inspected visually in a browser), plus its [README](https://github.com/duobaseio/forui/blob/main/README.md) and [CONTRIBUTING](https://github.com/duobaseio/forui/blob/main/CONTRIBUTING.md) (docs are MDX with a Flutter snippets app embedded for live widgets). We borrow the developer-experience structure, not the brand, design, claims or component breadth.

| Forui has | We had | Decision |
| --- | --- | --- |
| Landing with one promise, Get Started and source CTA | Only a README | Landing with one promise, Get started / Components / Gallery CTAs. No GitHub or pub.dev buttons until those exist. |
| Docs IA: Getting started, Concepts (themes, controls, localization, responsive), Guides, Reference | Four repo Markdown files | Same shape: Start, Concepts, Components (by module), Reference. |
| Categorized widget sidebar, page anchors, "On this page" | Inventory table in `docs/components.md` | One page per module (11), grouped sidebar, TOC, breadcrumbs, prev/next. |
| Live widget previews embedded in docs | A Flutter gallery app, no web host | Real Flutter gallery at `/play/`, opened on click, deep-linked per module (`?section=`). Docs show real native screenshots, labeled with platform. |
| Search ⌘K, LLMs page, API reference | None | Local search (⌘K/Ctrl K), `llms.txt`, raw `.md` per page, a signature reference generated from `lib/src`. |
| Theme builder, CLI | Not needed | Out of scope. `PaymentTheme` is documented with real code instead. |

## 2. Product thinking, answered on the owner's behalf

The owner asked for these answers to be made for them. They come from `PRD.md` and the repository; nothing here is market evidence. There are no interviews, adoption numbers or named users.

**Reason to exist**

1. *Workaround (P1):* Flutter developers building checkout today assemble generic Material widgets and hand-roll "pending" and "timeout" screens; the PRD records this as an **assumption**, not observed behavior.
2. *Why this over generic UI kits (P2):* general kits give buttons and cards; this kit models the payment attempt itself (unknown outcome, stale snapshots, re-quote approval) so the screen cannot claim success or invite a second charge. That reason holds with perfect distribution only if the state model is the visible product. The site must lead with it.
3. *Named person (P4):* none exists. The concrete readers are (a) a Flutter developer evaluating whether to compose a checkout, and (b) a portfolio reviewer judging design and engineering quality. Demand is **unproven**.

**What to build**

4. *One good idea, steps to it (P6):* "the screen stays honest when the result is not known yet." On the landing it must be reachable in one interaction: a state switcher showing real Flutter output for success, pending, unknown and changed total.
5. *Do less (P9):* no theme builder, no CLI, no fake playground in HTML. Reuse the existing gallery app and screenshots. Signatures and snippets come from the source so the site cannot drift.
6. *Design the system with real content (P12):* screenshots are real captures (Android 11 emulator, iOS 18.1 simulator, Flutter web), never HTML mockups labeled as Flutter.

**How to test it**

7. *Chain (P13):* a developer understands the promise in under a minute → can copy a compiling checkout → can see every state in the gallery → integrates with their own host. **Link under test now:** the second one (copy a compiling example). Half-built on purpose: hosting, analytics, versioned docs.
8. *Remove excuses (P14):* the Getting started code is analyzed against the real package (`website/snippets`), so "the snippet didn't compile" cannot be the reason a test fails.

**How it wins**

9. *Distribution (P17):* the user and the evaluator are the same developer; distribution will be pub.dev and a public repo once names are confirmed. Until then the site states "local only" and shows a path dependency.
10. *Outcome (P20):* the measurable outcome is the PRD's "external developer composes a checkout in ≤30 minutes", still **unproven**.

**Verdict.** One good idea: payment UI that cannot lie about an unresolved payment. Biggest risk: the kit reads as a screenshot gallery. Cheapest test: one outside Flutter developer follows Getting started with their own theme and data and is timed. This month: the site and copy-paste path at 100%; hosting, analytics and versioning deliberately not built. Violated principles today: P4 (no named user), P16 (fit not measured). Unresolved: package name, repository, and whether anyone besides the owner needs this.

## 3. Audience and promise

- **Audience:** Flutter developers building checkout, top-up or bill payment flows; portfolio reviewers.
- **Promise:** "Payment screens that stay honest when the result isn't known yet." Your backend decides money, identity and authorization; the kit renders its answers.

## 4. Stack and tradeoffs

- **Astro 5 (static output), plain CSS, small inline scripts.** Pre-rendered HTML per route, Markdown content, Shiki highlighting for Dart, no client framework. Alternative considered: a single hand-written HTML file (no build step, but no Markdown pipeline, TOC or per-page `.md`).
- **Fonts:** system UI for text; one self-hosted variable display face for headings (preloaded). Mono uses the platform's monospace stack.
- **Single sources:** `docs/integration.md`, `docs/compatibility.md`, `docs/decisions.md`, `docs/deployment.md` and `CHANGELOG.md` are rendered directly from the repository (links rewritten at build). Module pages are new web pages; their signatures are generated from `lib/src` at build and their main snippets are injected from `website/snippets`, which `flutter analyze` checks.
- **Search:** a build-time JSON index (~25 pages) loaded on first open. No third-party service.
- **Gallery:** `flutter build web --release --no-web-resources-cdn --base-href <base>play/app/` from `example/`, copied into `dist/play/app/`. `/play/` is a static page that loads it in an iframe only after a click.
- **Base path:** `SITE_BASE` (default `/`) and optional `SITE_URL` (canonical, Open Graph, sitemap). Without `SITE_URL` no absolute URL is invented.

## 5. Information architecture

```
/                      landing
/docs/                 introduction
  Start                getting-started, integration
  Concepts             payment-states, kyc, theming, accessibility, compatibility, decisions
  Components           foundation, interaction, navigation, sheets, media, promotions,
                       checkout, status, history, receipt, verification
  Reference            api, changelog, deployment
/play/                 Flutter gallery launcher (?section=<module>)
/docs/<slug>.md        raw Markdown for every docs page
/llms.txt              index for language models
/search.json /sitemap.xml /robots.txt /changelog.xml /404.html
```

## 6. Contract

| Deliverable | Outcome | Edges | Done when |
| --- | --- | --- | --- |
| Landing | Promise, real output, CTAs that work | 320 px width, dark mode, reduced motion, no JS | State switcher shows real Flutter captures for 4 states with honest labels; CTAs reach docs, components, gallery |
| Docs | Copyable, accurate pages for every exported module | No search results, long code on mobile, deep-link reload, missing clipboard permission | All 11 modules have pages with generated signatures; search, drawer, TOC, copy and copy-as-Markdown work by keyboard |
| Gallery | Real Flutter widgets, loaded on demand | Bundle missing, slow load, failure, subpath hosting | Click loads the app; failure shows retry and a direct link; `?section=` opens that module |
| Release | One folder any static host can serve | Root and subpath base | `pnpm --dir website build:release` produces `website/dist/`; link check passes for `/` and a subpath build |

**Security.** No backend, forms, secrets, cookies or tracking. Only first-party static assets (the Flutter gallery may fetch fallback fonts from Google's font CDN; this is checked and documented). Theme preference in `localStorage` with try/catch.

**Performance.** Landing and docs must not download Flutter. Record HTML/CSS/JS/image transfer of the landing and a docs page, the gallery bundle size, and gallery time-to-first-frame in local Chrome. No Lighthouse score is claimed.

**Proof.** Built output; internal link and asset check for both base paths; `flutter analyze` on `website/snippets`; real browser screenshots at 1440, 390 and 320 px, light and dark, inspected; keyboard checks of search, drawer, theme, copy and gallery launch. No native suites (unchanged package code).

## 7. Delivery boundary

Done means a verified local `website/dist/` and the documentation to deploy it. Not done here: choosing a host or domain, creating a repository, publishing to pub.dev, or deploying. `docs/deployment.md` explains each of those as a separate, owner-authorized step.
