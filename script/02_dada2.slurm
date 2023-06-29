#!/bin/bash
#SBATCH --job-name=02_dada2
#SBATCH --partition=PART_NAME
#SBATCH --mem-per-cpu=25000
#SBATCH --output=../log/02_dada2.%j.out
#SBATCH -c 4
#SBATCH --error=../log/02_dada2.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: 02_dada2.slurm --------------------#

# PURPOSE
# - quality trim, filter, denoise sequences, chimera removal, and merging of paired end reads. 
# INPUT
# - 01_import.fastq.qza (from: 01_import)
# OUTPUT
# - 02_dada2_stats.tsv.qza (intermediate)
# - 02_table.biom.qza (04_classify-filter)
# - 02_seq.fasta.qza  (04_classify-filter)
# - 02_seq.fasta.qzv (table of ASVs, visualization)
# - 02_dada2_stats.tsv.qzv (check # of reads passing filters)

# ----------------- SCRIPT START -------------------- # 

dos2unix ./config.sh
source ./config.sh

# record time and method name, env vars
echo -e "$(date)"
echo -e "working path: " $WKPATH

# setting input/output variables
echo -e "setting input/output variables"  
inputDir="${WKPATH}/output/01-import/qza"
# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/02-dada2" 
outputDirQZA="${outputDir}/qza" 
outputDirQZV="${outputDir}/qzv"
# directories to place results from script

# if previous import folder exists, delete it 
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
 
echo -e "step 4: starting dada2 denoising..."

qiime dada2 denoise-paired \
 --i-demultiplexed-seqs "$inputDir/01_import.fastq.qza" \
 --p-trunc-len-f "$QiimeDada2FL" \
 --p-trunc-len-r "$QiimeDada2RL" \
 --p-trim-left-f "$QiimeDada2FLeft" \
 --p-trim-left-r "$QiimeDada2RLeft" \
 --o-denoising-stats "$outputDirQZA/02_dada2_stats.tsv.qza" \
 --o-table "$outputDirQZA/02_table.biom.qza" \
 --o-representative-sequences "$outputDirQZA/02_seq.fasta.qza" \
 --p-n-threads 4 \
 --verbose

echo -e "finished dada2 denoise."
echo -e "$(date)"

echo -e "step 4a: export 02_dada2_seq.qzv"
qiime feature-table tabulate-seqs \
 --i-data "$outputDirQZA/02_seq.fasta.qza" \
 --o-visualization "$outputDirQZV/02_seq.fasta.qzv"

echo -e "step 4b: export 02_dada2_stats.tsv.qzv"
qiime metadata tabulate \
 --m-input-file "$outputDirQZA/02_dada2_stats.tsv.qza" \
 --p-page-size 400 \
 --o-visualization "$outputDirQZV/02_dada2_stats.tsv.qzv"

echo -e "finished dada2 qzv."
echo -e "$(date)"

