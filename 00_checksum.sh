#!/bin/bash

# Function to check the MD5 checksum of a file
check_md5sum() {
    local file
    file="$1"
    local md5sum_file
    md5sum_file="$2"

    # Calculate the MD5 checksum of the file
    local calculated_md5sum
    calculated_md5sum=$(md5sum "$file" | awk '{print $1}')

    # Read the expected MD5 checksum from the file
    local expected_md5sum
    expected_md5sum=$(awk -v filename="$file" '$2 == filename {print $1}' "$md5sum_file")
    ## awk -v = assign variable filename to value of $file
    ## if field 2 is equal to filename var print field 1
    ## use the file md5sum_file (argument 2 of the command)

    # Compare the calculated and expected MD5 checksums
    if [ "$calculated_md5sum" = "$expected_md5sum" ]; then
        echo "Checksum is valid: $file"
    else
        echo "Checksum is NOT valid: $file"
    fi
}

# Check if the script is called with the correct arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 <md5sum_list_file>"
    exit 1
fi

# Store the MD5 checksum list file path
md5sum_list_file="$1"

# Check if the MD5 checksum list file exists
if [ ! -f "$md5sum_list_file" ]; then
    echo "MD5 checksum list file not found: $md5sum_list_file"
    exit 1
fi

# Read each line of the MD5 checksum list file
while read -r line; do
    # Extract the MD5 checksum and file path from the line
    md5sum=$(echo "$line" | awk '{print $1}')
    file=$(echo "$line" | awk '{print $2}')

    # Check if the file exists
    if [ ! -f "$file" ]; then
        echo "File not found: $file"
    else
        # Call the function to check the MD5 checksum
        check_md5sum "$file" "$md5sum_list_file"
    fi
done < "$md5sum_list_file"