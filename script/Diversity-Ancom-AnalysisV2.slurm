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
	# taxonomy-silva.qza

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

