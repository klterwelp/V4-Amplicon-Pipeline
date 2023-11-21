#!/bin/bash
# ------------------ SCRIPT INFO: 00_checksum.sh -------------------- #

# PURPOSE
# - check the checksums for the downloaded data and original sequencing checksum
# INPUT
# - data folder containing sequencing "checksum" and fastq files for analysis
# - Set script/config.sh VARIABLES
#   - $WKPATH
# OUTPUT
# - not_downloaded.txt : files not downloaded that exist in sequencing checksum
# - downloaded.txt : downloaded files that exist in sequencing checksum
# - dwnld.checksum : checksum generated from fastq files in data folder
# - match.checksum : generated checksums checked against seq checksums
#                    TRUE = match seq checksum
#                    FALSE = do NOT match seq checksum

# ----------------- SCRIPT START -------------------- # 
# load parameters from config file
dos2unix ./config.sh
source ./config.sh

# start checksum log 
current_time=$(date "+%Y%m%d_%H%M%S")

exec &>> ../log/00_checksum_${current_time}.log

# setting input/output variables
echo -e "setting input/output variables"  
inputDir="${WKPATH}/data"
seqCheckTxt=("${inputDir}/"*.checksum)

outputDir="${WKPATH}/output/00-checksum"

# if previous output folder exists, delete it 
echo -e "checking for old folders, will remove to rerun analysis if md5sums are not identical" 

if [ -d "$outputDir" ]
then 
    echo -e "Previous output folder exists. Verifying existing checksum file. " 
    current_time=$(date "+%Y%m%d_%H%M%S")
    md5sum "${inputDir}/"*.fastq.gz > "${outputDir}/dwnld_${current_time}.checksum"
        if cmp -s "${outputDir}/dwnld_${current_time}.checksum" "${outputDir}/"dwnld.checksum; then
            echo "The md5sum files are identical."
            if cmp -s "$seqCheckTxt" "${outputDir}/seq.checksum"; then 
                echo "The sequencing checksum files are also identicial. No need to continue script."
                exit 0 
            else
                echo "The sequencing checksum files are not identical. Need to test checksums again. Deleting old output folders"
                rm -Rfv -- "$outputDir"
            fi
        else
            echo "The md5sum files are not identical. Need to generate new md5sums. Deleting old output folders"
            echo "Listing non-matching lines..."
            grep -Fxvf "${outputDir}/dwnld_${current_time}.checksum" "${outputDir}/"dwnld.checksum
            rm -Rfv -- "$outputDir"
        fi
fi 
    # -R deletes recursively, -f ignore non-existant files, -v verbose
    # '--'' : no more flags for rm command 

# making new import folders 
echo -e "creating new output folders" 
mkdir -p "${outputDir}"

# Does sequencing checksum file exist? 
echo "Sequencing checksum text file: $seqCheckTxt"
if [ ! -f "$seqCheckTxt" ]; then
    echo "Error: File $seqCheckTxt not found. Exiting script."
    exit 1
    else
        echo "File: $seqCheckTxt found. Copying to output folder"
        cp "$seqCheckTxt" "${outputDir}/seq.checksum"
fi

# Make declarative array to hold sequencing checksum information
declare -A seqChecksumsArray

echo "Making declarative array to hold sequencing checksum info..."

while IFS=' ' read -r filename checksum; do
    seqChecksumsArray["$filename"]=$checksum
done < "$seqCheckTxt"

# Make checksum array for downloaded fastq.gz files 
echo "Generate downloaded fastq file checksums"

md5sum "${inputDir}/"*.fastq.gz > "${outputDir}/"dwnld.checksum

echo "Making declarative array to hold downloaded checksum info..."

declare -A dwnlChecksumsArray 

while IFS=' ' read -r checksum fullpath; do
    filename=$(basename "$fullpath")
    dwnlChecksumsArray["$filename"]=$checksum
    done < "${outputDir}/dwnld.checksum"

# Test that filenames match 
echo "Identifying any files not downloaded..."

for filename in "${!seqChecksumsArray[@]}"; do
    dwnlChk=${dwnlChecksumsArray["$filename"]}

    if [ -z "$dwnlChk" ]; then 
        match="FALSE"
        echo "$filename" >> "${outputDir}/"not_downloaded.txt 
        else
        match="TRUE"
        echo "$filename" >> "${outputDir}/"downloaded.txt 
    fi
echo "$filename $match" >> "${outputDir}/"files.checksum
done
notdwl=$(wc -l < "${outputDir}/"not_downloaded.txt)
dwl=$(wc -l < "${outputDir}/"downloaded.txt)

echo "There are $notdwl files that were not downloaded but exist as files in seq checksum 
List of files in not_downloaded.txt"
echo "There are $dwl files that were downloaded AND exist as files in seq checksum. 
List of files in downloaded.txt"

echo "$dwl/${#dwnlChecksumsArray[@]} downloaded files exist within the sequencing checksum"

# Test that checksums match
echo "Testing checksums for matches between seq and downloaded checksums..."

for filename in "${!dwnlChecksumsArray[@]}"; do
    dwnlChk=${dwnlChecksumsArray["$filename"]}
    sqtChk=${seqChecksumsArray["$filename"]}

    if [ -z "$sqtChk" ]; then 
       match="not in seq.checksum"
       else 
        if [[ "$sqtChk" == "$dwnlChk" ]]; then
        match="TRUE"
        else
        match="FALSE"
        fi
    fi
    echo "$filename $match" >> "${outputDir}/"match.checksum
    done

numTrue=$(grep -c "TRUE" "${outputDir}/"match.checksum)
numFalse=$(grep -c "FALSE" "${outputDir}/"match.checksum)
echo "There are $numTrue fastq that match seq checksums.
There are $numFalse fastq that do NOT match seq checksums."

echo "checksum script complete"
