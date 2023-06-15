#!/bin/bash

#SBATCH --job-name=06_diversity
#SBATCH --partition=PART_NAME
#SBATCH --mem=10000
#SBATCH --output=log/01_import.%j.out
#SBATCH --nodes=1
#SBATCH --error=log/01_import.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: 06_diversity.slurm --------------------#

# PURPOSE
# - Filter feature table by prevalence and abundance
# - Generate core diversity metrics based on filtered table
# - Generate additional diversity metrics outside of core diversity 

# INPUT
# - table.qza (04-classify)
# - rooted-tree.qza (05-phylogeny)
# -taxonomy-${REF_DATABASE}.qza (04-classify)
# - Set script/config.sh VARIABLES
#   - $MAPname : metadata path
#   - $SAMPLINGdepth : rarefaction depth, default 10,000
# - DEICODE plugin must be installed

# OUTPUT
# - filtered-table.qza (intermediate)
#   filtered table only contains samples that are in metadata file
# - ab_filtered-table.qza (intermediate)
# - abundance filtered table, removed low prevalence and low abundance features
# - rarefied_ab_filtered-table.qza (intermediate)
#   rarefied abundance table, rarefied to $SAMPLINGdepth
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
# - additional-metrics-results/ 
#       -abfilter_jaccard_distance_matrix.qza
#       -abfilter_jaccard_pcoa_results.qza
#       -abfilter_jaccard_emperor.qzv
#       -deicode_distance_matrix.qza
#       -deicode_biplot_results.qza
#       -deicode_emperor.qzv

# ----------------- SCRIPT START -------------------- # 

# log directory
# script in main folder

# Source variable names from config.sh
echo -e "Source variable names from config.sh"
dos2unix ./config.sh
source ./config.sh

# setting input/output variables
echo -e "setting input/output variables"  
inputTax="${WKPATH}/output/04-classify"
inputPhylo="${WKPATH}/output/05-phylogeny"
# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/06-diversity"
outputDirTbl="${outputDir}/tables" 
outputDirAdd="${outputDir}/additional-metrics"
# directories to place results from script

# if previous output folder exists, delete it 
echo -e "checking for old folders, will remove to rerun analysis" 

if [ -d "$outputDir" ]
then 
    echo -e "Previous output folder exists, deleting now..." 
    rm -Rfv -- "$outputDir"
fi 
    # -R deletes recursively, -f ignore non-existant files, -v verbose
    # '--'' : no more flags for rm command 

# making new import folders 
echo -e "creating new output folders" 
mkdir -p "${outputDir}/{tables,additional-metrics}"
    # -p ; make parent directories if needed

echo -e "Input directories are...
taxonomic/seq: $inputTax
phylogeny: $inputPhylo" 

echo -e "Output directories are... 
main folder: $outputDir
tables: $outputDirTbl
additional metrics: $outputDirAdd" 

echo -e "finished setting up folders and variables" 
echo -e "$(date)"

#Pre-prep for all analyses
echo -e "Beginning file prep for downstream analyses"

qiime feature-table filter-samples \
    --i-table "$inputTax/table.qza" \
    --m-metadata-file "$MAPname" \
    --o-filtered-table "$outputDirTbl/filtered-table.qza"

qiime feature-table filter-features-conditionally \
    --i-table "$outputDirTbl/filtered-table.qza" \
    --p-prevalence 0.1 \
    --p-abundance 0.01 \
    --o-filtered-table "$outputDirTbl/ab_filtered-table.qza"

qiime feature-table rarefy \
    --i-table "$outputDirTbl/ab_filtered-table.qza" \
    --p-sampling-depth "$SAMPLINGdepth" \
    --o-rarefied-table "$outputDirTbl/rarefied_ab_filtered-table.qza"

echo -e "finished file prep"
echo -e "$(date)"

#Diversity
#Rerun Diversity for appropriate depth if 10,000 is insufficient or incorrect

# Generate core diversity metrics 
echo -e "Core Diversity Metrics"

qiime diversity core-metrics-phylogenetic \
    --i-phylogeny "$inputPhylo/rooted-tree.qza" \
    --i-table "$outputDirTbl/filtered-table.qza" \
    --p-sampling-depth "$SAMPLINGdepth" \
    --m-metadata-file "$MAPname" \
    --output-dir "$outputDir/core-metrics-results"

echo -e "finished core diversity metrics"
echo -e "$(date)"

# Generate abundance filtered jaccard 
echo -e "Additional Diversity Metrics"

qiime diversity beta \
    --i-table "$outputDirTbl/rarefied_ab_filtered-table.qza" \
    --p-metric 'jaccard' \
    --o-distance-matrix "$outputDirAdd/abfilter_jaccard_distance_matrix.qza"

qiime diversity pcoa \
    --i-distance-matrix "$outputDirAdd/abfilter_jaccard_distance_matrix.qza" \
    --o-pcoa "$outputDirAdd/abfilter_jaccard_pcoa_results.qza"

qiime emperor plot \
    --i-pcoa "$outputDirAdd/abfilter_jaccard_pcoa_results.qza" \
    --m-metadata-file "$MAPname" \
    --o-visualization "$outputDirAdd/abfilter_jaccard_emperor.qzv"

echo -e "finished abundance filtered jaccard" 
# jaccard is sensitive to rare taxa, filtered jaccard used to see if rare taxa changed results

echo -e "$(date)"

echo -e "Robust Aitchison PCA (DEICODE), compositional beta diversity" 
# doesn't recommend rarefaction or taxa collapse 
# requires plugin for DEICODE
# only used for cross-sectional data, need to use TEMPTED or CTF

qiime deicode rpca \
    --i-table "$outputDirTbl/filtered-table.qza" \
    --o-biplot "$outputDirAdd/deicode_biplot_results.qza" \
    --o-distance-matrix "$outputDirAdd/deicode_distance_matrix.qza"

qiime emperor biplot \
    --i-biplot "$outputDirAdd/deicode_biplot_results.qza" \
    --m-sample-metadata-file "$MAPname" \
    --m-feature-metadata-file "$inputTax/taxonomy-${REF_DATABASE}.qza" \
    --p-number-of-features "${featureNum}" \
    --o-visualization deicode_emperor.qzv 

echo -e "finished DEICODE calculations..." 
echo -e "$(date)"

