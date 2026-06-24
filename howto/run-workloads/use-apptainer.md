---
relatedlinks: "[Apptainer&#32;user&#32;documenation](https://apptainer.org/docs/user/latest/index.html)"
---

(howto-use-apptainer)=
# Use Apptainer

Apptainer can be used as a container runtime environment on Charmed HPC for running
containerized jobs. This guide provides examples of using Apptainer on Charmed HPC
to accomplish different tasks.

:::{admonition} New to Apptainer?
:class: note

If you're unfamiliar with using Apptainer in your jobs, see the [Apptainer user quick start guide](https://apptainer.org/docs/user/latest/quick_start.html)
for a high-level introduction to using Apptainer on HPC clusters.
:::

## Prerequisites

To successfully use Apptainer on your Charmed HPC cluster, you will at least need:

- A [deployed Slurm cluster](#howto-deploy-deploy-slurm).
- A [deployed shared filesystem](#howto-deploy-deploy-shared-filesystem).
- An [active Apptainer integration](#howto-manage-integrate-with-apptainer).

Once you have verified that Apptainer is integrated with your Charmed HPC, refer
to the sections below for the different ways that you can use Apptainer on Charmed HPC.

## Create a container image

### Use an image from a public container registry

Apptainer can pull pre-existing container images from public container registries.

For example, to pull a Valkey container image from Dockerhub and start a local
Valkey service on your cluster, run:

:::{code-block} shell
apptainer pull valkey.sif docker://ubuntu/valkey:7.2.10-24.04_stable
apptainer overlay create --size 1024 valkey.img
apptainer instance run --overlay valkey.img valkey.sif valkey
:::

Next, use `apptainer exec`{l=text} to test your connection to the Valkey service:

:::{code-block} shell
apptainer exec instance://valkey valkey-cli ping
:::

If the Valkey service is active, the output of `apptainer exec`{l=text} will be similar
to the following:

:::{terminal}
:copy:
:host: login

apptainer exec instance://valkey valkey-cli ping

PONG
:::

:::{admonition} Using images from other container registries
:class: note

You can use `apptainer help pull`{l=text} to view the full list of public
container registries Apptainer can pull images from.
:::

### Build your own image

:::{admonition} Before attempting to build your own container images
:class: warning

Check with your cluster administrator before attempting to build container images
on your Charmed HPC cluster. Each site has different policies about whether you
can build container images directly on your cluster, and some disallow
building container images on specific cluster resources such as login nodes.
:::

Apptainer can build container images using instructions from a container definition file.

For example, to build an Ubuntu 24.04 LTS-based container image with the `gfortran` compiler
pre-installed, create the container definition file _fortran-runtime.def_:

:::{code-block} shell
:caption: fortran-runtime.def
bootstrap: docker
from: ubuntu:24.04

%post
    apt-get -y update
    apt-get -y install gfortran

%test
    gfortran --version
    exit 0
:::

Then, use `apptainer build`{l=shell} to build your container image:

:::{code-block} shell
apptainer build fortran-runtime.sif fortran-runtime.def
:::

Next, create a simple Fortran program the prints "Hello world!" in the file _hello.f90_:

:::{code-block} fortran
:caption: hello.f90
PROGRAM hello_world
  IMPLICIT NONE
  PRINT *, "Hello world!"
END PROGRAM hello_world
:::

Now use your container with `apptainer exec`{l=text} to compile and run your Fortran program:

:::{code-block} shell
apptainer exec fortran-runtime.sif gfortran --output hello hello.f90
apptainer exec fortran-runtime.sif ./hello
:::

The output of `apptainer exec`{l=text} will be similar to the following:

:::{terminal}
:copy:
:host: login

apptainer exec fortran-runtime.sif ./hello

Hello world!
:::

## Provide your job's runtime environment

### Use the `apptainer`{l=shell} command

The `apptainer`{l=shell} command can be called directly in scripts to run job steps
in a container instance.

For example, to run some Python code using a containerized Python 3.13 interpreter, create
the job script _job.batch_. In this job script, you will call the `apptainer`{l=shell}
command directly, and you will submit the job to the partition `compute`:

:::{code-block} shell
:caption: job.batch
#!/usr/bin/env bash
#SBATCH --partition compute
#SBATCH --output job.out

apptainer pull python-3.13.sif docker://ubuntu/python:3.13-25.04
apptainer --silent exec python-3.13.sif \
  python3 -c 'import sys; print(f"Hello from Python {sys.version}!")'
:::

Now use `sbatch`{l=shell} to submit your job script to Slurm:

:::{code-block} shell
sbatch job.batch
:::

Then, use `cat`{l=shell} to view the results of your job after it completes:

:::{code-block} shell
cat job.out
:::

The output of `cat job.out`{l=shell} will be similar to the following:

:::{terminal}
:copy:
:host: login

cat job.out

Hello from Python 3.13.3 (main, Aug 14 2025, 11:53:40) [GCC 14.2.0]!
:::

[//]: # (TODO: Uncomment once https://github.com/canonical/slurm-charms/issues/143 is fixed.)
<!--
### Using the `--container` flag with `sbatch`{l=shell}

Declare in your batch script's front matter both the partition you want your workload to run within
and the container that will provide the runtime environment of your workload. For example, to create
a batch script with `compute ` selected as the partition your workload will run
within, and use a container with Python 3.13 pre-installed as the runtime environment:

:::{code-block} shell
#!/usr/bin/env bash
#SBATCH --partition compute
#SBATCH --container docker://ubuntu/python:3.13-25.04
#SBATCH --output stdout-%j.log

python3 --version
:::

Now submit your batch script using the `sbatch`{l=shell} command:

:::{terminal}
:copy:
:host: login

sbatch my-job.batch
:::
-->

### Use the `--container` flag with `srun`{l=shell}

Jobs submitted to Slurm with `srun`{l=shell} can be run inside a container instance using Apptainer.

For example, to submit a job to the partition `compute` that will use an Ubuntu 22.04 LTS container
image as the runtime environment, run:

:::{code-block} shell
srun --partition compute --container docker://ubuntu:22.04 \
  cat /etc/os-release | grep ^VERSION
:::

The output of `srun`{l=shell} will be similar to the following:

:::{terminal}
:copy:
:host: login

srun --partition compute --container docker://ubuntu:22.04 \
  cat /etc/os-release | grep ^VERSION

INFO:    Converting OCI blobs to SIF format
INFO:    Starting build...
INFO:    Fetching OCI image...
INFO:    Extracting OCI image...
INFO:    Inserting Apptainer configuration...
INFO:    Creating SIF file...
VERSION_ID="22.04"
VERSION="22.04.5 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
:::
