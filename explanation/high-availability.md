---
relatedlinks: "[Slurm&#32Workload&#32Manager&#32-&#32Quick&#32Start&#32Administrator&#32Guide&#32-&#32High&#32Availability](https://slurm.schedmd.com/quickstart_admin.html#HA), [Slurm&#32Workload&#32Manager&#32-&#32Quick&#32Start&#32Administrator&#32Guide&#32-&#32Configuration](https://slurm.schedmd.com/quickstart_admin.html#Config), [Slurm&#32Workload&#32Manager&#32-&#32slurm.conf&#32-&#32SlurmctldHost](https://slurm.schedmd.com/slurm.conf.html#OPT_SlurmctldHost), [Ubuntu&#32High-Performance&#32Computing&#32Spec:&#32slurmctld&#32high-availability&#32implementation&#32in&#32Charmed&#32HPC](https://hackmd.io/@ubuntu-hpc/HkqyL5K4le)"
---

(explanation-high-availability)=
# High Availability

High availability (HA) refers to the ability of a system to continue functioning despite component failures. The main motivation for HA is to eliminate single points of failure and minimize system downtime. HA can be provided through component redundancy, such as a computer cluster with multiple controllers that continues to function even if a controller has failed.

When an HA cluster distributes incoming requests across multiple controllers simultaneously, it is referred to as an active-active setup. In contrast, an active-passive setup designates one controller as the primary, which handles all requests while the others remain on standby, ready for one to take over should the primary fail.

(explanation-slurmctld-high-availability)=
## Slurmctld high availability

Slurm's `slurmctld` controller service has built-in HA support through an active-passive setup. The primary controller serves all Slurm client requests while backup controllers wait in standby. Controllers are defined by `SlurmctldHost` entries in the _slurm.conf_ configuration file, with the first entry being the primary and all others being backups, with backup fail-over order being the order defined in the file.

Charmed HPC uses Slurm's built-in HA support alongside [Juju's horizontal scaling capabilities](https://documentation.ubuntu.com/juju/latest/reference/scaling/) to allow for the `slurmctld` charm to run with multiple units in an HA configuration.

(explanation-slurmctld-high-availability-state-save-location)=
### Shared `StateSaveLocation` using `filesystem-client` charm

For `slurmctld` HA to function, all `slurmctld` controllers require mounting of the same shared file system to provide a common [`StateSaveLocation`](https://slurm.schedmd.com/slurm.conf.html#OPT_StateSaveLocation) directory to hold controller state data. This directory governs the responsiveness and throughput of the cluster, so it should be hosted on a file system with low latency. It is therefore recommended that the file system **not be the same as the file system used for the cluster compute nodes** to avoid I/O-intensive user jobs from impacting `slurmctld` responsiveness.

To allow for flexibility in choosing a shared file system for the `StateSaveLocation`, Charmed HPC implements support for the [`filesystem-client` charm](https://github.com/canonical/filesystem-charms) within the `slurmctld` charm. This enables users to integrate with the file system of their choice, such as their own CephFS deployment, a cloud-specific managed file system, or another that meets latency requirements.

:::{admonition} Appropriate file system
:class: warning

The Slurm developers [do not recommended NFS](https://slurm.schedmd.com/quickstart_admin.html#Config) for the shared file system due to inadequate performance.
:::

The `slurmctld` charm automatically configures the mount point for the shared file system when integrated with the `filesystem-client` on the `mount` endpoint. The shared file system is mounted on all `slurmctld` units at `/srv/slurmctld-statefs`. The `StateSaveLocation` is then set to a sub-directory: `/srv/slurmctld-statefs/checkpoint`.

To allow for this automatic mount point configuration, the `filesystem-client` must be deployed without `--config mountpoint` set. Attempting to integrate a `filesystem-client` where `--config mountpoint` has been set will result in a charm error.

### Single `slurmctld` migration to high availability

In a non-HA setup (a single `slurmctld` unit), `StateSaveLocation` data is stored on the unit local disk at `/var/lib/slurm/checkpoint`. Before `slurmctld` backup units can be added to enable high availability, the `slurmctld` charm must be integrated with a `filesystem-client` on the `mount` endpoint to provide the necessary shared storage. On integration, the `StateSaveLocation` data is automatically copied from the local disk to the shared file system provided by the `filesystem-client`.

Once the file system integration is complete, `juju add-unit` can be used to add backup units. It is **not possible to remove the `filesystem-client` integration** and return to a non-HA setup once the migration has completed. To avoid data loss, the files and directories in the local  `/var/lib/slurm/checkpoint` are left untouched following migration. Specific steps can be found in the [Migrating a single `slurmctld` to high availability](howto-manage-single-slurmctld-to-high-availability) how-to section.

Note that **this migration requires cluster downtime**: the `slurmctld` service is stopped by the charm for the transfer duration and restarted when the `StateSaveLocation` data is in place on the shared file system. To minimize downtime, `StateSaveLocation` data is first copied to the shared file system while the `slurmctld` service is live, then the service is stopped and the difference in `StateSaveLocation` data is synchronized.

Be aware that attempting to add units to up `slurmctld` without a `filesystem-client` will cause the new units to enter `BlockedStatus` until the `filesystem-client` is integrated.

(explanation-slurmctld-high-availability-etc-slurm)=
### Shared `/etc/slurm` configuration data

In an HA setup, all `slurmctld` instances require matching configuration files. That is, _slurm.conf_, _gres.conf_, and other Slurm configuration files must be identical on all `slurmctld` hosts. To achieve this in Charmed HPC, the shared file system enabled by the `filesystem-client` is used.

Similarly to `StateSaveLocation`, data in `/etc/slurm` is migrated to `/srv/slurmctld-statefs/etc/slurm` on `filesystem-client` integration. The `/etc/slurm` directory is then replaced with a symbolic link to `/srv/slurmctld-statefs/etc/slurm` on all `slurmctld` instances to ensure all access the same configuration files.

To avoid data loss, any existing `/etc/slurm/` is backed up to a date-stamped directory on the unit's local disk, for example `/etc/slurm_20250620_161437` for a backup performed on 2025-06-20 at 16:14:37. To prevent non-leaders from reading partially written configuration files, updates to files are made atomically via [slurmutils](https://github.com/canonical/slurmutils/).

The `slurmctld` charm leader in a Charmed HPC cluster handles all controller configuration operations. The leader generates cluster keys and all configuration files while non-leader units defer until these files appear in the shared storage.

Note that the charm leader under Juju and the primary `slurmctld` instance under Slurm may or may not be the same unit. Juju itself determines the charm leader while Slurm primary and backups are managed independently by the `slurmctld` charm in _slurm.conf_. Primary and backup order is determined by unit join order, with the most recent joining `slurmctld` instance being the lowest priority backup (the last `SlurmctldHost` entry in _slurm.conf_).
