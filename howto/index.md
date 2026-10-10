(howtos)=
# How-to guides

Detailed steps for key operations and common tasks when working with Charmed HPC.

## Environment initialization

- {ref}`Initialize cloud environment <howto-initialize-cloud-environment>`

(howto-deploy)=
## Deployment

- {ref}`Deploy Slurm <howto-deploy-deploy-slurm>`
- {ref}`Deploy Lustre <howto-deploy-deploy-lustre>`
- {ref}`Deploy a shared filesystem <howto-deploy-deploy-shared-filesystem>`
- {ref}`Deploy an identity provider <howto-deploy-deploy-identity-provider>`

(howto-integrate)=
## Integration with other tools

Connect your cluster to observability platforms and workload tools.

- {ref}`howto-manage-integrate-with-cos`
- {ref}`howto-manage-integrate-with-influxdb`
- {ref}`howto-integrate-email-notifications`
- {ref}`howto-manage-integrate-with-apptainer`

(howto-manage)=
## Cluster management

- {ref}`Manage compute nodes and partitions <howto-manage-compute-nodes>`
- {ref}`Manage users and groups <howto-manage-manage-users-and-groups>`
- {ref}`Rotate authentication keys <howto-manage-rotate-slurm-keys>`
- {ref}`howto-manage-single-slurmctld-to-high-availability`

## Running workloads

- {ref}`howto-use-apptainer`

## Resource clean up

Remove previously deployed components and free cloud resources when they are no longer needed.

- {ref}`Clean up Slurm <howto-cleanup-slurm>`
- {ref}`Clean up cloud resources <howto-cleanup-cloud-resources>`

:::{toctree}
:titlesonly:
:maxdepth: 1
:hidden:

Initialize cloud environment <initialize-cloud-environment>
Deploy <deploy/index>
Integrate with other tools <integrate/index>
Manage your cluster <manage/index>
Run workloads <run-workloads/index>
Clean up resources <cleanup/index>
:::
