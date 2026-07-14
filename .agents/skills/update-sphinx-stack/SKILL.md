---
name: update-sphinx-stack
description: 'Update the Charmed HPC documentation project to a new version of the Canonical Sphinx Stack. Use when updating sphinx-stack, starter pack, conf.py, Makefile, _dev directory, or documentation build tooling for Charmed HPC docs.'
argument-hint: 'Leave blank to update the current docs project, or provide the path to the docs directory.'
---

# Update the Sphinx Stack for Charmed HPC

Updates the Charmed HPC documentation project from an older version of the Canonical Sphinx Stack to the latest version.

## Project context

- **Project name**: Charmed HPC
- **Repository**: `charmed-hpc/docs`
- **Docs URL**: `https://ubuntu.com/hpc/docs/`
- **Current config source**: `conf.py` is the active configuration. During updates, rename it to `conf.py.tmp` before copying the new Sphinx Stack template over, then merge customizations from `conf.py.tmp` into the new `conf.py`.
- **Project-specific workflow**: `.github/workflows/pr.yaml` (commitlint checks) — preserve
- **Docs location**: Repository root (not a `docs/` subdirectory)

## Process

### 1. Verify the current state

- Check `_dev/version` to determine the current Sphinx Stack version.
- Confirm that `conf.py` contains `canonical_sphinx` in its `extensions` list.
- Identify any project-specific customizations in `conf.py`, `Makefile`, `.readthedocs.yaml`, and `.github/workflows/`.

**Pre-update audit:** Before starting, check that `conf.py` doesn't contain new or updated customizations that haven't been wrapped in custom blocks. 

Compare against the Sphinx Stack template to find new differences:
 ```bash
 diff /path/to/sphinx-stack/docs/conf.py conf.py
 ```

If any new customizations are found (differences in conf.py that are not in /path/to/sphinx-stack/docs/conf.py), wrap them in `# === CHARMED HPC CUSTOM ===` / `# === END CUSTOM ===` blocks before proceeding.

### 2. Backup existing files

Rename the following files to avoid overwriting:
- `conf.py` → `conf.py.tmp`
- `Makefile` → `Makefile.tmp`
- `.readthedocs.yaml` → `.readthedocs.yaml.tmp`

### 3. Update `conf.py`

Copy the new `conf.py` from the Sphinx Stack and merge project-specific customizations from `conf.py.tmp` (the renamed active config):

**Ensure all custom blocks are carried forward into the new `conf.py`.** Look for blocks wrapped with:
```python
# === CHARMED HPC CUSTOM ===
# ... custom values ...
# === END CUSTOM ===
```

Copy each custom block into the corresponding section of the new `conf.py`. Flag any sections that appear to be customizations that are not in custom blocks for the user to review. 

### 4. Update `Makefile`

Copy the new `Makefile` from the Sphinx Stack. Confirm there are no customizations in Makefile.tmp that need to be merged. 

### 5. Update `.readthedocs.yaml`

Copy the new `.readthedocs.yaml` from the Sphinx Stack. **Important**: the Sphinx Stack defaults assume docs live in a `docs/` subdirectory. Charmed HPC docs are at the repo root, so adjust:
- `sphinx.configuration: docs/conf.py` → `conf.py`
- `python.install.requirements: docs/requirements.txt` → `requirements.txt`
- `git diff` path: `'docs/'` → `'./'`

Preserve project-specific settings:
- `build.os: ubuntu-22.04`
- `build.tools.python: "3.11"`
- `sphinx.builder: dirhtml`
- `sphinx.fail_on_warning: true`
- `formats: [pdf]`
- PR cancellation logic with exit 183

### 6. Update the `_dev` directory

The `_dev/` directory contains internal tooling files not intended to be modified by users.

- Copy the `_dev/` directory from the Sphinx Stack.
- Ensure custom templates live in a project-level `_templates/` directory (not inside `_dev/`):
  - `header.html` — Google Tag Manager (`GTM-KNX3CJC`), Canonical logo, resource dropdown
  - `footer.html` — Sequential navigation, copyright, contributor listing overlay, cookie revoke link
- Ensure `templates_path` in `conf.py` points to `["_templates"]`.

**Why outside `_dev/`:** Custom templates and static assets must live at the project root (`_templates/` and `_static/`). The Sphinx Stack never touches these directories during updates, so they survive automatically. Never place custom templates inside `_dev/`.

### 7. Review `requirements.txt`

Compare with the Sphinx Stack's `requirements.txt`. The Charmed HPC project has custom extensions and dependencies that must be preserved, with the block indicated by `# Project-specific dependencies` / `# End project-specfic dependencies`.

### 8. Review `.github/workflows/`

