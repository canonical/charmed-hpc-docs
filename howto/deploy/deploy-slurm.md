---
myst:
  html_meta:
    description: Instructions on how to use Juju to deploy Slurm in either a standalone or high-availability configuration as the workload manager of a Charmed HPC cluster.
relatedlinks: "[Slurm&#32;website](https://slurm.schedmd.com/overview.html), [Slurm&#32;charms&#32;repository](https://github.com/canonical/slurm-charms)"
---

(howto-deploy-deploy-slurm)=
# How to deploy Slurm

This how-to guide shows you how to deploy the Slurm workload manager as the
resource management and job scheduling service of your Charmed HPC cluster.
The deployment, management, and operations of Slurm are controlled by the Slurm charms.

## Prerequisites

To successfully deploy Slurm in your Charmed HPC cluster, you will at least need:

- An [initialized cloud environment](#howto-initialize-cloud-environment).
- The [Juju CLI client](https://documentation.ubuntu.com/juju/latest/user/howto/manage-juju/) installed on your machine.

Once you have verified that you have met the prerequisites above, proceed to the instructions below.

## Deploy Slurm

You have two options for deploying Slurm:

1. Using the [Juju CLI client](https://documentation.ubuntu.com/juju/latest/user/reference/juju-cli/).
2. Using the [Juju Terraform client](https://canonical-terraform-provider-juju.readthedocs-hosted.com/latest/).

If you want to use Terraform to deploy Slurm, see the
[Manage `terraform-provider-juju`](https://canonical-terraform-provider-juju.readthedocs-hosted.com/latest/howto/manage-terraform-provider-juju/) how-to guide for additional
requirements.

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

First, use `juju add-model`{l=shell} to create the `slurm` model on your `charmed-hpc`
machine cloud:

:::{code-block} shell
juju add-model slurm charmed-hpc
:::

Now use `juju deploy`{l=shell} to deploy Slurm's services with MySQL as
the storage database for slurmdbd:

:::{include} /reuse/howto/setup/deploy-slurm/slurmctld-ha-note.txt
:::

:::{include} /reuse/howto/setup/deploy-slurm/slurm-lxd-warning.txt
:::

:::{code-block} shell
juju deploy sackd --base "ubuntu@26.04" --channel "edge"
juju deploy slurmctld --base "ubuntu@26.04" --channel "edge"
juju deploy slurmd --base "ubuntu@26.04" --channel "edge"
juju deploy slurmdbd --base "ubuntu@26.04" --channel "edge"
juju deploy slurmrestd --base "ubuntu@26.04" --channel "edge"
juju deploy mysql --channel "8.0/stable"
:::

After that, use `juju integrate`{l=shell} to integrate all of Slurm's services together,
and integrate slurmdbd with MySQL:

:::{code-block} shell
juju integrate slurmctld sackd
juju integrate slurmctld slurmd
juju integrate slurmctld slurmdbd
juju integrate slurmctld slurmrestd
juju integrate slurmdbd mysql:database
:::

::::

::::{tab-item} Terraform
:sync: terraform

First, create the Terraform configuration file _{{ slurm_tf_file }}_ using
`mkdir`{l=shell} and `touch`{l=shell}:

:::{code-block} shell
mkdir slurm
touch slurm/main.tf
:::

Now open _{{ slurm_tf_file }}_ in a text editor and add the Juju Terraform provider
to your configuration:

:::{literalinclude} /reuse/howto/setup/deploy-slurm/slurm.tf
:caption: {{ slurm_tf_file }}
:language: terraform
:lines: 1-8
:::

Next, create the `slurm` model on your `charmed-hpc` machine cloud:

:::{literalinclude} /reuse/howto/setup/deploy-slurm/slurm.tf
:caption: {{ slurm_tf_file }}
:language: terraform
:lines: 10-15
:::

Now deploy Slurm's services with MySQL as the storage database for slurmdbd:

:::{include} /reuse/howto/setup/deploy-slurm/slurmctld-ha-note.txt
:::

:::{include} /reuse/howto/setup/deploy-slurm/slurm-lxd-warning.txt
:::

:::{literalinclude} /reuse/howto/setup/deploy-slurm/slurm.tf
:caption: {{ slurm_tf_file }}
:language: terraform
:lines: 17-45
:::

After that, integrate all of Slurm's services together, and integrate slurmdbd with MySQL:

:::{literalinclude} /reuse/howto/setup/deploy-slurm/slurm.tf
:caption: {{ slurm_tf_file }}
:language: terraform
:lines: 47-115
:::

You can expand the dropdown below to view the full _{{ slurm_tf_file }}_ Terraform
configuration before applying it. Now use the `terraform`{l=shell} command to apply
your configuration:

:::{code-block} shell
terraform -chdir=slurm init
terraform -chdir=slurm apply -auto-approve
:::

:::{dropdown} Full _{{ slurm_tf_file }}_ Terraform configuration file
:::{literalinclude} /reuse/howto/setup/deploy-slurm/slurm.tf
:caption: {{ slurm_tf_file }}
:language: terraform
:::
:::

::::

:::::

Your Slurm deployment will become active within a few minutes. The output of the
`juju status`{l=shell} will be similar to the following:

:::{terminal}
juju status

Model  Controller              Cloud/Region         Version  SLA          Timestamp
slurm  charmed-hpc-controller  localhost/localhost  3.6.27   unsupported  17:34:28-06:00

App         Version          Status  Scale  Charm       Channel     Rev  Exposed  Message
mysql       8.0.44-0ubun...  active      1  mysql       8.0/stable  444  no
sackd       25.11.2-1ubu...  active      1  sackd                    67  no
slurmctld   25.11.2-1ubu...  active      1  slurmctld               144  no       primary - UP
slurmd      25.11.2-1ubu...  active      1  slurmd                  165  no
slurmdbd    25.11.2-1ubu...  active      1  slurmdbd                150  no
slurmrestd  25.11.2-1ubu...  active      1  slurmrestd              151  no

Unit           Workload  Agent  Machine  Public address  Ports           Message
mysql/0*       active    idle   4        10.2.171.104    3306,33060/tcp  Primary
sackd/0*       active    idle   0        10.2.171.132    6818/tcp
slurmctld/0*   active    idle   1        10.2.171.16     6817,9092/tcp   primary - UP
slurmd/0*      active    idle   3        10.2.171.246    6818/tcp
slurmdbd/0*    active    idle   2        10.2.171.26     6819/tcp
slurmrestd/0*  active    idle   5        10.2.171.147    6820/tcp

Machine  State    Address       Inst id        Base          AZ                    Message
0        started  10.2.171.132  juju-7c7460-0  ubuntu@26.04  charmed-hpc-tutorial  Running
1        started  10.2.171.16   juju-7c7460-1  ubuntu@26.04  charmed-hpc-tutorial  Running
2        started  10.2.171.26   juju-7c7460-2  ubuntu@26.04  charmed-hpc-tutorial  Running
3        started  10.2.171.246  juju-7c7460-3  ubuntu@26.04  charmed-hpc-tutorial  Running
4        started  10.2.171.104  juju-7c7460-4  ubuntu@22.04  charmed-hpc-tutorial  Running
5        started  10.2.171.147  juju-7c7460-5  ubuntu@26.04  charmed-hpc-tutorial  Running
:::

(deploy-slurmctld-high-availability)=
### Deploying `slurmctld` in high availability

The `slurmctld` charm optionally supports [high availability (HA)](explanation-high-availability)
through the native functionality provided by Slurm. This functionality requires a
low-latency shared filesystem; follow the instructions in the
[Deploy a shared filesystem](howto-deploy-deploy-shared-filesystem) section to deploy a shared filesystem.

:::{admonition} Choosing a shared filesystem
:class: warning

See the [Shared `StateSaveLocation` using `filesystem-client` charm](explanation-slurmctld-high-availability-state-save-location)
section for guidance on choosing a shared filesystem. It is recommended that the
HA file system **not be the same as the filesystem used for the cluster compute nodes**
to avoid I/O-intensive user jobs from impacting slurmctld's responsiveness.
The suggested approach is to deploy a dedicated HA file system then subsequently
provision a separate file system for the compute nodes.
:::

Once a chosen shared filesystem has been deployed and made available through a proxy or provider charm,
use the following instructions, substituting `[filesystem-provider]` with the name of the provider charm
to deploy slurmctld with HA enabled.

In this example, two slurmctld units are deployed. One slurmctld unit
acts as the primary Slurm controller, and the other unit serves as the backup controller:

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

:::{code-block} shell
juju deploy filesystem-client --channel latest/edge
juju integrate filesystem-client:filesystem [filesystem-provider]:filesystem

juju deploy slurmctld --base "ubuntu@26.04" --channel "edge" --num-units 2
juju integrate slurmctld:mount filesystem-client:mount
:::

::::

::::{tab-item} Terraform
:sync: terraform

:::{literalinclude} /reuse/howto/setup/deploy-slurm/slurm-ha.tf
:caption: {{ slurm_tf_file }}
:language: terraform
:::

::::

:::::

Once `slurmctld` is scaled up, the output of `juju status`{l=shell} will be similar
to the following. The output can be different depending on the shared filesystem you chose.
CephFS is used in this example to provide the HA filesystem:

:::{terminal}
juju status

Model  Controller   Cloud/Region         Version  SLA          Timestamp
slurm  charmed-hpc  charmed-hpc/default  3.6.0    unsupported  17:16:37Z

App                 Version          Status  Scale  Charm                Channel      Rev  Exposed  Message
cephfs-server-proxy                  active      1  cephfs-server-proxy  latest/edge   25  no
filesystem-client                    active      1  filesystem-client    latest/edge   20  no       Integrated with `cephfs` provider
mysql               8.0.39-0ubun...  active      1  mysql                8.0/stable   313  no
sackd               23.11.4-1.2u...  active      1  sackd                latest/edge    4  no
slurmctld           23.11.4-1.2u...  active      1  slurmctld            latest/edge   86  no       primary - UP
slurmd              23.11.4-1.2u...  active      1  slurmd               latest/edge  107  no
slurmdbd            23.11.4-1.2u...  active      1  slurmdbd             latest/edge   78  no
slurmrestd          23.11.4-1.2u...  active      1  slurmrestd           latest/edge   80  no

Unit                    Workload  Agent      Machine  Public address  Ports           Message
mysql/0*                active    idle       5        10.32.18.127    3306,33060/tcp  Primary
sackd/0*                active    idle       4        10.32.18.203
slurmctld/0*            active    idle       0        10.32.18.15                     primary - UP
  filesystem-client/0*  active    idle                10.32.18.15                     Mounted filesystem at `/srv/slurmctld-statefs`
slurmctld/1             active    idle       6        10.32.18.204                    backup - UP
  filesystem-client/1   active    idle                10.32.18.204                    Mounted filesystem at `/srv/slurmctld-statefs`
slurmd/0*               active    idle       1        10.32.18.207
slurmdbd/0*             active    idle       2        10.32.18.102
slurmrestd/0*           active    idle       3        10.32.18.9

Machine  State    Address       Inst id        Base          AZ  Message
0        started  10.32.18.15   juju-d566c2-0  ubuntu@24.04      Running
1        started  10.32.18.207  juju-d566c2-1  ubuntu@24.04      Running
2        started  10.32.18.102  juju-d566c2-2  ubuntu@24.04      Running
3        started  10.32.18.9    juju-d566c2-3  ubuntu@24.04      Running
4        started  10.32.18.203  juju-d566c2-4  ubuntu@24.04      Running
5        started  10.32.18.127  juju-d566c2-5  ubuntu@22.04      Running
6        started  10.32.18.204  juju-d566c2-6  ubuntu@24.04      Running
:::

::::

:::::

(deploy-slurm-lxd)=
### Deploying Slurm on LXD

Pass the constraint `"virt-type=virtual-machine"`{l=shell} to Juju to deploy
Slurm on virtual machines instead of system containers:

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

:::{code-block} shell
juju deploy sackd \
  --base "ubuntu@26.04" \
  --channel "edge" \
  --constraints="virt-type=virtual-machine"

juju deploy slurmctld \
  --base "ubuntu@26.04" \
  --channel "edge" \
  --constraints="virt-type=virtual-machine"

juju deploy slurmd \
  --base "ubuntu@26.04" \
  --channel "edge" \
  --constraints="virt-type=virtual-machine"

juju deploy slurmdbd \
  --base "ubuntu@26.04" \
  --channel "edge" \
  --constraints="virt-type=virtual-machine"

juju deploy slurmrestd \
  --base "ubuntu@26.04" \
  --channel "edge" \
  --constraints="virt-type=virtual-machine"

juju deploy mysql \
  --channel "8.0/stable" \
  --constraints="virt-type=virtual-machine"
:::

::::

::::{tab-item} Terraform
:sync: terraform

:::{literalinclude} /reuse/howto/setup/deploy-slurm/slurm-lxd.tf
:caption: {{ slurm_tf_file }}
:language: terraform
:::

::::

:::::

## Set compute nodes to `idle`

Compute nodes are initially registered with their state set to `down` after your
Slurm deployment becomes active. You can use the `set-node-state` action to set the
compute nodes' state to `idle` to make them available for scheduled jobs.
For example, to set the state of compute node `slurmd-0` to `idle`, run:

:::{code-block} shell
juju run slurmctld/leader set-node-state nodes="slurmd-0" state=idle
:::

::::{admonition} Tips
:class: note
1. You can get the node name of a compute node by substituting the forward slash `/` character in the
   unit's name with the dash `-` character. For example, the unit `slurmd/0` in Juju would be named
   `slurmd-0` in Slurm.

   `juju status`{l=shell} can be used to find unit names. For example, to list all the units that
   belong to the slurmd application, run:

:::{terminal}
juju status slurmd

Model  Controller   Cloud/Region         Version  SLA          Timestamp
slurm  charmed-hpc  charmed-hpc/default  3.6.0    unsupported  17:16:37Z

App         Version          Status  Scale  Charm       Channel      Rev  Exposed  Message
slurmd      23.11.4-1.2u...  active      1  slurmd      latest/edge  107  no

Unit           Workload  Agent      Machine  Public address  Ports           Message
slurmd/0*      active    idle       1        10.32.18.207

Machine  State    Address       Inst id        Base          AZ  Message
1        started  10.32.18.207  juju-d566c2-1  ubuntu@24.04      Running
:::

2. The `nodes` parameter of the `set-node-state` action accepts node name ranges for updating
   the state of multiple nodes at once. For example, to set the state of compute nodes `slurmd-0` to
   to `slurmd-9` to `idle`, the node name range `slurmd-[0-9]` can be used:

:::{code-block}
juju run slurmctld/leader set-node-state nodes="slurmd-[0-9]" state=idle
:::

::::

## Verify compute nodes are `idle`

You can use `sinfo`{l=shell} with `juju exec`{l=shell} to verify that a
compute node's state is `idle`. For example, to check if node `slurmd-0` is idle:

:::{terminal}
juju exec --unit sackd/0 -- sinfo --nodes slurmd-0

PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
slurmd       up   infinite      1   idle slurmd-0
:::

To verify that all the nodes in a partition are `idle`, run `sinfo`{l=shell} without the
`--nodes`{l=shell} flag:

:::{terminal}
juju exec --unit sackd/0 -- sinfo

PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
slurmd       up   infinite     10   idle slurmd-[0-9]
:::


## Next steps

Now that Slurm is deployed, you can deploy the shared filesystem of your Charmed HPC cluster:

- {ref}`howto-deploy-deploy-shared-filesystem`

You can also explore the {ref}`reference-glossary` for further information on {term}`sackd`,
{term}`slurmctld`, {term}`slurmd`, {term}`slurmdbd`, {term}`slurmrestd`, and {term}`MySQL`
and how they are managed by their respective charms.
