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
# - genus-table-silva.qza (change to table.qza from 04_classify-filter; add step to qiime taxa collapse)
# - Set script/config.sh VARIABLES
# 	- $MAPname : name of metadata file
#	- $metadataColumnName # ONLY IN NAMES, replace with forumla
# 	    - SHOULD ADD: $ANCOMBCformula and use that for names
# OUTPUT
# - L6-ANCOMBC-$metadataColumnName.qza (intermediate)
# - L6-ANCOMBC-TABLE-$metadataColumnName.qzv (visualizations)
# - L6-ANCOMBC-BARPLOT-$metadataColumnName.qzv (visualizations)

# ----------------- SCRIPT START -------------------- # 

# Source variable names from config.sh
echo -e "Source variable names from config.sh"
dos2unix ./config.sh
source ./config.sh

echo -e $(date)

#ANCOM-BC
#Add analyses for each comparison performed in mapping files
echo -e "ANCOM-BC"

# Collapse taxa based on level of taxonomy (6 for genus)
qiime taxa collapse \
--i-table filtered-table.qza \
--i-taxonomy "taxonomy-${REF_DATABASE}.qza" \
--p-level $taxaLvl \
--o-collapsed-table genus-table-silva.qza

qiime composition ancombc \
--i-table genus-table-silva.qza \
--m-metadata-file $MAPname \
--p-formula "Supplement + Diet + Time" \
# change to $ANCOMBCformula 
--o-differentials L6-ANCOMBC-$metadataColumnName.qza

#ANCOM-BC VISUALIZATION
#Add visualizations for ANCOMBC
echo -e "ANCOM-BC VISUALIZATION" 
echo -e $(date)

qiime composition tabulate \
--i-data L6-ANCOMBC-$metadataColumnName.qza \
--o-visualization L6-ANCOMBC-TABLE-$metadataColumnName.qzv 

qiime composition da-barplot \
--i-data L6-ANCOMBC-$metadataColumnName.qza \
--o-visualization L6-ANCOMBC-BARPLOT-$metadataColumnName.qzv 

echo -e "finished ANCOM-BC"
echo -e $(date)


