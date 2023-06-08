#!/bin/bash

#SBATCH --job-name=07_AlphaStats
#SBATCH --partition=PART_NAME
#SBATCH --mem=10000
#SBATCH --output=log/01_import.%j.out
#SBATCH --nodes=1
#SBATCH --error=log/01_import.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: alphaStats.slurm --------------------#

# PURPOSE
# - Test statistical signficant differences for alpha diversity based on numeric/categorical metadata
# INPUT
# - table.qza (04_classify-filter)
# - rooted-tree.qza (05_phylogeny)
# - Set script/config.sh VARIABLES
# 	- $MAPname : name of metadata file 
# OUTPUT
# - alpha-group-signifance/	(visualizations)								
# 	-faith-pd-group-significance.qzv	
#		-evenness-group-significance.qzv
#		-shannon-group-significance.qzv
#		-observed-features-group-significance.qzv
#   -faith-numeric-correlation.qzv
#   -evenness-numeric-correlation.qzv
#   -shannon-numeric-correlation.qzv
#   -observed-features-numeric-correlation.qzv

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
 
echo -e "finished file prep"
echo -e "$(date)"

echo -e "Running alpha diversity statistical significance tests"

echo -e "Running group statistical tests (categorical)" 

for metric in 'shannon' 'observed_features' 'evenness' 'faith_pd'
do 
echo $metric
qiime diversity alpha-group-significance \
  --i-alpha-diversity "${metric}_vector.qza" \
  --m-metadata-file "$MAPname" \
  --o-visualization "${metric}-group-significance.qzv"
done
# for-loop to test statistically significant differences between groups of alpha diversity values 

echo -e "$(date)"
echo -e "Done calculating group alpha diversity stats" 

echo -e "Running correlational statistical tests (categorical)" 
for metric in 'shannon' 'observed_features' 'evenness' 'faith_pd'
do 
echo $metric
qiime diversity alpha-correlation \
  --i-alpha-diversity "${metric}_vector.qza" \
  --m-metadata-file "$MAPname" \
  --o-visualization "${metric}-numeric-correlation.qzv"
done
# for-loop to test statistically significant correlations for numeric metadata and alpha diversity 

echo -e "$(date)"
echo -e "Done calculating correlational (numeric) alpha diversity stats" 