#!/bin/bash

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#.             EDIT. BELOW. PARAMETERS.               #
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#

# ------------- GENERAL PARAMETERS ------------- #
# adjustable parameters used for multiple scripts

part_name=""
    # partition to use for SLURM scripts
    # default is "scavenger" partition
    # replaced from SLURM headers during 00A_install.sh

email_address=""
    # email address to send emails upon completion of SLURM script
    # replaced from SLURM headers during 00A_install.sh

PREFIX=""
    # PILastName-YYYYMMDD
    # Name of analysis folder 

WKPATH="/hpc/group/kimlab/Qiime2/${PREFIX}"
    # Path to the analysis folder 

TMPDIR="/work/klt75"
    # Temporary work directory location 

MAPname=""
    # enter entire path surrounded in quotes
    # include .txt / .tsv file extension with the file name and path
    # used for: 03_decontam, 04_classify-filter, diversity and ANCOMBC scripts
    # not used for: 01_import, 03_dada2, 05_phylogeny 

REF_DATABASE="silva"
    # name of reference database used for training classifier in 00_trainClassifier
    # also used for naming the taxonomic sequences in 04_classify-filter

controlCol="sample_type"
    # column name that contains whether samples are negative, mock, or sample
    # used for decontam, zymoQC, sample filter function

controlName="blank"
    # in controlCol, the name used for blank/negative controls 
    # used for decontam, sample filter function

mockname="zymo" 
    # in controlCol, the name used for zymo controls
    # used for zymoQC, sample filter function

# ----------------- GENERAL FILES -------------------- #
# files used in multiple scripts; do not edit manually

taxQZA="${WKPATH}/output/04-classify/${REF_DATABASE}/qza/taxonomy-${REF_DATABASE}.qza"
    # taxonomy file created by 04-classify
tableQZA="${WKPATH}/output/04-classify/${REF_DATABASE}/qza/table.qza"
    # filtered table of ASVs created by 04-classify
treeQZA="${WKPATH}/output/05-phylogeny/${REF_DATABASE}/rooted-tree.qza"
    # rooted tree from 05-phylogeny script

# ------------- TRAIN CLASSIFIER PARAMETERS ------------- # 
# variables used to train the classifier used in 04_classify-filter

fPrimer=GTGCCAGCMGCCGCGGTAA
rPrimer=GGACTACHVGGGTWTCTAAT
    # PCR primers (forward and reverse)
    # must be 5'-> 3' orientation
    # ensure that the sequences are only the biological primer section
reFasta=
    # path to database reference sequences
    # include file name and extension
reTaxonomy= 
    # path to database taxonomic classifications
    # include file name and extension

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

decontamMethod='combined'
    # 'combined' : uses both frequency and prevalence methods (default for core)
    # 'frequency' : uses DNA concentration to ID contam (not for low biomass)
    # 'prevalence' : compares features in controls vs samples (recommended for low biomass)

# ------------- CLASSIFY/FILTER PARAMETERS ------------- # 
# variables used for classifying taxonomy and filter unknown/eukaryotic seqs

REF_FILE="/hpc/group/kimlab/Qiime2/reference/qiime2-2022.8/silva-138-99-515-806-nb-classifier.qza"
    # location of classifier used for assigning taxonomy 

TABLEclassify="${WKPATH}/output/02-dada2/qza/02_table.biom.qza"
    # specify table used as input for filtering out taxa/sequences
    # use DADA2 table if skipping decontam, decontam table otherwise
    # if not using decontam: "${WKPATH}/output/02-dada2/qza/02_table.biom.qza"
    # if using decontam: "${WKPATH}/output/03-decontam/qza/03_decontam_table.qza"

# ------------------ ZYMO QC PARAMETERS ----------- #
MOCKrefseq="/hpc/group/kimlab/Qiime2/reference/zymo-refs/zymo-seqs.fasta" 
    # reference that contains the fasta sequences for the taxa in the mock community 
    # for zymo this would be in: "/hpc/group/kimlab/Qiime2/reference/zymo-refs/zymo-seqs.fasta"

MOCKtax="/hpc/group/kimlab/Qiime2/Kim20230512-ZymoBeadTest/meta/clean/zymo-taxonomy-sampleid.tsv"
    # expected taxonomy table 
    # the following path gives the expected frequency + taxonomy for the zymo mock community using SILVA database classifier
    # /hpc/group/kimlab/Qiime2/reference/zymo-refs/zymo-taxonomy.tsv
    # first column should be taxonomy
    # next columns names need to match the sample-id for the mock community samples  
    # if there are 2 mock communities then you would have three columns: 
    # 1) Taxonomy column with the taxonomy names following the name structure of the classifier database
    # 2) sample-ID#1 column with the relative frequency values based on the zymo mock community
    # 3) sample-ID#2 column, exactly the same as sample-ID#1 but with different column name
    # an example can be found in the following location: 
    # /hpc/group/kimlab/Qiime2/Kim20230512-ZymoBeadTest/meta/clean/zymo-taxonomy-sampleid.tsv

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

# 06 DIVERSITY 
featureNum=8
# adjusts number of arrows appearing on biplot
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
