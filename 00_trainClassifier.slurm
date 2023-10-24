#!/bin/bash
#SBATCH --job-name=00_trainClassifier
#SBATCH --partition=PART_NAME
#SBATCH --mem-per-cpu=25000
#SBATCH --output=log/00_trainClassifier.%j.out
#SBATCH -c 4
#SBATCH --error=log/00_trainClassifier.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: 00_train-classifier.slurm --------------------#

# PURPOSE
# - train classifier based on database of choice 
# - not required if using the pre-trained QIIME2 classifier
# INPUT 
# - Set script/config.sh VARIABLES
#   - $fPrimer : forward PCR primer, only bio seq
#   - $rPrimer : reverse PCR primer, only bio seq
#     - must be 5'->3'
#   - $reFasta : path to database reference sequences
#   - $reTaxonomy : path to database taxonomic classifications
#   - ${REF_DATABASE} : database used for training classifier
# - must have RESCRIPt plugin installed 
# OUTPUT
# - import-refseqs.qza (intermediate): imported fasta into qza
# - ref-taxonomy.qza (intermediate): imported taxonomy into qza
# - classifier.qza (04_classify-filter) 

# ----------------- SCRIPT START -------------------- # 


# load parameters
dos2unix ./config.sh
source ./config.sh

# record time and method name, env vars
echo -e "$(date)"
echo -e "working path: " $WKPATH

# setting input/output variables
echo -e "setting input/output variables"  

# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/00-Classifier" 
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


# set up filenames 
FastaName=$(basename "$reFasta")

# 01: import reference datasets: taxonomy and sequence 
echo -e "Step One: Importing reference datasets..." 
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path "$reFasta" \
  --output-path "$outputDirQZA/import-refseqs.qza"

qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path "$reTaxonomy" \
  --output-path "$outputDirQZA/ref-taxonomy.qza"
 
 echo -e "$(date)"
 echo -e "...finished importing reference datasets"

# 02: extract sequence segments via RESCRIPt 
echo -e "$(date)"
echo -e "Step Two: Extracting sequence segments via RESCRIPt." 

echo -e "Generate an initial reference pool of sequence segments"

# 02A: generate initial reference pool of sequence segments
 qiime feature-classifier extract-reads \
  --i-sequences "$outputDirQZA/import-refseqs.qza" \
  --p-f-primer "$fPrimer" \
  --p-r-primer "$rPrimer" \
  --o-reads "$outputDirQZA/primer-match-refseqs.qza"

 qiime rescript dereplicate \
    --i-sequences "$outputDirQZA/primer-match-refseqs.qza" \
    --i-taxa "$outputDirQZA/ref-taxonomy.qza" \
    --p-mode 'uniq' \
    --p-threads 8 \
    --o-dereplicated-sequences "$outputDirQZA/primer-match-refseqs-derep.qza" \
    --o-dereplicated-taxa "$outputDirQZA/primer-match-ref-taxonomy.qza"

qiime feature-table tabulate-seqs \
  --i-data "$outputDirQZA/primer-match-refseqs.qza" \
  --o-visualization "$outputDirQZV/primer-match-refseqs.qzv"

# 02B: expand reference segment seq pool 
echo -e "Extract seq segments iteration one"
echo -e "$(date)"
 ## Iteration One
qiime rescript extract-seq-segments \
    --i-input-sequences "$outputDirQZA/import-refseqs.qza" \
    --i-reference-segment-sequences "$outputDirQZA/primer-match-refseqs.qza" \
    --p-perc-identity 0.7 \
    --p-min-seq-len 10 \
    --p-threads 8 \
    --o-extracted-sequence-segments "$outputDirQZA/extracted-seq-segments-01.qza" \
    --o-unmatched-sequences "$outputDirQZA/unmatched-sequences-01.qza" \
    --verbose
