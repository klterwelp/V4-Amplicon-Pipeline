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
# - more info in vignette: https://benjjneb.github.io/decontam/vignettes/decontam_intro.html

# INPUT
# - $WKPATH/03_dada2/qza/03_table.biom.qza  # table from dada2
# - Set script/config.sh VARIABLES
#   - $MAPname : name of metadata file 
#   - $concCol : concentration column with concentration of each sample after cleanup
#   - $controlCol : column that tells whether sample is negative/blank or experimental
#   - $controlName : inside controlCol, name used for negatives (ex: "blank")

# OUTPUT
# - 03_decontam_scores.qza (intermediate)
#   - table of scores on how likely an ASV is contamination
# - 03_decontam_table.qza (04_classify-filter.slurm)
#   - table of sequences after removal of contaminating sequences

# ----------------- SCRIPT START -------------------- # 

qiime quality-control decontam-identify \
    --i-table "$WKPATH/03_dada2/qza/03_table.biom.qza" \
    --m-metadata "$MAPname" \
    --p-method 'combined' \
    --p-freq-concentration-column $concCol \
    --p-prev-control-column $controlCol \
    --p-prev-control-indicator $controlName \
    --o-decontam-scores "03_decontam_scores.qza"

qiime quality-control decontam-remove \
    --i-decontam-scores "03_decontam_scores.qza" \
    --i-table "$WKPATH/03_dada2/qza/03_table.biom.qza" \
    --o-filtered-table "03_decontam_table.qza" 
