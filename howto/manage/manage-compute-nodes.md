---
relatedlinks: "[Slurm&#32;documentation](https://slurm.schedmd.com/documentation.html), [Slurm&#32;Workload&#32;Manager&#32;-&#32;slurm.conf&#32;-&#32;Node&#32;configuration](https://slurm.schedmd.com/slurm.conf.html#SECTION_NODE-CONFIGURATION)"
myst:
  html_meta:
    description: Instructions on how to configure compute nodes, set node states, and scale partitions up and down in a Charmed HPC cluster using the Slurm charms.
---

(howto-manage-compute-nodes)=
# Manage compute nodes and partitions

{term}`Slurm` is the workload manager and job scheduling system of Charmed HPC. This guide
provides instructions on how you can use the {term}`slurmd` and {term}`slurmctld` charms to
configure compute nodes, change their state, and adjust the size of your partitions.

(howto-manage-custom-node-config)=
## Apply custom configuration to specific compute nodes

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
## Modify the default state and reason of new compute nodes

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
## Modify the state of compute nodes

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
## Scale partitions

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