The official guide calls out four workflow types to review:
- **Automatic doc checks** (`automatic-doc-checks.yml`): Replace with the Sphinx Stack version if updated. Adjust `paths` filter for repo-root docs (`'./**'` instead of `'docs/**'`).
- **CLA check** (`cla-check.yml`): Add from Sphinx Stack if not present.
- **Check for removed URLs** (`check-removed-urls.yml`): Add from Sphinx Stack if not present.
- **Markdown style check** (`markdown-style-checks.yml`): Add from Sphinx Stack if using Markdown docs.

**Preserve project-specific workflows**:
- `.github/workflows/pr.yaml` — commitlint checks for conventional commits. This is not part of the Sphinx Stack and must be kept.

**Remove obsolete Sphinx Stack workflows** (if present):
- `.github/workflows/sphinx-python-dependency-build-checks.yml`
- `.github/workflows/test-sphinx-stack.yml`

These were part of older Sphinx Stack versions and are no longer maintained.

### 9. Review `.gitignore`

Update `.sphinx/` references to `_dev/` and add `.venv/` (the new virtual environment location):
```
.venv/
_dev/warnings.txt
_dev/.wordlist.dic
_dev/.doctrees/
_dev/node_modules/
_dev/styles/*
_dev/vale.ini
```

### 10. Preserve custom GitHub skills

The Charmed HPC project has custom agent skills in `.github/skills/` that are not part of the Sphinx Stack. Always preserve this folder. 

### 11. Clean up obsolete files

Delete files that are no longer part of the Sphinx Stack:
- `conf.py.tmp`, `Makefile.tmp`, `.readthedocs.yaml.tmp` (after verification)

**Note**: `.github/pull_request_template.md` and `.github/CODEOWNERS` are listed as obsolete in the official guide, but the Charmed HPC project maintains custom versions of these files. **Keep them** unless explicitly deprecating them.

**Keep `.tmp` files until the build passes.** If something breaks, diff against them:
```bash
diff conf.py.tmp conf.py          # see what customizations were applied
diff -u Makefile.tmp Makefile     # compare Makefile changes
```

Delete `.tmp` files only after all checks pass.

### 12. Build and test

**Run these commands locally to verify the update:**

Clean cached files and rebuild:
```bash
make clean
make run
```

Run documentation checks to ensure CI will pass:
```bash
make spelling
make linkcheck
make woke
make lint-md
```

Fix any errors reported. Common causes of build errors:
- Incorrect file locations or paths
- Incompatible requirements
- Missing customizations
- Cached build files (use `make clean`)

**After the build succeeds, verify custom features render correctly:**
- Custom header/footer templates show Canonical branding
- Google Tag Manager (`GTM-KNX3CJC`) loads
- Cookie banner and link overwrite JS function correctly
- Contributor listing displays on pages
- Redirects work (old `howto/setup/` and `howto/use/` paths)
- Social links (Discourse, Matrix, GitHub) and feedback buttons work
- Open Graph meta tags show correct Charmed HPC branding

A successful build does not guarantee custom features work — these require manual verification in the built output.

## Decisions

- **Source of truth for config**: `conf.py` is the active configuration. Rename it to `conf.py.tmp` before copying the new Sphinx Stack template, then merge customizations from `conf.py.tmp` into the new `conf.py` and delete `conf.py.tmp`.
- **Custom block markers**: Use `# === CHARMED HPC CUSTOM ===` / `# === END CUSTOM ===` comment blocks in `conf.py` to wrap all project-specific values. This makes them trivial to spot during diffs and ensures nothing is lost during merges.
- **Custom skills**: Always preserve `.github/skills/` — they are project-specific.
- **Project-specific workflows**: Always preserve `.github/workflows/pr.yaml` and any other non-Sphinx-Stack workflows.
- **Project governance files**: Keep `.github/pull_request_template.md` and `.github/CODEOWNERS` as they are actively maintained for Charmed HPC.
- **Template location**: Custom templates live in project-level `_templates/`, not inside `_dev/`.
- **Venv location**: The venv moves from `.sphinx/venv` to `.venv`. Ensure `.gitignore` is updated.

## Constraints

- DO NOT modify files inside `_dev/` unless intentionally customizing Sphinx Stack internals.
- DO NOT delete `.github/pull_request_template.md` or `.github/CODEOWNERS` without confirming they are not actively used.
- DO verify the build after each major step (`conf.py`, `Makefile`, `_dev/` update) to isolate errors.
- DO ensure `html_static_path` and `templates_path` in `conf.py` point outside `_dev/`.
- DO preserve `conf.py.tmp` customizations — the new `conf.py` is an unconfigured template by default.