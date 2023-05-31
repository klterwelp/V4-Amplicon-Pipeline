#!/bin/bash
#SBATCH --job-name=04_taxfilter
#SBATCH --partition=scavenger
#SBATCH --mem-per-cpu=25000
#SBATCH --output=log/04_taxfilter.%j.out
#SBATCH -c 4
#SBATCH --error=log/04_taxfilter.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=zhengzheng.hu@duke.edu

# file: 04_taxfilter.sbatch
# filter feature table and sequences based on taxanomy, remove mitochondria,chloroplast,unassigned,eukaryota

# load parameters
dos2unix ./config.sh
source ./config.sh

# record time and method name, env vars
echo -e $(date)
echo -e "working path: " $WKPATH

mkdir -p ${WKPATH}/03_dada2/${REF_DATABASE}/qza
mkdir -p ${WKPATH}/03_dada2/${REF_DATABASE}/qzv
mkdir -p ${WKPATH}/set/${REF_DATABASE}/root/qza
mkdir -p $DOWNPATH

# clasification, taxonomy
echo -e "step 04A: classify-sklearn ..."
 qiime feature-classifier classify-sklearn \
  --i-classifier $REF_FILE \
  --i-reads $WKPATH/03_dada2/qza/${PREFIX}03_seq.fasta.qza \
  --o-classification $WKPATH/03_dada2/${REF_DATABASE}/qza/${PREFIX}04_seq-taxonomy_${REF_DATABASE}.tsv.qza

echo -e "finished classify-sklearn..."
echo -e $(date)

echo -e "step 04B: filter based on taxanomy, remove mitochondria & chloroplast seqs ..."
# filter based on taxanomy, remove mitochondria & chloroplast DNAs
qiime taxa filter-table \
  --i-table $WKPATH/03_dada2/qza/${PREFIX}03_table.biom.qza \
  --i-taxonomy $WKPATH/03_dada2/${REF_DATABASE}/qza/${PREFIX}04_seq-taxonomy_${REF_DATABASE}.tsv.qza \
  --p-exclude mitochondria,chloroplast,unassigned,eukaryota \
  --o-filtered-table $WKPATH/set/${REF_DATABASE}/root/qza/${PREFIX}04_table_root_${REF_DATABASE}-cleaned.biom.qza

qiime taxa filter-table \
  --i-table $WKPATH/03_dada2/qza/${PREFIX}03_table.biom.qza \
  --i-taxonomy $WKPATH/03_dada2/${REF_DATABASE}/qza/${PREFIX}04_seq-taxonomy_${REF_DATABASE}.tsv.qza \
  --p-include mitochondria,chloroplast,unassigned,eukaryota \
  --o-filtered-table $WKPATH/03_dada2/${REF_DATABASE}/qza/${PREFIX}04_table_${REF_DATABASE}-excluded.biom.qza

qiime taxa filter-seqs \
  --i-sequences $WKPATH/03_dada2/qza/${PREFIX}03_seq.fasta.qza \
  --i-taxonomy $WKPATH/03_dada2/${REF_DATABASE}/qza/${PREFIX}04_seq-taxonomy_${REF_DATABASE}.tsv.qza \
  --p-exclude mitochondria,chloroplast,unassigned,eukaryota \
  --o-filtered-sequences $WKPATH/set/${REF_DATABASE}/root/qza/${PREFIX}04_seq_root_${REF_DATABASE}-cleaned.fasta.qza
 
qiime taxa filter-seqs \
  --i-sequences $WKPATH/03_dada2/qza/${PREFIX}03_seq.fasta.qza \
  --i-taxonomy $WKPATH/03_dada2/${REF_DATABASE}/qza/${PREFIX}04_seq-taxonomy_${REF_DATABASE}.tsv.qza \
  --p-include mitochondria,chloroplast,unassigned,eukaryota \
  --o-filtered-sequences $WKPATH/03_dada2/${REF_DATABASE}/qza/${PREFIX}04_seq_${REF_DATABASE}-excluded.fasta.qza

# visualizations
qiime feature-table summarize \
 --i-table $WKPATH/03_dada2/${REF_DATABASE}/qza/${PREFIX}04_table_${REF_DATABASE}-excluded.biom.qza \
 --m-sample-metadata-file $WKPATH/meta/${PREFIX}_map.txt \
 --o-visualization $WKPATH/03_dada2/${REF_DATABASE}/qzv/${PREFIX}04_table_${REF_DATABASE}-excluded.biom.qzv
 
qiime taxa barplot \
  --i-table $WKPATH/03_dada2/${REF_DATABASE}/qza/${PREFIX}04_table_${REF_DATABASE}-excluded.biom.qza \
  --i-taxonomy $WKPATH/03_dada2/${REF_DATABASE}/qza/${PREFIX}04_seq-taxonomy_${REF_DATABASE}.tsv.qza \
  --m-metadata-file $WKPATH/meta/${PREFIX}_map.txt \
  --o-visualization $WKPATH/03_dada2/${REF_DATABASE}/qzv/${PREFIX}04_barplot_${REF_DATABASE}-excluded.biom.qzv 
  
qiime metadata tabulate \
  --m-input-file $WKPATH/03_dada2/${REF_DATABASE}/qza/${PREFIX}04_seq-taxonomy_${REF_DATABASE}.tsv.qza $WKPATH/03_dada2/${REF_DATABASE}/qza/${PREFIX}04_seq_${REF_DATABASE}-excluded.fasta.qza \
  --o-visualization $WKPATH/03_dada2/${REF_DATABASE}/qzv/${PREFIX}04_table_tax_${REF_DATABASE}-excluded.tsv.qzv  
  
# export files for downstream analysis
cp $WKPATH/set/${REF_DATABASE}/root/qza/${PREFIX}04_table_root_${REF_DATABASE}-cleaned.biom.qza $DOWNPATH/table.qza
cp $WKPATH/set/${REF_DATABASE}/root/qza/${PREFIX}04_seq_root_${REF_DATABASE}-cleaned.fasta.qza $DOWNPATH/rep-seqs.qza
cp $REF_FILE $DOWNPATH/classifier.qza

  
 echo -e "finished filter based on taxanomy..."
 echo -e $(date)