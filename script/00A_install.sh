#!/bin/bash
# ------------------ SCRIPT INFO: 00_install.sh -------------------- #

# PURPOSE
# - set up pipeline folders
# - replace partition name and email address in .slurm scripts
# INPUT
# - script folder containing all scripts ".slurm"
# - Set script/config.sh VARIABLES
#   - $email_address
#   - $part_name
# OUTPUT
# - make folders: rawData, cleanData, log, cache, output, report
# - replace partition name and email address based on config.sh

# ----------------- SCRIPT START -------------------- # 

# making folders for analysis 
mkdir -p ./{rawData,cleanData}/{data,meta}
mkdir -p ./{log,cache,output,report}
mkdir -p report/{graphs,docs}

# load parameters from config file
dos2unix ./config.sh
source ./config.sh

# create script log
exec &>> ./log/00_install.log

# replacing partition name in all slurm files
sed -i "s/PART_NAME/${part_name}/g" *.slurm*

# replacing email address in all slurm files
sed -i "s/EMAIL_ADDRESS/${email_address}/g" *.slurm*

