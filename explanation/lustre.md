---
myst:
  html_meta:
    description: Discover how Charmed HPC deploys Lustre, the open source parallel distributed filesystem for HPC, using the lustre-server charm for scalable cluster storage.
relatedlinks: "[Lustre&#32;documentation](https://wiki.lustre.org/)"
---

(explanation-lustre)=
# Lustre

## Architecture

[Lustre](https://wiki.lustre.org/) is an open source parallel distributed filesystem designed for high-performance computing. It is the most widely used file system on the TOP500 list of HPC systems, providing high-throughput, scalable storage.

[The Lustre architecture](https://wiki.lustre.org/Lustre_Architecture_for_Admins) is composed of distinct "servers", providing specific filesystem functionality, and "targets", the storage for the holding server data:

- **Management Server (MGS)**: Maintains configuration data for the filesystem. Typically co-located with the first MDS.
- **Management Target (MGT)**: Stores MGS data. Modest requirements: [“the MGT is less than 100 MB even on the largest systems”](https://wiki.lustre.org/Lustre_Architecture_for_Admins#Management_Server_(MGS)).
- **Metadata Server (MDS)**: Manages the filesystem namespace. Keeps track of file directories, attributes, and location in the cluster, specifically which OST(s) hold file data.
- **Metadata Target (MDT)**: Stores MDS data. Must be on fast (low latency, high bandwidth) storage, such as NVMe drives.
- **Object Storage Server (OSS)**: Manages the file data. Handles I/O from Lustre clients.
- **Object Storage Target (OST)**: Stores OSS data. The unit of parallelism - each file stored within Lustre is split over one or more OSTs which, across multiple OSSes, can be accessed in parallel. High bandwidth storage required.

Lustre relies on a [backend filesystem](https://wiki.lustre.org/Lustre_Architecture_for_Admins#Backend_Filesystems) to perform data storage and handle low-level storage operations on targets. Two backend filesystems are supported: ldiskfs, a modification of the ext4 filesystem by the Lustre developers, and [ZFS](https://openzfs.org), a scalable filesystem supporting features that protect against data corruption. Lustre is overlaid on top of block storage devices formatted with one of these backend filesystems.

Clients access the filesystem by communicating with the MGS for configuration information, the MDS for metadata operations, and the OSSes directly for bulk data transfer. Communication occurs over [LNet](https://wiki.lustre.org/Lustre_Architecture_for_Admins#LNet_(Lustre_Networking)), Lustre's network layer, which supports TCP and high-speed interconnects such as InfiniBand.

## `lustre-server` charm

Lustre can be integrated into a Charmed HPC deployment using the `lustre-server` charm. This charm provides all Lustre server components - MGS, MDS, and OSS - in a single charm. It automates installation, LNet initialization, storage provisioning, and service lifecycle management.

### Integrating with clients

The `lustre-server` charm implements the `filesystem` endpoint, providing compatibility with the [`filesystem-client`](https://charmhub.io/filesystem-client) charm. Clients mount the Lustre filesystem by integrating a deployed `filesystem-client` with the `lustre-server` via Juju.

For instructions on deploying the `lustre-server` charm and integrating with client nodes using the `filesystem-client` charm, see {ref}`howto-deploy-deploy-lustre`.

### Package installation

The Lustre server packages are installed from a PPA maintained by the Ubuntu HPC team located at [`ppa:ubuntu-hpc/lustre-2.17`](https://launchpad.net/~ubuntu-hpc/+archive/ubuntu/lustre-2.17) and containing the latest stable release supported by the charm. Setup of the PPA and package install are handled automatically by the charm during its `install` hook.

(explanation-lustre-lnet-configuration)=
### LNet configuration

LNet is Lustre's network layer, responsible for communication between clients and server components. LNet functions using Lustre Network Drivers (LNDs), such as `tcp` for TCP/IP networks and `o2ib` for RDMA networks such as InfiniBand, Omni-Path, and RDMA over Converged Ethernet (RoCE). See the [Lustre Networking (LNET) Overview](https://wiki.lustre.org/Lustre_Networking_(LNET)_Overview) for further information.

The `lustre-server` charm can automatically detect network interfaces and configure LNet or a custom configuration can be provided using the `lnet-networks` option.

Both the `lustre-server` charm and `filesystem-client` charms perform network auto-detection by default, during the charm `install` hook. LNet is automatically configured with a `tcp` network using the default route Ethernet interface. If RDMA hardware such as InfiniBand is detected, an `o2ib` network is also configured. When multiple RDMA devices are present, all of them are configured in a multi-rail setup in the `o2ib` network.

Auto-detection can be overridden by setting the `lnet-networks` configuration value. The format for `lnet-networks` is `<name>=<iface>[,<iface>...]`, where `<name>` is the LNet network name and `<iface>` is the network interface. For example, to configure LNet with a net name of `tcp` using the `eth0` interface, and a net name of `o2ib0` using the `ib0` and `ib1` interfaces, the following flag would be used:

```shell
--config lnet-networks="tcp=eth0; o2ib0=ib0,ib1"
```

### Service placement

The charm automatically places the MGS and MDS on the initial leader unit, with all subsequent units becoming OSSes. A minimum of two units is required in a deployment: one combined MGS+MDS and one OSS unit. A single unit deployment is not supported.

### Storage

#### ZFS

Storage targets are provisioned using [ZFS](https://openzfs.org) as the backend filesystem, as it is fully supported out-of-the-box in Ubuntu. ZFS consists of pools and datasets.

A **ZFS pool** (_zpool_) is the top-level structure in ZFS storage. It consists of one or more **virtual devices** (_vdevs_). Vdevs are a grouping of disks in various configurations providing differing balances of redundancy, capacity, and performance. For example, a single, standalone disk can be a vdev, as can a mirror of disks, as can [the RAID levels provided by ZFS](https://openzfs.org/wiki/System_Administration#Low_level_storage): RAIDZ1-3. A zpool of vdevs provides the storage from which ZFS datasets are created.

A **ZFS dataset** is a subdivision of a zpool that can be configured like an independent filesystem. Datasets inherit properties from their parent pool but ZFS features can be individually tailored per dataset. For example, a particular dataset can be configured for more frequent snapshots than another dataset in the same zpool.

TODO: how Lustre charm uses ZFS

### Health checks

The charm runs health checks during its `update-status` event that verify:

- Peer relation data is present and consistent.
- Required kernel modules are loaded.
- Lustre service mounts are active.

If all health checks pass while the unit is in a `BlockedStatus`, the unit is restored to `ActiveStatus`.
