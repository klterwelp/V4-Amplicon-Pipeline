#!/bin/bash
#SBATCH --job-name=03_dada2
#SBATCH --partition=PART_NAME
#SBATCH --mem-per-cpu=25000
#SBATCH --output=log/03_dada2.%j.out
#SBATCH -c 4
#SBATCH --error=log/03_dada2.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: 03_dada2.slurm --------------------#

# PURPOSE
# - quality trim, filter, denoise sequences, chimera removal, and merging of paired end reads. 
# INPUT
# - 01_import.fastq.qza (from: 01_import)
# OUTPUT
# - 03_dada2_stats.tsv.qza (intermediate)
# - 03_table.biom.qza (04_classify-filter)
# - 03_seq.fasta.qza  (04_classify-filter)
# - 03_seq.fasta.qzv (table of ASVs, visualization)
# - 03_dada2_stats.tsv.qzv (check # of reads passing filters)

# ----------------- SCRIPT START -------------------- # 

dos2unix ./config.sh
source ./config.sh

# record time and method name, env vars
echo -e $(date)
echo -e "working path: " $WKPATH
 
echo -e "step 4: starting dada2 denoising..."

mkdir -p ${WKPATH}/03_dada2/qza
mkdir -p ${WKPATH}/03_dada2/qzv

qiime dada2 denoise-paired \
 --i-demultiplexed-seqs $WKPATH/01_import/qza/${PREFIX}01_import.fastq.qza \
 --p-trunc-len-f $QiimeDada2FL \
 --p-trunc-len-r $QiimeDada2RL \
 --p-trim-left-f $QiimeDada2FLeft \
 --p-trim-left-r $QiimeDada2RLeft \
 --o-denoising-stats $WKPATH/03_dada2/qza/${PREFIX}03_dada2_stats.tsv.qza \
 --o-table $WKPATH/03_dada2/qza/${PREFIX}03_table.biom.qza \
 --o-representative-sequences $WKPATH/03_dada2/qza/${PREFIX}03_seq.fasta.qza \
 --p-n-threads 4 \
 --verbose
echo -e "finished dada2 denoise."
echo -e $(date)

echo -e "step 4a: export 03_dada2_seq.qzv"
qiime feature-table tabulate-seqs \
 --i-data $WKPATH/03_dada2/qza/${PREFIX}03_seq.fasta.qza \
 --o-visualization $WKPATH/03_dada2/qzv/${PREFIX}03_seq.fasta.qzv

echo -e "step 4b: export 03_dada2_stats.tsv.qzv"
qiime metadata tabulate \
 --m-input-file $WKPATH/03_dada2/qza/${PREFIX}03_dada2_stats.tsv.qza \
 --p-page-size 400 \
 --o-visualization $WKPATH/03_dada2/qzv/${PREFIX}03_dada2_stats.tsv.qzv

echo -e "finished dada2 qzv."
echo -e $(date)

