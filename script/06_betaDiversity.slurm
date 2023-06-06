#!/bin/bash

#SBATCH --job-name=06_Beta
#SBATCH --partition=PART_NAME
#SBATCH --mem=10000
#SBATCH --output=log/01_import.%j.out
#SBATCH --nodes=1
#SBATCH --error=log/01_import.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: betaDiversity.slurm --------------------#
# log directory
# script in main folder

# Source variable names from config.sh
echo -e "Source variable names from config.sh"
dos2unix ./config.sh
source ./config.sh

# record time and method name, env vars
echo -e "$(date)"

#Pre-prep for all analyses
echo -e "Beginning file prep for downstream analyses"

qiime feature-table filter-samples \
--i-table table.qza \
--m-metadata-file "$MAPname" \
--o-filtered-table filtered-table.qza

qiime feature-table filter-features-conditionally \
--i-table filtered-table.qza \
--p-prevalence 0.1 \
--p-abundance 0.01 \
--o-filtered-table ab_filtered-table.qza

# Jaccard is sensitive to rare taxa so the ab_filtered-table will be used for that metric

echo -e "finished file prep"
echo -e "$(date)"