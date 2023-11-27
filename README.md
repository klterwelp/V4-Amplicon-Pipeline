# V4_AmpliconPipeline

This is the project for 16S V4 analysis pipeline development. All updated scripts for 16S V4 amplicon analysis will be uploaded to this project. All amplicon analysis done through the Duke Microbiome Core Facility will pull from this project prior to running analyses. 

## How I use the pipeline:

1. Create project directory and subfolder for the scripts
```sh
mkdir -p {project-folder}/script
cd {project-folder}/script
```
2. Clone git repository into the script folder.
```sh
git clone git@gitlab.oit.duke.edu:duke-microbiome/v4_ampliconpipeline.git .
# the up-to-date pipeline is on gitlab for Duke
```
3. Fill out variables in config.sh.
```sh
part_name=""
email_address=""
PREFIX="{project-folder}"
```
4. Run installation script to make subfolders
```sh
cd script
sh 00A_install.sh
``` 
5. Copy data (demultiplexed FASTQ files) into data subfolder and ensure all data downloaded with checksum script
```sh
sh 00_checksum.sh
```
6. Activate a qiime2 conda environment
```sh
conda activate {qiime2-environment}
# insert your qiime2 environment name
# pipeline requires DEICODE plugin (diversity script) and RESCRIPt plugin installed (train classifier). 
```
7. Run scripts
To run any slurm/sbatch script:
```sh
cd script
sbatch script-name
```
The scripts are numbered based on when to complete them. 
Some can be run concurrently like 05_phylogeny and 05_ANCOMBC. 

- **00_trainClassifier.slurm**
  - train classifier based on database of choice
- **01_import.slurm**
  - This script imports demultiplexed, paired-end fastq.gz sequences into QIIME2
- **02_dada2.slurm**
  - quality trim, filter, denoise sequences, chimera removal, and merging of paired end reads. 
- **03_decontam.slurm**
  -  identify and remove contaminating sequences from sequence data
- **04_classify-filter.slurm**
  - classify sequences and filter based on taxonomy (remove eukaryotic/unassigned sequences)
- **05_ANCOMBC.slurm**
  - Run composition analysis with ANCOMBC 
- **05_phylogeny.slurm**
  - Generate a phylogenetic tree from filtered sequences 
- **05_zymoQC.slurm**
  - compare expected mock community composition and actual mock community composition
- **06a_rarefaction.slurm**
  - Generate alpha rarefaction curves and beta rarefaction to test rarefaction depth
- **06_diversity.slurm**
  - Generate diversity metrics based on filtered table
- **07_alphaStats.slurm**
  - Test statistical signficant differences for alpha diversity based on numeric/categorical metadata
- **07_betaStats.slurm**
  - Test statistical signficant differences for beta diversity
 
Not all of these scripts will need to be run. 
For example, I only train classifiers that I can't get from the qiime2 website. 
