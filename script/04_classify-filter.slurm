#!/bin/bash
#SBATCH --job-name=04_taxfilter
#SBATCH --partition=PART_NAME
#SBATCH --mem-per-cpu=25000
#SBATCH --output=log/04_taxfilter.%j.out
#SBATCH -c 4
#SBATCH --error=log/04_taxfilter.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: 04_classify_taxaFilter.slurm --------------------#

# PURPOSE
# - classify sequences and filter based on taxonomy (remove eukaryotic/unassigned sequences)
# INPUT 
# - 03_seq.fasta.qza (from: 03_dada2)
# - $MAPname (in meta/) -> required for excluded qzvs
# - Set script/config.sh VARIABLES
#   - $REF_FILE : path to trained classifier 
#   - $TABLEclassify : ASV table to filter from, either from DADA2 or decontam 
# OUTPUT 
# - taxonomy-${REF_DATABASE}.qza (Diversity.slurm, ANCOMBC)
#   - taxonomy table based on assignments by classifier
# - table.qza (ANCOMBC, Diversity.slurm)
#   - table of ASVs in samples, filtered by taxonomy
# - excluded_table.qza (intermediate)
#   - excluded ASV table
# - rep-seqs.qza (05_phylogeny, Diversity.slurm)
#   - filtered sequences 
# - excluded_rep-seqs.qza (intermediate)
#   - excluded sequences
# - excluded_table.qzv (visualization)
#   - table of sequences excluded
# - excluded_barplot.qzv (visualization)
#   - barplot of excluded sequences by sample
# - excluded_taxonomy-${REF_DATABASE}.qzv  (visualization)
#   - table of excluded taxonomies / sequences (ie; eukaryotic)

# ----------------- SCRIPT START -------------------- # 

# load parameters
dos2unix ./config.sh
source ./config.sh

# record time and method name, env vars
echo -e "$(date)"
echo -e "working path: " $WKPATH

# setting input/output variables
echo -e "setting input/output variables"  
inputDir="${WKPATH}/output/02-dada2/qza"
# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/04-classify"
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

# clasification, taxonomy
echo -e "step 04A: classify-sklearn ..."
 qiime feature-classifier classify-sklearn \
  --i-classifier "$REF_FILE" \
  --i-reads "$inputDir/02_seq.fasta.qza" \
  --o-classification "$outputDirQZA/taxonomy-${REF_DATABASE}.qza"

echo -e "finished classify-sklearn..."
echo -e "$(date)"

echo -e "step 04B: filter based on taxonomy, remove mitochondria & chloroplast seqs ..."
# filter based on taxonomy, remove mitochondria & chloroplast DNAs

qiime taxa filter-table \
  --i-table "$TABLEclassify" \
  --i-taxonomy "$outputDirQZA/taxonomy-${REF_DATABASE}.qza" \
  --p-exclude mitochondria,chloroplast,unassigned,eukaryota \
  --o-filtered-table $outputDirQZA/table.qza

qiime taxa filter-seqs \
  --i-sequences "$inputDir"/02_seq.fasta.qza \
  --i-taxonomy "$outputDirQZA/taxonomy-${REF_DATABASE}.qza" \
  --p-exclude mitochondria,chloroplast,unassigned,eukaryota \
  --o-filtered-sequences "$outputDirQZA"/rep-seqs.qza

# generate tables with filtered taxa only 

qiime taxa filter-table \
  --i-table "$TABLEclassify" \
  --i-taxonomy "$outputDirQZA/taxonomy-${REF_DATABASE}.qza" \
  --p-include mitochondria,chloroplast,unassigned,eukaryota \
  --o-filtered-table "$outputDirQZA"/excluded_table.qza
 
qiime taxa filter-seqs \
  --i-sequences "$inputDir"/02_seq.fasta.qza \
  --i-taxonomy "$outputDirQZA/taxonomy-${REF_DATABASE}.qza" \
  --p-include mitochondria,chloroplast,unassigned,eukaryota \
  --o-filtered-sequences "$outputDirQZA"/excluded_rep-seqs.qza

# visualizations of taxa excluded from final sequences and table

qiime feature-table summarize \
 --i-table "$outputDirQZA"/excluded_table.qza \
 --m-sample-metadata-file "$MAPname" \
 --o-visualization "$outputDirQZV"/excluded_table.qzv
 
qiime taxa barplot \
  --i-table "$outputDirQZA"/excluded_table.qza \
  --i-taxonomy "$outputDirQZA/taxonomy-${REF_DATABASE}.qza" \
  --m-metadata-file "$MAPname" \
  --o-visualization "$outputDirQZV"/excluded_barplot.qzv 
  
qiime metadata tabulate \
  --m-input-file "$outputDirQZA/taxonomy-${REF_DATABASE}.qza" $outputDirQZA/excluded_rep-seqs.qza \
  --o-visualization "$outputDirQZV/excluded_taxonomy-${REF_DATABASE}.qzv"  
  
 echo -e "finished filter based on taxonomy..."
 echo -e "$(date)"