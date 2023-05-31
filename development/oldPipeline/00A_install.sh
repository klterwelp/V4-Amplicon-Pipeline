#!/bin/bash

# file: 00_install.sh

# making folders
mkdir -p ./log
mkdir -p ../meta

# load parameters
dos2unix ./config.sh
source ./config.sh

# create script log
exec &>> ./log/00_install.log

# Replacing working dir in all slurm files
sed -i "s/PART_NAME/${part_name}/g" *.slurm*

# Replacing email address in all slurm files
sed -i "s/EMAIL_ADDRESS/${email_address}/g" *.slurm*

