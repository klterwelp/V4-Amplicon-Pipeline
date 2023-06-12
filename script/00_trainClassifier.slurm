#!/bin/bash
#SBATCH --job-name=00_trainClassifier
#SBATCH --partition=scavenger
#SBATCH --mem-per-cpu=25000
#SBATCH --output=log/00_trainClassifier.%j.out
#SBATCH -c 4
#SBATCH --error=log/00_trainClassifier.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=klt75@duke.edu

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

# set up filenames 
FastaName=$(basename "$reFasta")

# 01: import reference datasets: taxonomy and sequence 
echo -e "Step One: Importing reference datasets..." 
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path "$reFasta" \
  --output-path import-refseqs.qza

qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path "$reTaxonomy" \
  --output-path ref-taxonomy.qza
 
 echo -e "$(date)"
 echo -e "...finished importing reference datasets"

# 02: extract sequence segments via RESCRIPt 
echo -e "$(date)"
echo -e "Step Two: Extracting sequence segments via RESCRIPt." 

echo -e "Generate an initial reference pool of sequence segments"

# 02A: generate initial reference pool of sequence segments
 qiime feature-classifier extract-reads \
  --i-sequences import-refseqs.qza \
  --p-f-primer "$fPrimer" \
  --p-r-primer "$rPrimer" \
  --o-reads primer-match-refseqs.qza

 qiime rescript dereplicate \
    --i-sequences primer-match-refseqs.qza \
    --i-taxa ref-taxonomy.qza \
    --p-mode 'uniq' \
    --p-threads 8 \
    --o-dereplicated-sequences primer-match-refseqs-derep.qza \
    --o-dereplicated-taxa primer-match-ref-taxonomy.qza

qiime feature-table tabulate-seqs \
  --i-data primer-match-refseqs.qza \
  --o-visualization primer-match-refseqs.qzv

# 02B: expand reference segment seq pool 
echo -e "Extract seq segments iteration one"
echo -e "$(date)"
 ## Iteration One
qiime rescript extract-seq-segments \
    --i-input-sequences import-refseqs.qza \
    --i-reference-segment-sequences primer-match-refseqs.qza \
    --p-perc-identity 0.7 \
    --p-min-seq-len 10 \
    --p-threads 8 \
    --o-extracted-sequence-segments extracted-seq-segments-01.qza \
    --o-unmatched-sequences unmatched-sequences-01.qza \
    --verbose
qiime feature-table tabulate-seqs \
  --i-data extracted-seq-segments-01.qza \
  --o-visualization extracted-seq-segments-01.qzv
 ## Iteration Two 
echo -e "Extract seq segments iteration two"
echo -e "$(date)"
qiime rescript extract-seq-segments \
    --i-input-sequences import-refseqs.qza \
    --i-reference-segment-sequences extracted-seq-segments-01.qza \
    --p-perc-identity 0.7 \
    --p-min-seq-len 10 \
    --p-threads 8 \
    --o-extracted-sequence-segments extracted-seq-segments-02.qza \
    --o-unmatched-sequences unmatched-sequences-02.qza \
    --verbose
qiime feature-table tabulate-seqs \
  --i-data extracted-seq-segments-02.qza \
  --o-visualization extracted-seq-segments-02.qzv
echo -e "$(date)"
echo -e "...finished extracting sequence segments via  RESCRIPt"

# 03: filter by sequence length and taxonomy

qiime rescript filter-seqs-length \
    --i-sequences extracted-seq-segments-02.qza \
    --p-global-min 100 \
    --p-global-max 800 \
    --o-filtered-seqs extracted-seq-segments-lengthkeep-02.qza \
    --o-discarded-seqs extracted-seq-segments-lengthkeep-discard-02.qza

qiime rescript filter-taxa \
    --i-taxonomy ref-taxonomy.qza \
    --m-ids-to-keep-file extracted-seq-segments-lengthkeep-02.qza \
    --o-filtered-taxonomy extracted-tax-segments-lengthkeep-02.qza

# 04: evaluate reference taxa and sequences 

qiime metadata tabulate \
    --m-input-file extracted-tax-segments-lengthkeep-02.qza \
    --o-visualization extracted-tax-segments-lengthkeep-02.qzv
    
qiime rescript evaluate-taxonomy \
    --i-taxonomies extracted-tax-segments-lengthkeep-02.qza \
    --o-taxonomy-stats evaltax-lengthkeep-02.qzv

qiime rescript evaluate-seqs \
    --i-sequences extracted-seq-segments-lengthkeep-02.qza \
    --p-kmer-lengths 16 8 4 2 \
    --o-visualization evalseq-lengthkeep-02.qzv

# 05: train Naive Bayes Classifier 
echo -e "training and evaluating Naive Bayes Classifier..."
echo -e "$(date)"
qiime rescript evaluate-fit-classifier \
    --i-sequences extracted-seq-segments-lengthkeep-02.qza \
    --i-taxonomy extracted-tax-segments-lengthkeep-02.qza \
    --p-n-jobs 2 \
    --o-classifier "{$FastaName}-classifier.qza" \
    --o-evaluation "{$FastaName}-classifier-evaluation.qzv" \
    --o-observed-taxonomy "{$FastaName}-refseqs-predicted-taxonomy.qza"

qiime rescript evaluate-taxonomy \
  --i-taxonomies extracted-tax-segments-lengthkeep-02.qza "{$FastaName}-refseqs-predicted-taxonomy.qza" \
  --p-labels ref-taxonomy predicted-taxonomy \
  --o-taxonomy-stats taxonomy-evaluation.qzv

echo -e "$(date)"
echo -e "finished training"