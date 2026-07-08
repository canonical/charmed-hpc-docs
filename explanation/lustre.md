---
myst:
  html_meta:
    description: Discover how Charmed HPC deploys Lustre, the open source parallel distributed filesystem for HPC, using the lustre-server charm for scalable cluster storage.
relatedlinks: "[Lustre&#32;documentation](https://wiki.lustre.org/)"
---

(explanation-lustre)=
# Lustre

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

:::{admonition} Experimental
:class: warning

The `lustre-server` charm is in an experimental state and is not yet ready for production use. Functionality is expected to change significantly over the next iterations.
:::

### Package installation

TODO

### LNet configuration

TODO

### Service placement

TODO

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

### Integrating with clients

The `lustre-server` charm implements the `filesystem` endpoint, providing compatibility with the [`filesystem-client`](https://charmhub.io/filesystem-client) charm. Clients mount the Lustre filesystem by integrating a deployed `filesystem-client` with the `lustre-server` via Juju.

For instructions on deploying the `lustre-server` charm and integrating with client nodes, see {ref}`howto-deploy-deploy-lustre`.
