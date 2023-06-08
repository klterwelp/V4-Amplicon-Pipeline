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
# PURPOSE
# - Measure beta diversity using: bray curtis, jaccard, weighted/unweighted unifrac
# - Generate abundance filtered table 
# INPUT
# - table.qza (04_classify-filter)
# - rooted-tree.qza (05_phylogeny)
# - Set script/config.sh VARIABLES
#   - $MAPname : metadata path
# OUTPUT
# - filtered-table.qza (intermediate)
# - ab_filtered-table.qza (intermediate)
# - braycurtis_distance_matrix.qza (07_betaStats)
# - jaccard_distance_matrix.qza (07_betaStats)
# - abfilter_jaccard_distance_matrix.qza (07_betaStats)
# - unweighted_unifrac_distance_matrix.qza (07_betaStats)
# - weighted_unifrac_distance_matrix.qza (07_betaStats)

# ----------------- SCRIPT START -------------------- # 
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

for metrics in 'braycurtis' 'jaccard'
do 
qiime diversity beta \
    --i-table filtered-table.qza \
    --p-metric "$metrics" \
    --o-distance-matrix "${metrics}_distance_matrix.qza"
done
# generates beta diversity metrics for bray curtis and jaccard (without filtering)

qiime diversity beta \
    --i-table ab_filtered-table.qza \
    --p-metric 'jaccard' \
    --o-distance-matrix 'abfilter_jaccard_distance_matrix.qza'

# generates jaccard matrix with abundance filtering, use to see if rare taxa are main drivers 

for metrics in 'unweighted_unifrac' 'weighted_unifrac'
do 
qiime diversity beta-phylogenetic \
    --i-table filtered-table.qza \
    --p-metric "$metrics" \
    --o-distance-matrix "${metrics}_distance_matrix.qza"
done