(reference)=
# Reference

Technical specifications and data for Charmed HPC, covering configurations, supported values, and cluster components.

## System architecture

- {ref}`reference-underlying-projects-and-dependencies`

## Hardware and networking

- {ref}`GPU resource scheduling in Slurm <gres>`
- {ref}`reference-interconnects`

## Monitoring

Dashboards, metrics, and log queries available when COS is integrated with a Charmed HPC cluster.

- {ref}`reference-monitoring-grafana-dashboards`
- {ref}`reference-monitoring-loki-logs`
- {ref}`reference-monitoring-prometheus-alerts`
- {ref}`reference-monitoring-prometheus-metrics`

## Troubleshooting

Where logs are located, how to read them, and how to control verbosity and retention when inspecting a cluster directly rather than through COS.

- {ref}`reference-log-locations`

## Performance

Reference data for evaluating and tuning the performance of a Charmed HPC cluster, including benchmarks and hardware-specific metrics.

- {ref}`Benchmark results on Microsoft Azure <reference-performance>`

```{filtered-toctree}
:titlesonly:
:maxdepth: 1
:hidden:

Underlying projects and dependencies <underlying-projects-and-dependencies>
gpus
interconnects
monitoring/index
logging
Performance <performance>

```
