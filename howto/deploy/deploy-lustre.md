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

- A [Slurm cluster](#howto-deploy-deploy-slurm).
- The [Juju CLI client](https://documentation.ubuntu.com/juju/latest/user/howto/manage-juju/) installed on your machine.
- Secure boot **disabled** on target machines, as the charm builds DKMS kernel modules.

## Deploy the `lustre-server` charm

To deploy the `lustre-server` charm:

:::{code-block} shell
juju deploy lustre-server \
  --channel latest/edge \
  -n 2
:::

At least two units are required; a single unit deployment is not supported.

The Juju application leader at deployment time becomes a combined MGS+MDS unit. All additional units become OSSes, each providing one OST.

Wait for all units in the deployment to become active:

:::{code-block} shell
juju status
:::

## Deploy the `filesystem-client` charm

To mount the Lustre filesystem on client nodes, deploy the `filesystem-client` subordinate charm
charm with `mountpoint` configuration set to the path Lustre should be mounted at on each client.
Then integrate with the `lustre-server` application on the `filesystem` endpoint:

:::{code-block} shell
juju deploy filesystem-client \
  --channel latest/edge \
  --config mountpoint="/mnt/lustre"

juju integrate filesystem-client:filesystem lustre-server:filesystem
:::

Now integrate any deployed primary charm with the `filesystem-client` on the `juju-info` endpoint to
mount Lustre. For example, to mount on all `slurmd` compute nodes of a Slurm cluster deployment:

:::{code-block} shell
juju integrate filesystem-client:juju-info slurm:juju-info
:::

Lustre will then be mounted at `/mnt/lustre` on each compute node.
