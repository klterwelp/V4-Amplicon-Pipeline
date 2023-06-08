#!/bin/bash

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#.             EDIT. BELOW. PARAMETERS.               #
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#

part_name="scavenger"
email_address="klt75@duke.edu"

PREFIX="Mentz-20221025"
WKPATH="/hpc/group/kimlab/Qiime2/${PREFIX}"
TMPDIR="/work/klt75"

# DADA2 parameters
 QiimeDada2FL=220
 QiimeDada2RL=130
 QiimeDada2FLeft=0
 QiimeDada2RLeft=0

REF_DATABASE="silva"
REF_FILE="/hpc/group/kimlab/Qiime2/reference/qiime2-2022.8/silva-138-99-515-806-nb-classifier.qza"

#SET="total"
#SET="baseline"
#SET_SELECTION="samplefilter='keep'"
#MIN_FREQ=10000

#PHYLOGENY="align-to-tree-mafft-fasttree"
#PHYLOGENY="align-to-tree-mafft-raxml"

# for core metrics script
#QiimeDepth=0

# for alpha rarefaction 
QiimeMax=58245
StepNumber=10

DOWNPATH="/hpc/group/kimlab/Qiime2/Mentz-20221025/Mentz-20221025"

# Diversity-ANCOM-analysis parameters 
MAPname="map-noZymo.txt"
# requires .txt / .tsv file extension in the variable
metadataColumnNames=("col1" "col2" "col3")
# metadataColumnNames must be in the following format: 
# metadataColumnNames=("col1" "col2" "col3")
# where names are surrounded in quotes and separated by ONE space
# entire list surrounded in ()
# ensure that the metadata column names are an EXACT MATCH with metadata file

SAMPLINGdepth=10000

# ----------------------- ANCOMBC Variables ---------------------------- # 
# taxonomic level to collapse down to for ANCOMBC analysis: 
    # genus = 6
taxaLvl=6
