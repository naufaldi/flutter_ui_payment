# Documentation map

Start with [the daily design-system guide](design-system.md) when changing the kit. Read only the linked topic spec for the change; the decision history is not an onboarding checklist.

## Active: requirements and daily work

| Document | Audience and role |
| --- | --- |
| [Product PRD](../PRD.md) | Product and engineering: scope, user stories, payment invariants and acceptance. |
| [Foundation PRD](prd-foundation-components.md) | Component maintainers: detailed normative specs and B1–B13 quality bar. [§8](prd-foundation-components.md#8-decisions) records approved decisions; use the latest applicable decision, including explicit amendments and supersession. |
| [Daily guide](design-system.md) | Maintainers and agents: derived summary of active rules, with links back to their source. It adds no requirements or APIs. |
| [Agent instructions](../AGENTS.md) | Contributors: workflow, checks, safety and device ownership. |

## Reference: integration and evidence

For complete mobile host examples, use the website's **Blocks** section and
`example/lib/compositions/README.md`. Components document APIs; domain Patterns
explain behavior; Guides cover general recipes. D105 records this navigation
split while preserving existing page URLs. History and KYC block issues remain
follow-ups, not shipped examples.

| Document | Audience and role |
| --- | --- |
| [Component inventory](components.md) and [component site](https://flutter-ui-payment.netlify.app/components/) | Host developers: current public names, shipped usage, states and host responsibilities. |
| [Integration](integration.md) | Host developers: state ownership, adapters and recovery. |
| [Compatibility](compatibility.md) | Integrators: declared platform support and recorded verification limits. |
| [Decisions and tradeoffs](decisions.md) | Maintainers: rationale, costs and historical evidence; consult the PRD register for the decision contract. |
| [Design research](design-research.md#0-current-direction-stripe-calm) | Designers: chosen direction in §0; earlier alternatives remain research history. |

**Requirements and implementation answer different questions.** PRDs and the decision register specify approved requirements. Exported [source](../lib/flutter_ui_payment.dart), generated [API data](../website/src/data/api.json) and component documentation describe what ships. D98's family review and host adoption are implemented and locally verified under D100–D103; see the [family disposition](decisions.md#d98-family-disposition) for supported surfaces and limits. This is not a package publication or deployment. A mismatch is a gap to resolve, not permission to silently replace the requirement with the implementation. The daily guide is navigation derived from these sources.

## Historical: preserved in place

[Foundation plan](foundation-plan.md), [UI review plan](ui-review-plan.md), [website plan](web-plan.md) and [research handoff](design-research-handoff.md) preserve earlier context, proposed work and evidence. Their original instructions and status claims apply to that snapshot. They are not today's backlog or delivery authorization.

The foundation PRD also retains historical baseline observations (§0), the rollout (§11), resolved owner questions (§13) and the issue checklist (§14). Headings and links stay stable.

## Updating the docs

- Change requirements through a recorded decision in foundation PRD §8 and a concise rationale in `decisions.md`. Preserve IDs and explain supersession rather than deleting history.
- Update the relevant spec and the derived daily guide when active rules change. Keep detail in topic specs, not in another large summary.
- Update component usage when shipped APIs change; regenerate `api.json` with `pnpm gen:api`. Never document planned parameters as available.
- Keep historical plans labelled in place. Do not move files or renumber headings to reorganize navigation.
- Use [AGENTS.md](../AGENTS.md) for checks, captures, mirrors and release-note workflow. A documentation update grants no merge or deployment authorization.
