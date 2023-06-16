# Pipeline Structure
## 01_import 
### PURPOSE
- import demultiplexed pair end fastq.gz sequences into QIIME2
### INPUT
- demultiplexed paired-end fastq.gz sequences in data folder 
### OUTPUT
- manifest.csv (intermediate)
- 01_import.fastq.qza (used in 03_dada2)
- 01_import.qzv (check seq quality)

## 03_dada2
### PURPOSE
- quality trim, filter, denoise sequences, chimera removal, and merging of paired end reads. 
### INPUT
- 01_import.fastq.qza (from: 01_import)
### OUTPUT
- 03_dada2_stats.tsv.qza (intermediate)
- 03_table.biom.qza (03b_decontam, 04_classify-filter)
- 03_seq.fasta.qza  (04_classify-filter)
- 03_seq.fasta.qzv (table of ASVs, visualization)
- 03_dada2_stats.tsv.qzv (check # of reads passing filters)

## 03b_decontam
### PURPOSE
- identify and remove contaminating sequences from sequence data 
### INPUT
- 03_table.biom.qza  # table from dada2
### OUTPUT
- 03_decontam_scores.qza (intermediate)
    - table of scores on how likely an ASV is contamination
- 03_decontam_table.qza (04_classify-filter.slurm)
    - table of sequences after removal of contaminating sequences

## 04_classify-filter
### PURPOSE
- classify sequences and filter based on taxonomy (remove eukaryotic/unassigned sequences)
### INPUT 
- 03_seq.fasta.qza (03_dada2)
### OUTPUT 
- taxonomy-${REF_DATABASE}.qza (Diversity.slurm, ANCOMBC)
    - taxonomy table based on assignments by classifier
- table.qza (ANCOMBC, Diversity.slurm)
    - table of ASVs in samples, filtered by taxonomy
- excluded_table.qza (intermediate)
    - excluded ASV table
- rep-seqs.qza (05_phylogeny, Diversity.slurm)
    - filtered sequences 
- excluded_rep-seqs.qza (intermediate)
    - excluded sequences
- excluded_table.qzv (visualization)
    - table of sequences excluded
- excluded_barplot.qzv (visualization)
    - barplot of excluded sequences by sample
- excluded_taxonomy-${REF_DATABASE}.qzv  (visualization)
    - table of excluded taxonomies / sequences (ie; eukaryotic)
## 05_ANCOMBC
### PURPOSE
- Run composition analysis with ANCOMBC 
### INPUT
- table.qza (04_classify-filter)
- taxonomy-${REF_DATABASE}.qza (04_classify-filter)
### OUTPUT
- filtered-table.qza
- "L$lvl-table-${REF_DATABASE}".qza
- $ANCOMBCfolder"/
    - "L$lvl"-ANCOMBC.qza (intermediate)
    - "L$lvl"-table-ANCOMBC.qzv  (visualizations)
    - "L$lvl"-barplot-ANCOMBC.qzv (visualizations)

## 06_rarefaction
### PURPOSE
- Filter feature table by prevalence and abundance
- Generate rarefaction beta/alpha to test rarefaction depth

### INPUT
- table.qza 
- rooted-tree.qza
- Set script/config.sh VARIABLES
   - $MAPname : metadata path
   - $SAMPLINGdepth : rarefaction depth, default 10,000
   - $QiimeMax : max rarefaction depth, usually set to max number of reads from all samples !!! change to -> $MaxDepth
   - $StepNumber : number of rarefaction depth steps to include between min (1) and $MaxDepth 

### OUTPUT
- filtered-table.qza (intermediate)
   -filtered table only contains samples that are in metadata file
- alpha-rarefaction.qzv (visualization)
   -rarefaction curve for alpha diversity metrics 
- braycurtis_beta_rarefaction.qzv (visualization)
- jaccard_beta_rarefaction.qzv (visualization)
- unweighted_unifrac_beta_rarefaction.qzv (visualization)
- weighted_unifrac_beta_rarefaction.qzv (visualization)
   -beta rarefaction for all beta diversity metrics 

## 06_diversity
### PURPOSE
- Filter feature table by prevalence and abundance
- Generate core diversity metrics based on filtered table
- Generate additional diversity metrics outside of core diversity 
    - abundance filtered jaccard, DEICODE

### INPUT
- table.qza (04-classify)
- rooted-tree.qza (05-phylogeny)
-taxonomy-${REF_DATABASE}.qza (04-classify)
- Set script/config.sh VARIABLES
     - $MAPname : metadata path
     - $SAMPLINGdepth : rarefaction depth, default 10,000
- DEICODE plugin must be installed

### OUTPUT
- filtered-table.qza (intermediate)
    - filtered table only contains samples that are in metadata file
- ab_filtered-table.qza (intermediate)
    - abundance filtered table, removed low prevalence and low abundance features
- rarefied_ab_filtered-table.qza (intermediate)
    - rarefied abundance table, rarefied to $SAMPLINGdepth
- core-metrics-results/ (intermediate-qza/visualizations-qzv)
  		-faith_pd_vector.qza
 		-observed_features_vector.qza 
 		-shannon_vector.qza
  		-evenness_vector.qza

  		-unweighted_unifrac_distance_matrix.qza
 		-weighted_unifrac_distance_matrix.qza
 		-jaccard_distance_matrix.qza
 		-bray_curtis_distance_matrix.qza

 		-unweighted_unifrac_pcoa_results.qza
 		-weighted_unifrac_pcoa_results.qzv
 		-jaccard_pcoa_results.qzv
 		-bray_curtis_pcoa_results.qzv

 		-unweighted_unifrac_emperor.qzv
 		-weighted_unifrac_emperor.qzv
 		-jaccard_emperor.qzv
 		-bray_curtis_emperor.qzv

- additional-metrics-results/ 
        -abfilter_jaccard_distance_matrix.qza
        -abfilter_jaccard_pcoa_results.qza
        -abfilter_jaccard_emperor.qzv

        -deicode_distance_matrix.qza
        -deicode_biplot_results.qza
        -deicode_emperor.qzv
        *add gemmeli / TEMPTED instead of DEICODE*

## 07_alphaStats
### PURPOSE
 - Test statistical signficant differences for alpha diversity based on numeric/categorical metadata

### INPUT
 - table.qza (04_classify-filter)
 - rooted-tree.qza (05_phylogeny)

### OUTPUT
 - alpha-group-signifance/	(visualizations)								
  	- faith-pd-group-significance.qzv	
 		-evenness-group-significance.qzv
 		-shannon-group-significance.qzv
 		-observed-features-group-significance.qzv
    -faith-numeric-correlation.qzv
    -evenness-numeric-correlation.qzv
    -shannon-numeric-correlation.qzv
    -observed-features-numeric-correlation.qzv

## 07_betaStats
### PURPOSE
- Test statistical signficant differences for beta diversity 
### INPUT
/diversity.slurm 
    -unweighted_unifrac_distance_matrix.qza (diversity.slurm)
    -weighted_unifrac_distance_matrix.qza (diversity.slurm)
    -jaccard_distance_matrix.qza (diversity.slurm)
    -bray_curtis_distance_matrix.qza (diversity.slurm)
- Set script/config.sh VARIABLES
  	- $MAPname : name of metadata file 
    - $metadataColumnNames : array of metadata column names to check for significant differences
### OUTPUT
- "${metric}-${col}-permanova.qzv"
    $metric = 'bray_curtis' 'jaccard' 'unweighted_unifrac' 'weighted_unifrac'
        assigned with $diversityMetrics var
    $col = $metadataColumnNames column name 