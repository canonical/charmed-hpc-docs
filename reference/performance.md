---
myst:
  html_meta:
    description: Performance benchmarks for Charmed HPC on Microsoft Azure, covering GPU flops and InfiniBand interconnect latency and bandwidth.
---

(reference-performance)=
# Performance

Performance values for the [Charmed HPC Benchmarks](https://github.com/canonical/charmed-hpc-benchmarks/) running on Microsoft Azure are provided on this page. Steps for reproducing these results are available in the [benchmarking suite documentation](https://github.com/canonical/charmed-hpc-benchmarks/blob/main/README.md). These results are intended to provided best-possible marks for performance to help guide tuning and identification of bottlenecks. Real-world performance may fluctuate depending on factors such as varying cluster workloads and resource contention.

## Metrics

GPU performance and InfiniBand interconnect performance are measured on suitably equipped VMs to illustrate the ability of Charmed HPC to leverage the HPC capabilities of the cloud.

GPU performance is measured for both single precision workloads, where speed and larger scale is preferred over numerical accuracy, and double precision workloads, where additional accuracy is required.

Latency and bandwidth are measured for InfiniBand to determine how quickly a message can traverse the network,  as well as the network throughput. These metrics govern the ability of the cluster to run MPI, and other distributed memory dependent applications across nodes.

### GPU flops

GPU single and double precision floating point operations per second (flops) are measured by the [gpu_burn](http://wili.cc/blog/gpu-burn.html) stress test, with [code modifications by the ReFrame developers](https://github.com/reframe-hpc/reframe/tree/v4.7.4/hpctestlib/microbenchmarks/gpu/src/gpu_burn), built using the CUDA toolkit.

### InfiniBand interconnect latency and bandwidth

InfiniBand RDMA latency and bandwidth are measured by the [OSU Micro-Benchmarks](https://mvapich.cse.ohio-state.edu/benchmarks/) for MPI and the [Intel MPI Benchmarks (IMB)](https://github.com/intel/mpi-benchmarks), built with OpenMPI and GCC. All runs are performed on two cluster compute nodes, one MPI process per node.

Point-to-point performance is measured with the OSU `osu_bw` and `osu_latency` benchmarks, as well as the IMB MPI-1 `PingPong` benchmark.

Collective performance is measured with the OSU `osu_alltoall` and `osu_allreduce` benchmarks, as well as the IMB MPI-1 `AllReduce` benchmark.

## Method

All performance tests run under the following base software:

* Juju 3.6.3
* Ubuntu 24.04
* ReFrame 4.7.4

on a Charmed HPC cluster deployed on Microsoft Azure, with the following specifications:

:::{csv-table}
:name: performance-cluster
:header: >
: application, VM size, charm, channel, revision

`login`, 1x `Standard_D2as_v6`, sackd, edge, 13
`slurmctld`, 1x `Standard_D2as_v6`, slurmctld, edge, 95
`slurmdbd`, 1x `Standard_D2as_v6`, slurmdbd, edge, 87
`mysql`, 1x `Standard_D2as_v6`, mysql, 8.0/stable, 313
`nc4as-t4-v3`, 1x `Standard_NC4as_T4_v3`, slurmd, edge, 116
`hb120rs-v3`, 2x `Standard_HB120rs_v3`, slurmd, edge, 116
`nfs-share-client`, N/A - subordinate charm, filesystem-client, edge, 15
`nfs-share-server`, 1x `Standard_D2as_v6`, nfs-server-proxy, edge, 21
:::

Where no specific VM features are required, VM instances are `Standard_D2as_v6`, the default size for Juju 3.6.3.

### Tesla T4 GPU - `Standard_NC4as_T4_v3` instances

GPU tests are built with the following Ubuntu software package:

* `nvidia-cuda-toolkit_12.0.140~12.0.1-4build4`

Runs are performed on a single [`Standard_NC4as_T4_v3`](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/gpu-accelerated/ncast4v3-series) instance, equipped with an NVIDIA Tesla T4 and deployed as Juju application `nc4as-t4-v3` as described in the [table above](#performance-cluster).

### HDR InfiniBand - `Standard_HB120rs_v3` instances

MPI tests are built and run with the following Ubuntu software packages:

* `openmpi-bin_4.1.6-7ubuntu2`
* `libopenmpi-dev_4.1.6-7ubuntu2`
* `gcc-13_13.3.0-6ubuntu2~24.04`

Runs are performed on two [`Standard_HB120rs_v3`](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/high-performance-compute/hbv3-series) instances, equipped with 200 Gb/s HDR InfiniBand and deployed as Juju application `hb120rs-v3` as described in the [table above](#performance-cluster).

## Results

The results presented are the best performance achieved by the corresponding metric across all tests.

:::{csv-table}
:header: >
: metric, VM size, result, unit, note

Tesla T4 single precision, 1x `Standard_NC4as_T4_v3`, 4454, Gflops/s,
Tesla T4 double precision, 1x `Standard_NC4as_T4_v3`, 252, Gflops/s,
InfiniBand latency, 2x `Standard_HB120rs_v3`, 1.59, us, 1 byte transfer size
InfiniBand bandwidth, 2x `Standard_HB120rs_v3`, 196.06, Gb/s, 4 MiB transfer size
:::

For comparison of InfiniBand results, Microsoft-published performance data for the `HBv3-series` is available [on the Azure website](https://learn.microsoft.com/en-us/azure/virtual-machines/hbv3-performance).
