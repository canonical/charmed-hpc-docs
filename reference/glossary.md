(reference-glossary)=
# Glossary

```{glossary}

Amazon Web Services (AWS)
    A cloud platform provided by Amazon.

    Resources: [AWS website {octicon}`link-external`](https://aws.amazon.com/)

Apptainer
    HPC-focused container runtime. Formerly Singularity.

    Resources: [Apptainer - Portable, Reproducible Containers {octicon}`link-external`](https://apptainer.org/), [apptainer charm {octicon}`link-external`](https://charmhub.io/apptainer)

Canonical Observability Stack (COS)
    Suite of charms providing open-source monitoring and logging tools.

    Resources: [Canonical observability documentation {octicon}`link-external`](https://documentation.ubuntu.com/observability)

Ceph
    Distributed storage system that provides object, block, and file storage. Can be deployed and
    managed using {term}`MicroCeph`.

    Resources: [Ceph website {octicon}`link-external`](https://ceph.io)

CephFS
    POSIX-compliant file system interface that runs on top of a Ceph storage cluster.

    Resources: [Ceph file system {octicon}`link-external`](https://docs.ceph.com/en/latest/cephfs/), [ceph-fs charm {octicon}`link-external`](https://charmhub.io/ceph-fs)

Charm
    Python software for automating the lifecycle of applications. Also known as a charmed operator.
    Managed with Juju. Two kinds of charm exist:

    1. **Machine charms:** charms made to deploy on a bare-metal server, virtual machine, or system
    container
    2. **Kubernetes charms:** charms built to deploy on Kubernetes.

    Resources: [Juju charm definition {octicon}`link-external`](https://documentation.ubuntu.com/juju/latest/reference/charm/)

Cluster
    A collection of distinct computers, known as nodes, networked together to act as a single, more
    powerful system.

`filesystem-client`
    A charm that requests and mounts exported filesystems on virtual machines.

    Resources: [filesystem-client charm {octicon}`link-external`](https://charmhub.io/filesystem-client)

Graphics Processing Unit (GPU)
    A specialized processor that is designed to accelerate image processing and graphics rendering
    for output to a display device.

Grafana
    An open-source platform for data visualization, monitoring, and observability. Used to create
    dashboards and graphs from time series data stored in various data sources.

    Resources: [Grafana website {octicon}`link-external`](https://grafana.com/), [Grafana documentation {octicon}`link-external`](https://grafana.com/docs/), [Grafana charm {octicon}`link-external`](https://charmhub.io/grafana-k8s)

High-Performance Computing (HPC)
    The practice of aggregating computing power using clusters and parallel processing to complete
    tasks faster than standard computing.

InfluxDB
    An open-source, distributed, time series database.

    Resources: [InfluxData site {octicon}`link-external`](https://www.influxdata.com/), [influxdb charm {octicon}`link-external`](https://charmhub.io/influxdb)

Integration
    An exchange of data between two charms that allows for interoperability. Formerly known as a
    relation.

    Resources: [Juju integrations explained {octicon}`link-external`](https://canonical.com/juju/integrations)

Job
    A user-submitted workload managed by the cluster workload manager. Consists of a script
    containing the executable commands to run an application and declarations of the resources
    required for that application, such as CPU core count and walltime.

Juju
    A charmed operator tool that helps deploy, integrate and manage applications across multiple
    environments.

    Resources: [Juju documentation {octicon}`link-external`](https://documentation.ubuntu.com/juju/latest/)

Loki
    An open-source log aggregation system designed to store and query logs from applications and
    infrastructure. Designed to be cost-effective and easy to operate.

    Resources: [Grafana Loki website {octicon}`link-external`](https://grafana.com/oss/loki/), [Loki documentation {octicon}`link-external`](https://grafana.com/docs/loki/latest/), [Loki charm {octicon}`link-external`](https://charmhub.io/loki-k8s)

MicroCeph
    A tool that simplifies deployment and management of Ceph storage both standalone and in a
    charmed environment using Juju.

    Resources: [MicroCeph documentation {octicon}`link-external`](https://canonical-microceph.readthedocs-hosted.com/stable/), [microceph charm {octicon}`link-external`](https://charmhub.io/microceph)

Microsoft Azure
    A cloud platform provided by Microsoft.

    Resources: [Microsoft Azure website {octicon}`link-external`](https://azure.microsoft.com/)

MySQL
    An open source relational database management system (RDBMS) that uses Structured Query Language
    (SQL) for defining, manipulating, and querying data.

    Resources: [MySQL website {octicon}`link-external`](https://www.mysql.com), [MySQL charm {octicon}`link-external`](https://charmhub.io/mysql)

OpenTelemetry Collector
    A vendor-agnostic implementation for receiving, processing, and exporting telemetry data. Removes
    the need to run, operate, and maintain multiple agents/collectors to support open-source telemetry
    data formats (e.g. Jaeger, Prometheus) to multiple open-source or commercial back-ends.

    Resources: [OpenTelemetry Collector documentation {octicon}`link-external`](https://opentelemetry.io/docs/collector/), [OpenTelemetry Collector GitHub {octicon}`link-external`](https://github.com/open-telemetry/opentelemetry-collector), [opentelemetry-collector charm {octicon}`link-external`](https://charmhub.io/opentelemetry-collector)

Proxy charm
    An intermediary charm that enables charms to integrate with non-charmed applications. Also known
    as an integrator charm.

Prometheus
    An open-source monitoring and alerting system that collects and stores metrics as time series
    data. Features a flexible query language (PromQL) and built-in alerting capabilities.

    Resources: [Prometheus website {octicon}`link-external`](https://prometheus.io/), [Prometheus documentation {octicon}`link-external`](https://prometheus.io/docs/), [Prometheus charm {octicon}`link-external`](https://charmhub.io/prometheus-k8s)

`sackd`
    Slurm Auth and Credential Kiosk daemon. Typically used to provide cluster login nodes.

    Resources: [Slurm Workload Manager - sackd {octicon}`link-external`](https://slurm.schedmd.com/sackd.html), [sackd charm {octicon}`link-external`](https://charmhub.io/sackd)

`scontrol`
    Slurm administrative command-line tool for viewing and modifying cluster configuration and state.
    Used to manage jobs, nodes, partitions, reservations, and other cluster resources. Provides
    real-time control and monitoring capabilities for Slurm administrators.

    Resources: [Slurm Workload Manager - scontrol {octicon}`link-external`](https://slurm.schedmd.com/scontrol.html)

Slurm
    A free and open source workload manager consisting of multiple co-operating software components,
    each responsible for a piece of cluster functionality.

    Resources: [Slurm Workload Manager - Documentation {octicon}`link-external`](https://slurm.schedmd.com/documentation.html)

Slurm charms
    A set of {term}`charmed operators <Charm>` that deploy and manage {term}`Slurm`.

    Resources: [Slurm charms repository {octicon}`link-external`](https://github.com/canonical/slurm-charms)

`slurmctld`
    Slurm central management/controller daemon. Schedules jobs and monitors other components.

    Resources: [Slurm Workload Manager - slurmctld {octicon}`link-external`](https://slurm.schedmd.com/slurmctld.html), [slurmctld charm {octicon}`link-external`](https://charmhub.io/slurmctld)

`slurmd`
    Slurm compute node daemon. Executes jobs scheduled by the controller.

    Resources: [Slurm Workload Manager - slurmd {octicon}`link-external`](https://slurm.schedmd.com/slurmd.html), [slurmd charm {octicon}`link-external`](https://charmhub.io/slurmd)

`slurmdbd`
    Slurm accounting database daemon. Provides an interface between Slurm and a database for holding
    historic job statistics.

    Resources: [Slurm Workload Manager - slurmdbd {octicon}`link-external`](https://slurm.schedmd.com/slurmdbd.html), [slurmdbd charm {octicon}`link-external`](https://charmhub.io/slurmdbd)

`slurmrestd`
    REST API interface for Slurm.

    Resources: [Slurm Workload Manager - slurmrestd {octicon}`link-external`](https://slurm.schedmd.com/slurmrestd.html), [slurmrestd charm {octicon}`link-external`](https://charmhub.io/slurmrestd)


`slurmutils`
    Python library for facilitating edits to Slurm configuration files.

    Resources: [slurmutils GitHub {octicon}`link-external`](https://github.com/canonical/slurmutils)

System Security Services Daemon (`sssd`)
    A daemon that manages the retrieval and caching of user credentials and attributes from remote
    identity providers.

    Refers to both the software and the corresponding charm.

    Resources: [SSSD - System Security Services Daemon - sssd.io {octicon}`link-external`](https://sssd.io), [sssd charm {octicon}`link-external`](https://charmhub.io/sssd)

Walltime
    The maximum duration of a job declared in the job script. Serves as a limit after which the
    workload manager will forcibly end the job.

Workload manager
    Software responsible for accepting user jobs, placing them in a queue, and deciding where and
    when they will run on a cluster - the process known as: job scheduling. Optimizes utilization
    of a cluster by matching job requirements (CPU core count, walltime) to available hardware
    while enforcing site-specific usage policies. Slurm is a workload manager.
```
