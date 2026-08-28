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

For an explanation of Lustre and related terminology, see the {ref}`Lustre explanation page <explanation-lustre>`.

## Prerequisites

- The [Juju CLI client](https://documentation.ubuntu.com/juju/latest/user/howto/manage-juju/) installed on your machine.
- Secure boot **disabled** on target machines, as the charm builds DKMS kernel modules.

(howto-deploy-deploy-lustre-server)=
## Deploy the `lustre-server` charm

To deploy with the default configuration, where the initial leader unit is a combined MGS+MDS (Management Server + Metadata Server) and all remaining units are OSSes (Object Storage Servers), run the following:

:::{code-block} shell
juju deploy lustre-server \
  --channel latest/edge \
  -n <number of units>
:::

A minimum of two units is required; one combined MGS+MDS and one OSS unit. A single unit deployment is not supported.

### Deploy with custom LNet configuration

If the {ref}`default LNet auto-detection of a "tcp" Network Identifier (NID) on the default route interface and a multi-rail "o2ib" NID on all detected RDMA devices <explanation-lustre-lnet-configuration>` is not suitable for your deployment (for example, you wish to exclude the "tcp" network or wish to disable multi-rail), override by deploying as described in {ref}`howto-deploy-deploy-lustre-server` but include the `lnet-networks` configuration option following format: `<name>=<iface>[,<iface>...]`.

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
juju integrate filesystem-client:juju-info slurmd:juju-info
:::

Lustre will then be mounted at `/mnt/lustre` on each compute node. Confirm this by running `juju status`{l=shell} and confirming the output is similar to the following:

:::{terminal}
juju status

Model   Controller    Cloud/Region         Version  SLA          Timestamp
lustre  charmed-hpc   charmed-hpc/default  3.6.27   unsupported  15:51:22+01:00

App                Version  Status  Scale  Charm              Channel      Rev  Exposed  Message
filesystem-client           active      1  filesystem-client  latest/edge   34  no       Integrated with `lustre` provider
lustre-server               active      2  lustre-server      latest/edge    5  no       MGS+MDS ready
slurmctld          25.11.2  active      1  slurmctld          latest/edge  167  no       primary - UP
slurmd             25.11.2  active      1  slurmd             latest/edge  184  no

Unit                    Workload  Agent  Machine  Public address  Ports          Message
lustre-server/0*        active    idle   2        10.200.245.163                 MGS+MDS ready
lustre-server/1         active    idle   3        10.200.245.225                 OSS ready
slurmctld/0*            active    idle   0        10.200.245.162  6817,9092/tcp  primary - UP
slurmd/0*               active    idle   1        10.200.245.25   6818/tcp
  filesystem-client/0*  active    idle            10.200.245.25                  Mounted filesystem at `/mnt/lustre`

Machine  State    Address         Inst id        Base          AZ  Message
0        started  10.200.245.162  juju-b8dc1c-0  ubuntu@26.04      Running
1        started  10.200.245.25   juju-b8dc1c-1  ubuntu@26.04      Running
2        started  10.200.245.163  juju-b8dc1c-2  ubuntu@26.04      Running
3        started  10.200.245.225  juju-b8dc1c-3  ubuntu@26.04      Running
:::

Confirm the Lustre filesystem is usable by creating a test file:

:::{code-block} shell
juju exec --unit slurmd/0 -- sudo touch /mnt/lustre/afile
:::

then viewing the file stripe layout:

:::{terminal}
juju exec --unit slurmd/0 -- sudo lfs getstripe /mnt/lustre

/mnt/lustre
stripe_count:  1 stripe_size:   4194304 pattern:        stripe_offset: -1

/mnt/lustre/afile
lmm_stripe_count:  1
lmm_stripe_size:   4194304
lmm_pattern:       raid0
lmm_layout_gen:    0
lmm_stripe_offset: 1
	obdidx		 objid		 objid		 group
	     1	             2	          0x2	   0x240000400
:::
