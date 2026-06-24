# Charmed HPC

Charmed HPC is a platform for managing high-performance computing clusters. It automates the lifecycle of essential cluster software and processes, such as workload management, shared storage, GPU access, and high-bandwidth networking. This allows operations teams and systems administrators to focus on running workloads rather than maintaining infrastructure.

---

## In this documentation

- __Learn more about Charmed HPC:__ [Getting Started tutorial](tutorial-getting-started-with-charmed-hpc), [Underlying projects](reference/underlying-projects-and-dependencies.md)
- __Workload management:__ [Deploy Slurm](howto/deploy/deploy-slurm.md), [Manage Slurm](howto/manage/manage-slurm.md), [Clean up Slurm](howto/cleanup/cleanup-slurm.md), [Grafana Dashboards](reference/monitoring/grafana-dashboards.md)
- __Storage and Resources:__ [Deploy shared filesystem](howto/deploy/deploy-shared-filesystem.md), [GPUs](explanation/gpus.md), [GRES](reference/gpus.md), [Interconnects](explanation/interconnects.md)
- __Security and Identity:__ [Deploy identity provider](howto/deploy/deploy-identity-provider.md), [Hardening guidelines](reference/hardening.md), [Cryptography](explanation/cryptography.md)
- __Performance:__ [High availability](explanation/high-availability.md), [Benchmarks](reference/performance.md)

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
