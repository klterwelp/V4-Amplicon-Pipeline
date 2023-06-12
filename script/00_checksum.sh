#!/bin/bash
# I'm going to rewrite this in R instead

# in data folder
checksumFile=$(ls *.checksum)

checksums=$( awk '{ print $2}' $checksumFile)
# this will take the second column of the checksum file to get the list of md5sum
md5sum --status -c $checksums && echo OK

# make checksum file to check against
#dataFiles=( $(ls ./*.fastq.gz)), doesn't work
# mapfile -t array < <(mycommand)

#mapfile -t dataVar < <(ls *.fastq.gz) 
# list of files in dataVar ending in fastq.gz 

dataArray=(*.fastq.gz)
if microcheck.
for file in "${dataArray[@]}"
do
md5sum $file >> microcheck.md5
done 
# makes our version of the md5 sum 

md5sum --status -c microcheck.md5
# checks that since making the md5 sum none of the files are changed