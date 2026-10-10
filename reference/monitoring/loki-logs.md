---
myst:
  html_meta:
    description: Reference page for the Loki log queries for Charmed HPC charms, including slurmctld, slurmd, slurmdbd, MySQL, and GLAuth, and how to exclude unwanted log files.
---
(reference-monitoring-loki-logs)=
# Loki logs

The following table lists all the charms used as part of Charmed HPC that expose logs to Loki, and the
corresponding query to see the exported logs in Grafana.
Follow the [Visualize log data](https://grafana.com/docs/loki/latest/visualize/grafana/#grafana-explore)
tutorial from the Grafana documentation for instructions on where and how to query for Loki logs.

For the on-disk location of these logs, and for services that do not export to Loki, see
{ref}`reference-log-locations`.

:::{csv-table}
:header: >
: charm, query

<!-- TODO: track https://github.com/canonical/grafana-agent-operator/issues/46 to use juju labels instead of filenames -->
slurmctld, `{juju_charm="opentelemetry-collector"} | filename =~ ".*/var/log/slurm/slurmctld.*"`{l=shell}
slurmd, `{juju_charm="opentelemetry-collector"} | filename =~ ".*/var/log/slurm/slurmd.*"`{l=shell}
slurmdbd, `{juju_charm="opentelemetry-collector"} | filename =~ ".*/var/log/slurm/slurmdbd.*"`{l=shell}
mysql, `{juju_charm="opentelemetry-collector"} | filename =~ ".*/var/log/mysql/.*"`{l=shell}
postgresql-k8s, `{juju_charm="postgresql-k8s"}`{l=shell}

<!-- TODO: enable when traefik exposes logs to Loki (https://github.com/canonical/traefik-k8s-operator/pull/363) -->
<!-- traefik-k8s, `{juju_charm="traefik-k8s"}`{l=shell} -->

<!-- TODO: change to `juju_charm` when https://github.com/canonical/loki-k8s-operator/issues/466 gets fixed. -->
glauth-k8s, `{charm="glauth-k8s"}`{l=shell}
:::

## Ignoring log files

By default, every instance of the `opentelemetry-collector` charm will log all the files in the `/var/log` directory.
This is sometimes not ideal, since it increases the amount of logs stored by Loki which are unrelated
to the running application. A solution for this is to set the `path_exclude` configuration for
`opentelemetry-collector`, which will allow it to ignore such log files:

:::{code-block} shell
juju config opentelemetry-collector path_exclude="/var/log/{unattended-upgrades,apt,}/*.log"
:::
