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

#------------------ SCRIPT INFO: Diversity-ANCOM-AnalysisV2.slurm --------------------#
# PURPOSE
# - This script does wayyyy too much
# INPUT
# - table.qza
# - rooted-tree.qza
# - taxonomy-silva.qza
# - Set script/config.sh VARIABLES
# 	- $metadataColumnName : metadata column of interest
# 	- $SAMPLINGdepth : rarefaction sampling depth
# 	- $MAPname : metadata file
# OUTPUT
# - filtered-table.qza
# - genus-table-silva.qza
# - comp-genus-table-silva.qza
# - taxa-barplots-silva.qzv
# - core-metrics-results/ (intermediate/visualizations)
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
# - ANCOM/
#		- L6-ANCOM-$metadataColumnName.qzv

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

qiime taxa collapse \
--i-table filtered-table.qza \
--i-taxonomy taxonomy-silva.qza \
--p-level 6 \
--o-collapsed-table genus-table-silva.qza

qiime composition add-pseudocount \
--i-table genus-table-silva.qza \
--o-composition-table comp-genus-table-silva.qza

echo -e “finished file prep”
echo -e $(date)

#TaxaPlots
echo -e "TaxaBarPlots"

qiime taxa barplot \
--i-table filtered-table.qza \
--i-taxonomy taxonomy-silva.qza \
--m-metadata-file $MAPname \
--o-visualization taxa-barplots-silva.qzv

echo -e "Barplots Complete"
echo -e $(date)

#Diversity
#Rerun Diversity for appropriate depth if 10,000 is insufficient or incorrect
echo -e "Diversity"

qiime diversity core-metrics-phylogenetic \
--i-phylogeny rooted-tree.qza \
--i-table filtered-table.qza \
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

#ANCOM
#Add analyses for each comparison performed in mapping files
echo -e "ANCOM"

qiime composition ancom \
--i-table comp-genus-table-silva.qza \
--m-metadata-file $MAPname \
--m-metadata-column $metadataColumnName \
--o-visualization L6-ANCOM-$metadataColumnName.qzv

echo -e "finished ANCOM"
echo -e $(date)

#File Sorting
#Make Changes to file names below as needed and add any new file names produced during additional steps
echo -e "Preparing Directories"

mkdir Taxonomy
mkdir Scripts
mkdir Diversity 
mkdir Differential_Abundance
mkdir Core_Analysis_Files
mkdir Core_Analysis_Files/Tables
mkdir Core_Analysis_Files/Sequences
mkdir Core_Analysis_Files/Phylogenetic_Trees
mkdir Core_Analysis_Files/Metadata_Files
mkdir Diversity/Alpha_Diversity_Results
mkdir Diversity/Beta_Diversity_Results
mkdir Diversity/Alpha_Diversity_Artifacts
mkdir Diversity/Beta_Diversity_Artifacts
mkdir Diversity/Beta_Diversity_Results/PCoA_Plots
mkdir Diversity/Beta_Diversity_Results/Stats

echo -e "Directories Built"
echo -e $(date)

#Migrate Files
echo -e "Begin Migrating Files"
mv filtered-table.qza Core_Analysis_Files/Tables
mv genus-table-silva.qza Core_Analysis_Files/Tables
mv comp-genus-table-silva.qza Core_Analysis_Files/Tables
mv taxa-barplots-silva.qzv Taxonomy
mv core-metrics-results/evenness_vector.qza Diversity/Alpha_Diversity_Artifacts
mv core-metrics-results/faith_pd_vector.qza Diversity/Alpha_Diversity_Artifacts
mv core-metrics-results/observed_features_vector.qza Diversity/Alpha_Diversity_Artifacts
mv core-metrics-results/rarefied_table.qza Core_Analysis_Files/Sequences
mv core-metrics-results/shannon_vector.qza Diversity/Alpha_Diversity_Artifacts
mv evenness-group-significance.qzv Diversity/Alpha_Diversity_Results
mv faith-pd-group-significance.qzv Diversity/Alpha_Diversity_Results
mv observed-features-group-significance.qzv Diversity/Alpha_Diversity_Results
mv shannon-group-significance.qzv Diversity/Alpha_Diversity_Results
mv core-metrics-results/bray_curtis_distance_matrix.qza Diversity/Beta_Diversity_Artifacts
mv core-metrics-results/bray_curtis_pcoa_results.qza Diversity/Beta_Diversity_Artifacts
mv core-metrics-results/jaccard_distance_matrix.qza Diversity/Beta_Diversity_Artifacts
mv core-metrics-results/jaccard_pcoa_results.qza Diversity/Beta_Diversity_Artifacts
mv core-metrics-results/unweighted_unifrac_distance_matrix.qza Diversity/Beta_Diversity_Artifacts
mv core-metrics-results/unweighted_unifrac_pcoa_results.qza Diversity/Beta_Diversity_Artifacts
mv core-metrics-results/weighted_unifrac_distance_matrix.qza Diversity/Beta_Diversity_Artifacts
mv core-metrics-results/weighted_unifrac_pcoa_results.qza Diversity/Beta_Diversity_Artifacts
mv core-metrics-results/bray_curtis_emperor.qzv Diversity/Beta_Diversity_Results/PCoA_Plots
mv core-metrics-results/jaccard_emperor.qzv Diversity/Beta_Diversity_Results/PCoA_Plots
mv core-metrics-results/unweighted_unifrac_emperor.qzv Diversity/Beta_Diversity_Results/PCoA_Plots
mv core-metrics-results/weighted_unifrac_emperor.qzv Diversity/Beta_Diversity_Results/PCoA_Plots
mv bray-curtis-$metadataColumnName-permanova.qzv Diversity/Beta_Diversity_Results/Stats
mv jaccard-$metadataColumnName-permanova.qzv Diversity/Beta_Diversity_Results/Stats
mv unweighted-unifrac-$metadataColumnName-permanova.qzv Diversity/Beta_Diversity_Results/Stats
mv weighted-unifrac-$metadataColumnName-permanova.qzv Diversity/Beta_Diversity_Results/Stats
mv L6-ANCOM-$metadataColumnName.qzv Differential_Abundance 

echo -e "File Sorting Completed"
echo -e $(date)

