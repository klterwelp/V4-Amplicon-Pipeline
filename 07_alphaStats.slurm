#!/bin/bash

#SBATCH --job-name=07_AlphaStats
#SBATCH --partition=PART_NAME
#SBATCH --mem=10000
#SBATCH --output=../log/07_AlphaStats.%j.out
#SBATCH --nodes=1
#SBATCH --error=../log/07_AlphaStats.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: alphaStats.slurm --------------------#

# PURPOSE
# - Test statistical signficant differences for alpha diversity based on numeric/categorical metadata
# INPUT
# - ${metric}_vector.qza 
# - alpha diversity vectors (06-diversity)
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

# setting input/output variables
echo -e "setting input/output variables"  
inputDir="${WKPATH}/output/06-diversity/${REF_DATABASE}/qza"
# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/07-alphaStats/${REF_DATABASE}"
outputGroup="${outputDir}/group" 
outputCorr="${outputDir}/correlation"
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
mkdir -p "${outputDir}"/{group,correlation}
    # -p ; make parent directories if needed
    
echo -e "Input directories is $inputDir" 

echo -e "Output directories are... 
main folder: $outputDir
Group/Categorical: $outputGroup
Correlation/Numeric: $outputCorr" 

echo -e "finished setting up folders and variables" 
echo -e "$(date)"

echo -e "Running alpha diversity statistical significance tests"

echo -e "Running group statistical tests (categorical)" 

for metric in 'shannon' 'observed_features' 'evenness' 'faith_pd'
do 
echo $metric
qiime diversity alpha-group-significance \
  --i-alpha-diversity "$inputDir/${metric}_vector.qza" \
  --m-metadata-file "$MAPname" \
  --o-visualization "$outputGroup/${metric}-group-significance.qzv"
done
# for-loop to test statistically significant differences between groups of alpha diversity values 

echo -e "$(date)"
echo -e "Done calculating group alpha diversity stats" 

echo -e "Running correlational statistical tests (categorical)" 
for metric in 'shannon' 'observed_features' 'evenness' 'faith_pd'
do 
echo $metric
qiime diversity alpha-correlation \
  --i-alpha-diversity "$inputDir/${metric}_vector.qza" \
  --m-metadata-file "$MAPname" \
  --o-visualization "$outputCorr/${metric}-numeric-correlation.qzv"
done
# for-loop to test statistically significant correlations for numeric metadata and alpha diversity 

echo -e "$(date)"
echo -e "Done calculating correlational (numeric) alpha diversity stats" 