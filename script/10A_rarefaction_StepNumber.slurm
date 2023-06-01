#!/bin/bash
#SBATCH --job-name=10A_rarefaction
#SBATCH --partition=scavenger
#SBATCH --mem=10000
#SBATCH --output=log/10A_rarefaction.%j.out
#SBATCH --nodes=1
#SBATCH --error=log/10A_rarefaction.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=klt75@duke.edu

#------------------ SCRIPT INFO: 10A_rarefaction.slurm --------------------#

# PURPOSE
# - Generate alpha rarefaction curve from 1:$QiimeMax reads 
# - Determine rarefaction depth for alpha diversity based on alpha-rarefaction.qzv 
# INPUT
# - filtered-table.qza
# - rooted-tree.qza
# - Set script/config.sh VARIABLES
#   - $QiimeMax
#   - $StepNumber
#   - $MAPname
# OUTPUT
# - alpha-rarefaction.qzv

# ----------------- SCRIPT START -------------------- # 

# Source variable names from config.sh
echo -e "Source variable names from config.sh"
dos2unix ./config.sh
source ./config.sh


# alpha, beta diversity and PCoa analysis
# need to add the variable "QiimeMax" based on the highest number of reads in all samples
# need to add variable StepNumber based on number of steps between highest and 1


echo -e $(date)
# rarefaction, check sample depth & seq read depth sufficient or not.
echo -e "alpha diversity, rarefaction..." 
qiime diversity alpha-rarefaction \
  --i-table filtered-table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-max-depth $QiimeMax \
  --p-steps $StepNumber \
  --m-metadata-file $MAPname \
  --o-visualization alpha-rarefaction.qzv

  echo -e "finished rarefaction..."
echo -e $(date)
