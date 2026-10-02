#!/usr/bin/env bash
#SBATCH --job-name=favorite-lts-mascot
#SBATCH --partition=compute
#SBATCH --nodes=2
#SBATCH --error=mascot_error.txt
#SBATCH --output=mascot_output.txt

apptainer exec workload.sif generate --rows 1000000
apptainer run workload.sif favorite_lts_mascot.csv --output graph.out
