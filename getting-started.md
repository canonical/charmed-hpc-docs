---
myst:
  html_meta:
    description: Tutorial to get started with Charmed HPC by building a cluster, submitting batch jobs, and using container images with Juju, Slurm, Ceph, and Apptainer.
---

(tutorial-getting-started-with-charmed-hpc)=
# Getting started with Charmed HPC

This tutorial takes you through multiple aspects of Charmed HPC, such as:

* Building a small Charmed HPC cluster with a shared filesystem
* Preparing and submitting a multi-node batch job to your Charmed HPC cluster's workload scheduler
* Creating and using a container image to provide the runtime environment for a submitted batch job

By the end of this tutorial, you will have worked with a variety of open source projects, such as:

- Multipass
- Juju
- Charms
- Apptainer
- Ceph
- Slurm

This tutorial assumes that you have had some exposure to high-performance computing concepts such
as job scheduling, but does not assume prior experience building HPC clusters. This tutorial
also does not expect you to have any prior experience with the listed projects above.

<!-- How long should this tutorial take to complete? -->

:::{admonition} Using Charmed HPC in production
:class: note

The Charmed HPC cluster built in this tutorial is for learning purposes and should not be
used as the basis for a production HPC cluster. For more in-depth steps on how to deploy
a fully operational Charmed HPC cluster, see [Charmed HPC's How-to guides](#howtos).
:::

## Prerequisites

To successfully complete this tutorial, you will need:

* At least 8 CPU cores, 16GB RAM, and 40GB storage available
* [Multipass installed](https://canonical.com/multipass/install)
* An active internet connection

## Create a virtual machine with Multipass

First, download a copy of the cloud initialization (cloud-init) file,
[charmed-hpc-tutorial-cloud-init.yml], that defines the underlying cloud infrastructure
for the virtual machine.

For this tutorial, the file includes instructions for creating and configuring your LXD
machine cloud `localhost` with the `charmed-hpc-controller` Juju controller and creating
workload and submit scripts for the example jobs. The cloud-init step will be completed
as part of the virtual machine launch and will not be something you need to set up
manually.

You can expand the dropdown below to view the full cloud-init file before
downloading onto your local system:

::::{dropdown} charmed-hpc-tutorial-cloud-init.yml
:::{literalinclude} /reuse/tutorial/charmed-hpc-tutorial-cloud-init.yml
:caption: [charmed-hpc-tutorial-cloud-init.yml]
:language: yaml
:linenos:
:::
::::

Now, from the local directory holding the cloud-init file, launch a virtual machine using Multipass:

[charmed-hpc-tutorial-cloud-init.yml]: /reuse/tutorial/charmed-hpc-tutorial-cloud-init.yml

:::{code-block} shell
multipass launch 26.04 \
  --name charmed-hpc-tutorial \
  --cloud-init charmed-hpc-tutorial-cloud-init.yml \
  --memory 16G --disk 40G --cpus 8 --timeout 1000
:::

The virtual machine launch process should take five minutes or less to complete, but may
take longer depending on the speed of your network. Upon completion of the launch process,
check the status of cloud-init to confirm that all processes completed successfully.

First, enter the `charmed-hpc-tutorial` virtual machine:

:::{code-block} shell
multipass shell charmed-hpc-tutorial
:::

Then, use `cloud-init status`{l=shell} to check if the `charmed-hpc-tutorial` was
successfully initialized:

:::{code-block} shell
cloud-init status --long
:::

The output of `cloud-init status`{l=shell} will be similar to the following:

:::{terminal}
:user: ubuntu
:host: charmed-hpc-tutorial
:copy:

cloud-init status --long

status: done
extended_status: done
boot_status_code: enabled-by-generator
last_update: Thu, 01 Jan 1970 00:03:45 +0000
detail: DataSourceNoCloud [seed=/dev/sr0]
errors: []
recoverable_errors: {}
:::

If the status shows `done` and there are no errors, then you are ready to move on to
deploying the cluster charms.

## Deploy Slurm and shared filesystem

Next, you will deploy Slurm and the filesystem. The Slurm components of your deployment
will be composed of:

- The Slurm management daemon: `slurmctld`
- Two Slurm compute daemons: `slurmd`, grouped in a partition named `tutorial-partition`
- The authentication and credential kiosk daemon: `sackd` to provide the login node

First, use `juju add-model`{l=shell} to create the `slurm` model on your cloud `localhost`:

:::{code-block} shell
juju add-model slurm localhost
:::

Then, use `juju deploy`{l=shell} to deploy `sackd`, `slurmctld`, and `slurmd`:

:::{code-block} shell
juju deploy slurmctld \
  --base "ubuntu@26.04" \
  --channel "edge" \
  --constraints="virt-type=virtual-machine"

juju deploy slurmd tutorial-partition \
  --num-units 2 \
  --base "ubuntu@26.04" \
  --channel "edge" \
  --config default-node-state=idle \
  --constraints="virt-type=virtual-machine"

juju deploy sackd \
  --base "ubuntu@26.04" \
  --channel "edge" \
  --constraints="virt-type=virtual-machine"
:::

After that, use `juju integrate`{l=shell} to integrate the Slurm services together:

:::{code-block} shell
juju integrate slurmctld sackd
juju integrate slurmctld tutorial-partition
:::

<!-- Note about use of --constraints="virt-type=virtual-machine" ? -->

Next, use `juju deploy`{l=shell} to deploy the filesystem pieces, which are:

- `microceph`, the distributed storage system
- `ceph-fs` to expose the MicroCeph cluster as a shared filesystem using [CephFS](https://docs.ceph.com/en/reef/cephfs/)
- `filesystem-client` to mount the filesystem, named `scratch`

:::{code-block} shell
juju deploy microceph \
  --channel squid/stable \
  --constraints="virt-type=virtual-machine mem=4G root-disk=20G"

juju deploy ceph-fs \
  --channel squid/stable

juju deploy filesystem-client scratch \
  --base "ubuntu@26.04" \
  --channel latest/edge \
  --config mountpoint=/scratch
:::

After that, use `juju add-storage`{l=shell} to add storage to microceph:

:::{code-block} shell
juju add-storage microceph/0 osd-standalone=loop,2G,3
:::

Then, use `juju integrate`{l=shell} to integrate the filesystem components
together aqnd with Slurm:

:::{code-block} shell
juju integrate scratch ceph-fs
juju integrate ceph-fs microceph
juju integrate scratch tutorial-partition
juju integrate scratch sackd
:::

Your Charmed HPC cluster will become active within a few minutes. The output of the
`juju status`{l=shell} will be similar to the following:

:::{terminal}
:user: ubuntu
:host: charmed-hpc-tutorial
:copy:

juju status

Model  Controller              Cloud/Region         Version  SLA          Timestamp
slurm  charmed-hpc-controller  localhost/localhost  3.6.27   unsupported  16:35:02-06:00

App                 Version          Status  Scale  Charm              Channel       Rev  Exposed  Message
ceph-fs             19.2.3           active      1  ceph-fs            squid/stable  300  no       Unit is ready
microceph                            active      1  microceph          squid/stable  296  no       (workload) charm is ready
sackd               25.11.2-1ubu...  active      1  sackd                             67  no
scratch                              active      3  filesystem-client  latest/edge    28  no       Integrated with `cephfs` provider
slurmctld           25.11.2-1ubu...  active      1  slurmctld                        144  no       primary - UP
tutorial-partition  25.11.2-1ubu...  active      2  slurmd                           165  no

Unit                   Workload  Agent  Machine  Public address  Ports          Message
ceph-fs/0*             active    idle   5        10.2.171.6                     Unit is ready
microceph/0*           active    idle   4        10.2.171.220                   (workload) charm is ready
sackd/0*               active    idle   3        10.2.171.238    6818/tcp
  scratch/2            active    idle            10.2.171.238                   Mounted filesystem at `/scratch`
slurmctld/0*           active    idle   0        10.2.171.197    6817,9092/tcp  primary - UP
tutorial-partition/0*  active    idle   1        10.2.171.79     6818/tcp
  scratch/1            active    idle            10.2.171.79                    Mounted filesystem at `/scratch`
tutorial-partition/1   active    idle   2        10.2.171.120    6818/tcp
  scratch/0*           active    idle            10.2.171.120                   Mounted filesystem at `/scratch`

Machine  State    Address       Inst id        Base          AZ                    Message
0        started  10.2.171.197  juju-9890c4-0  ubuntu@26.04  charmed-hpc-tutorial  Running
1        started  10.2.171.79   juju-9890c4-1  ubuntu@26.04  charmed-hpc-tutorial  Running
2        started  10.2.171.120  juju-9890c4-2  ubuntu@26.04  charmed-hpc-tutorial  Running
3        started  10.2.171.238  juju-9890c4-3  ubuntu@26.04  charmed-hpc-tutorial  Running
4        started  10.2.171.220  juju-9890c4-4  ubuntu@24.04  charmed-hpc-tutorial  Running
5        started  10.2.171.6    juju-9890c4-5  ubuntu@24.04  charmed-hpc-tutorial  Running
:::


<!-- Add summary of what the last few steps accomplished and what juju status is showing-->

## Copy files onto cluster

The workload files that were created during the cloud initialization step now need
to be copied onto the cluster filesystem from the virtual machine filesystem.

You will use `juju exec`{l=shell} and `juju scp`{l=shell} to make the new
example directories, set appropriate permissions, and then finally copy the files over:

:::{code-block} shell
juju exec -u sackd/0 -- \
  sudo mkdir /scratch/mpi_example /scratch/apptainer_example

juju exec -u sackd/0 -- \
  sudo chown $USER: /scratch/*

juju scp submit_hello.sh mpi_hello_world.c \
  sackd/0:/scratch/mpi_example

juju scp submit_apptainer_mascot.sh generate.py workload.py workload.def \
  sackd/0:/scratch/apptainer_example
:::

The `/scratch` directory is mounted on the compute nodes and will be used to read
and write from during the batch jobs.

## Run a batch job

In the following steps, you will compile a small Hello World MPI script and run it
by submitting a batch job to Slurm.

### Compile

First, SSH into the login node, `sackd/0`:

:::{code-block} shell
juju ssh sackd/0
:::

This will place you in your home directory `/home/ubuntu`. Next, you will need to move
to the `/scratch/mpi_example` directory, install the Open MPI libraries needed for
compiling, and then compile the _mpi_hello_world.c_ file by running the `mpicc` command:

:::{code-block} shell
cd /scratch/mpi_example
sudo apt install build-essential openmpi-bin libopenmpi-dev
mpicc -o mpi_hello_world mpi_hello_world.c
:::

For quick referencing, the two files for the MPI Hello World example are provided in dropdowns here:

::::{dropdown} mpi_hello_world.c
:::{literalinclude} /reuse/tutorial/mpi_hello_world.c
:caption: [mpi_hello_world.c]
:language: c
:::
::::

::::{dropdown} submit_hello.sh
:::{literalinclude} /reuse/tutorial/submit_hello.sh
:caption: [submit_hello.sh]
:language: bash
:::
::::

[mpi_hello_world.c]: /reuse/tutorial/mpi_hello_world.c
[submit_hello.sh]: /reuse/tutorial/submit_hello.sh

### Submit batch job

Now, submit your batch job to the queue using `sbatch`{l=shell}:

:::{code-block} shell
sbatch submit_hello.sh
:::

Your job will complete after a few seconds. The generated _output.txt_ file will look
similar to the following:

:::{terminal}
:user: ubuntu
:host: login
:copy:

cat output.txt

Hello world from processor juju-640476-1, rank 0 out of 2 processors
Hello world from processor juju-640476-2, rank 1 out of 2 processors
:::

The batch job successfully spread the MPI job across two nodes that were able to report
back their MPI rank to a shared output file.

## Run a container job

Next you will go through the steps to generate a random sample of Ubuntu mascot votes
and plot the results. The process requires Python and a few specific libraries so
you will use Apptainer to build a container job and run the job on the cluster.

### Set up Apptainer

Apptainer must be deployed and integrated with the existing Slurm deployment using Juju
and these steps need to be completed from the `charmed-hpc-tutorial` environment; to
return to that environment from within `sackd/0`, use the `exit`{l=shell} command.

First, use `juju deploy`{l=shell} to deploy Apptainer:

:::{code-block} shell
juju deploy apptainer --base "ubuntu@26.04" --channel "latest/edge"
:::

Next, use `juju integrate`{l=shell} to integrate Apptainer with Slurm:

:::{code-block} shell
juju integrate apptainer slurmctld
juju integrate apptainer sackd
juju integrate apptainer tutorial-partition
:::

After a few minutes, the output `juju status` will look similar to the following:

:::{terminal}
:user: ubuntu
:host: charmed-hpc-tutorial
:copy:

juju status

Model  Controller              Cloud/Region         Version  SLA          Timestamp
slurm  charmed-hpc-controller  localhost/localhost  3.6.27   unsupported  16:45:32-06:00

App                 Version          Status  Scale  Charm              Channel       Rev  Exposed  Message
apptainer           1.5.3            active      3  apptainer          latest/edge    22  no
ceph-fs             19.2.3           active      1  ceph-fs            squid/stable  300  no       Unit is ready
microceph                            active      1  microceph          squid/stable  296  no       (workload) charm is ready
sackd               25.11.2-1ubu...  active      1  sackd                             67  no
scratch                              active      3  filesystem-client  latest/edge    28  no       Integrated with `cephfs` provider
slurmctld           25.11.2-1ubu...  active      1  slurmctld                        144  no       primary - UP
tutorial-partition  25.11.2-1ubu...  active      2  slurmd                           165  no

Unit                   Workload  Agent  Machine  Public address  Ports          Message
ceph-fs/0*             active    idle   5        10.2.171.6                     Unit is ready
microceph/0*           active    idle   4        10.2.171.220                   (workload) charm is ready
sackd/0*               active    idle   3        10.2.171.238    6818/tcp
  apptainer/0*         active    idle            10.2.171.238
  scratch/2            active    idle            10.2.171.238                   Mounted filesystem at `/scratch`
slurmctld/0*           active    idle   0        10.2.171.197    6817,9092/tcp  primary - UP
tutorial-partition/0*  active    idle   1        10.2.171.79     6818/tcp
  apptainer/1          active    idle            10.2.171.79
  scratch/1            active    idle            10.2.171.79                    Mounted filesystem at `/scratch`
slurmd/1               active    idle   2        10.2.171.120    6818/tcp
  apptainer/2          active    idle            10.2.171.120
  scratch/0*           active    idle            10.2.171.120                   Mounted filesystem at `/scratch`

Machine  State    Address       Inst id        Base          AZ                    Message
0        started  10.2.171.197  juju-9890c4-0  ubuntu@26.04  charmed-hpc-tutorial  Running
1        started  10.2.171.79   juju-9890c4-1  ubuntu@26.04  charmed-hpc-tutorial  Running
2        started  10.2.171.120  juju-9890c4-2  ubuntu@26.04  charmed-hpc-tutorial  Running
3        started  10.2.171.238  juju-9890c4-3  ubuntu@26.04  charmed-hpc-tutorial  Running
4        started  10.2.171.220  juju-9890c4-4  ubuntu@24.04  charmed-hpc-tutorial  Running
5        started  10.2.171.6    juju-9890c4-5  ubuntu@24.04  charmed-hpc-tutorial  Running
:::

### Build the container image using `apptainer`

Before you can submit your container workload to your Charmed HPC cluster,
you must build the container image from the build recipe. The build recipe file
_workload.def_ defines the environment and libraries that will be in the container image.

To build the image, log back into to the cluster login node, change to the
example directory, and run `apptainer build`:

:::{code-block} shell
juju ssh sackd/0
cd /scratch/apptainer_example
apptainer build workload.sif workload.def
:::

The files for the Apptainer Mascot Vote example are provided here for reference.

::::{dropdown} generate\.py
:::{literalinclude} /reuse/tutorial/generate.py
:caption: [generate.py]
:language: python
:linenos:
:::
::::

::::{dropdown} workload\.py
:::{literalinclude} /reuse/tutorial/workload.py
:caption: [workload.py]
:language: python
:linenos:
:::
::::

::::{dropdown} workload.def
:::{literalinclude} /reuse/tutorial/workload.def
:caption: [workload.def]
:::
::::

::::{dropdown} submit_apptainer_mascot.sh
:::{literalinclude} /reuse/tutorial/submit_apptainer_mascot.sh
:caption: [submit_apptainer_mascot.sh]
:::
::::

[workload.py]: /reuse/tutorial/workload.py
[generate.py]: /reuse/tutorial/generate.py
[workload.def]: /reuse/tutorial/workload.def
[submit_apptainer_mascot.sh]: /reuse/tutorial/submit_apptainer_mascot.sh



### Use the image to run jobs

Now that you have built the container image, you can submit a job to the
cluster that uses the new  _workload.sif_ image to generate one million
lines in a table and then uses the resulting _favorite_lts_mascot.csv_ to
build the bar plot:

:::{code-block} shell
sbatch submit_apptainer_mascot.sh
:::

To view the status of the job while it is running, run `squeue`.

Once the job has completed, view the generated bar plot that will look
similar to the following:

:::{terminal}
:user: ubuntu
:host: login
:copy:

cat graph.out

────────────────────── Favorite LTS mascot ───────────────────────
│Bionic Beaver    ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 101124.00
│Dapper Drake     ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 99889.00
│Focal Fossa      ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 99956.00
│Hardy Heron      ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 99872.00
│Jammy Jellyfish  ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 99848.00
│Lucid Lynx       ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 99651.00
│Noble Numbat     ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 100625.00
│Precise Pangolin ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 99670.00
│Trusty Tahr      ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 99366.00
│Xenial Xerus     ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 99999.00
:::


## Summary and clean up

In this tutorial, you:

- Deployed and integrated Slurm and a shared filesystem
- Launched an MPI batch job and saw cross-node communication results
- Built a container image with Apptainer and used it to run a batch job and
- generate a bar plot

Now that you have completed the tutorial, if you would like to completely remove the
virtual machine, return to your local terminal and `multipass delete` the virtual
machine as follows:

:::{code-block} shell
multipass delete --purge charmed-hpc-tutorial
:::

## Next steps

Now that you have gotten started with Charmed HPC, check out the
{ref}`explanation` section for details on important concepts and the
{ref}`howtos` for how to use more of Charmed HPC's features.
