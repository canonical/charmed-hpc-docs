---
myst:
  html_meta:
    description: Discover how Charmed HPC deploys Lustre, the open source parallel distributed filesystem for HPC, using the lustre-server charm for scalable cluster storage.
relatedlinks: "[Lustre&#32;wiki](https://wiki.lustre.org/), [Lustre&#32;manual](https://doc.lustre.org/lustre_manual.xhtml)"
---

(explanation-lustre)=
# Lustre

## Architecture

[Lustre](https://wiki.lustre.org/) is an open source parallel distributed filesystem designed for high-performance computing. It is the most widely used filesystem on the TOP500 list of HPC systems, providing high-throughput, scalable storage.

[The Lustre architecture](https://wiki.lustre.org/Lustre_Architecture_for_Admins) consists of "servers" that provide filesystem services and storage "targets" that hold their data:

- **Management Server (MGS)**: Maintains configuration data for the filesystem. Typically co-located with the first MDS.
- **Management Target (MGT)**: Stores MGS data. Modest requirements: [“the MGT is less than 100 MB even on the largest systems”](https://wiki.lustre.org/Lustre_Architecture_for_Admins#Management_Server_(MGS)).
- **Metadata Server (MDS)**: Manages the filesystem namespace. Keeps track of file directories, attributes, and location in the cluster, specifically which OST(s) hold file data.
- **Metadata Target (MDT)**: Stores MDS data. Must be on fast (low latency, high bandwidth) storage, such as NVMe drives.
- **Object Storage Server (OSS)**: Manages the file data. Handles I/O from Lustre clients.
- **Object Storage Target (OST)**: Stores file data managed by an OSS. OSTs are Lustre's unit of data-storage parallelism: files can be striped across multiple OSTs and accessed in parallel. High bandwidth storage required.

Lustre relies on a [backend filesystem](https://wiki.lustre.org/Lustre_Architecture_for_Admins#Backend_Filesystems) to perform data storage and handle low-level storage operations on targets. Two backend filesystems are supported: ldiskfs, a modification of the ext4 filesystem by the Lustre developers, and [ZFS](https://openzfs.org), a scalable filesystem supporting features that protect against data corruption. Lustre is overlaid on top of block storage devices formatted with one of these backend filesystems.

Clients access the filesystem by communicating with the MGS for configuration information, the MDS for metadata operations, and the OSSes directly for bulk data transfer. Communication occurs over [LNet](https://wiki.lustre.org/Lustre_Architecture_for_Admins#LNet_(Lustre_Networking)), Lustre's network layer, which supports TCP and high-speed interconnects such as InfiniBand.

## `lustre-server` charm

Lustre can be integrated into a Charmed HPC deployment using the [`lustre-server`](https://charmhub.io/lustre-server) charm. This charm provides all Lustre server components - MGS, MDS, and OSS - in a single charm. It automates installation, LNet initialization, storage setup, and service lifecycle management.

### Integrating with clients

The `lustre-server` charm implements the `filesystem` endpoint, providing compatibility with the [`filesystem-client`](https://charmhub.io/filesystem-client) charm. Clients mount the Lustre filesystem by integrating a deployed `filesystem-client` with the `lustre-server` via Juju.

For instructions on deploying the `lustre-server` charm and integrating with client nodes using the `filesystem-client` charm, see {ref}`howto-deploy-deploy-lustre`.

### Package installation

The Lustre server packages are installed from a PPA maintained by the Ubuntu HPC team located at [`ppa:ubuntu-hpc/lustre-2.17`](https://launchpad.net/~ubuntu-hpc/+archive/ubuntu/lustre-2.17) and containing the latest stable release supported by the charm. Setup of the PPA and package install are handled automatically by the charm during its `install` hook.

(explanation-lustre-lnet-configuration)=
### LNet configuration

LNet is Lustre's network layer, responsible for communication between clients and server components. It supports multiple Lustre Network Drivers (LNDs), including:

- `tcp` for networks using TCP/IP.
- `o2ib` for RDMA networks such as InfiniBand and RoCE.

See the [Lustre Networking (LNET) Overview](https://wiki.lustre.org/Lustre_Networking_(LNET)_Overview) for further information.

By default, the `lustre-server` and `filesystem-client` charms perform network auto-detection, configuring a `tcp` network on the Ethernet interface that provides the default route. If RDMA interfaces are detected, the charms also configure them as a multi-rail `o2ib` network.

Auto-detection can be overridden by setting the `lnet-networks` charm configuration value. Set this option when Lustre traffic must use specific interfaces or when an automatically detected interface must be excluded. The option uses format:

```
<name>=<iface>[,<iface>...]
```

where `<name>` is the LNet network name and `<iface>` is the network interface. For example:

```shell
--config lnet-networks="tcp=eth0; o2ib0=ib0,ib1"
```

configures LNet with a net name of `tcp` using the `eth0` interface, and a net name of `o2ib0` using the `ib0` and `ib1` interfaces.

Note, the `lustre-server` and `filesystem-client` charms must share LNet configurations (compatible `lnet-networks` values) otherwise they will not be able to communicate and the Lustre filesystem will not mount.

### Service placement

Storage attachments determine the role of each `lustre-server` unit. Attaching storage to `mgt-mdt` configures the unit as a combined MGS+MDS, while attaching storage to `ost` configures the unit as an OSS.

A deployment requires one combined MGS+MDS unit and at least one OSS unit. Additional OSS units can be added to increase the filesystem's capacity and aggregate I/O bandwidth.

### Storage

#### ZFS

Storage targets are provisioned using [ZFS](https://openzfs.org) as the backend filesystem, as it is fully supported out-of-the-box in Ubuntu. ZFS consists of pools and datasets.

A **ZFS pool** (_zpool_) is the top-level structure in ZFS storage. It consists of one or more **virtual devices** (_vdevs_). A vdev is a grouping of disks in various configurations providing differing balances of redundancy, capacity, and performance. For example, a single, standalone disk can be a vdev, as can a mirror of disks, as can [the RAID levels provided by ZFS](https://openzfs.org/wiki/System_Administration#Low_level_storage): RAIDZ1-3. A zpool of vdevs provides the storage from which ZFS datasets are created.

A **ZFS dataset** is a subdivision of a zpool that can be configured like an independent filesystem. Datasets inherit properties from their parent pool but ZFS features can be individually tailored per dataset. For example, a particular dataset can be configured for more frequent snapshots than another dataset in the same zpool.

#### ZFS layout created by the `lustre-server` charm

Storage is attached to charm units through two Juju storage endpoints:

- `mgt-mdt` supplies storage for the Management Target (MGT) and Metadata Target (MDT). Attaching storage to this endpoint assigns the unit the combined MGS+MDS role.
- `ost` supplies storage for the Object Storage Target (OST). Attaching storage to this endpoint assigns the unit the OSS role.

The charm combines the storage attached to each unit into a ZFS pool, with the pool layout determined by the unit's role.

On the combined MGS+MDS unit, the charm groups the disks attached to `mgt-mdt` into a zpool of mirrored vdevs. This layout prioritizes the reliability and random-I/O performance required for filesystem metadata. As each disk is mirrored, an even number of disks is required and usable capacity is approximately half of the total raw capacity.

On each OSS unit, the charm combines all disks attached to `ost` into a single RAIDZ2 vdev. The resulting zpool provides one OST per OSS. RAIDZ2 uses the equivalent capacity of two disks for parity and can tolerate the failure of any two disks in the vdev. A minimum of three disks is required and the approximate usable capacity of an OSS is the combined capacity of all its disks minus two disks.

### Health checks

The charm runs health checks during its `update-status` event that verify:

- Peer relation data is present and consistent.
- Required kernel modules are loaded.
- Lustre service mounts are active.

If all health checks pass while the unit is in a `BlockedStatus`, the unit is restored to `ActiveStatus`.
