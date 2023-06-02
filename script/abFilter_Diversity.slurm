#!/bin/bash
#SBATCH --job-name=Total-Analysis
#SBATCH --partition=scavenger
#SBATCH --mem-per-cpu=25000
#SBATCH --output=log/JA-Analysis.%j.out
#SBATCH -c 4
#SBATCH --error=log/JA-Analysis.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=klt75@duke.edu

#------------------ SCRIPT INFO: abFilter_Diversity.slurm --------------------#

# PURPOSE
# - Filter feature table by prevalence and abundance
# - Generate core diversity metrics based on filtered table
# - Test statistical signficant differences for alpha and beta diversity metrics 
# INPUT
# - table.qza (04_classify-filter)
# - rooted-tree.qza (05_phylogeny)
# - Set script/config.sh VARIABLES
# 	- $metadataColumnName : metadata column to test
# 	- $SAMPLINGdepth : sampling depth for rarefaction, found from 10A_rarefaction
# 	- $MAPname : name of metadata file 
# OUTPUT
# - filtered-table.qza (intermediate) 
# 		- ASV table filtered by samples in metadata
# - ab_filtered-table.qza (intermediate) 
# 		- abundance/prevalence filtered ASV table 
# - core-metrics-results/ (intermediate-qza/visualizations-qzv)
# 		-faith_pd_vector.qza
#		-observed_features_vector.qza 
#		-shannon_vector.qza
# 		-evenness_vector.qza
# 		-unweighted_unifrac_distance_matrix.qza
#		-weighted_unifrac_distance_matrix.qza
#		-jaccard_distance_matrix.qza
#		-bray_curtis_distance_matrix.qza
#		-unweighted_unifrac_pcoa_results.qza
#		-weighted_unifrac_pcoa_results.qzv
#		-jaccard_pcoa_results.qzv
#		-bray_curtis_pcoa_results.qzv
#		-unweighted_unifrac_emperor.qzv
#		-weighted_unifrac_emperor.qzv
#		-jaccard_emperor.qzv
#		-bray_curtis_emperor.qzv
# - alpha-group-signifance/	(visualizations)								(only require $MAPname)
# 		-faith-pd-group-significance.qzv	
#		-evenness-group-significance.qzv
#		-shannon-group-significance.qzv
#		-observed-features-group-significance.qzv
# - beta-group-significance/ (visualizations)								(require $metadataColumnName)
#		-weighted-unifrac-$metadataColumnName-permanova.qzv 
#		-unweighted-unifrac-$metadataColumnName-permanova.qzv
#		-bray-curtis-$metadataColumnName-permanova.qzv
#		-jaccard-$metadataColumnName-permanova.qzv

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

qiime feature-table filter-features-conditionally \
--i-table filtered-table.qza \
--p-prevalence 0.1 \
--p-abundance 0.01 \
--o-filtered-table ab_filtered-table.qza
 

echo -e “finished file prep”
echo -e $(date)


#Diversity
#Rerun Diversity for appropriate depth if 10,000 is insufficient or incorrect
echo -e "Diversity"

qiime diversity core-metrics-phylogenetic \
--i-phylogeny rooted-tree.qza \
--i-table ab_filtered-table.qza \
--p-sampling-depth $SAMPLINGdepth \
--m-metadata-file $MAPname \
--output-dir core-metrics-results

echo -e "finished Diversity"
echo -e $(date)

#Diversity statistics
#Modify metadata column based on mapping file, add comparisons as needed

echo -e "Diversity Stats"

qiime diversity alpha-group-significance \
--i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
--m-metadata-file $MAPname \
--o-visualization faith-pd-group-significance.qzv

qiime diversity alpha-group-significance \
--i-alpha-diversity core-metrics-results/evenness_vector.qza \
--m-metadata-file $MAPname \
--o-visualization evenness-group-significance.qzv

qiime diversity alpha-group-significance \
--i-alpha-diversity core-metrics-results/shannon_vector.qza \
--m-metadata-file $MAPname \
--o-visualization shannon-group-significance.qzv

qiime diversity alpha-group-significance \
--i-alpha-diversity core-metrics-results/observed_features_vector.qza \
--m-metadata-file $MAPname \
--o-visualization observed-features-group-significance.qzv

qiime diversity beta-group-significance \
--i-distance-matrix core-metrics-results/weighted_unifrac_distance_matrix.qza \
--m-metadata-file $MAPname \
--m-metadata-column $metadataColumnName \
--p-pairwise \
--o-visualization weighted-unifrac-$metadataColumnName-permanova.qzv 

qiime diversity beta-group-significance \
--i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
--m-metadata-file $MAPname \
--m-metadata-column $metadataColumnName \
--p-pairwise \
--o-visualization unweighted-unifrac-$metadataColumnName-permanova.qzv 

qiime diversity beta-group-significance \
--i-distance-matrix core-metrics-results/bray_curtis_distance_matrix.qza \
--m-metadata-file $MAPname \
--m-metadata-column $metadataColumnName \
--p-pairwise \
--o-visualization bray-curtis-$metadataColumnName-permanova.qzv 

qiime diversity beta-group-significance \
--i-distance-matrix core-metrics-results/jaccard_distance_matrix.qza \
--m-metadata-file $MAPname \
--m-metadata-column $metadataColumnName \
--p-pairwise \
--o-visualization jaccard-$metadataColumnName-permanova.qzv 

echo -e "Finished Diversity Statistics"
echo -e $(date)

