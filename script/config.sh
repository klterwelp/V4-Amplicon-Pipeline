#!/bin/bash

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#.             EDIT. BELOW. PARAMETERS.               #
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#

# ------------- GENERAL PARAMETERS ------------- #
# parameters used for multiple scripts

part_name="scavenger"
    # partition to use for SLURM scripts
    # default is "scavenger" partition
    # replaced from SLURM headers during 00A_install.sh

email_address="klt75@duke.edu"
    # email address to send emails upon completion of SLURM script
    # replaced from SLURM headers during 00A_install.sh

PREFIX="Mentz-20221025"
    # PILastName-YYYYMMDD
    # Name of analysis folder 

WKPATH="/hpc/group/kimlab/Qiime2/${PREFIX}"
    # Path to the analysis folder 

TMPDIR="/work/klt75"
    # Temporary work directory location 

MAPname="map-noZymo.txt"
    # enter entire path surrounded in quotes
    # include .txt / .tsv file extension with the file name and path
    # used for: 03_decontam, 04_classify-filter, diversity and ANCOMBC scripts
    # not used for: 01_import, 03_dada2, 05_phylogeny 

REF_DATABASE="silva"
    # name of reference database used for training classifier in 00_trainClassifier
    # also used for naming the taxonomic sequences in 04_classify-filter

# ------------- TRAIN CLASSIFIER PARAMETERS ------------- # 
# variables used to train the classifier used in 04_classify-filter

fPrimer=GTGCCAGCMGCCGCGGTAA
rPrimer=GGACTACHVGGGTWTCTAAT
    # must be 5'-> 3' orientation
    # ensure that the sequences are only the biological primer section
reFasta=
    # path to database reference sequences
    # include file name, end with : .fasta
reTaxonomy= 
    # path to database taxonomic classifications
    # include file name, end with : .txt

# ------------- DADA2 PARAMETERS ------------- # 
# variables used for DADA2 denoising

 QiimeDada2FL=220
    # position where FORWARD reads are truncated (remove 3' end)
    # usually select position just before quality score dips

 QiimeDada2RL=130
    # position where REVERSE reads are truncated (remove 3' end)
    # usually select position just before quality score dips

 QiimeDada2FLeft=0
    # position where FORWARD reads should be trimmed on 5' end
    # usually first few beginning bases read are lower quality 
 QiimeDada2RLeft=0
    # position where REVERSE reads should be trimmed on 5' end
    # usually first few beginning bases read are lower quality 

# ------------- DECONTAM PARAMETERS ------------- # 
# variables used for DECONTAM removal of contaminating sequences
concCol="ng_ul"
    # column that contains the concentrations of samples after beads cleanup

controlCol="sample_type"
    # column name that contains whether samples are blank or not

controlName="blank"
    # in controlCol, the name used for blank/negative controls 

# ------------- CLASSIFY/FILTER PARAMETERS ------------- # 
# variables used for classifying taxonomy and filter unknown/eukaryotic seqs

REF_FILE="/hpc/group/kimlab/Qiime2/reference/qiime2-2022.8/silva-138-99-515-806-nb-classifier.qza"
    # location of classifier used for assigning taxonomy 

TABLEclassify="$WKPATH/03_dada2/qza/03_table.biom.qza"
    # specify table used as input for filtering out taxa/sequences
    # use DADA2 table if skipping decontam, decontam table otherwise
    # if not using decontam: "$WKPATH/03_dada2/qza/03_table.biom.qza"
    # if using decontam: "03_decontam_table.qza"

# ------------- DIVERSITY PARAMETERS ------------- # 
# variables used for generating all diversity scripts

# 06 RAREFACTION

# Alpha rarefaction ----

QiimeMax=58245
    # set to maximum number of reads in all samples 

StepNumber=10
    # default = 10, number of rarefaction levels between max reads and 1

# 06 RAREFACTION AND DIVERSITY

SAMPLINGdepth=10000
    # rarefaction depth, default is 10,000 reads. 
    # adjust depending on rarefaction curve and beta rarefaction qzvs from 06_rarefaction

# 07 BETA STATS

metadataColumnNames=("col1" "col2" "col3")
    # use following format: 
    # metadataColumnNames=("col1" "col2" "col3")
    # column names are surrounded in quotes "" and separated by ONE space
    # entire array surrounded in ()
    # ensure that the metadata column names are an EXACT MATCH with metadata file

# ------------- ANCOMBC PARAMETERS ------------- # 
taxaLvl=(5 6)
    # taxonomic level to collapse down to for ANCOMBC analysis
    # default is 6, genus level
    # do multiple levels via: 
    # taxaLvl=(5 6)
    # lvl separated by ONE space
    # entire array surrounded in ()

ANCOMBCformula=("Supplement + Diet + Time" "Supplement + Diet" "Time")
    # Each formula in R model formulae format
        # Additional predictor variables are added with "+"
        # If you think the interactive variables use "*"
        # More info: https://stat.ethz.ch/R-manual/R-devel/library/stats/html/formula.html
    # use following format for each formula:  
    # ANCOMBCformula=("for1" "for2" "for3")
    # forumula surrounded in quotes "" and separated by ONE space
    # entire array surrounded in ()
    # ensure that the metadata column names in formula are an EXACT MATCH with metadata file
        # column names CANNOT contain "+/-*%" because these are used in formulae  

# ------------- ARCHIVED PARAMETERS ---------- # (Delete later)
#SET="total"
#SET="baseline"
#SET_SELECTION="samplefilter='keep'"
#MIN_FREQ=10000

#PHYLOGENY="align-to-tree-mafft-fasttree"
#PHYLOGENY="align-to-tree-mafft-raxml"

# for core metrics script
#QiimeDepth=0

#DOWNPATH="/hpc/group/kimlab/Qiime2/Mentz-20221025/Mentz-20221025"

# Diversity-ANCOM-analysis parameters 
# requires .txt / .tsv file extension in the variable