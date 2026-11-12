(explanation-interconnects)=
# High-speed interconnects

A high-speed interconnect is a networking technology which enables performant communication and data transfer between nodes in a cluster. Communication is both high-bandwidth (large throughput) and low-latency (minimal delay). Performant communication is particularly beneficial for applications which can span multiple compute nodes, such as applications that employ the Message Passing Interface (MPI) standard for parallel computing.

This performance is achieved through Remote Direct Memory Access (RDMA): a mechanism that enables a networked (remote) computer to directly access the memory of another computer, independently of either computer's CPU and operating system. NVIDIA InfiniBand is a common implementation of RDMA.

(explanation-rdma-driver)=
## Interconnect driver installation and management

### Auto-install

Charmed HPC installs [`rdma-core`](https://github.com/linux-rdma/rdma-core) from the operating system repositories when the `slurmd` charm is deployed on a compute node. The `rdma-core` package automatically detects available interconnect hardware and sets up the appropriate userspace libraries and services to enable RDMA. Drivers for supported NVIDIA ConnectX InfiniBand adapters are provided automatically by the operating system kernel. The [`openmpi-bin`](https://www.open-mpi.org/) package is installed from repositories on compute nodes to allow for the running of MPI applications.

#### OpenMPI UCX override

Debian and Ubuntu repositories ship the `openmpi-bin` package with [Unified Communication X UCX](https://openucx.readthedocs.io/en/master/) disabled in configuration file `/etc/openmpi/openmpi-mca-params.conf` in order to [suppress warning messages](https://github.com/open-mpi/ompi/issues/8367) when running on a system without a high-speed interconnect. UCX is a framework designed for high-performance computing communication and is the default preferred communication method for InfiniBand networks in OpenMPI. With UCX disabled, OpenMPI falls back to other communication methods, which can be less performant. In order to improve performance on InfiniBand Charmed HPC clusters, UCX is re-enabled by the `slurmd` charm on install. The parameters in `/etc/openmpi/openmpi-mca-params.conf` are overridden to remove all instances of `ucx` and `uct` from the lists of disabled OpenMPI components. For example:

```
mtl = ^ofi
btl = ^uct,openib,ofi
pml = ^ucx
osc = ^ucx,pt2pt
```

becomes:

```
mtl = ^ofi
btl = ^openib,ofi
osc = ^pt2pt
```

### Interconnect management

High-speed interconnects typically require management software to orchestrate the communication between nodes. This software can be referred to as a subnet manager or fabric manager. Implementation is cloud-specific, with public clouds often providing a managed solution without access to the management software. For implementation details on supported clouds, refer to:

- {ref}`reference-interconnects`
