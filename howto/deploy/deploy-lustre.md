---
myst:
  html_meta:
    description: Instructions on how to deploy the Lustre parallel filesystem in a Charmed HPC cluster using the lustre-server charm.
relatedlinks: "[Lustre&#32;website](https://wiki.lustre.org/), [filesystem-charms&#32;repository](https://github.com/canonical/filesystem-charms)"
---

(howto-deploy-deploy-lustre)=
# How to deploy Lustre

This how-to guide shows you how to deploy the Lustre parallel filesystem in your Charmed HPC
cluster using the `lustre-server` charm, and integrate it with compute nodes via the
`filesystem-client` charm.

:::{admonition} Experimental
:class: warning

The `lustre-server` charm is in an experimental state and is not ready for production use.
:::

## Prerequisites

- The [Juju CLI client](https://documentation.ubuntu.com/juju/latest/user/howto/manage-juju/) installed on your machine.
- Secure boot **disabled** on target machines, as the charm builds DKMS kernel modules.

(howto-deploy-deploy-lustre-server)=
## Deploy the `lustre-server` charm

To deploy with the default configuration, where the initial leader unit is a combined MGS+MDS and all remaining units are OSSes, run the following:

:::{code-block} shell
juju deploy lustre-server \
  --channel latest/edge \
  -n <number of units>
:::

A minimum of two units is required; a single unit deployment is not supported.

## Deploy the `lustre-server` charm with custom LNet configuration

To override LNet auto-detection and deploy with a custom configuration, deploy as described in {ref}`howto-deploy-deploy-lustre-server` but include the `lnet-networks` configuration option following format: `<name>=<iface>[,<iface>...]`.

For example, to configure LNet with a net name of `tcp` using the `eth0` interface, and a net name of `o2ib0` using the `ib0` and `ib1` interfaces, run the following:

:::{code-block} shell
juju deploy lustre-server \
  --channel latest/edge \
  --config lnet-networks="tcp=eth0; o2ib0=ib0,ib1" \
  -n <number of units>
:::

## Deploy the `filesystem-client` charm

To mount the Lustre filesystem on client nodes, deploy the `filesystem-client` subordinate charm,
with the `mountpoint` configuration set to the path Lustre should be mounted at on each client and
the `enable-lustre` configuration set to `true`. Then integrate with the `lustre-server` application
on the `filesystem` endpoint:

:::{code-block} shell
juju deploy filesystem-client \
  --channel latest/edge \
  --config mountpoint="/mnt/lustre" \
  --config enable-lustre=true

juju integrate filesystem-client:filesystem lustre-server:filesystem
:::

Now integrate any deployed primary charm with the `filesystem-client` on the `juju-info` endpoint to
mount Lustre. For example, to mount on all `slurmd` compute nodes of a Slurm cluster deployment:

:::{code-block} shell
juju integrate filesystem-client:juju-info slurm:juju-info
:::

Lustre will then be mounted at `/mnt/lustre` on each compute node.
