#!/bin/bash

#SBATCH --job-name=01_import
#SBATCH --partition=PART_NAME
#SBATCH --mem=10000
#SBATCH --output=log/01_import.%j.out
#SBATCH --nodes=1
#SBATCH --error=log/01_import.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: 01_import.sbatch --------------------#

# PURPOSE
# - import demultiplexed pair end fastq.gz sequences into QIIME2
# INPUT
# - demultiplexed paired-end fastq.gz sequences in data folder 
# OUTPUT
# - manifest.csv (intermediate)
# - 01_import.fastq.qza (used in 03_dada2)
# - 01_import.qzv (visualize seq quality)

# ----------------- SCRIPT START -------------------- # 

# load parameters from config.sh
dos2unix ./config.sh
source ./config.sh

# record time and project path
echo -e $(date)
echo -e "working path: " $WKPATH

echo -e "step 0: creating manifest file..."
cd ${WKPATH}/data
echo "sample-id,absolute-filepath,direction" > manifest.csv
for i in *R1* ; do echo "${i/_S*.fastq.gz},$PWD/$i,forward"; done >> manifest.csv
for i in *R2* ; do echo "${i/_S*.fastq.gz},$PWD/$i,reverse"; done >> manifest.csv

echo -e "finished creating manifest file."
echo -e $(date)

# importing data
echo -e "step 1: importing paired end demultiplexed fastq.gz data..."

mkdir -p ${WKPATH}/01_import/qza
mkdir -p ${WKPATH}/01_import/qzv

qiime tools import \
 --type 'SampleData[PairedEndSequencesWithQuality]' \
 --input-path $WKPATH/data/manifest.csv \
 --output-path $WKPATH/01_import/qza/${PREFIX}01_import.fastq.qza \
 --input-format PairedEndFastqManifestPhred33

echo -e "finished importing."
echo -e $(date)

# summarizing & visualization based on demultiplexing results. can add thread option
echo -e "step 2b: starting demux summarizing..."

qiime demux summarize \
 --i-data $WKPATH/01_import/qza/${PREFIX}01_import.fastq.qza \
 --o-visualization $WKPATH/01_import/qzv/${PREFIX}01_import.qzv

echo -e "finished demux summarizing."
echo -e $(date)
