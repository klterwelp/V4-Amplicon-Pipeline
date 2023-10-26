#!/bin/bash

#SBATCH --job-name=07_BetaStats
#SBATCH --partition=PART_NAME
#SBATCH --mem=10000
#SBATCH --output=../log/07_BetaStats.%j.out
#SBATCH --nodes=1
#SBATCH --error=../log/07_BetaStats.%j.err
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

# setting input/output variables
echo -e "setting input/output variables"  
inputDir="${WKPATH}/output/06-diversity/${REF_DATABASE}/qza"
# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/07-betaStats/${REF_DATABASE}"
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
mkdir -p "${outputDir}"
    # -p ; make parent directories if needed

echo -e "Input directory is...$inputDir" 

echo -e "Output directory is...$outputDir"

echo -e "finished setting up folders and variables" 
echo -e "$(date)"
diversityMetrics=('bray_curtis' 'jaccard' 'unweighted_unifrac' 'weighted_unifrac' 'deicode' 'abfilter_jaccard')
# beta diversity metrics generated from 06_diversity.slurm, can remove some if not interested

for col in "${metadataColumnNames[@]}"
do
colFolder="$outputDir/${col}"
mkdir -p "$colFolder"
echo -e "Calculating beta significance for $col in folder $colFolder" 
    for metric in "${diversityMetrics[@]}"
    do 
    echo "Calculating significance of $metric for $col"
    qiime diversity beta-group-significance \
        --i-distance-matrix "$inputDir/${metric}_distance_matrix.qza" \
        --m-metadata-file "$MAPname" \
        --m-metadata-column "${col}" \
        --p-pairwise \
        --o-visualization "$colFolder/${metric}-${col}-permanova.qzv"
    done
done

# Purpose of nested for-loop:
    # for every column in metadataColumnNames 
    # make folder named after column 
    # calculate diversity beta-group-significance 
    # for each diversity metric




