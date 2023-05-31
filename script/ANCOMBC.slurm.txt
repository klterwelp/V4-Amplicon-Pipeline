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

# file: Diversity-ANCOM-Analysis.slurm
# input files needed in main folder:
	# feature table from composition-add-pseudocount 
	# metadata table

# input in Config file: 
	# set $metadataColumnName variable to metadata column of interest
	# set $MAPname variable to the mapping file with the samples we will analyze 

# log directory
# script in main folder

# Source variable names from config.sh
echo -e "Source variable names from config.sh"
dos2unix ./config.sh
source ./config.sh

echo -e $(date)

#ANCOM-BC
#Add analyses for each comparison performed in mapping files
echo -e "ANCOM-BC"

qiime composition ancombc \
--i-table genus-table-silva.qza \
--m-metadata-file $MAPname \
--p-formula "Supplement + Diet + Time" \
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


