#!/usr/bin/env bash
#SBATCH --job-name=hello_world
#SBATCH --partition=compute
#SBATCH --nodes=2
#SBATCH --error=error.txt
#SBATCH --output=output.txt

mpirun ./mpi_hello_world
