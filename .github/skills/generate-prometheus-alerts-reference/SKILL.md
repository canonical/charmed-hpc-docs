---
name: generate-prometheus-alerts-reference
description: 'Generate a reference documentation page for the Prometheus alert rules used in Charmed HPC. Uses the GitHub MCP server to scan charm repositories for alert rule definitions and produces a MyST Markdown page listing all alerts with their severity and description.'
argument-hint: 'No arguments required. Run this skill to regenerate the Prometheus alerts reference page.'
---

# Generate Prometheus Alerts Reference

Scans the primary Charmed HPC charm repositories on GitHub for Prometheus alert rule files and generates a reference documentation page at `reference/monitoring/prometheus-alerts.md`.

## Repositories to scan

Use the GitHub MCP server tools (`mcp_github_get_file_contents`) to scan the following repositories for Prometheus alert rules:

1. `canonical/slurm-charms` — look inside each charm directory under `charms/*/src/cos/alert_rules/prometheus/`
2. `canonical/sssd-operator` — look under `src/cos/alert_rules/prometheus/`
3. `canonical/filesystem-charms` — look inside each charm directory under `charms/*/src/cos/alert_rules/prometheus/`
4. `canonical/apptainer-operator` — look under `src/cos/alert_rules/prometheus/`

Alert rule files use the `.rule` or `.rules` extension and are in YAML format.

Files with the `.rule` extension contain a single alert rule with the following structure:

```yaml
alert: AlertName
expr: <PromQL expression>
for: <duration>
labels:
  severity: <warning|critical>
annotations:
  summary: <short summary>
  description: >
    <detailed description>
```

Files with the `.rules` extension use the Prometheus rule group schema and may contain multiple alert rules:

```yaml
groups:
  - name: <group name>
    rules:
      - alert: AlertName
        expr: <PromQL expression>
        for: <duration>
        labels:
          severity: <warning|critical>
        annotations:
          summary: <short summary>
          description: >
            <detailed description>
```

## Process

1. **Scan repositories** — For each repository listed above, use the GitHub MCP server to list the contents of the Prometheus alert rules directories. For monorepos (`slurm-charms`, `filesystem-charms`), iterate over each charm subdirectory.

2. **Read alert rule files** — For each `.rule` or `.rules` file found, retrieve its content using the GitHub MCP server and extract:
   - `alert` — the alert name
   - `labels.severity` — the severity level (e.g. "warning", "critical")
   - `annotations.summary` or `annotations.description` — a human-readable description of when the alert fires

3. **Group alerts by charm** — Organise the collected alerts by the charm that provides them (e.g. `slurmctld`, `slurmd`, `sssd`).

4. **Generate the documentation page** — Write the file `reference/monitoring/prometheus-alerts.md` using the format specified below.

5. **Update the monitoring index** — Add the new page to the toctree in `reference/monitoring/index.md` and to the bullet list of pages.

## Output format

The generated page MUST follow this exact MyST Markdown structure:

```markdown
(reference-monitoring-prometheus-alerts)=
# Prometheus alerts

This page lists the Prometheus alert rules provided by Charmed HPC charms. These alerts
fire when specific conditions are met in your cluster and can be viewed in the Prometheus
or {term}`Grafana` web interface.

See {ref}`howto-manage-integrate-with-cos` for instructions on integrating with COS.

```{note}
The tables below provide the following information:

- **Alert**: the alert name as shown in the Prometheus dashboard.
- **Description**: a summary of when the alert is triggered.
- **Severity**: the alert severity (`warning` or `critical`).
```

## <Charm name>

:::{list-table}
:header-rows: 1

* - Alert
  - Description
  - Severity
* - `AlertName`
  - Description of when the alert fires.
  - warning
:::
```

Repeat the `## <Charm name>` section and table for each charm that has alert rules. Use the charm directory name as the section heading (e.g. "Slurmctld", "Slurmd"). Capitalise the first letter.

If a repository or charm has no alert rules, omit it from the output entirely — do NOT include empty sections.

## Updating the monitoring index

After generating the page, ensure `reference/monitoring/index.md` includes the new page:

1. Add a bullet point in the content list:
   ```markdown
   - {ref}`Prometheus alerts <reference-monitoring-prometheus-alerts>`
   ```

2. Add to the toctree:
   ```markdown
   Prometheus alerts <prometheus-alerts>
   ```

## Constraints

- ONLY use `mcp_github_get_file_contents` from the GitHub MCP server to retrieve repository contents. Do NOT clone repositories locally.
- DO NOT invent or fabricate alert rules. Only document alerts that actually exist in the repositories at the time of generation.
- DO NOT modify any other documentation pages except `reference/monitoring/prometheus-alerts.md` and `reference/monitoring/index.md`.
- If no alert rules are found in any repository, report this to the user instead of generating an empty page.
- Use MyST Markdown (`.md`), NOT reStructuredText (`.rst`).
- The page title MUST be "Prometheus alerts".
- The cross-reference label MUST be `(reference-monitoring-prometheus-alerts)=`.

