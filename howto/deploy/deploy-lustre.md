---
myst:
  html_meta:
    description: Instructions on how to deploy the Lustre parallel filesystem in a Charmed HPC cluster using the lustre-server charm.
relatedlinks: "[Lustre&#32;wiki](https://wiki.lustre.org/), [Lustre&#32;manual](https://doc.lustre.org/lustre_manual.xhtml), [filesystem-charms&#32;repository](https://github.com/canonical/filesystem-charms)"
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

A Lustre deployment requires at least two `lustre-server` units:

- One combined Management Server and Metadata Server (MGS+MDS).
- One or more Object Storage Servers (OSSes).

Deploy the required units:

:::{code-block} shell
juju deploy lustre-server \
  --channel latest/edge \
  -n <number-of-units>
:::

Assign the unit roles by attaching storage. To configure `lustre-server/0` as the combined MGS+MDS, attach storage to its `mgt-mdt` endpoint:

:::{code-block} shell
juju add-storage lustre-server/0 mgt-mdt=loop,2,1G
:::

creating two 1GB volumes for `mgt-mdt`.

To configure `lustre-server/1` as an OSS, attach storage to its `ost` endpoint:

:::{code-block} shell
juju add-storage lustre-server/1 ost=loop,4,1G
:::

creating four 1GB volumes for `ost`.

Repeat the `juju add-storage` command for each additional unit that should act as an OSS.

The `loop` storage pool is suitable for testing only. For a production deployment, replace it with an [appropriate Juju storage pool](https://canonical.com/juju/docs/juju-cli/latest/reference/storage/#storage-pool) and choose capacities suitable for the filesystem workload.

(howto-deploy-deploy-lustre-custom-lnet)=
### Deploy with custom LNet configuration

By default, the charm configures a `tcp` LNet network on the interface that provides the default route. If it detects RDMA interfaces, it also configures them as a multi-rail `o2ib` network.

Deploy `lustre-server` with the `lnet-networks` configuration option set when you need to override the default. For example, to select specific interfaces or exclude an automatically detected interface. For help planning the network configuration, see {ref}`LNet configuration <explanation-lustre-lnet-configuration>` and the [Lustre Operations Manual](https://doc.lustre.org/lustre_manual.xhtml#understandinglustrenetworking).

Set this option only during the initial deployment. Changes to `lnet-networks` after deployment are not applied.

The option accepts semicolon-separated network definitions in the format `<name>=<iface>[,<iface>...]`. For example, the following command configures `tcp` on `eth0` and a multi-rail `o2ib0` network on `ib0` and `ib1`:

:::{code-block} shell
juju deploy lustre-server \
  --channel latest/edge \
  --config lnet-networks="tcp=eth0; o2ib0=ib0,ib1" \
  -n <number-of-units>
:::

## Deploy the `filesystem-client` charm

To mount the Lustre filesystem on client nodes, deploy the `filesystem-client` subordinate charm,
with the `mountpoint` configuration set to the path Lustre should be mounted at on each client and
the `enable-lustre` configuration set to `true`. Note, if you deployed `lustre-server` with a
{ref}`custom LNet configuration <howto-deploy-deploy-lustre-custom-lnet>`, you must also include a
compatible `lnet-networks` configuration in the following command:

:::{code-block} shell
juju deploy filesystem-client \
  --channel latest/edge \
  --config mountpoint="/mnt/lustre" \
  --config enable-lustre=true
:::

Then integrate with the `lustre-server` application on the `filesystem` endpoint:

:::{code-block} shell
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

then view the file stripe layout:

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
