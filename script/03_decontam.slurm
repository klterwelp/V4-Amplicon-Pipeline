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

dos2unix ./config.sh
source ./config.sh

# record time and method name, env vars
echo -e "$(date)"
echo -e "working path: " "$WKPATH"

# setting input/output variables
echo -e "setting input/output variables"  
inputDir="${WKPATH}/output/02-dada2/qza"
# directory containing raw fastq.gz files 
outputDir="${WKPATH}/output/03-decontam" 
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

qiime quality-control decontam-identify \
    --i-table "$inputDir/02_table.biom.qza" \
    --m-metadata "$MAPname" \
    --p-method 'combined' \
    --p-freq-concentration-column "$concCol" \
    --p-prev-control-column "$controlCol" \
    --p-prev-control-indicator "$controlName" \
    --o-decontam-scores "$outputDirQZA/03_decontam_scores.qza"

qiime quality-control decontam-score-viz \
    --i-decontam-scores "$outputDirQZA/03_decontam_scores.qza" \
    --i-table "$inputDir/02_table.biom.qza" \
    --o-visualization "$outputDirQZV/03_decontam_scores.qzv" 
    
qiime quality-control decontam-remove \
    --i-decontam-scores "$outputDirQZA/03_decontam_scores.qza" \
    --i-table "$inputDir/02_table.biom.qza" \
    --o-filtered-table "$outputDirQZA/03_decontam_table.qza" 
