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
juju deploy sackd --base "ubuntu@26.04" --channel "latest/edge"
juju deploy slurmctld --base "ubuntu@26.04" --channel "latest/edge"
juju deploy slurmd --base "ubuntu@26.04" --channel "latest/edge"
juju deploy slurmdbd --base "ubuntu@26.04" --channel "latest/edge"
juju deploy slurmrestd --base "ubuntu@26.04" --channel "latest/edge"
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
:lines: 17-50
:::

After that, integrate all of Slurm's services together, and integrate slurmdbd with MySQL:

:::{literalinclude} /reuse/howto/setup/deploy-slurm/slurm.tf
:caption: {{ slurm_tf_file }}
:language: terraform
:lines: 52-120
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
:scroll:

juju status

Model  Controller              Cloud/Region         Version  SLA          Timestamp
slurm  charmed-hpc-controller  localhost/localhost  3.6.28   unsupported  18:37:21-06:00

App         Version          Status  Scale  Charm       Channel      Rev  Exposed  Message
mysql       8.0.44-0ubun...  active      1  mysql       8.0/stable   444  no
sackd       25.11.2          active      1  sackd       latest/edge   89  no
slurmctld   25.11.2          active      1  slurmctld   latest/edge  167  no       primary - UP
slurmd      25.11.2          active      1  slurmd      latest/edge  184  no
slurmdbd    25.11.2          active      1  slurmdbd    latest/edge  161  no
slurmrestd  25.11.2          active      1  slurmrestd  latest/edge  161  no

Unit           Workload  Agent  Machine  Public address  Ports           Message
mysql/0*       active    idle   5        10.124.231.36   3306,33060/tcp  Primary
sackd/0*       active    idle   0        10.124.231.87   6818/tcp
slurmctld/0*   active    idle   1        10.124.231.54   6817,9092/tcp   primary - UP
slurmd/0*      active    idle   2        10.124.231.120  6818/tcp
slurmdbd/0*    active    idle   3        10.124.231.109  6819/tcp
slurmrestd/0*  active    idle   4        10.124.231.15   6820/tcp

Machine  State    Address         Inst id        Base          AZ  Message
0        started  10.124.231.87   juju-b22d6d-0  ubuntu@26.04      Running
1        started  10.124.231.54   juju-b22d6d-1  ubuntu@26.04      Running
2        started  10.124.231.120  juju-b22d6d-2  ubuntu@26.04      Running
3        started  10.124.231.109  juju-b22d6d-3  ubuntu@26.04      Running
4        started  10.124.231.15   juju-b22d6d-4  ubuntu@26.04      Running
5        started  10.124.231.36   juju-b22d6d-5  ubuntu@22.04      Running
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
juju deploy filesystem-client --base "ubuntu@26.04" --channel latest/edge
juju integrate filesystem-client:filesystem [filesystem-provider]:filesystem

juju deploy slurmctld --base "ubuntu@26.04" --channel "latest/edge" --num-units 2
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
:scroll:

juju status

Model  Controller              Cloud/Region         Version  SLA          Timestamp
slurm  charmed-hpc-controller  localhost/localhost  3.6.28   unsupported  17:35:38-06:00

App                  Version          Status  Scale  Charm                Channel          Rev  Exposed  Message
cephfs-server-proxy                   active      1  cephfs-server-proxy  latest/edge       44  no
filesystem-client                     active      2  filesystem-client    latest/edge       37  no       Integrated with `cephfs` provider
mysql                8.0.44-0ubun...  active      1  mysql                8.0/stable       444  no
sackd                25.11.2          active      1  sackd                latest/edge       89  no
slurmctld            25.11.2          active      2  slurmctld            latest/edge      167  no       primary - UP
slurmd               25.11.2          active      1  slurmd               latest/edge      184  no
slurmdbd             25.11.2          active      1  slurmdbd             latest/edge      161  no
slurmrestd           25.11.2          active      1  slurmrestd           latest/edge      161  no

Unit                    Workload  Agent  Machine  Public address  Ports           Message
cephfs-server-proxy/0*  active    idle   6        10.124.231.117
mysql/0*                active    idle   5        10.124.231.202  3306,33060/tcp  Primary
sackd/0*                active    idle   0        10.124.231.214  6818/tcp
slurmctld/0*            active    idle   1        10.124.231.134  6817,9092/tcp   primary - UP
  filesystem-client/0*  active    idle            10.124.231.134                  Mounted filesystem at `/srv/slurmctld-statefs`
slurmctld/1             active    idle   7        10.124.231.183  6817,9092/tcp   backup - UP
  filesystem-client/1   active    idle            10.124.231.183                  Mounted filesystem at `/srv/slurmctld-statefs`
slurmd/0*               active    idle   2        10.124.231.113  6818/tcp
slurmdbd/0*             active    idle   3        10.124.231.7    6819/tcp
slurmrestd/0*           active    idle   4        10.124.231.225  6820/tcp

Machine  State    Address         Inst id        Base          AZ  Message
0        started  10.124.231.214  juju-fcea50-0  ubuntu@26.04      Running
1        started  10.124.231.134  juju-fcea50-1  ubuntu@26.04      Running
2        started  10.124.231.113  juju-fcea50-2  ubuntu@26.04      Running
3        started  10.124.231.7    juju-fcea50-3  ubuntu@26.04      Running
4        started  10.124.231.225  juju-fcea50-4  ubuntu@26.04      Running
5        started  10.124.231.202  juju-fcea50-5  ubuntu@22.04      Running
6        started  10.124.231.117  juju-fcea50-6  ubuntu@26.04      Running
7        started  10.124.231.183  juju-fcea50-7  ubuntu@26.04      Running
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
  --channel "latest/edge" \
  --constraints="virt-type=virtual-machine"

juju deploy slurmctld \
  --base "ubuntu@26.04" \
  --channel "latest/edge" \
  --constraints="virt-type=virtual-machine"

juju deploy slurmd \
  --base "ubuntu@26.04" \
  --channel "latest/edge" \
  --constraints="virt-type=virtual-machine"

juju deploy slurmdbd \
  --base "ubuntu@26.04" \
  --channel "latest/edge" \
  --constraints="virt-type=virtual-machine"

juju deploy slurmrestd \
  --base "ubuntu@26.04" \
  --channel "latest/edge" \
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
:scroll:

juju status slurmd

Model  Controller              Cloud/Region         Version  SLA          Timestamp
slurm  charmed-hpc-controller  localhost/localhost  3.6.28   unsupported  17:39:46-06:00

App     Version  Status  Scale  Charm   Channel      Rev  Exposed  Message
slurmd  25.11.2  active      1  slurmd  latest/edge  184  no

Unit       Workload  Agent  Machine  Public address  Ports     Message
slurmd/0*  active    idle   2        10.124.231.113  6818/tcp

Machine  State    Address         Inst id        Base          AZ  Message
2        started  10.124.231.113  juju-fcea50-2  ubuntu@26.04      Running
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
