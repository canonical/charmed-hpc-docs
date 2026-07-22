---
relatedlinks: "[Slurm&#32;documentation](https://slurm.schedmd.com/documentation.html)"
myst:
  html_meta:
    description: Learn how to manage Slurm in Charmed HPC clusters. Discover controller configuration, compute node management, partition scaling, and security practices.
---

(howto-manage-slurm)=
# Manage Slurm

{term}`Slurm` is the workload manager and job scheduling system of Charmed HPC.
This guide provides instructions on how you can use the {term}`Slurm charms` to manage
the different components and services of your Slurm deployment.

## Managing the Slurm controller

(howto-manage-customize-job-email-name)=
### Customize job notification sender name

This section requires that the Slurm cluster has been
[integrated with a mail server](howto-integrate-email-notifications) to enable job notifications.

To customize the name that appears in the sign-off of email notifications sent by Slurm, set the
`slurmctld` configuration value `email-from-name`:

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

:::{code-block} shell
juju config slurmctld email-from-name="The my-cluster-name Admin Team"
:::

::::

::::{tab-item} Terraform
:sync: terraform

:::{code-block} terraform
:caption: `main.tf`
module "slurmctld" {
  source      = "git::https://github.com/canonical/slurm-charms//charms/slurmctld/terraform"
  model_uuid  = juju_model.slurm.uuid
  config = {
    email-from-name = "The my-cluster-name Admin Team"
  }
}
:::

::::

:::::

(howto-manage-single-slurmctld-to-high-availability)=
### Migrate a single slurmctld unit to high availability

To migrate a previously deployed single {term}`slurmctld` unit to a [high availability (HA)](explanation-high-availability) setup, a low-latency shared file system must be integrated to enable sharing of controller data across all `slurmctld` units. For guidance on choosing and deploying a shared file system, see the following sections:

* [How to deploy a shared filesystem](howto-deploy-deploy-shared-filesystem)
* [Shared `StateSaveLocation` using `filesystem-client` charm](explanation-slurmctld-high-availability-state-save-location)
* [Deploying `slurmctld` in high availability](deploy-slurmctld-high-availability)

Once a chosen shared file system has been deployed and made available via a proxy or other file system provider charm, run the following, substituting `[filesystem-provider]` with the name of the provider charm, to deploy a `slurmctld` HA setup with two units (a primary and single backup):

:::{admonition} Migration downtime
:class: warning

**This migration requires cluster downtime**.

The `slurmctld` service is stopped during the copy of Slurm data from the unit local `/var/lib/slurm/checkpoint` to shared storage. Downtime varies depending on the scale of data to be transferred and transfer rate to the shared storage.

This is a one-time cluster downtime. Once the data migration is complete, no further downtime is necessary when adding or removing `slurmctld` units.
:::

:::::{tab-set}

::::{tab-item} CLI
:sync: cli

:::{code-block} shell
juju deploy filesystem-client --channel latest/edge
juju integrate filesystem-client:filesystem [filesystem-provider]:filesystem

juju integrate slurmctld:mount filesystem-client:mount
juju add-unit -n 1 slurmctld
:::

::::

::::{tab-item} Terraform
:sync: terraform

:::{code-block} terraform
:caption: `main.tf`
module "filesystem-client" {
  source      = "git::https://github.com/canonical/filesystem-charms//charms/filesystem-client/terraform"
  model_uuid  = juju_model.slurm.uuid
}

resource "juju_integration" "provider_to_filesystem" {
  model_uuid = juju_model.slurm.uuid

  application {
    name     = module.[filesystem-provider].app_name
    endpoint = module.[filesystem-provider].provides.filesystem
  }

  application {
    name     = module.filesystem-client.app_name
    endpoint = module.filesystem-client.requires.filesystem
  }
}

module "slurmctld" {
  source      = "git::https://github.com/canonical/slurm-charms//charms/slurmctld/terraform"
  model_uuid  = juju_model.slurm.uuid
  constraints = "virt-type=virtual-machine"
  units       = 2
}

resource "juju_integration" "filesystem-to-slurmctld" {
  model_uuid = juju_model.slurm.uuid

  application {
    name     = module.slurmctld.app_name
    endpoint = module.slurmctld.provides.mount
  }

  application {
    name     = module.filesystem-client.app_name
    endpoint = module.filesystem-client.requires.mount
  }
}
:::

::::

:::::

Once `slurmctld` is scaled up, the output of the `juju status`{l=shell} command should be similar to the following, varying by choice of shared file system - here CephFS:

