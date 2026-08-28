---
relatedlinks: "[Slurm&#32;Workload&#32;Manager&#32;-&#32;Quick&#32;Start&#32;Administrator&#32;Guide&#32;-&#32;High&#32;Availability](https://slurm.schedmd.com/quickstart_admin.html#HA), [Slurm&#32;Workload&#32;Manager&#32;-&#32;slurm.conf&#32;-&#32;SlurmctldHost](https://slurm.schedmd.com/slurm.conf.html#OPT_SlurmctldHost)"
myst:
  html_meta:
    description: Instructions on how to migrate a single slurmctld unit in a Charmed HPC cluster to a high-availability setup by integrating a shared filesystem and adding backup units.
---

(howto-manage-single-slurmctld-to-high-availability)=
# Migrate Slurm controller to high availability

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

Once an additional `slurmctld` unit is added, the output of the `juju status`{l=shell} command should be similar to the following, varying by choice of shared file system - here CephFS:

:::{terminal}
juju status

Model  Controller   Cloud/Region         Version  SLA          Timestamp
slurm  charmed-hpc  localhost/localhost  3.6.0    unsupported  17:16:37Z

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

## Related topics

How-to guides:

* {ref}`Deploy a shared filesystem <howto-deploy-deploy-shared-filesystem>`

Explanation:

* {ref}`explanation-high-availability`
