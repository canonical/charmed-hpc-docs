(howtos)=
# How-to guides

Detailed steps for key operations and common tasks when working with Charmed HPC.

## Initialize your environment

Install dependencies and initialize the backing cloud for your cluster.

- {ref}`Initialize cloud environment <howto-initialize-cloud-environment>`

(howto-deploy)=
## Deploy

Deploy and configure the core components of your cluster.

- {ref}`Deploy Slurm <howto-deploy-deploy-slurm>`
- {ref}`Deploy a shared filesystem <howto-deploy-deploy-shared-filesystem>`
- {ref}`Deploy an identity provider <howto-deploy-deploy-identity-provider>`

(howto-integrate)=
## Integrate with other tools

Connect your cluster to observability platforms and workload tools.

- {ref}`howto-manage-integrate-with-apptainer`
- {ref}`howto-manage-integrate-with-cos`
- {ref}`howto-manage-integrate-with-influxdb`
- {ref}`howto-integrate-email-notifications`

(howto-manage)=
## Manage your cluster

Operate your cluster after deployment, including node-level tasks and cluster-wide maintenance.

- {ref}`Manage compute nodes and partitions <howto-manage-compute-nodes>`
- {ref}`Rotate authentication keys <howto-manage-rotate-slurm-keys>`
- {ref}`howto-manage-single-slurmctld-to-high-availability`

## Run workloads

Submit jobs and run containerized workloads on your cluster.

- {ref}`howto-use-apptainer`

## Clean up resources

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