:::{terminal}
juju status

Model  Controller   Cloud/Region         Version   SLA          Timestamp
slurm  charmed-hpc  localhost/localhost  3.6.26.1  unsupported  17:16:37Z

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

(howto-manage-rotate-auth-key)=
### Rotate the Slurm authentication key

:::{admonition} Rotation downtime
:class: warning

**Key rotation requires cluster downtime**.

Authentication key rotation is a significant cluster-wide change and may cause interruption to the controller, compute nodes, accounting database and REST API.

Downtime varies depending on the node count of the cluster.
:::

Before beginning the rotation process, ensure the cluster in an appropriate
state for maintenance. Refer to the Slurm FAQ: ["How can I dry up the workload for a maintenance period?"](https://slurm.schedmd.com/faq.html#maint_time)

The `rotate-auth-key` action can be run on the slurmctld leader unit to start the asynchronous
process of rotating the authentication key for Slurm remote procedure calls:

:::{code-block} shell
juju run slurmctld/leader rotate-auth-key
:::

After the command returns, progress of the rotation can be monitored by viewing the status of the
`slurmctld` leader unit:

:::{terminal}
juju status

[...]
Unit             Workload  Agent      Machine  Public address  Ports           Message
slurmctld/0*     waiting   executing  2        10.200.245.185  6817,9092/tcp   (rotate-auth-key) Authentication key rotation in progress. Waiting for rotation to complete.
[...]
:::

Once the unit returns to `active` status, the key rotation has completed. A new key is in place and
the previous key has been deleted. The cluster can now be restored to full service.

(howto-manage-rotate-jwt-key)=
### Rotate the JWT authentication key

:::{admonition} Rotation downtime
:class: warning

**Key rotation requires accounting database API downtime**.

JWT key rotation will result in the accounting database being inaccessible via the Slurm REST API
until the rotation process completes.

The duration of the downtime depends on the time taken for the `slurmdbd` unit to process the
rotation event.
:::

Before beginning the rotation process, ensure the cluster is in an appropriate state where database API
downtime can be tolerated.

The `rotate-auth-key` action can be run on the slurmctld leader unit to start the asynchronous
process of rotating the JWT key for API authentication:

:::{code-block} shell
juju run slurmctld/leader rotate-jwt-key
:::

After the command returns, progress of the rotation can be monitored by viewing the `slurmdbd` unit
status log:

:::{terminal}
juju show-status-log slurmdbd/0

[...]
20 Apr 2026 12:55:00+01:00  juju-unit  executing  running secret-changed hook for secret:aapaln45l33kcv0so3i0
20 Apr 2026 12:55:01+01:00  juju-unit  idle
20 Apr 2026 12:58:02+01:00  workload   active
[...]
:::

Once the unit has been observed running the `secret-changed` hook and then returning to `active` status,
the key rotation has completed. A new key is in place and the previous key has been deleted. The
cluster is now restored to full service.

## Managing compute nodes and partitions

(howto-manage-custom-node-config)=
### Apply custom configuration to specific compute nodes

:::{admonition} Do you need a custom node configuration?
:class: note

The {term}`slurmd` charm creates a default node configuration during deployment.

This default configuration contains the hardware information of the node, and
information on any GPUs that are attached to the underlying machine. You should only set
a custom node configuration if you have bespoke requirements not captured by the
default node configuration such as individual node weights or stricter resource restrictions.
:::

The `set-node-config` action can be run on any slurmd unit to apply
a custom node configuration that will override the compute node's default
configuration.

For example, to update the Weight and MemSpecLimit of unit `slurmd/0`, run:

:::{code-block} shell
juju run slurmd/0 set-node-config parameters="weight=100 memspeclimit=2048"
:::

Multiple slurmd unit names can also be passed as arguments `juju run`{l=shell} to
update the node configuration of multiple compute nodes at once. For example,
to update the Weight and MemSpecLimit of units `slurmd/1`, `slurmd/2`, and `slurmd/3`, run:

:::{code-block} shell
juju run slurmd/1 slurmd/2 slurmd/3 \
  set-node-config parameters="weight=100 memspeclimit=2048"
:::

To reset a compute node's configuration to its default configuration, run:

:::{code-block} shell
juju run slurmd/0 set-node-config reset=true
:::

See the [slurmd charm's actions on Charmhub {octicon}`link-external`](https://charmhub.io/slurmd/actions)
for further information on the parameters that can be passed to the `set-node-config` action.

::::{admonition} Known limitations of the `set-node-config` action
:class: warning

1. A compute node's configuration cannot be updated while there are jobs currently
   running on the node.

   To update the compute node's configuration it must be deleted and reregistered;
   however, a compute node cannot be deleted if jobs are currently running on it.

   If you must update the configuration of a compute node that has jobs running on it,
   first drain the node with the `set-node-state` action:

   :::{code-block} shell
   juju run slurmctld/leader set-node-state \
     nodes="<nodename>" \
     state=drain \
     reason="Updating node configuration"
   :::

   After that, once all jobs have completed, use `set-node-config` to update the configuration
   of the compute node. The compute node can then be resumed with `set-node-state`:

   :::{code-block} shell
   juju run slurmctld/leader set-node-state \
     nodes="<nodename>" \
     state=idle
   :::

2. Certain node configuration options cannot be modified with `set-node-config`.

   The options that cannot be modified are `NodeName`, `NodeAddr`,
   `NodeHostname`, `State`, `Reason`, and `Port`. These options are managed
   directly by the slurmd charm. The `set-node-config` action will fail if you attempt
   to set any of these options.

   You can see the full list of node configuration options in the
   ["Node configuration" section of Slurm's documentation {octicon}`link-external`](https://slurm.schedmd.com/slurm.conf.html#SECTION_NODE-CONFIGURATION).
::::

(howto-manage-default-node-state)=
### Modify the default state and reason of new compute nodes

Compute nodes start in the `down` state by default. The `default-node-state` option
can be used to modify the default state that compute nodes will start in. For example,
to set new compute nodes' default state to `idle`, run:

:::{code-block} shell
juju config slurmd default-node-state=idle
:::

To deploy a new partition where all compute nodes will start in the `idle` state, run:

:::{code-block} shell
juju deploy slurmd <partition> --config default-node-state=idle
:::

The `default-node-reason` configuration option can be used to provide a reason for
the default state of a new node. For example, to set the reason for why a new compute
node has started in the `down` state, run:

:::{code-block} shell
juju config slurmd default-node-reason="New node."
:::

Note that the configured value for `default-node-reason` will be ignored if
`default-node-state` is set to `idle`.

See the [slurmd charm's configuration options on Charmhub {octicon}`link-external`](https://charmhub.io/slurmd/configurations)
for further information about the`default-node-state` and `default-node-reason`
configuration options.

(howto-manage-node-state)=
### Modify the state of compute nodes

The `set-node-state` action can be run on any slurmctld unit to update the state
of registered compute nodes in Charmed HPC.

For example, to set the state of compute nodes `slurmd-[0-19]` to idle, run:

:::{code-block} shell
juju run slurmctld/leader set-node-state nodes="slurmd-[0-19]" state=idle
:::

To set their state to down with the reason of "Weekly maintenance", run:

:::{code-block} shell
juju run slurmctld/leader set-node-state \
  nodes="slurmd-[0-19]" \
  state=down \
  reason="Weekly maintenance"
:::

The following compute node states can be set using `set-node-state`:

- `idle`
- `down`
- `drain`
- `fail`
- `failing`

See the [slurmctld charm's actions on Charmhub {octicon}`link-external`](https://charmhub.io/slurmctld/actions)
for further information on the parameters that can be passed to the `set-node-state` action.

(howto-manage-scale-partitions)=
### Scale partitions

Partitions in Charmed HPC are elastic. The number of compute nodes in a partition can
be increased and decreased using `juju add-unit`{l=shell} and `juju remove-unit`{l=shell}
respectively.

For example, to add 15 more compute nodes to the partition `slurmd`, run:

:::{code-block} shell
juju add-unit --num-units 15 slurmd
:::

To remove compute nodes `slurmd-[0-2]` from the partition `slurmd`, run:

:::{code-block} shell
juju remove-unit slurmd/0 slurmd/1 slurmd/2
:::

::::{admonition} Drain compute nodes before scaling down a partition
:class: warning

Compute nodes selected for removal should be drained before running `juju remove-unit`{l=shell}
if they have running jobs on them. They can be drained using the `set-node-state` action:

:::{code-block} shell
juju run slurmctld/leader set-node-state \
  nodes="slurmd-[0-2]" \
  state=drain \
  reason="Removing from partition"
:::

`juju remove-unit`{l=shell} can then be called after all jobs have completed on
the selected compute nodes.

::::
