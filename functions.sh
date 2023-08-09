#!/bin/bash
# ------------------ SCRIPT INFO: functions.sh -------------------- #
# PURPOSE
# - Organization of code chunks used in more than one script

# ----------------- SCRIPT START -------------------- # 
filter_qiime_table() {
    outputTableFolder="$1" 
    # set variable for output $outputTableFolder
    # Remove negative and positive controls
    echo -e "Removing negative and positive controls..." 
    qiime feature-table filter-features \
        --i-table "$tableQZA" \
        --m-metadata-file "$MAPname" \
        --p-where "["$controlCol"] IN ('$controlName', '$mockname')" \
        --p-exclude-ids TRUE \
        --o-filtered-table "$outputTableFolder"/sample-table.qza 
    
    echo -e "Removing samples not in map file..." 
    # Remove samples not in map file
    qiime feature-table filter-samples \
        --i-table "$outputDir"/sample-table.qza \
        --m-metadata-file "$MAPname" \
        --o-filtered-table "$outputTableFolder"/filtered-table.qza

    echo -e "finished filtering table" 

}

check_and_create_folders() {
    outputDir="$1"
    shift 
    subfolders=("$@")

    echo -e "checking for old folders, will remove to rerun analysis" 
    if [ -d "$outputDir" ]; then
        echo -e "Previous output folder exists, deleting now..." 
        rm -Rfv -- "$outputDir"
    fi 

    echo -e "creating new output folders" 
    for folder in "${subfolders[@]}"
    do 
    mkdir -p "$outputDir/$folder"
    done
}
# shift removes the first parameter, leading the rest of the parameters to be used as subfolders

# example of usage: 
#   check_and_create_folders dada2 qza qzv table
#   check_and_create_folders $outputDir "${randomfolders[@]}"
#   where $outputDir=dada2 AND randomfolders=("qza" "qzv" "table")
#   creates: dada2/qza, dada2/qzv, dada2/table