---
name: update-landing-pages
description: 'Update or create documentation landing pages (index.md). Use when updating, creating, or restructuring landing pages, index pages, toctrees, or page groupings in the documentation.'
argument-hint: 'Path to the landing page, or leave blank to update all landing pages.'
---

# Update Landing Pages

Updates directory-level `index.md` landing pages to follow a consistent structure and style.

## Process

1. **Read the landing page and its sibling content** — Understand the current structure of the `index.md` and read all content pages in the same directory (and subdirectorys).
2. **Assess whether changes are needed** — If the existing categories are functional and cover all relevant pages, do not restructure them. Only update descriptions, phrasing, or links as needed. Proceed to step 5.
3. **Assess content pages for break-up** — Before determining categories, decide which pages should be broken into individual section links on the landing page (see break-up rules below). The resulting individual section links are treated as distinct items for the purposes of categorisation.
4. **Determine categories** — Only if restructuring is necessary: group all items — whole pages and individual broken-out sections alike — by topic, technical domain, or function. Section links from a single page may be distributed across different categories if they belong to different logical groupings. For how-to pages, use action/verb titles (e.g. "Set up and deploy" not "Setup"). Avoid single-page categories unless the grouping is the best logical organisation. If a new page is being added, first check whether it fits an existing category before proposing restructuring. **Name categories to accommodate likely future content**, not just the current pages — choose titles that would still make sense if related pages were added later (e.g. "System architecture" rather than "Cluster components and architecture" to allow for architecture diagrams and descriptions). **Do not use a page's own title as its category heading** — if a category would contain only a glossary page, use a distinct label like "Terminology" instead of "Glossary".
5. **Write descriptions** — Follow the description guidelines below for the top-level page description and any category descriptions.
6. **Update `{ref}` links** — Use custom labels to control displayed text (see ref link rules below).
7. **Update the toctree** — Ensure toctree labels match the category headings where applicable.
8. **Verify** — Build docs locally and confirm all links resolve and navigation renders correctly.

## Landing page structure

Every directory-level landing page follows this structure:

```
# Page title

Top-level description mentioning Charmed HPC.

## Category heading (if multiple categories)

Optional category description.

- {ref}`Custom label <anchor>`
- {ref}`Custom label <anchor>`

## Another category heading

- {ref}`Custom label <anchor>`

:::{toctree}
:titlesonly:
:maxdepth: 1
:hidden:

Label <path>
:::
```

### Single-category pages

If a landing page has only one logical category (e.g. `reference/monitoring/index.md`), omit the category sub-heading. Use just the page header, a description, and the page list.

## Description guidelines

### Top-level page description

- **Must** mention Charmed HPC.
- Keep it concise — one or two sentences.
- Describe the scope of the section, not the pages within it. Do not simply list out the category names or page topics — some of those terms may appear naturally for context or framing, but the description should add meaning beyond what the headings alone convey.
- **Orient the reader** by signalling the [Diátaxis](https://diataxis.fr/) category the section belongs to. Each category has a distinct purpose and reader need:
  - **Tutorial** — Learning-oriented. The reader is acquiring skills through guided practice. Signal this with language like "step-by-step", "build", "hands-on", "from scratch".
  - **How-to guides** — Task-oriented. The reader has a specific goal and needs clear steps. Signal this with language like "detailed steps", "deploy", "configure", "manage", "run".
  - **Reference** — Information-oriented. The reader needs accurate technical facts to consult. Signal this with language like "technical descriptions", "specifications", "lists", "parameters".
  - **Explanation** — Understanding-oriented. The reader wants background, context, or design rationale. Signal this with language like "background context", "design decisions", "how it works", "concepts".

### Category descriptions

- Only add a category description if the category heading and page titles together do not convey enough information.
- Keep descriptions to 1–2 sentences.
- Provide useful insights and context about what the pages in the category cover — highlight possibilities or nuance that the titles alone don't reveal — without going into low-level technical detail.
- **Do not** relist or enumerate the pages below the description.
- **Do not** repeat "Charmed HPC" in every category description — the top-level description already establishes the context. Use "your cluster" or similar instead.
- **Do not** restate the Diátaxis category (e.g. do not say "these how-to guides" or "this reference material").

### Sub-landing page descriptions

- Sub-landing pages (e.g. `howto/deploy/index.md`) should have a **more detailed** description than the corresponding category blurb on the parent landing page.
- Avoid duplicating the exact same description on both the parent and sub-landing page.
- Provide broader context about what the pages collectively cover, without listing each individual page.

## Phrasing rules

- **Plain and factual**: Keep all descriptions straightforward and factual. Avoid assertive, promotional, or boastful language (e.g. do not use "authoritative", "comprehensive", "powerful", "seamlessly", "best-in-class", or similar).
- **No meta-referrals**: Do not use phrases like "in these guides", "on these pages", "see the how-to guides in this section for", "these how-to guides provide instructions for", or "the reference material in this section". Refer directly to the content or omit the referral.
- **How-to category titles**: Use action/verb form (e.g. "Set up and deploy", "Clean up resources", "Integrate with other tools", "Run workloads").

## `{ref}` link rules

- If a content page title includes "How to" (e.g. `# How to deploy Slurm`), use a custom label on the landing page that omits "How to": `{ref}`Deploy Slurm <howto-deploy-deploy-slurm>``
- **Do not** remove "How to" from the actual page title — only from the landing page reference.
- If a content page title does not include "How to", a bare `{ref}` (without custom label) is acceptable.
- If a page title is not descriptive enough in the landing page context (e.g. a title like "Performance" gives little information about the content), use a custom label that summarises the page's actual scope: `{ref}`Benchmark results on Microsoft Azure <reference-performance>``

## Break-up rules for long pages

Decide whether to list a page's internal sections as separate items on the landing page based on **content coupling**, not page length or section count.

### Break up: discrete independent sections

If a page's `##` (or `###`) sections are **discrete, independent processes** grouped by similarity — where each section can be consulted on its own — list them as individual items on the landing page.

- Each item links to a specific section anchor within the page.
- If the page lacks explicit anchors for those sections, add them (e.g. `(howto-manage-scale-partitions)=`).
- Break at `##` level by default. Use `###` level only when `##` sections themselves contain multiple discrete sub-tasks.
- Section links from a broken-up page do **not** all need to appear in the same category on the landing page. If sections from a single page belong to different logical groupings, distribute the links across the appropriate categories.

**Examples of discrete sections**: individual management tasks (rotate keys, scale partitions), independent security domains (Slurm hardening, OS hardening), separate reference listings (projects, charms, integrations).

### Do not break up: sequential steps

If a page's sections are **sequential steps in a single process** — where they must be followed in order — list the page as a single item on the landing page.

**Examples of sequential sections**: prerequisites → deploy → verify, prerequisites → create image → run workload, metrics → method → results.

## Toctree conventions

- Toctree entries for sub-index pages should use labels matching the sub-landing page header: `Set up and deploy <setup/index>`
- Toctree entries for content pages should use short titles without "How to": `Deploy Slurm <deploy-slurm>`
- Preserve `:titlesonly:`, `:maxdepth: 1`, and `:hidden:` directives.

## Constraints

- Do **not** modify the root `index.md` (site home page) — it has a different purpose and structure.
- Do **not** modify content pages beyond adding section anchors where needed for break-up links.
- Do **not** modify files in the `reuse/` directory — these are internal includes, not published pages.
