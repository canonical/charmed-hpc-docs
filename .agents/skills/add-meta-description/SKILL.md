---
name: add-meta-description
description: 'Add HTML meta descriptions to MyST Markdown documentation pages using front matter. Use when adding metadata, SEO descriptions, html_meta, myst front matter, or meta descriptions to a documentation page.'
argument-hint: 'Path to the Markdown file, or leave blank to use the current file.'
---

# Add Meta Description

Adds a well-crafted HTML meta description to a MyST Markdown documentation page via front matter.

## Process

1. **Read the file** — Read the current file to understand its content before making any edits. Always check the file first in case front matter already exists.
2. **Write the description** — Compose a meta description based on the page content following the guidelines below.
3. **Add the front matter** — Insert the front matter block at the very top of the file, before any existing content (including any label/anchor like `(reference-foo)=`).

## Content guidelines

- **Length**: Maximum 200 characters including spaces. Keep the most important information in the first 150 characters.
- **Language**: Simple and direct. Avoid unnecessary adverbs or adjectives.
- **Keywords**: Include the product name (Charmed HPC) and the page's focus keywords — the terms users are most likely to search for.
- **Summarise**: Where possible, summarise the page content concisely.
- **Calls to action**: Vary language — use "Discover", "Familiarise", "Read" as alternatives to "Learn how to".
- **No keyword stuffing**.

## Front matter format

```markdown
---
myst:
  html_meta:
    description: Your description of the page.
---
```

Place this block at the very top of the file. Do not use newlines within the `description` value.

## Constraints

- DO NOT modify any content below the front matter block.
- DO NOT add front matter if it already exists — update the existing `description` value instead.
- DO NOT exceed 200 characters in the description.
- ONLY add or update the `myst.html_meta.description` front matter key.
