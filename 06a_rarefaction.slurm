#!/bin/bash

#SBATCH --job-name=06_rarefaction
#SBATCH --partition=PART_NAME
#SBATCH --mem=10000
#SBATCH --output=../log/06_rarefaction.%j.out
#SBATCH --nodes=1
#SBATCH --error=../log/06_rarefaction.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: 06_rarefaction.slurm --------------------#

# PURPOSE
# - Filter feature table by prevalence and abundance
# - Generate rarefaction beta/alpha to test rarefaction depth

# INPUT
# - $tableQZA
# - $treeQZA
# - Set script/config.sh VARIABLES
#   - $MAPname : metadata path
#   - $SAMPLINGdepth : rarefaction depth, default 10,000
#   - $QiimeMax : max rarefaction depth, usually set to max number of reads from all samples !!! change to -> $MaxDepth
#   - $StepNumber : number of rarefaction depth steps to include between min (1) and $MaxDepth 

# OUTPUT
# - filtered-table.qza (intermediate)
#   filtered table only contains samples that are in metadata file
# - alpha-rarefaction.qzv (visualization)
#   rarefaction curve for alpha diversity metrics 
# - braycurtis_beta_rarefaction.qzv (visualization)
# - jaccard_beta_rarefaction.qzv (visualization)
# - unweighted_unifrac_beta_rarefaction.qzv (visualization)
# - weighted_unifrac_beta_rarefaction.qzv (visualization)
#   beta rarefaction for all beta diversity metrics 

# ----------------- SCRIPT START -------------------- # 

# log directory
# script in main folder

# Source variable names from config.sh
echo -e "Source variable names from config.sh"
dos2unix ./config.sh
source ./config.sh

# setting input/output variables
echo -e "setting input/output variables"  
inputTax="${WKPATH}/output/04-classify/qza"
inputPhylo="${WKPATH}/output/05-phylogeny/qza"
# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/06-rarefaction"
outputDirA="${outputDir}/alpha" 
outputDirB="${outputDir}/beta"
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
mkdir -p "${outputDir}"/{alpha,beta}
    # -p ; make parent directories if needed

echo -e "Input directories are...
taxonomic/seq: $inputTax
phylogeny: $inputPhylo" 

echo -e "Output directories are... 
main folder: $outputDir
Alpha: $outputDirA
Beta: $outputDirB" 

echo -e "finished setting up folders and variables" 
echo -e "$(date)"
# record time and method name, env vars
echo -e "$(date)"

#Pre-prep for all analyses
echo -e "Beginning file prep for downstream analyses"

qiime feature-table filter-samples \
    --i-table "$tableQZA" \
    --m-metadata-file "$MAPname" \
    --o-filtered-table "$outputDir/filtered-table.qza"

echo -e "finished file prep"
echo -e "$(date)"

#Diversity
#Rerun Diversity for appropriate depth if 10,000 is insufficient or incorrect

echo -e "$(date)"
# Rarefaction, check sample depth & seq read depth sufficient or not.
echo -e "alpha diversity, rarefaction..." 
qiime diversity alpha-rarefaction \
  --i-table "$outputDir/filtered-table.qza" \
  --i-phylogeny "$treeQZA" \
  --p-max-depth "$QiimeMax" \
  --p-steps "$StepNumber" \
  --m-metadata-file "$MAPname" \
  --o-visualization "$outputDirA/alpha-rarefaction.qzv"

echo -e "finished alpha rarefaction..."
echo -e "$(date)"

echo -e "beta diversity, rarefaction..." 

for metrics in 'braycurtis' 'jaccard' 'unweighted_unifrac' 'weighted_unifrac'
do 
echo -e "${metrics} rarefaction" 
qiime diversity beta-rarefaction \
    --i-table "$outputDir/filtered-table.qza" \
    --i-phylogeny "$treeQZA" \
    --m-metadata-file "$MAPname" \
    --p-sampling-depth "$SAMPLINGdepth" \
    --p-metric "$metrics" \
    --p-clustering-method 'nj' \
    --o-visualization "$outputDirB/${metrics}_beta_rarefaction.qzv"
done
echo -e "finished beta rarefaction..."
echo -e "$(date)"
