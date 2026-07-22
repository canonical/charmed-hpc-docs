---
relatedlinks: "[Get&#32;started&#32;with&#32;COS](https://documentation.ubuntu.com/observability/track-2/tutorial/installation/), [COS&#32;best&#32;practices](https://documentation.ubuntu.com/observability/track-2/reference/best-practices/), [Slurm&#32;metrics&#32;guide](https://slurm.schedmd.com/metrics.html)"
myst:
  html_meta:
    description: Instructions on how to integrate Charmed HPC with the Canonical Observability Stack (COS) to monitor your cluster by forwarding logs and metrics for interactive analysis.
---

(howto-manage-integrate-with-cos)=
# Integrate with Canonical Observability Stack

This how-to guide provides instructions for integrating Charmed HPC with the
Canonical Observability Stack (COS). This integration enables you to monitor your
deployed Charmed HPC cluster by forwarding collected logs and metrics from
your cluster's services to COS for interactive analysis.

:::{admonition} New to COS?
:class: note

If you're unfamiliar with operating COS, see the [COS tutorials](https://documentation.ubuntu.com/observability/track-2/tutorial/)
for a high-level introduction to the Canonical Observability Stack.
:::

## Prerequisites

To integrate Charmed HPC with COS, you will need:

* An [isolated](https://charmhub.io/topics/canonical-observability-stack/reference/best-practices#deploy-in-isolation) [COS deployment](https://charmhub.io/topics/canonical-observability-stack/tutorials/install-microk8s) with [ingress](https://charmhub.io/topics/canonical-observability-stack/explanation/ingress) enabled
* An active [Slurm deployment](#howto-deploy-deploy-slurm) in your [`charmed-hpc` machine cloud](#howto-initialize-machine-cloud)
* The [Juju CLI client](https://documentation.ubuntu.com/juju/latest/user/howto/manage-juju/) installed on your machine
* The [`jq` CLI command](https://jqlang.org/download/) installed on your machine

:::{admonition} Ingress enabled
:class: warning

Your COS deployment __must__ have ingress enabled. If your COS deployment does not have
ingress enabled, Charmed HPC will be unable to forward collected logs and metrics as COS
will be unreachable over the network.
:::

:::{admonition} Before you begin
:class: note

The instructions below assume that Charmed HPC and COS have their own, individual controllers,
and that they are connected together with cross-model integration endpoints.

The instructions below also assume that the name of the COS controller is `cos-controller`, and
that the model holding your COS deployment is named `cos`. If the name of your COS controller is
not `cos-controller`, or the name of your model is not `cos`, substitute `cos-controller`
and `cos` with the names of your COS controller and model in the commands below.
:::

## Deploy OpenTelemetry Collector

First, use `juju deploy`{l=shell} to deploy {term}`OpenTelemetry Collector` in the `slurm`
model on your `charmed-hpc` machine cloud:

:::{code-block} shell
juju deploy opentelemetry-collector \
  --channel 2/stable \
  --base "ubuntu@26.04"
:::

:::{include} /reuse/common/tip-determine-current-juju-model.txt
:::

## Integrate OpenTelemetry Collector with Charmed HPC

Next, use `juju integrate`{l=shell} to integrate OpenTelemetry Collector with your
Charmed HPC cluster's applications:

:::{code-block}
juju integrate opentelemetry-collector slurmctld
juju integrate opentelemetry-collector sackd
juju integrate opentelemetry-collector slurmd
:::

OpenTelemetry Collector will install itself on each unit of the `slurmctld` application
to collect logs and metrics from the slurmctld service's metrics endpoint. It will also scrape
the metrics endpoints provided by the `sackd` and `slurmd` applications.

(howto-integrate-test-connectivity-cos)=
## Test connectivity between Charmed HPC and COS

Now ensure that your Charmed HPC cluster can communicate with your COS deployment.

To check if your Charmed HPC cluster can communicate with COS, first grab the URLs
of the COS services from [`Catalogue`](https://charmhub.io/catalogue-k8s) using the `juju show-unit`{l=shell}
command below:

:::{code-block} shell
juju show-unit --model cos-controller:cos catalogue/0 --format json | \
  jq '.[]."relation-info".[]."application-data".url | select (. != null)'
:::

The piped output of the `juju show-unit`{l=shell} will be similar to the following:

:::{terminal}
:copy:

juju show-unit --model cos-controller:cos catalogue/0 --format json | \
  jq '.[]."relation-info".[]."application-data".url | select (. != null)'

"http://10.190.89.230/cos-grafana"
"http://10.190.89.230/cos-prometheus-0"
"http://10.190.89.230/cos-alertmanager"
:::

Save these URLs as they will be used later in the
{ref}`howto-manage-integrate-with-cos-access-monitoring-resources` section.

Next, to verify that your Charmed HPC cluster can communicate with COS, access
Prometheus with `curl` using the `juju exec`{l=shell} command below:

:::{code-block} shell
juju exec --unit opentelemetry-collector/0 -- \
  curl -s http://10.190.89.230/cos-prometheus-0/api/v1/status/runtimeinfo
:::

If the output of `juju exec`{l=shell} looks similar to the success message below, this
means that your Charmed HPC cluster can communicate with COS:

:::{terminal}
:copy:
juju exec --unit opentelemetry-collector/0 -- \
  curl -s http://10.190.89.230/cos-prometheus-0/api/v1/status/runtimeinfo

{
  "status": "success",
  "data": {
    "startTime": "2025-02-06T19:09:05.141616388Z",
    "CWD": "/",
    "reloadConfigSuccess": true,
    "lastConfigTime": "2025-02-06T19:10:36Z",
    "corruptionCount": 0,
    "goroutineCount": 56,
    "GOMAXPROCS": 8,
    "GOMEMLIMIT": 9223372036854776000,
    "GOGC": "",
    "GODEBUG": "",
    "storageRetention": "15d or 819MiB204KiB819B"
  }
}
:::


## Integrate OpenTelemetry Collector with COS

Next, use `juju offer`{l=shell} create offers for COS from your `cos` model:

:::{code-block} shell
juju switch cos-controller:cos
juju offer cos.grafana:grafana-dashboard grafana-dashboards
juju offer cos.loki:logging loki-logging
juju offer cos.prometheus:receive-remote-write prometheus-receive-remote-write
:::

After that, use `juju consume`{l=shell} to consume the offers in your `slurm` model:

:::{code-block} shell
juju switch charmed-hpc-controller:slurm
juju consume cos-controller:cos.prometheus-receive-remote-write
juju consume cos-controller:cos.grafana-dashboards
juju consume cos-controller:cos.loki-logging
:::

Now use `juju integrate`{l=shell} in your `slurm` model to
integrate OpenTelemetry Collector with the COS offer endpoints:

:::{code-block} shell
juju integrate opentelemetry-collector prometheus-receive-remote-write
juju integrate opentelemetry-collector loki-logging
juju integrate opentelemetry-collector grafana-dashboards
:::

You can now use the URLs from the {ref}`howto-integrate-test-connectivity-cos`
section to access monitoring resources such as metrics, logs, and alerts collected
from your Charmed HPC cluster.

(howto-manage-integrate-with-cos-access-monitoring-resources)=
## Access monitoring resources

First, use the `get-admin-password` action to retrieve the Grafana admin password:

:::{code-block} shell
juju run grafana/leader \
  --model cos-controller:cos \
  --wait 1m \
  get-admin-password
:::

:::{admonition} About the admin password
:class: note

The `get-admin-password` action returns the initial admin password that is
generated when COS is first deployed. The action will return a notice if the
initial admin password has been changed by your COS deployment's administrator.
If the password has been changed, you will need to either create a Grafana account
in COS or get the admin password from your COS deployment's administrator.
:::

Next, open your browser and navigate to the Grafana dashboard URL you saved after
completing the {ref}`howto-integrate-test-connectivity-cos` section.

Log in as the user `admin` using the password returned by the `get-admin-password` action.
You can see the available dashboards by opening the sidebar menu and clicking on `Dashboards`.

## Next steps

You can now use COS to monitor your Charmed HPC cluster.

You can also start exploring the {ref}`reference-monitoring-grafana-dashboards`,
{ref}`reference-monitoring-loki-logs`, and {ref}`reference-monitoring-prometheus-metrics`
sections in the {ref}`reference-monitoring` section for an overview of all
the metrics, logs, and dashboards that are provided by your Charmed HPC cluster.
