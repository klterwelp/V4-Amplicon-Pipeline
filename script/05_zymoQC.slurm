#!/bin/bash
#SBATCH --job-name=05_phylogeny
#SBATCH --partition=PART_NAME
#SBATCH --mem-per-cpu=25000
#SBATCH --output=log/05_phylogeny.%j.out
#SBATCH -c 4
#SBATCH --error=log/05_phylogeny.%j.err
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
inputDir="${WKPATH}/output/04-classify/qza"
# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/05-zymoQC"
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
mkdir -p "${outputDir}/{qza,qzv}"
    # -p ; make parent directories if needed

echo -e "Input directory is...$inputDir" 

echo -e "Output directories are... 
main folder: $outputDir
qza: $outputDirQZA
qzv: $outputDirQZV"

echo -e "finished setting up folders and variables" 
echo -e "$(date)"

# import relative expected zymo sequences into qiime2 format

biom convert \
  -i zymo-taxonomy.tsv \
  -o expected-taxonomy.biom \
  --table-type="OTU table" \
  --to-json
  ## convert tsv into biom 
qiime tools import \
 --type "FeatureTable[RelativeFrequency]" \
 --input-path expected-taxonomy.biom \
 --input-format BIOMV100Format \
 --output-path expected-taxonomy.qza

 ## import biom into rel.freq feature table

# import expected zymo sequences into qiime2 format
cat zymo-refseq/D6331.refseq/ssrRNAs/*.fasta >> zymo-seqs.fasta
    ## concatenate all fasta files in folder into one fasta file
qiime tools import \
  --input-path zymo-seqs.fasta \
  --output-path expected-seqs.qza \
  --type 'FeatureData[Sequence]'
  ## import fasta file into qza format

# filter out ASV table + rep-seqs to only zymo controls 

qiime feature-table filter-samples \
    --i-table "$tableQZA" \
    --m-metadata-file "$MAPname" \
    --p-where "$controlCol"="$mockname" \
    --o-filtered-table zymo-table.qza
    ## filter table to only contain zymo controls

qiime feature-table filter-seqs \
    --i-table zymo-table.qza \
    --i-data "$inputDir/rep-seqs.qza" \
    --o-filtered-data zymo-rep-seqs.qza

# turn ASV table into a table of rel. abundance table  
qiime feature-table relative-frequency \
    --i-table zymo-table.qza \
    --o-relative-frequency-table zymo-freq-table.qza

# compare expected v actual frequencies 
qiime quality-control evaluate-composition \
  --i-expected-features expected-taxonomy.qza \
  --i-observed-features zymo-freq-table.qza \
  --o-visualization eval-mock-freq-test.qzv

# compare expected sequences to actual sequences 
qiime quality-control evaluate-seqs \
  --i-query-sequences zymo-rep-seqs.qza \
  --i-reference-sequences expected-seqs.qza \
  --o-visualization eval-mock-seqs-test.qzv