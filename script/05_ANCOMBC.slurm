#!/bin/bash
#SBATCH --job-name=ANCOMBC
#SBATCH --partition=scavenger
#SBATCH --mem-per-cpu=25000
#SBATCH --output=log/ancombc.%j.out
#SBATCH -c 4
#SBATCH --error=log/ancombc.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=klt75@duke.edu

#------------------ SCRIPT INFO: ANCOMBC.slurm --------------------#

# PURPOSE
# - Run composition analysis with ANCOMBC 
# INPUT
# - table.qza 
# - metadata
# - taxonomy-${REF_DATABASE}.qza
# - Set script/config.sh VARIABLES
# 	- $MAPname : name of metadata file
#   - $ANCOMBCformula : ANCOMBC formula, in R formulae format 
#	- $metadataColumnName # ONLY IN NAMES, replace with forumla
# OUTPUT
# - $ANCOMBCfolder"/"L$lvl"-ANCOMBC.qza (intermediate)
# - "L$lvl-table-${REF_DATABASE}".qza
# - "$ANCOMBCfolder"/"L$lvl"-table-ANCOMBC.qzv  (visualizations)
# - "$ANCOMBCfolder"/"L$lvl"-barplot-ANCOMBC.qzv (visualizations)

# ----------------- SCRIPT START -------------------- # 

# Source variable names from config.sh
echo -e "Source variable names from config.sh"
dos2unix ./config.sh
source ./config.sh

echo -e $(date)

echo -e "creating sedding variable" 
echo -e $(date)

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
echo -e $(date)
# EXPLANATION OF ABOVE:
# += concatenates string (sedding replacement argument) to $seddings var
# ; creates break in command, sed will take multiple replacement arguments strung together this way
# \ used to back out of special character properties (ie; * being wildcard)

#ANCOM-BC
#Add analyses for each comparison performed in mapping files

echo -e "Setting up collapsed taxa tables for ANCOMBC" 
echo -e $(date)

for lvl in "${taxaLvl[@]}"
do
# Collapse taxa based on level of taxonomy (6 for genus)
qiime taxa collapse \
--i-table filtered-table.qza \
--i-taxonomy "taxonomy-${REF_DATABASE}.qza" \
--p-level $lvl \
--o-collapsed-table "L$lvl-table-${REF_DATABASE}".qza
done

echo -e "...finished generating collapsed taxa tables for ANCOMBC" 
echo -e $(date)

echo -e "Starting ANCOMBC Analyses"

for formula in "${ANCOMBCformula[@]}"
do
ANCOMBCfolder=$(echo "$formula" | sed $seddings)
echo -e "In $ANCOMBCfolder folder" 
    for lvl in "${taxaLvl[@]}"
    do
    echo -e "ANCOMBC analysis for formula: $formula and taxonomic level : $lvl"
    # ANCOMBC differentials
    qiime composition ancombc \
        --i-table "L$lvl-table-${REF_DATABASE}".qza \
        --m-metadata-file "$MAPname" \
        --p-formula $formula \
        --o-differentials "$ANCOMBCfolder"/"L$lvl"-ANCOMBC.qza
    #Add visualizations for ANCOMBC
    echo -e "ANCOMBC VISUALIZATION for formula: $formula and taxonomic level : $lvl" 
    qiime composition tabulate \
        --i-data "$ANCOMBCfolder"/"L$lvl"-ANCOMBC.qza \
        --o-visualization "$ANCOMBCfolder"/"L$lvl"-table-ANCOMBC.qzv 

    qiime composition da-barplot \
        --i-data "$ANCOMBCfolder"/"L$lvl"-ANCOMBC.qza \
        --o-visualization "$ANCOMBCfolder"/"L$lvl"-barplot-ANCOMBC.qzv 
    done
done

echo -e "finished ANCOM-BC"
echo -e $(date)


