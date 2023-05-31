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

# file: Diversity-ANCOM-Analysis.slurm
# input files needed in main folder:
	# table.qza
	# $MAPname (DescriptiveNamemap.txt) 
		# remove rows we are not interested in analyzing for this run
	# rooted-tree.qza

# input in Config file: 
	# set $metadataColumnName variable to metadata column of interest
	# set $SAMPLINGdepth variable to sampling depth 
	# set $MAPname variable to the mapping file with the samples we will analyze 

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

