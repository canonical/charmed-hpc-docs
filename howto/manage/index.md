# Manage your cluster

Administer a Charmed HPC cluster after initial deployment, from routine compute node operations to cluster-wide changes that require a maintenance window.

## Manage compute nodes and partitions

Adjust the configuration and state of individual compute nodes, and change partition capacity as demand on your cluster changes.

- {ref}`howto-manage-custom-node-config`
- {ref}`howto-manage-default-node-state`
- {ref}`howto-manage-node-state`
- {ref}`howto-manage-scale-partitions`

## Manage identity and security

Control user and group permissions, and manage how users are able to access the cluster.

- {ref}`howto-manage-users-and-groups`
- {ref}`howto-manage-user-authentication`

Replace the keys that secure internal cluster communication and REST API access.

- {ref}`howto-manage-rotate-auth-key`
- {ref}`howto-manage-rotate-jwt-key`

## Enable high-availability

- {ref}`howto-manage-single-slurmctld-to-high-availability`

:::{toctree}
:titlesonly:
:maxdepth: 1
:hidden:

Manage compute nodes and partitions <manage-compute-nodes>
Manage users and groups <manage-users-and-groups>
Manage user authentication <manage-user-authentication>
Rotate authentication keys <rotate-authentication-keys>
Migrate Slurm controller to high availability <migrate-slurmctld-to-high-availability>
:::
