#!/bin/bash

#SBATCH --job-name=01_import
#SBATCH --partition=PART_NAME
#SBATCH --mem=10000
#SBATCH --output=../log/01_import.%j.out
#SBATCH --nodes=1
#SBATCH --error=../log/01_import.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: 01_import.slurm --------------------#

# PURPOSE
# - import demultiplexed pair end fastq.gz sequences into QIIME2
# INPUT
# - demultiplexed paired-end fastq.gz sequences in data folder 
# OUTPUT
# - manifest.csv (intermediate)
# - 01_import.fastq.qza (used in 03_dada2)
# - 01_import.qzv (check seq quality)

# ----------------- SCRIPT START -------------------- # 

# load parameters from config.sh
dos2unix ./config.sh
source ./config.sh

# record time and project path
echo -e "$(date)"
echo -e "working path: " $WKPATH

# setting input/output variables
echo -e "setting input/output variables"  
inputDir="${WKPATH}/data"
# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/01-import" 
outputDirQZA="${outputDir}/qza" 
outputDirQZV="${outputDir}/qzv"
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
mkdir -p "${outputDir}"/{qza,qzv}
    # -p ; make parent directories if needed

echo -e "Input directory is...$inputDir" 

echo -e "Output directories are... 
main folder: $outputDir
qza: $outputDirQZA
qzv: $outputDirQZV" 

echo -e "finished setting up folders and variables" 
echo -e "$(date)"

echo -e "step 0: creating manifest file..."
cd "$inputDir" || exit
# exits script if inputDir doesn't exist, continues if it does
echo "sample-id,absolute-filepath,direction" > "${outputDir}/manifest.csv"
for i in *R1* ; do echo "${i/_S*.fastq.gz},$PWD/$i,forward"; done >> "${outputDir}/manifest.csv"
for i in *R2* ; do echo "${i/_S*.fastq.gz},$PWD/$i,reverse"; done >> "${outputDir}/manifest.csv"

echo -e "finished creating manifest file."
echo -e "$(date)"

# importing data
echo -e "step 1: importing paired end demultiplexed fastq.gz data..."

qiime tools import \
 --type 'SampleData[PairedEndSequencesWithQuality]' \
 --input-path "${outputDir}/manifest.csv" \
 --output-path "${outputDirQZA}"/01_import.fastq.qza \
 --input-format PairedEndFastqManifestPhred33

echo -e "finished importing."
echo -e "$(date)"

# summarizing & visualization based on demultiplexing results. can add thread option
echo -e "step 2b: starting demux summarizing..."

qiime demux summarize \
 --i-data "${outputDirQZA}"/01_import.fastq.qza \
 --o-visualization "${outputDirQZV}"/01_import.qzv

echo -e "finished demux summarizing."
echo -e "$(date)"
