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
# - rooted-tree.qza (Diversity.slurm) : phylogenetic diversity measurements 

# ----------------- SCRIPT START -------------------- # 

# load parameters
dos2unix ./config.sh
source ./config.sh

# phylogeny
echo -e "step 05: Begin Construction of Phylogenetic Tree"
echo -e $(date)
qiime phylogeny align-to-tree-mafft-iqtree \
--i-sequences rep-seqs.qza \
--o-alignment aligned-rep-seqs.qza \
--o-masked-alignment masked-alignment-rep-seqs.qza \
--o-tree unrooted-tree.qza \
--o-rooted-tree rooted-tree.qza

echo -e "Finished Construction of Phylogenetic Tree"
echo -e $(date)

# Move final outputs to data analysis folder 
echo -e "Moving final outputs to data analysis folders"
echo -e $(date)

mkdir Core_Analysis_Files/Tables
mkdir Core_Analysis_Files/Sequences
mkdir Core_Analysis_Files/Phylogenetic_Trees
mv aligned-rep-seps.qza Core_Analysis_Files/Sequences
mv masked-alignment-rep-seqs.qza Core_Analysis_files/Sequences
mv unrooted-tree.qza Core_Analysis_Files/Phylogenetic_Trees