qiime feature-table tabulate-seqs \
  --i-data "$outputDirQZA/extracted-seq-segments-01.qza" \
  --o-visualization "$outputDirQZV/extracted-seq-segments-01.qzv"
 ## Iteration Two 
echo -e "Extract seq segments iteration two"
echo -e "$(date)"
qiime rescript extract-seq-segments \
    --i-input-sequences "$outputDirQZA/import-refseqs.qza" \
    --i-reference-segment-sequences "$outputDirQZA/extracted-seq-segments-01.qza" \
    --p-perc-identity 0.7 \
    --p-min-seq-len 10 \
    --p-threads 8 \
    --o-extracted-sequence-segments "$outputDirQZA/extracted-seq-segments-02.qza" \
    --o-unmatched-sequences "$outputDirQZA/unmatched-sequences-02.qza" \
    --verbose
qiime feature-table tabulate-seqs \
  --i-data "$outputDirQZA/extracted-seq-segments-02.qza" \
  --o-visualization "$outputDirQZV/extracted-seq-segments-02.qzv"
echo -e "$(date)"
echo -e "...finished extracting sequence segments via  RESCRIPt"

# 03: filter by sequence length and taxonomy

qiime rescript filter-seqs-length \
    --i-sequences "$outputDirQZA/extracted-seq-segments-02.qza" \
    --p-global-min 100 \
    --p-global-max 800 \
    --o-filtered-seqs "$outputDirQZA/extracted-seq-segments-lengthkeep-02.qza" \
    --o-discarded-seqs "$outputDirQZA/extracted-seq-segments-lengthkeep-discard-02.qza"

qiime rescript filter-taxa \
    --i-taxonomy "$outputDirQZA/ref-taxonomy.qza" \
    --m-ids-to-keep-file "$outputDirQZA/extracted-seq-segments-lengthkeep-02.qza" \
    --o-filtered-taxonomy "$outputDirQZA/extracted-tax-segments-lengthkeep-02.qza"

# 04: evaluate reference taxa and sequences 

qiime metadata tabulate \
    --m-input-file "$outputDirQZA/extracted-tax-segments-lengthkeep-02.qza" \
    --o-visualization "$outputDirQZV/extracted-tax-segments-lengthkeep-02.qzv"
    
qiime rescript evaluate-taxonomy \
    --i-taxonomies "$outputDirQZA/extracted-tax-segments-lengthkeep-02.qza" \
    --o-taxonomy-stats "$outputDirQZV/evaltax-lengthkeep-02.qzv"

qiime rescript evaluate-seqs \
    --i-sequences "$outputDirQZA/extracted-seq-segments-lengthkeep-02.qza" \
    --p-kmer-lengths 16 8 4 2 \
    --o-visualization "$outputDirQZV/evalseq-lengthkeep-02.qzv"

# 05: train Naive Bayes Classifier 
echo -e "training and evaluating Naive Bayes Classifier..."
echo -e "$(date)"
qiime rescript evaluate-fit-classifier \
    --i-sequences "$outputDirQZA/extracted-seq-segments-lengthkeep-02.qza" \
    --i-taxonomy "$outputDirQZA/extracted-tax-segments-lengthkeep-02.qza" \
    --p-n-jobs 2 \
    --o-classifier "$outputDirQZA/$FastaName-classifier.qza" \
    --o-evaluation "$outputDirQZV/$FastaName-classifier-evaluation.qzv" \
    --o-observed-taxonomy "$outputDirQZA/$FastaName-refseqs-predicted-taxonomy.qza"

qiime rescript evaluate-taxonomy \
  --i-taxonomies "$outputDirQZA/extracted-tax-segments-lengthkeep-02.qza" "$outputDirQZA/$FastaName-refseqs-predicted-taxonomy.qza" \
  --p-labels ref-taxonomy predicted-taxonomy \
  --o-taxonomy-stats "$outputDirQZV/taxonomy-evaluation.qzv"

echo -e "$(date)"
echo -e "finished training"