#!/bin/bash

#SBATCH --job-name=06_Alpha
#SBATCH --partition=PART_NAME
#SBATCH --mem=10000
#SBATCH --output=log/01_import.%j.out
#SBATCH --nodes=1
#SBATCH --error=log/01_import.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: abFilter_Diversity.slurm --------------------#

# PURPOSE
# - Filter feature table by prevalence and abundance
# - Generate alpha rarefaction curve
# - Generate alpha diversity metrics 
# - Test statistical signficant differences for alpha diversity 
# INPUT
# - table.qza (04_classify-filter)
# - rooted-tree.qza (05_phylogeny)
# - Set script/config.sh VARIABLES
# 	- $SAMPLINGdepth : sampling depth for rarefaction, default 10,000 
# 	- $MAPname : name of metadata file 
#   - $QiimeMax # max rarefaction depth, usually set to max number of reads from all samples !!! change to -> $MaxDepth
#   - $StepNumber # number of rarefaction depths to include between min (1) and $MaxDepth 
# OUTPUT
# - filtered-table.qza (intermediate) 
# 		- ASV table filtered by samples in metadata
# - alpha-rarefaction.qzv (visualization, check optimal rarefaction depth)
# - ab_filtered-table.qza (intermediate) 
# 		- abundance/prevalence filtered ASV table 
# - core-metrics-results/ (intermediate-qza/visualizations-qzv)
# 		-faith_pd_vector.qza
#		-observed_features_vector.qza 
#		-shannon_vector.qza
# 		-evenness_vector.qza
# - alpha-group-signifance/	(visualizations)								
# 		-faith-pd-group-significance.qzv	
#		-evenness-group-significance.qzv
#		-shannon-group-significance.qzv
#		-observed-features-group-significance.qzv

# ----------------- SCRIPT START -------------------- # 

# log directory
# script in main folder

# Source variable names from config.sh
echo -e "Source variable names from config.sh"
dos2unix ./config.sh
source ./config.sh

# record time and method name, env vars
echo -e $(date)

#Pre-prep for all analyses
echo -e “Beginning file prep for downstream analyses”

qiime feature-table filter-samples \
--i-table table.qza \
--m-metadata-file $MAPname \
--o-filtered-table filtered-table.qza
 
echo -e “finished file prep”
echo -e $(date)

#Diversity
#Rerun Diversity for appropriate depth if 10,000 is insufficient or incorrect
echo -e "Diversity"

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