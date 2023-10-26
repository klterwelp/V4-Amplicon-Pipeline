#!/bin/bash
#SBATCH --job-name=05_zymoQC
#SBATCH --partition=PART_NAME
#SBATCH --mem-per-cpu=25000
#SBATCH --output=../log/05_zymoQC.%j.out
#SBATCH -c 4
#SBATCH --error=../log/05_zymoQC.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: 05_zymoQC.slurm --------------------#

# PURPOSE
# - compare expected mock community composition and actual mock community composition
# INPUT 
# - rep-seqs.qza (filtered sequences from 04_taxfilter) 
# OUTPUT 

# ----------------- SCRIPT START -------------------- # 

# load parameters
dos2unix ./config.sh
source ./config.sh

# setting input/output variables
echo -e "setting input/output variables"  
inputDir="${WKPATH}/output/04-classify/${REF_DATABASE}/qza"
# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/05-zymoQC/${REF_DATABASE}"
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

echo -e "setting up zymo reference variables..."
echo -e "$(date)"

echo -e "Zymo references are...
zymo ref seqs: $MOCKrefseq
zymo taxonomy: $MOCKtax"

echo -e "finished setting up folders and variables" 
echo -e "$(date)"

# import relative expected zymo sequences into qiime2 format
echo -e "importing expected taxonomy into qiime2 format" 
echo -e "$(date)"
biom convert \
  -i "$MOCKtax" \
  -o "$outputDir"/expected-taxonomy.biom \
  --table-type="OTU table" \
  --to-json
  ## convert tsv into biom 
qiime tools import \
 --type "FeatureTable[RelativeFrequency]" \
 --input-path "$outputDir"/expected-taxonomy.biom \
 --input-format BIOMV100Format \
 --output-path "$outputDirQZA"/expected-taxonomy.qza

 ## import biom into rel.freq feature table

# import expected zymo sequences into qiime2 format
echo -e "importing expected sequences into qiime2 format" 
echo -e "$(date)"

qiime tools import \
  --input-path "$MOCKrefseq" \
  --output-path "$outputDirQZA"/expected-seqs.qza \
  --type 'FeatureData[Sequence]'
  ## import fasta file into qza format

# filter out ASV table + rep-seqs to only zymo controls 
echo -e "filtering ASV and rep-seqs table to only include zymo controls" 
echo -e "$(date)"
qiime feature-table filter-samples \
    --i-table "$tableQZA" \
    --m-metadata-file "$MAPname" \
    --p-where "["$controlCol"]='$mockname'" \
    --o-filtered-table "$outputDir"/zymo-table.qza
    ## filter table to only contain zymo controls
qiime feature-table filter-seqs \
    --i-table "$outputDir"/zymo-table.qza \
    --i-data "$inputDir/rep-seqs.qza" \
    --o-filtered-data "$outputDirQZA"/zymo-rep-seqs.qza

 qiime taxa collapse \
    --i-table "$outputDir"/zymo-table.qza \
    --i-taxonomy $taxQZA \
    --p-level 7 \
    --o-collapsed-table "$outputDir"/taxa-zymo-table.qza

# turn ASV table into a table of rel. abundance table  
echo -e "creating relative abundance table" 
echo -e "$(date)"
qiime feature-table relative-frequency \
    --i-table "$outputDir"/taxa-zymo-table.qza \
    --o-relative-frequency-table "$outputDirQZA"/zymo-freq-table.qza

# compare expected v actual frequencies 
echo -e "compare expected vs actual relative abundances and sequences" 
echo -e "$(date)"
qiime quality-control evaluate-composition \
  --i-expected-features "$outputDirQZA"/expected-taxonomy.qza \
  --i-observed-features "$outputDirQZA"/zymo-freq-table.qza \
  --o-visualization "$outputDirQZV"/eval-mock-freq-test.qzv

# compare expected sequences to actual sequences 
qiime quality-control evaluate-seqs \
  --i-query-sequences "$outputDirQZA"/zymo-rep-seqs.qza \
  --i-reference-sequences "$outputDirQZA"/expected-seqs.qza \
  --o-visualization "$outputDirQZV"/eval-mock-seqs-test.qzv 

echo -e "finished zymo QC" 
echo -e "$(date)"