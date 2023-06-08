#!/bin/bash

#SBATCH --job-name=07_BetaStats
#SBATCH --partition=PART_NAME
#SBATCH --mem=10000
#SBATCH --output=log/01_import.%j.out
#SBATCH --nodes=1
#SBATCH --error=log/01_import.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: betaStats.slurm --------------------#

