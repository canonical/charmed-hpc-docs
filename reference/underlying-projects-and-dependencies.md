(reference-underlying-projects-and-dependencies)=
# Underlying projects and dependencies

Charmed HPC is a modular composition of underlying projects and dependencies. The tables below list the
projects, charms, integrations, libraries, packages, and deployment plans that drive and manage the
operations of a Charmed HPC cluster.

(reference-projects)=
## Projects

The underlying projects that compose Charmed HPC can be divided into three categories.

### Core

Core projects are projects that are maintained directly as part of Charmed HPC.

:::{csv-table}
:header: >
: project, source code, bug report
:widths: 15, 10, 10

slurm-charms, [Source](https://github.com/canonical/slurm-charms), [Issue tracker](https://github.com/canonical/slurm-charms/issues)
filesystem-charms, [Source](https://github.com/canonical/filesystem-charms), [Issue tracker](https://github.com/canonical/filesystem-charms/issues)
sssd-operator, [Source](https://github.com/canonical/sssd-operator), [Issue tracker](https://github.com/canonical/sssd-operator/issues)
apptainer-operator, [Source](https://github.com/canonical/apptainer-operator), [Issue tracker](https://github.com/canonical/apptainer-operator/issues)
slurmutils, [Source](https://github.com/canonical/slurmutils), [Issue tracker](https://github.com/canonical/slurmutils/issues)
charmed-hpc-libs, [Source](https://github.com/canonical/charmed-hpc-libs), [Issue tracker](https://github.com/canonical/charmed-hpc-libs/issues)
charmed-hpc-terraform, [Source](https://github.com/canonical/charmed-hpc-terraform), [Issue tracker](https://github.com/canonical/charmed-hpc-terraform/issues)
:::

### Dependencies

Dependency projects are projects that are required for Charmed HPC to operate successfully, but
are not maintained directly as part of Charmed HPC.

:::{csv-table}
:header: >
: project, source code, bug report
:widths: 15, 10, 10

juju, [Source](https://github.com/juju/juju), [Issue tracker](https://github.com/juju/juju/issues)
mysql, [Source](https://github.com/canonical/mysql-operators), [Issue tracker](https://github.com/canonical/mysql-operators/issues)
mysql-router, [Source](https://github.com/canonical/mysql-router-operator), [Issue tracker](https://github.com/canonical/mysql-router-operator/issues)
traefik-k8s, [Source](https://github.com/canonical/traefik-k8s-operator), [Issue tracker](https://github.com/canonical/traefik-k8s-operator/issues)
glauth-k8s, [Source](https://github.com/canonical/glauth-k8s-operator), [Issue tracker](https://github.com/canonical/glauth-k8s-operator/issues)
postgresql-k8s, [Source](https://github.com/canonical/postgresql-k8s-operator), [Issue tracker](https://github.com/canonical/postgresql-k8s-operator/issues)
:::

### Optional dependencies

Optional dependency projects are projects that are not required for Charmed HPC to operate successfully, but
can enhance the operations of a Charmed HPC cluster. Like dependency projects, optional dependency projects
are not maintained directly as part of Charmed HPC.

:::{csv-table}
:header: >
: project, source code, bug report
:widths: 15, 10, 10

opentelemetry-collector, [Source](https://github.com/canonical/opentelemetry-collector-operator), [Issue tracker](https://github.com/canonical/opentelemetry-collector-operator/issues)
grafana-k8s, [Source](https://github.com/canonical/grafana-k8s-operator), [Issue tracker](https://github.com/canonical/grafana-k8s-operator/issues)
prometheus-k8s, [Source](https://github.com/canonical/prometheus-k8s-operator), [Issue tracker](https://github.com/canonical/prometheus-k8s-operator/issues)
alertmanager-k8s, [Source](https://github.com/canonical/alertmanager-k8s-operator), [Issue tracker](https://github.com/canonical/alertmanager-k8s-operator/issues)
loki-k8s, [Source](https://github.com/canonical/loki-k8s-operator), [Issue tracker](https://github.com/canonical/loki-k8s-operator/issues)
catalogue-k8s, [Source](https://github.com/canonical/catalogue-k8s-operator), [Issue tracker](https://github.com/canonical/catalogue-k8s-operator/issues)
influxdb, [Source](https://code.launchpad.net/influxdb-charm), [Issue tracker](https://bugs.launchpad.net/influxdb-charm)
:::

(reference-charms)=
## Charms

Charmed HPC is composed of both Machine and Kubernetes charms.

Several of the charms include configuration options that are useful for customizing Charmed HPC deployments. These
charms can also include actions that are useful for running common lifecycle operations on a deployed Charmed
HPC cluster.

:::{admonition} Blank cells
:class: note

A charm does not have any modifiable configuration options or runnable actions if a table cell below is blank.
:::

### Machine charms

:::{csv-table}
:header: >
: charm, configuration options, actions
:widths: 15, 10, 10

[sackd](https://charmhub.io/sackd)
[slurmctld](https://charmhub.io/slurmctld), [Options](https://charmhub.io/slurmctld/configurations), [Actions](https://charmhub.io/slurmctld/actions)
[slurmd](https://charmhub.io/slurmd), [Options](https://charmhub.io/slurmd/configurations), [Actions](https://charmhub.io/slurmd/actions)
[slurmdbd](https://charmhub.io/slurmdbd)
[slurmrestd](https://charmhub.io/slurmrestd)
[filesystem-client](https://charmhub.io/filesystem-client), [Options](https://charmhub.io/filesystem-client/configurations)
[nfs-server-proxy](https://charmhub.io/nfs-server-proxy), [Options](https://charmhub.io/nfs-server-proxy/configurations)
[cephfs-server-proxy](https://charmhub.io/cephfs-server-proxy), [Options](https://charmhub.io/cephfs-server-proxy/configurations)
[sssd](https://charmhub.io/sssd)
[apptainer](https://charmhub.io/apptainer), , [Actions](https://charmhub.io/apptainer/actions)
[opentelemetry-collector](https://charmhub.io/opentelemetry-collector), [Options](https://charmhub.io/opentelemetry-collector/configurations), [Actions](https://charmhub.io/opentelemetry-collector/actions)
[mysql](https://charmhub.io/mysql), [Options](https://charmhub.io/mysql/configurations), [Actions](https://charmhub.io/mysql/actions)
[mysql-router](https://charmhub.io/mysql-router), [Options](https://charmhub.io/mysql-router/configurations), [Actions](https://charmhub.io/mysql-router/actions)
[influxdb](https://charmhub.io/influxdb), [Options](https://charmhub.io/influxdb/configurations), [Actions](https://charmhub.io/influxdb/actions)
:::

### Kubernetes charms

:::{csv-table}
:header: >
: charm, configuration options, actions
:widths: 15, 10, 10

[glauth-k8s](https://charmhub.io/glauth-k8s), [Options](https://charmhub.io/glauth-k8s/configurations)
[postgresql-k8s](https://charmhub.io/postgresql-k8s), [Options](https://charmhub.io/postgresql-k8s/configurations), [Actions](https://charmhub.io/postgresql-k8s/actions)
[traefik-k8s](https://charmhub.io/traefik-k8s), [Options](https://charmhub.io/traefik-k8s/configurations), [Actions](https://charmhub.io/traefik-k8s/actions)
[grafana-k8s](https://charmhub.io/grafana-k8s), [Options](https://charmhub.io/grafana-k8s/configurations), [Actions](https://charmhub.io/grafana-k8s/actions)
[prometheus-k8s](https://charmhub.io/prometheus-k8s), [Options](https://charmhub.io/prometheus-k8s/configurations), [Actions](https://charmhub.io/prometheus-k8s/actions)
[alertmanager-k8s](https://charmhub.io/alertmanager-k8s), [Options](https://charmhub.io/alertmanager-k8s/configurations), [Actions](https://charmhub.io/alertmanager-k8s/actions)
[loki-k8s](https://charmhub.io/loki-k8s), [Options](https://charmhub.io/loki-k8s/configurations)
[catalogue-k8s](https://charmhub.io/catalogue-k8s), [Options](https://charmhub.io/catalogue-k8s/configurations), [Actions](https://charmhub.io/catalogue-k8s/actions)
:::

## Integrations

Charmed HPC uses integrations to dictate how charmed applications communicate with each other.

:::{csv-table}
:header: >
: integration, interface implementation
:widths: 15, 10

sackd, [Implementation](https://github.com/canonical/slurm-charms/blob/main/internal/sackd-interface/README.md)
slurmctld, [Implementation](https://github.com/canonical/slurm-charms/blob/main/pkg/slurmctld-interface/README.md)
slurmd, [Implementation](https://github.com/canonical/slurm-charms/blob/main/internal/slurmd-interface/README.md)
slurmdbd, [Implementation](https://github.com/canonical/slurm-charms/blob/main/internal/slurmdbd-interface/README.md)
slurmrestd, [Implementation](https://github.com/canonical/slurm-charms/blob/main/internal/slurmrestd-interface/README.md)
slurm-oci-runtime, [Implementation](https://github.com/canonical/slurm-charms/blob/main/pkg/slurm-oci-runtime-interface/README.md)
cos_agent, [Implementation](https://charmhub.io/grafana-agent/libraries/cos_agent)
ldap, [Implementation](https://charmhub.io/glauth-k8s/libraries/ldap)
mysql_client, [Implementation](https://charmhub.io/data-platform-libs/libraries/data_interfaces)
filesystem_info, [Implementation](https://charmhub.io/filesystem-client/libraries/filesystem_info)
mount_info, [Implementation](https://charmhub.io/filesystem-client/libraries/mount_info)
:::
