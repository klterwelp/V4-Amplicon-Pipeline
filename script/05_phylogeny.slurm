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

#------------------ SCRIPT INFO: 05_phylogeny.slurm --------------------#

# PURPOSE
# - generate a phylogenetic tree from sequences  
# INPUT 
# - rep-seqs.qza (filtered sequences from 04_taxfilter) 
# OUTPUT 
# - aligned-rep-seqs.qza (intermediate) : aligned sequences
# - masked-alignment-rep-seqs.qza (interemdiate) : masked aligned sequences
# - unrooted-tree.qza (intermediate) : used to construct rooted tree
# - $treeQZA / rooted-tree.qza (Diversity.slurm) : phylogenetic diversity measurements 

# ----------------- SCRIPT START -------------------- # 

# load parameters
dos2unix ./config.sh
source ./config.sh

# setting input/output variables
echo -e "setting input/output variables"  
inputDir="${WKPATH}/output/04-classify/qza"
# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/05-phylogeny"
outputDirQZA="${outputDir}/qza" 
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
mkdir -p "${outputDir}/qza"
    # -p ; make parent directories if needed

echo -e "Input directory is...$inputDir" 

echo -e "Output directories are... 
main folder: $outputDir
qza: $outputDirQZA"

echo -e "finished setting up folders and variables" 
echo -e "$(date)"

# Phylogeny
echo -e "step 05: Begin Construction of Phylogenetic Tree"
echo -e "$(date)"
qiime phylogeny align-to-tree-mafft-iqtree \
--i-sequences "$inputDir/rep-seqs.qza" \
--o-alignment "${outputDir}/aligned-rep-seqs.qza" \
--o-masked-alignment "${outputDir}/masked-alignment-rep-seqs.qza" \
--o-tree "${outputDir}/unrooted-tree.qza" \
--o-rooted-tree "$treeQZA"

echo -e "Finished Construction of Phylogenetic Tree"
echo -e "$(date)"