---
relatedlinks: "[Apptainer&#32;admin&#32;documentation](https://apptainer.org/docs/admin/latest/), [Apptainer&#32;(Charmhub)](https://charmhub.io/apptainer), [Apptainer&#32;charm&#32;repository](https://github.com/canonical/apptainer-operator)"
---

(howto-manage-integrate-with-apptainer)=
# Integrate with Apptainer

Charmed HPC can integrate with Apptainer to enable container workload scheduling with Slurm.
This guide explains how to enable container workload scheduling by deploying and integrating
Apptainer with Charmed HPC.

:::{admonition} New to Apptainer?
:class: note

If you're unfamiliar with operating Apptainer installations, see the [Apptainer admin quick start guide](https://apptainer.org/docs/admin/latest/admin_quickstart.html)
for a high-level introduction to administering Apptainer.
:::

## Prerequisites

- A [deployed Slurm cluster](#howto-deploy-deploy-slurm).

## Deploy Apptainer

First, use `juju deploy`{l=shell} to deploy {term}`Apptainer` in the `slurm` model on
your `charmed-hpc` machine cloud:

:::{code-block} shell
juju deploy apptainer
:::

:::{include} /reuse/common/tip-determine-current-juju-model.txt
:::

## Integrate Apptainer with Slurm

Next, use `juju integrate`{l=shell} to integrate Apptainer with Slurm:

:::{code-block} shell
juju integrate apptainer sackd
juju integrate apptainer slurmd
juju integrate apptainer slurmctld
:::

Apptainer will install itself on all the `sackd` and `slurmd` units, and will
share its configuration with the Slurm controller service, `slurmctld`.

## Verify that Apptainer is integrated with Slurm

Use `juju exec`{l=text} to submit a test job.

For example, to submit a test job where the runtime environment is Ubuntu 22.04, run:

:::{code-block} shell
juju exec -u sackd/0 -- \
  srun --partition slurmd --container=docker://ubuntu:22.04 \
  cat /etc/os-release | grep ^VERSION
:::

If Apptainer has been successfully integrated with Slurm, the output of the test job
will be similar to the following:

:::{terminal}
:copy:
juju exec -u sackd/0 -- srun --partition slurmd --container=docker://ubuntu:22.04 cat /etc/os-release | grep ^VERSION

INFO:    Converting OCI blobs to SIF format
INFO:    Starting build...
INFO:    Fetching OCI image...
INFO:    Extracting OCI image...
INFO:    Inserting Apptainer configuration...
INFO:    Creating SIF file...
VERSION_ID="22.04"
VERSION="22.04.5 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
:::

## Next steps

You can now use Apptainer to run workloads and build container images on your Charmed HPC cluster.
Explore the {ref}`howto-use-apptainer` how-to for more information on using Apptainer on your Charmed HPC cluster.
