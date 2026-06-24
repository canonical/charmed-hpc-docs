(howto-deploy-deploy-shared-filesystem)=
# How to deploy a shared filesystem

Charmed HPC allows automatic integration with shared filesystems using the
[filesystem-client](https://charmhub.io/filesystem-client) charm. This how-to guide shows you how to
deploy `filesystem-client` to integrate with externally managed shared filesystems.

:::{admonition} Terraform modules available
:class: note

If you plan on using Terraform to handle your deployment, we also provide Terraform modules to setup a
cloud managed NFS server on the [`charmed-hpc-terraform`][hpc-tf] repository, with
[examples][nfs-tf-examples] on how to deploy the modules.
:::

[hpc-tf]: https://github.com/canonical/charmed-hpc-terraform
[nfs-tf-examples]: https://github.com/canonical/charmed-hpc-terraform/blob/main/examples

## Prerequisites

- A [Slurm cluster](#howto-deploy-deploy-slurm).

## Deploy an external filesystem server

External servers that provide a shared filesystem cannot be integrated directly. Instead,
we can use a [proxy charm](https://documentation.ubuntu.com/juju/latest/reference/charm/#proxy-charm) in order to expose
the required information to applications managed by Juju.

:::::::{tab-set}

::::::{tab-item} NFS

To integrate with an external NFS server, you will require:
- An externally managed NFS server.
- The server's hostname.
- The exported path.
- (optional) the port.

Each public cloud has its own procedure to deploy a public NFS server. Provided here are links to
the set up procedures on a few well-known public clouds.

::::{grid} 1 1 2 3

:::{grid-item-card} Amazon Web Services
:link: https://docs.aws.amazon.com/filegateway/latest/files3/nfs-fileshare-quickstart-settings.html
:link-alt: docs.aws.amazon.com
Set up information.
:::

:::{grid-item-card} Microsoft Azure
:link: https://learn.microsoft.com/en-us/azure/storage/files/storage-files-quick-create-use-linux
:link-alt: learn.microsoft.com
Set up information.
:::

:::{grid-item-card} Google Cloud Platform
:link: https://cloud.google.com/filestore/docs/create-instance-gcloud
:link-alt: cloud.google.com
Set up information.
:::
::::

However, if only a minimal server for testing is necessary, a small NFS server can be set up with LXD.

::::{dropdown} Deploy an NFS server on LXD

First, launch a virtual machine using [LXD](https://canonical.com/lxd):

:::{code-block} shell
$ snap install lxd
$ lxd init --auto
$ lxc launch ubuntu:24.04 nfs-server --vm
$ lxc shell nfs-server
:::

Inside the LXD virtual machine, set up an NFS kernel server that exports
a `/data` directory:

:::{code-block} shell
apt update && apt upgrade
apt install nfs-kernel-server
mkdir -p /data
cat << 'EOF' > /etc/exports
/srv     *(ro,sync,subtree_check)
/data    *(rw,sync,no_subtree_check,no_root_squash)
EOF
exportfs -a
systemctl restart nfs-kernel-server
:::

:::{admonition} Verification
:class: note

You can verify if the NFS server is exporting the desired directories
by using the command `showmount -e localhost`{l=shell} while inside the LXD virtual machine.
:::

Grab the network address of the LXD virtual machine and exit the current shell session:

:::{code-block} shell
hostname -I
exit
:::

::::


After gathering all the required information, you can deploy the `nfs-server-proxy` charm in order to
expose the externally managed server inside a Juju model.

:::{code-block} shell
juju deploy nfs-server-proxy \
  --channel latest/edge \
  --config hostname=<server hostname> \
  --config path=<exported path> \
  --config port=<server port>
:::

::::::

::::::{tab-item} CephFS

To integrate with an external CephFS share, you will require:
 - The unique identifier of the cluster (commonly known as fsid).
 - The name of the filesystem within the Ceph cluster.
 - The exported path of the filesystem.
 - The list of hostnames for MON nodes of the Ceph cluster.
 - The username with permissions to access the filesystem.
 - The cephx key for the username.

Here, a Ceph cluster will be set up using [MicroCeph][ceph].

[ceph]: https://canonical-microceph.readthedocs-hosted.com/v19.2.0-squid

First, launch a virtual machine using [LXD](https://ubuntu.com/lxd):

:::{code-block} shell
snap install lxd
lxd init --auto
lxc launch ubuntu:24.04 cephfs-server --vm
lxc shell cephfs-server
:::

Inside the LXD virtual machine, set up MicroCeph to export a Ceph filesystem.

:::{code-block} shell
# Setup environment
ln -s /bin/true /usr/local/bin/udevadm
apt-get -y update
apt-get -y install ceph-common jq
snap install microceph

# Bootstrap Microceph
microceph cluster bootstrap

# Add a storage disk to Microceph
microceph disk add loop,2G,3
:::

We will create two new disk pools, then
assign the two pools to a new filesystem with the name `cephfs`.

:::{code-block} shell
# Create a new data pool for our filesystem
microceph.ceph osd pool create cephfs_data

# and a metadata pool for the same filesystem
microceph.ceph osd pool create cephfs_metadata

# Create a new filesystem that uses the two created data pools
microceph.ceph fs new cephfs cephfs_metadata cephfs_data
:::

We will also use `fs-client` as the username for the
clients, and expose the whole directory tree (`/`) in read-write mode (`rw`).

:::{code-block} shell
microceph.ceph fs authorize cephfs client.fs-client / rw
:::

:::{admonition} Verification
:class: note

You can verify if the CephFS server is working correctly by using the command
`microceph.ceph fs status cephfs` while inside the LXD virtual machine.
:::

To gather the required information for proxying the externally managed Ceph filesystem:

:::{code-block} shell
export HOST=$(hostname -I | tr -d '[:space:]'):6789
export FSID=$(microceph.ceph -s -f json | jq -r '.fsid')
export CLIENT_KEY=$(microceph.ceph auth print-key client.fs-client)
:::

Print the required information for reference and then exit the current shell session:

:::{code-block} shell
echo $HOST
echo $FSID
echo $CLIENT_KEY
exit
:::

Having collected all the required information, you can deploy the `cephfs-server-proxy` charm to
expose the externally managed Ceph filesystem inside a Juju model.

:::{code-block} shell
juju deploy cephfs-server-proxy \
  --channel latest/edge \
  --config fsid=<value of $FSID> \
  --config sharepoint=cephfs:/ \
  --config monitor-hosts="<value of $HOST>" \
  --config auth-info=fs-client:<value of $CLIENT_KEY>
:::

::::::

:::::::


## Deploy the filesystem-client

To add the `filesystem-client` charm, which mounts a shared filesystem to the cluster nodes:

:::{code-block} shell
juju deploy filesystem-client \
  --channel latest/edge \
  --config mountpoint='/scratch' \
  --config noexec=true
:::

The `mountpoint` configuration represents the path that the filesystem will be mounted onto.

`filesystem-client` is a [subordinate charm](https://documentation.ubuntu.com/juju/latest/reference/charm/#subordinate-charm)
that can automatically mount any shared filesystems for the application related with it.
In this case, we will relate it to the `sackd` and `slurmd` applications to have shared storage
between all the login and compute nodes in the cluster:

:::{code-block} shell
juju integrate sackd:juju-info filesystem-client:juju-info
juju integrate slurmd:juju-info filesystem-client:juju-info
:::

## Relate the filesystem client with the filesystem provider

Every filesystem provider can be integrated with the filesystem client using the
`filesystem` endpoint.

:::{code-block} shell
juju integrate filesystem-client:filesystem <filesystem-provider>:filesystem
:::

Afterwards, test that the filesystem is accessible to read and write from the `slurmd` application
machines:

:::{code-block} shell
juju ssh slurmd/0 -- touch /scratch/script.py
juju ssh slurmd/1 -- stat /scratch/script.py
:::
