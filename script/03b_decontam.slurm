#!/bin/bash
#SBATCH --job-name=03_decontam
#SBATCH --partition=PART_NAME
#SBATCH --mem-per-cpu=25000
#SBATCH --output=log/03_decontam.%j.out
#SBATCH -c 4
#SBATCH --error=log/03_decontam.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=EMAIL_ADDRESS

#------------------ SCRIPT INFO: 03b_decontam.slurm --------------------#

# PURPOSE
# - identify and remove contaminating sequences from sequence data 
# INPUT
# - $WKPATH/03_dada2/qza/03_table.biom.qza  # table from dada2
# - Set script/config.sh VARIABLES
#   - $MAPname : name of metadata file 

# ----------------- SCRIPT START -------------------- # 

qiime quality-control decontam-identify \
    --i-table "$WKPATH/03_dada2/qza/03_table.biom.qza" \
    --m-metadata "$MAPname" \
    --p-method 'combined' \
    --p-freq-concentration-column $concCol \
    --p-prev-control-column $controlCol \
    --p-prev-control-indicator $controlName \
    --o-decontam-scores "03_decontam_scores.qza"

# concentration column would be concentration of DNA in each sample, prior to pooling
# define controls (via control column and control indicator)
# vignette: https://benjjneb.github.io/decontam/vignettes/decontam_intro.html

qiime quality-control decontam-remove \
    --i-decontam-scores "03_decontam_scores.qza" \
    --i-table "$WKPATH/03_dada2/qza/03_table.biom.qza" \
    --o-filtered-table "decontam_table.qza" 
