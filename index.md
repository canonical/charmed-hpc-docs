# Charmed HPC

Charmed HPC is a platform for managing high-performance computing clusters. It automates the lifecycle of essential cluster software and processes, such as workload management, shared storage, GPU access, and high-bandwidth networking. This allows operations teams and systems administrators to focus on running workloads rather than maintaining infrastructure.

---

## In this documentation

### Getting started

::::{domain}
:::{slice} Tutorial
{doc}`Getting started with Charmed HPC <getting-started>`
:::

:::{slice} Installation
{doc}`Initialize cloud environment <howto/initialize-cloud-environment>`
{doc}`Deploy Slurm <howto/deploy/deploy-slurm>`
{doc}`Deploy a shared filesystem <howto/deploy/deploy-shared-filesystem>`
:::
::::

### Hardware and architecture

::::{domain}
:::{slice} Hardware
{doc}`GPUs <explanation/gpus>`
{doc}`GPU resource scheduling <reference/gpus>`
{doc}`Interconnects <explanation/interconnects>`
{doc}`Public cloud interconnects <reference/interconnects>`
:::

:::{slice} Architecture and foundations
{doc}`Underlying projects and dependencies <reference/underlying-projects-and-dependencies>`
:::
::::

### Purpose-built capabilities

::::{domain}
:::{slice} Running workloads
{doc}`Integrate with Apptainer <howto/integrate/integrate-with-apptainer>`
{doc}`Use Apptainer <howto/run-workloads/use-apptainer>`
:::

:::{slice} Configuration and tuning
{doc}`Manage compute nodes and partitions <howto/manage/manage-compute-nodes>`
:::

:::{slice} Observability and monitoring
{doc}`Integrate with COS <howto/integrate/integrate-with-cos>`
{doc}`Integrate with InfluxDB <howto/integrate/integrate-with-influxdb>`
{doc}`Integrate with a mail server <howto/integrate/integrate-with-email>`
{doc}`Email notifications for jobs <explanation/job-email-notifications>`
{doc}`Grafana dashboards <reference/monitoring/grafana-dashboards>`
{doc}`Prometheus alerts <reference/monitoring/prometheus-alerts>`
{doc}`Prometheus metrics <reference/monitoring/prometheus-metrics>`
{doc}`Loki logs <reference/monitoring/loki-logs>`
:::

:::{slice} Reliability and availability
{doc}`High availability <explanation/high-availability>`
{doc}`Migrate Slurm controller to high availability <howto/manage/migrate-slurmctld-to-high-availability>`
{doc}`Instance auto-reboots <explanation/reboot-timing>`
:::
::::

### Performance, identity, and security

::::{domain}
:::{slice} Performance
{doc}`Benchmark results <reference/performance>` slice
:::

:::{slice} Identity and access
{doc}`Deploy an identity provider <howto/deploy/deploy-identity-provider>`
:::

:::{slice} Security and cryptography
{doc}`Security hardening guidelines <reference/hardening>`
{doc}`Cryptography and authentication <explanation/cryptography>`
{doc}`Key rotation <explanation/key-rotation>`
{doc}`Rotate authentication keys <howto/manage/rotate-authentication-keys>`
:::
::::

### Lifecycle

::::{domain}
:::{slice} Decommission and clean up
{doc}`Clean up Slurm <howto/cleanup/cleanup-slurm>`
{doc}`Clean up cloud resources <howto/cleanup/cleanup-cloud-resources>`
:::
::::

### Reference and community

::::{domain}
:::{slice} Reference
{doc}`Glossary <reference/glossary>`
:::

:::{slice} Contribute
{doc}`Contributing to documentation <contributing/documentation>`
{doc}`Contributing to code <contributing/code>`
:::
::::

## How this documentation is organized

This documentation uses the [Diátaxis](https://diataxis.fr/) documentation structure.

* The [Tutorial](tutorial-getting-started-with-charmed-hpc) takes you step-by-step through building a small Charmed HPC cluster, submitting batch jobs, and using container images.

* [How-to guides](howto/index) assume you have basic familiarity with Charmed HPC. They cover key operations for [deploy](howto/deploy/index.md), [integration](howto/integrate/index.md), [management](howto/manage/index.md), and [usage](howto/run-workloads/index.md).

* [Reference](reference/index) provides technical information such as [underlying projects and dependencies](reference/underlying-projects-and-dependencies.md), [monitoring](reference/monitoring/index.md), and [performance benchmarks](reference/performance.md).

* [Explanation](explanation/index) includes topic overviews, background and context, and detailed discussions of key concepts.
---

## Project and community

Charmed HPC is an Ubuntu community project. It's an open source project that warmly welcomes community contributions, suggestions, fixes, and constructive feedback.

**Get involved**

* [Support](https://discourse.ubuntu.com/c/project/hpc/151)
* [Online chat](https://matrix.to/#/#hpc:ubuntu.com)
* [Contribute](contributing/index)

<!-- **Releases**

* [Release notes](https://discourse.ubuntu.com/c/hpc/151)
* [Roadmap](https://github.com/orgs/canonical/projects) -->

**Governance and policies**

* [Code of Conduct](https://ubuntu.com/community/ethos/code-of-conduct)
<!-- * [Commercial support](https://ubuntu.com/pro) -->

Thinking about using Charmed HPC for your next project? [Get in touch!](https://matrix.to/#/#hpc:ubuntu.com)

```{filtered-toctree}
:hidden:
:titlesonly:

Getting started <getting-started>
howto/index
explanation/index
reference/index
contributing/index
```
