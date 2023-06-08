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
# PURPOSE
# - Test statistical signficant differences for beta diversity 
# INPUT
# /diversity.slurm 
#   -unweighted_unifrac_distance_matrix.qza (diversity.slurm)
#   -weighted_unifrac_distance_matrix.qza (diversity.slurm)
#   -jaccard_distance_matrix.qza (diversity.slurm)
#   -bray_curtis_distance_matrix.qza (diversity.slurm)
# - Set script/config.sh VARIABLES
# 	- $MAPname : name of metadata file 
#   - $metadataColumnNames : array of metadata column names to check for significant differences
# OUTPUT
# - "${metric}-${col}-permanova.qzv"
#   $metric = 'bray_curtis' 'jaccard' 'unweighted_unifrac' 'weighted_unifrac'
#       assigned with $diversityMetrics var
#   $col = $metadataColumnNames column name 

# ----------------- SCRIPT START -------------------- # 

# log directory
# script in main folder

# Source variable names from config.sh
echo -e "Source variable names from config.sh"
dos2unix ./config.sh
source ./config.sh

# record time and method name, env vars
echo -e "$(date)"

diversityMetrics=('bray_curtis' 'jaccard' 'unweighted_unifrac' 'weighted_unifrac' 'deicode' 'abfilter_jaccard')
# beta diversity metrics generated from 06_diversity.slurm, can remove some if not interested

for col in "${metadataColumnNames[@]}"
do
echo "Calculating beta significance for $col" 
    for metric in "${diversityMetrics[@]}"
    do 
    echo "Calculating significance of $metric for $col"
    qiime diversity beta-group-significance \
        --i-distance-matrix "${metric}_distance_matrix.qza" \
        --m-metadata-file $MAPname \
        --m-metadata-column "${col}" \
        --p-pairwise \
        --o-visualization "${metric}-${col}-permanova.qzv"
    done
done

# Purpose of nested for-loop:
    # for every column in metadataColumnNames 
    # calculate diversity beta-group-significance 
    # for each diversity metric




