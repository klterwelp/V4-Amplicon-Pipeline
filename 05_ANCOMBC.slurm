#!/bin/bash
#SBATCH --job-name=ANCOMBC
#SBATCH --partition=PART_NAME
#SBATCH --mem-per-cpu=25000
#SBATCH --output=../log/ancombc.%j.out
#SBATCH -c 4
#SBATCH --error=../log/ancombc.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: ANCOMBC.slurm --------------------#

# PURPOSE
# - Run composition analysis with ANCOMBC 
# INPUT
# - table.qza (04_classify-filter)
# - metadata 
# - $taxQZA (04_classify-filter)
# - Set script/config.sh VARIABLES
# 	- $MAPname : name of metadata file
#   - $ANCOMBCformula : ANCOMBC formula, in R formulae format 
#	- $metadataColumnName # ONLY IN NAMES, replace with forumla
# OUTPUT
# - filtered-table.qza
# - "L$lvl-table-${REF_DATABASE}".qza
# - $ANCOMBCfolder"/
#   - "L$lvl"-ANCOMBC.qza (intermediate)
#   - "L$lvl"-table-ANCOMBC.qzv  (visualizations)
#   - "L$lvl"-barplot-ANCOMBC.qzv (visualizations)
# ----------------- SCRIPT START -------------------- # 

# Source variable names from config.sh
echo -e "Source variable names from config.sh"
dos2unix ./config.sh
source ./config.sh

echo -e "$(date)"
# setting input/output variables
echo -e "setting input/output variables"  
inputDir="${WKPATH}/output/04-classify/qza"
# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/05-ancombc"
# directory to place results from script

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

echo -e "Output directory is... 
main folder: $outputDir"

echo -e "finished setting up folders and variables" 
echo -e "$(date)"

echo -e "creating sedding variable" 
echo -e "$(date)"

# replace all special characters with words
seddings="s/\+//g;"
# replace + with nothing
seddings+="s/\*/INT/g;"
# replace * with INT
seddings+="s/\-/NOT/g;"
# replace - with NOT
seddings+="s/\^/ORD/g;"
# replace ^ with ORD
seddings+="s/\//DIV/g;"
# replace / with DIV
seddings+="s/[^a-zA-Z0-9]//g"
# remove rest of non alpha-num characters with nothing

echo -e "finished sedding variable" 
echo -e "$(date)"
# EXPLANATION OF ABOVE:
# += concatenates string (sedding replacement argument) to $seddings var
# ; creates break in command, sed will take multiple replacement arguments strung together this way
# \ used to back out of special character properties (ie; * being wildcard)

#ANCOM-BC
#Add analyses for each comparison performed in mapping files
echo -e "filtering table by metadata" 

qiime feature-table filter-samples \
    --i-table "$tableQZA" \
    --m-metadata-file "$MAPname" \
    --o-filtered-table "$outputDir"/filtered-table.qza

echo -e "Setting up collapsed taxa tables for ANCOMBC" 
echo -e "$(date)"

for lvl in "${taxaLvl[@]}"
do
# Collapse taxa based on level of taxonomy (6 for genus)
qiime taxa collapse \
--i-table "$outputDir"/filtered-table.qza \
--i-taxonomy "$taxQZA" \
--p-level "$lvl" \
--o-collapsed-table "$outputDir/L$lvl-table-${REF_DATABASE}".qza
done

echo -e "...finished generating collapsed taxa tables for ANCOMBC" 
echo -e "$(date)"

echo -e "Starting ANCOMBC Analyses"

for formula in "${ANCOMBCformula[@]}"
do
ANCOMBCfolder=$(echo "$formula" | sed $seddings)
ANCOMBCoutput="$outputDir/$ANCOMBCfolder"
mkdir "$ANCOMBCoutput"
echo -e "In $ANCOMBCfolder folder" 
    for lvl in "${taxaLvl[@]}"
    do
    echo -e "ANCOMBC analysis for formula: $formula and taxonomic level : $lvl"
    # ANCOMBC differentials
    qiime composition ancombc \
        --i-table "$outputDir/L$lvl-table-${REF_DATABASE}".qza \
        --m-metadata-file "$MAPname" \
        --p-formula "$formula" \
        --o-differentials "$ANCOMBCoutput/L$lvl"-ANCOMBC.qza

    #Add visualizations for ANCOMBC
    echo -e "ANCOMBC VISUALIZATION for formula: $formula and taxonomic level : $lvl" 
    qiime composition tabulate \
        --i-data "$ANCOMBCoutput/L$lvl"-ANCOMBC.qza \
        --o-visualization "$ANCOMBCoutput/L$lvl"-table-ANCOMBC.qzv 

    qiime composition da-barplot \
        --i-data "$ANCOMBCoutput/L$lvl"-ANCOMBC.qza \
        --o-visualization "$ANCOMBCoutput/L$lvl"-barplot-ANCOMBC.qzv 
    done
done

echo -e "finished ANCOMBC"
echo -e "$(date)"


