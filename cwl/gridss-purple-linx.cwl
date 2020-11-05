#!/usr/bin/env cwl-runner

cwlVersion: v1.1
class: Workflow

# Metadata
id: gridss-purple-linx
label: Gridss Purple Linx
doc: |
  Run gridss-gripss-amber-cobalt-purple-linx as steps in a workflow

requirements:
  StepInputExpressionRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement:
    expressionLib:
    - var specified_name_or_sample_name_prefix = function(specified_name, sample_name, sample_type){
        /*
        If specified_name isn't null, return that.
        Otherwise return sample_name + "_N" if sample_type is normal
        or sample_name + "_T" if sample_type is tumour
        */
        if (specified_name !== null){
          return specified_name;
        } else if (sample_type === "normal") {
          return sample_name + "_N";
        } else if (sample_type === "tumor") {
          return sample_name + "_T";
        } else {
        /*
        Unsure what happened here
        */
          return "";
        }
      }

inputs:
  # Workflow parameters
  sample_name:
    type: string
    doc: |
      sample name - default name of the sample.
  tumor_bam:
    type: File
    doc: |
      tumour BAM file
    secondaryFiles:
      - pattern: ".bai"
        required: true
  normal_bam:
    type: File
    doc: |
      matched normal BAM file
    secondaryFiles:
      - pattern: ".bai"
        required: true
  snvvcf:
    type: File
    doc: |
        A somatic SNV VCF with the AD genotype field populated.
    secondaryFiles:
      - pattern: ".tbi"
        required: false
  fasta_reference:
    type: File
    doc: |
      reference genome fasta file with the following secondary files
    secondaryFiles:
      - pattern: ".fai"
        required: true
      - pattern: "^.dict"
        required: true
  bwa_reference_files:
    type: File[]?
    doc: |
      Bwa reference files to complement the fasta reference
      Note, tools will need to mount these files in the same directory as the fasta reference.
      Nameroot must equal the basename to the fasta reference for each file
  reference_cache_files_gridss:
    type: File[]?
    doc: |
      Skips creation of the reference genome in the gridss step if provided.
      Should have suffixes .grdss_cache and .img with the fasta_reference basename as the nameroot.
      Note, tools will need to mount this file in the same directory as the fasta reference
  gc_profile:
    type: File
    doc: |
      .cnp file of GC in reference genome. 1k bins.
  breakend_pon:
    type: File
    doc: |
      Single breakend pon bed file
  breakpoint_pon:
    type: File
    doc: |
      Paired breakpoint pon bedpe file
  breakpoint_hotspot:
    type: File
    doc: |
      Paired breakpoint hotspot bedpe file or known fusion pairs
  validation_stringency:
    type: string?
    doc: |
      htsjdk SAM/BAM validation level (STRICT (default), LENIENT, or SILENT)
    default: "STRICT"
  # Optional workflow args
  normal_sample:
    type: string?
    doc: |
      sample name of matched normal (Default: \${sample}_N)
      Must match that in the input vcf file
  tumor_sample:
    type: string?
    doc: |
      sample name of tumor. Must match the somatic snvvcf sample name. (Default: \${sample}_T)
  # Gridss - specific options
  repeatmaskerbed_gridss:
    type: File?
    doc: |
      Optional - bedops rmsk2bed BED file for genome.
  blacklist_gridss:
    type: File?
    doc: |
      Optional - BED file containing regions to ignore
  threads_gridss:
    type: int?
    doc: |
      Number of threads to use - set to 8 by default
  jvmheap_gridss:
    type: string?
    doc: |
      JVM heap size for running gridss - defaults to 27.5g
  assembly_gridss:
    type: string?
    doc: |
      location of the GRIDSS assembly BAM. This file will be created by GRIDSS.
  jar_gridss:
    type: string?
    doc: |
      location of GRIDSS jar
    default: "/opt/gridss/gridss-2.9.4-gridss-jar-with-dependencies.jar"
  workdir_gridss:
    type: string?
    doc: |
      location of gridss working directory
  steps_gridss:
    type: string?
    doc: |
      Optional - processing steps to run. Defaults to all steps.
      Multiple steps are specified using comma separators.
      Possible steps are: setupreference, preprocess, assemble, call, all.
      WARNING: multiple instances of GRIDSS generating reference files at the same time will result in file corruption.
      Make sure these files are generated before runninng parallel GRIDSS jobs.
    default: "all"
  configuration_gridss:
    type: File?
    doc: |
      Optional configuration file used to override default GRIDSS setting
  externalaligner_gridss:
    type: boolean?
    doc: |
      Optional - use the system version of bwa instead of the in-process version packaged with GRIDSS
  maxcoverage_gridss:
    type: int?
    doc: |
      Optional - maximum coverage. Regions with coverage in excess of this are ignored.
  picardoptions_gridss:
    type: string?
    doc: |
      Currently Deprecated due to IAP having linkMerge issues
      Optional - additional standard Picard command line options.
      Useful options include VALIDATION_STRINGENCY=LENIENT and COMPRESSION_LEVEL=0.
      See https://broadinstitute.github.io/picard/command-line-overview.html
  useproperpair_gridss:
    type: boolean?
    doc: |
      use SAM 'proper pair' flag to determine whether a read pair is discordant.
      Default: use library fragment size distribution to determine read pair concordance
  concordantreadpairdistribution_gridss:
    type: float?
    doc: |
      portion of 6 sigma read pairs distribution considered concordantly mapped. Default: 0.995
  keepTempFiles_gridss:
    type: boolean?
    doc: |
      keep intermediate files. Not recommended except for debugging due to the high disk usage.
  nojni_gridss:
    type: boolean?
    doc: |
      do not use JNI native code acceleration libraries (snappy, GKL, ssw, bwa).
  jobindex_gridss:
    type: boolean?
    doc: |
      zero-based assembly job index (only required when performing parallel assembly across multiple computers)
  jobnodes_gridss:
    type: boolean?
    doc: |
      total number of assembly jobs (only required when performing parallel assembly across multiple computers). Note than an assembly jobs is required after all indexed jobs have been completed to gather the output files together.
  # Gripss - specific options

  hard_max_normal_absolute_support_gripss:
    type: float?
    doc: |
      Hard max normal absolute support
  hard_max_normal_relative_support_gripss:
    type: float?
    doc: |
      Hard max normal relative support
  hard_min_tumor_qual_gripss:
    type: int?
    doc: |
      Hard min tumor qual
  max_hom_length_short_inv_gripss:
    type: int?
    doc: |
      Max homology length short inversion
  max_inexact_hom_length_short_del_gripss:
    type: int?
    doc: |
      Max inexact homology length short del
  max_short_strand_bias_gripss:
    type: float?
    doc: |
      Max short strand bias
  min_length_gripss:
    type: int?
    doc: |
      Min length
  min_normal_coverage_gripss:
    type: int?
    doc: |
      Min normal coverage
  min_qual_break_end_gripss:
    type: int?
    doc: |
      Min qual break end
  min_qual_break_point_gripss:
    type: int?
    doc: |
      Min qual break point
  min_qual_rescue_mobile_element_insertion_gripss:
    type: int?
    doc: |
      Min tumor allelic frequency
  min_tumor_af_gripss:
    type: float?
    doc: |
      Min tumor allelic frequency [0.005]
  soft_max_normal_relative_support_gripss:
    type: float?
    doc: |
      Max normal support
  # Amber options
  bafsnps_amber:
    type: File?
    doc: |
      bed file of het SNP locations used by amber as -loci
  threads_amber:
    type: int?
    doc: |
      Number of threads used for amber step
  min_mapping_quality_amber:
    type: int?
    doc: |
      Minimum mapping quality for an alignment to be used
  min_base_quality_amber:
    type: int?
    doc: |
      Minimum quality for a base to be considered
  min_depth_percent_amber:
    type: float?
    doc: |
      Max percentage of median depth
  max_depth_percent_amber:
    type: float?
    doc: |
      Only include reference sites with read depth
      within max percentage of median reference read depth
  min_het_af_percent_amber:
    type: float?
    doc: |
      Min heterozygous AF%
  max_het_af_percent_amber:
    type: float?
    doc: |
      Max heterozygous AF%
  # Cobalt Options
  threads_cobalt:
    type: int?
    doc: |
      Number of threads to run cobalt command
  min_quality_cobalt:
    type: int?
    doc: |
      Min calling quality
  # Purple options
  threads_purple:
    type: int?
    doc: |
      Number of  threads
  no_charts_purple:
    type: boolean?
    doc: |
      Disables creation of (non-circos) charts
  max_ploidy_purple:
    type: float?
    doc: |
      Maximum ploidy (default 8.0)
  min_ploidy_purple:
    type: float?
    doc: |
      Minimum ploidy (default 1.0)
  somatic_min_peak_purple:
    type: int?
    doc: |
      Minimum number  of somatic  variants to  consider a  peak. Default  50.
  somatic_min_variants_purple:
    type: int?
    doc: |
      Minimum number of somatic  variants  required to  assist highly  diploid fits.  Default 10.
  somatic_min_purity_spread_purple:
    type: float?
    doc: |
      Minimum spread  within  candidate  purities before  somatics can be  used. Default  0.15
  somatic_min_purity_purple:
    type: float?
    doc: |
      Somatic fit  will not be  used if both  somatic and  fitted purities  are less than  this value.  Default 0.17
  somatic_penalty_weight_purple:
    type: float?
    doc: |
      Proportion of somatic  deviation to  include in  fitted purity  score. Default  1.
  highly_diploid_percentage_purple:
    type: float?
    doc: |
      Proportion of  genome that  must be diploid  before using  somatic fit.  Default 0.97.
  # Optional Smoothing Arguments
  min_diploid_tumor_ratio_count_purple:
    type: int?
    doc: |
      Minimum ratio  count while  smoothing  before diploid  regions become  suspect.
  min_diploid_tumor_ratio_count_centromere_purple:
    type: int?
    doc: |
      Minimum ratio  count while  smoothing  before diploid  regions become  suspect while  approaching  centromere.
  min_purity_purple:
    type: float?
    doc: |
      Minimum purity  (default 0.08)
  max_purity_purple:
    type: float?
    doc: |
      Maximum purity  (default 1.0)
  purity_increment_purple:
    type: float?
    doc: |
      Purity  increment  (default 0.01)
  max_norm_factor_purple:
    type: float?
    doc: |
      Maximum norm factor (default  2.0)
  min_norm_factor_purple:
    type: float?
    doc: |
      Minimum norm factor (default  0.33)
  norm_factor_increment_purple:
    type: float?
    doc: |
      Norm factor increments  (default  0.01)
  ploidy_penalty_factor_purple:
    type: float?
    doc: |
      Penalty factor to apply to the  number of copy  number events
  ploidy_penalty_min_purple:
    type: float?
    doc: |
      Minimum ploidy penalty
  ploidy_penalty_min_standard_deviation_per_ploidy_purple:
    type: float?
    doc: |
      Minimum ploidy  penalty  standard  deviation to be  applied
  ploidy_penalty_standard_deviation_purple:
    type: float?
    doc: |
      Standard  deviation of  normal  distribution  modelling  ploidy  deviation from  whole number
  ploidy_penalty_sub_min_additional_purple:
    type: float?
    doc: |
      Additional  penalty to  apply to major  allele < 1 or  minor allele <  0
  ploidy_penalty_sub_one_major_allele_multiplier_purple:
    type: float?
    doc: |
      Penalty  multiplier  applied to  major allele <  1
  # LINX options
  check_fusions_linx:
    type: boolean?
    doc: |
      Optional - discover and annotate gene fusions
  check_drivers_linx:
    type: boolean?
    doc: |
      Optional - Discover and annotate gene fusions
  fragile_site_file_linx:
    type: File?
    doc: |
      list of known fragile sites - specify Chromosome,PosStart,PosEnd - fragile_sites.csv
  line_element_file_linx:
    type: File?
    doc: |
      list of known LINE elements - specify Chromosome,PosStart,PosEnd - line_elements.csv
  replication_origins_file_linx:
    type: File?
    doc: |
      optional - Replication timing input - in BED format with replication timing as the 4th column -
      heli_rep_origins.bed
  viral_hosts_file_linx:
    type: File?
    doc: |
      optional - list of known viral hosts - Refseq_id,Virus_name = viral_host_ref.csv
  gene_transcripts_dir_linx:
    type: Directory?
    doc: |
      Directory for Ensembl reference files - see instructions for generation below.
      /path_to_ensembl_data_cache/
  # Clustering
  proximity_distance_linx:
    type: int?
    doc: |
      Optional - (default = 5000), minimum distance to cluster SVs
  chaining_sv_limit_linx:
    type: int?
    doc: |
      threshold for # SVs in clusters to skip chaining routine (default = 2000)
  # Fusion analysis
  log_reportable_fusion_linx:
    type: boolean?
    doc: |
      Only log reportable fusions
  known_fusion_file_linx:
    type: File?
    doc: |
      Known fusion reference data - known pairs, promiscuous 5' and 3' genes,
      IG regions and exon DELs & DUPs
  fusion_gene_distance_linx:
    type: int?
    doc: |
      Distance upstream of gene to consider a breakend applicable
  restricted_fusion_genes_linx:
    type: string?
    doc: |
      Restrict fusion search to specified genes, separated by ';'
  log_debug_linx:
    type: boolean?
    doc: |
      logs in debug mode
  # Linx visualiser options
  circos_linx_visualiser:
    type: string?
    doc: |
      Path to circos binary
    default: "/usr/local/bin/circos"
  inner_radius_linx_visualiser:
    type: float?
    doc: |
      Innermost starting radius of minor-allele ploidy track
  outer_radius_linx_visualiser:
    type: float?
    doc: |
      Outermost ending radius of chromosome track
  gap_radius_linx_visualiser:
    type: float?
    doc: |
      Radial gap between tracks
  exon_rank_radius_linx_visualiser:
    type: float?
    doc: |
      Radial gap left for exon rank labels
  # Relative Track Size
  gene_relative_size_linx_visualiser:
    type: float?
    doc: |
      Size of gene track relative to segments and copy number alterations
  segment_relative_size_linx_visualiser:
    type: float?
    doc: |
      Size of segment (derivative chromosome) track relative to copy number alterations and genes
  cna_relative_size_linx_visualiser:
    type: float?
    doc: |
      Size of gene copy number alterations (including major/minor allele) relative to genes and segments
  min_label_size_linx_visualiser:
    type: int?
    doc: |
      Minimum size of labels in pixels
  max_label_size_linx_visualiser:
    type: int?
    doc: |
      Maximum size of labels in pixels
  max_gene_characters_linx_visualiser:
    type: int?
    doc: |
      Maximum allowed gene length before applying scaling them
  max_distance_labels_linx_visualiser:
    type: int?
    doc: |
      Maximum number of distance labels before removing them
  max_position_labels_linx_visualiser:
    type: int?
    doc: |
      Maximum number of position labels before increasing distance between labels
  exact_position_linx_visualiser:
    type: int?
    doc: |
      Display exact positions at all break ends
  min_line_size_linx_visualiser:
    type: int?
    doc: |
      Minimum size of lines in pixels
  max_line_size_linx_visualiser:
    type: int?
    doc: |
      Maximum size of lines in pixels
  glyph_size_linx_visualiser:
    type: int?
    doc: |
      Size of glyphs in pixels
  # Interpolate Positions
  interpolate_cna_positions_linx_visualiser:
    type: boolean?
    doc: |
      Interpolate copy number positions rather than adjust scale
  interpolate_exon_positions_linx_visualiser:
    type: boolean?
    doc: |
      Interpolate exon positions rather than adjust scale
  # Chromosome Panel
  chr_range_height_linx_visualiser:
    type: int?
    doc: |
      Chromosome range height in pixels per row
  chr_range_columns_linx_visualiser:
    type: int?
    doc: |
      Maximum chromosomes per row
  fusion_height_linx_visualiser:
    type: int?
    doc: |
      Height of each fusion in pixels
  fusion_legend_rows_linx_visualiser:
    type: int?
    doc: |
      Number of rows in protein domain legend
  fusion_legend_height_per_row_linx_visualiser:
    type: int?
    doc: |
      Height of each row in protein domain legend
  clusterId_linx_visualiser:
    type: boolean?
    doc: |
      Only generate image for specified comma separated clusters
  chromosome_linx_visualiser:
    type: boolean?
    doc: |
      Only generate images for specified comma separated chromosomes
  threads_linx_visualiser:
    type: int?
    doc: |
      Number of threads to use
  include_line_elements_linx_visualiser:
    type: boolean?
    doc: |
      Include line elements in chromosome visualisations (excluded by default)
  gene_linx_visualiser:
    type: boolean?
    doc: |
      Add canonical transcriptions of supplied comma-separated genes to image.
      Requires config 'gene_transcripts_dir' to be set as well.

steps:
  # Preprocessing step
  get_tumor_sample_name:
    in:
      defined_string:
        source: tumor_sample
      fall_back_string:
        source: sample_name
        valueFrom: "$(self)_T"
    out:
      - out_string
    run: expressions/string_or_default.cwl
  get_normal_sample_name:
    in:
      defined_string:
        source: normal_sample
      fall_back_string:
        source: sample_name
        valueFrom: "$(self)_N"
    out:
      - out_string
    run: expressions/string_or_default.cwl
  gridss_step:
    in:
      input_bams:
        source: [normal_bam, tumor_bam]
        linkMerge: merge_flattened
      reference:
        source: fasta_reference
      bwa_reference_files:
        source: bwa_reference_files
      gridss_reference_cache_files:
        source: reference_cache_files_gridss
      output:
        source: sample_name
        valueFrom: "$(self).unfiltered.vcf.gz"
      workingdir:
        source: sample_name
        valueFrom: "$(self)_gridss/"
      assembly:
        source: sample_name
        valueFrom: "$(self).gridss-assembly.bam"
      threads:
        source: threads_gridss
      jvmheap:
        source: jvmheap_gridss
      blacklist:
        source: blacklist_gridss
      repeatmaskerbed:
        source: repeatmaskerbed_gridss
      picardoptions:
        source: validation_stringency
        valueFrom: "VALIDATION_STRINGENCY=$(self)"
      labels:
        source: [get_normal_sample_name/out_string, get_tumor_sample_name/out_string]
        linkMerge: merge_flattened
      jar:
        source: jar_gridss
      steps:
        source: steps_gridss
      configuration:
        source: configuration_gridss
      externalaligner:
        source: externalaligner_gridss
      maxcoverage:
        source: maxcoverage_gridss
      useproperpair:
        source: useproperpair_gridss
      concordantreadpairdistribution:
        source: concordantreadpairdistribution_gridss
      keepTempFiles:
        source: keepTempFiles_gridss
      nojni:
        source: nojni_gridss
      jobindex:
        source: jobindex_gridss
      jobnodes:
        source: jobnodes_gridss
    out:
      - out_vcf
      - assembly_bam
    run: tools/gridss-2.9.4.cwl
  gridss_index_vcf_step:
    in:
      gzipped_vcf:
        source: gridss_step/out_vcf
    out:
      - indexed_vcf
    run: tools/tabix-0.2.6.nolisting.cwl
  gripss_step:
    in:
      input_vcf:
        source: gridss_index_vcf_step/indexed_vcf
      output_vcf:
        source: sample_name
        valueFrom: "$(self).vcf.gz"
      ref_genome:
        source: fasta_reference
      breakend_pon:
        source: breakend_pon
      breakpoint_hotspot:
        source: breakpoint_hotspot
      breakpoint_pon:
        source: breakpoint_pon
      hard_max_normal_absolute_support:
        source: hard_max_normal_absolute_support_gripss
      hard_max_normal_relative_support:
        source: hard_max_normal_relative_support_gripss
      hard_min_tumor_qual:
        source: hard_min_tumor_qual_gripss
      max_hom_length_short_inv:
        source: max_hom_length_short_inv_gripss
      max_inexact_hom_length_short_del:
        source: max_inexact_hom_length_short_del_gripss
      max_short_strand_bias:
        source: max_short_strand_bias_gripss
      min_length:
        source: min_length_gripss
      min_normal_coverage:
        source: min_normal_coverage_gripss
      min_qual_break_end:
        source: min_qual_break_end_gripss
      min_qual_break_point:
        source: min_qual_break_point_gripss
      min_qual_rescue_mobile_element_insertion:
        source: min_qual_rescue_mobile_element_insertion_gripss
      min_tumor_af:
        source: min_tumor_af_gripss
      soft_max_normal_relative_support:
        source: soft_max_normal_relative_support_gripss
    out:
      - gridss_filtered_vcf
    run: tools/gripss-1.8.cwl
  gripss_hard_filter_vcf_step:
    in:
      input_vcf:
        source: gripss_step/gridss_filtered_vcf
      output_vcf:
        source: sample_name
        valueFrom: "$(self).filtered.vcf.gz"
    out:
      - gridss_hard_filtered_vcf
    run: tools/gripss-hardfilter-1.8.cwl
  amber_step:
    in:
      reference:
        source: get_normal_sample_name/out_string
      reference_bam:
        source: normal_bam
      tumor:
        source: get_tumor_sample_name/out_string
      tumor_bam:
        source: tumor_bam
      output_dir:
        source: sample_name
        valueFrom: "$(self)_amber"
      loci:
        source: bafsnps_amber
      threads:
        source: threads_amber
      min_mapping_quality:
        source: min_mapping_quality_amber
      min_base_quality:
        source: min_base_quality_amber
      min_depth_percent:
        source: min_depth_percent_amber
      max_depth_percent:
        source: max_depth_percent_amber
      min_het_af_percent:
        source: min_het_af_percent_amber
      max_het_af_percent:
        source: max_het_af_percent_amber
      validation_stringency:
        source: validation_stringency
    out:
      - outdir
    run: tools/amber-3.5.cwl
  cobalt_step:
    in:
      reference:
        source: get_normal_sample_name/out_string
      reference_bam:
        source: normal_bam
      tumor:
        source: get_tumor_sample_name/out_string
      tumor_bam:
        source: tumor_bam
      output_dir:
        source: sample_name
        valueFrom: "$(self)_cobalt"
      gc_profile:
        source: gc_profile
      threads:
        source: threads_cobalt
      min_quality:
        source: min_quality_cobalt
    out:
      - outdir
    run: tools/cobalt-1.10.cwl
  purple_step:
    in:
      reference:
        source: get_normal_sample_name/out_string
      tumor:
        source: get_tumor_sample_name/out_string
      output_dir:
        source: sample_name
        valueFrom: "$(self)_purple"
      amber:
        source: amber_step/outdir
      cobalt:
        source: cobalt_step/outdir
      gc_profile:
        source: gc_profile
      ref_genome:
        source: fasta_reference
      threads:
        source: threads_purple
      somatic_vcf:
        source: snvvcf
      structural_vcf:
        source: gripss_hard_filter_vcf_step/gridss_hard_filtered_vcf
      sv_recovery_vcf:
        source: gripss_step/gridss_filtered_vcf
      no_charts:
        source: no_charts_purple
      max_ploidy:
        source: max_ploidy_purple
      min_ploidy:
        source: min_ploidy_purple
      somatic_min_peak:
        source: somatic_min_peak_purple
      somatic_min_variants:
        source: somatic_min_variants_purple
      somatic_min_purity_spread:
        source: somatic_min_purity_spread_purple
      somatic_min_purity:
        source: somatic_min_purity_purple
      somatic_penalty_weight:
        source: somatic_penalty_weight_purple
      highly_diploid_percentage:
        source: highly_diploid_percentage_purple
      min_diploid_tumor_ratio_count:
        source: min_diploid_tumor_ratio_count_purple
      min_diploid_tumor_ratio_count_centromere:
        source: min_diploid_tumor_ratio_count_centromere_purple
      min_purity:
        source: min_purity_purple
      max_purity:
        source: max_purity_purple
      purity_increment:
        source: purity_increment_purple
      max_norm_factor:
        source: max_norm_factor_purple
      min_norm_factor:
        source: min_norm_factor_purple
      norm_factor_increment:
        source: norm_factor_increment_purple
      ploidy_penalty_factor:
        source: ploidy_penalty_factor_purple
      ploidy_penalty_min:
        source: ploidy_penalty_min_purple
      ploidy_penalty_min_standard_deviation_per_ploidy:
        source: ploidy_penalty_min_standard_deviation_per_ploidy_purple
      ploidy_penalty_standard_deviation:
        source: ploidy_penalty_standard_deviation_purple
      ploidy_penalty_sub_min_additional:
        source: ploidy_penalty_sub_min_additional_purple
      ploidy_penalty_sub_one_major_allele_multiplier:
        source: ploidy_penalty_sub_one_major_allele_multiplier_purple
    out:
      - outdir
      # Structural vcf explicitly required
      - structural_vcf_out
    run: tools/purple-2.51.cwl
  linx_step:
    in:
      sample:
        source: get_tumor_sample_name/out_string
      sv_vcf:
        source: purple_step/structural_vcf_out
      purple_dir:
        source: purple_step/outdir
      output_dir:
        source: sample_name
        valueFrom: "$(self)_linx"
      check_fusions:
        source: check_fusions_linx
      check_drivers:
        source: check_drivers_linx
      fragile_site_file:
        source: fragile_site_file_linx
      line_element_file:
        source: line_element_file_linx
      replication_origins_file:
        source: replication_origins_file_linx
      viral_hosts_file:
        source: viral_hosts_file_linx
      gene_transcripts_dir:
        source: gene_transcripts_dir_linx
      proximity_distance:
        source: proximity_distance_linx
      chaining_sv_limit:
        source: chaining_sv_limit_linx
      log_reportable_fusion:
        source: log_reportable_fusion_linx
      known_fusion_file:
        source: known_fusion_file_linx
      fusion_gene_distance:
        source: fusion_gene_distance_linx
      restricted_fusion_genes:
        source: restricted_fusion_genes_linx
      write_vis_data:
        valueFrom: ${ return true; }
      log_debug:
        source: log_debug_linx
    out:
      - outdir
      # Optional outputs when -write_vis_data in linx tool set to true
      # Required for visualiser step
      - vis_segments
      - vis_sv_data
      - vis_protein_domain
      - fusions_detailed
      - vis_copy_number
      - vis_gene_exon
    run: tools/linx-1.11.cwl
  linx_visualiser_step:
    in:
      sample:
        source: get_tumor_sample_name/out_string
      plot_out:
        source: sample_name
        valueFrom: "$(self)_linx_visualiser_plots"
      data_out:
        source: sample_name
        valueFrom: "$(self)_linx_visualiser_data"
      segment:
        source: linx_step/vis_segments
      link:
        source: linx_step/vis_sv_data
      protein_domain:
        source: linx_step/vis_protein_domain
      fusion:
        source: linx_step/fusions_detailed
      cna:
        source: linx_step/vis_copy_number
      exon:
        source: linx_step/vis_gene_exon
      circos:
        source: circos_linx_visualiser
      inner_radius:
        source: inner_radius_linx_visualiser
      outer_radius:
        source: outer_radius_linx_visualiser
      gap_radius:
        source: gap_radius_linx_visualiser
      exon_rank_radius:
        source: exon_rank_radius_linx_visualiser
      gene_relative_size:
        source: gene_relative_size_linx_visualiser
      segment_relative_size:
        source: segment_relative_size_linx_visualiser
      cna_relative_size:
        source: cna_relative_size_linx_visualiser
      min_label_size:
        source: min_label_size_linx_visualiser
      max_label_size:
        source: max_label_size_linx_visualiser
      max_gene_characters:
        source: max_gene_characters_linx_visualiser
      max_distance_labels:
        source: max_distance_labels_linx_visualiser
      max_position_labels:
        source: max_position_labels_linx_visualiser
      exact_position:
        source: exact_position_linx_visualiser
      min_line_size:
        source: min_line_size_linx_visualiser
      max_line_size:
        source: max_line_size_linx_visualiser
      glyph_size:
        source: glyph_size_linx_visualiser
      interpolate_cna_positions:
        source: interpolate_cna_positions_linx_visualiser
      interpolate_exon_positions:
        source: interpolate_exon_positions_linx_visualiser
      chr_range_height:
        source: chr_range_height_linx_visualiser
      chr_range_columns:
        source: chr_range_columns_linx_visualiser
      fusion_height:
        source: fusion_height_linx_visualiser
      fusion_legend_rows:
        source: fusion_legend_rows_linx_visualiser
      fusion_legend_height_per_row:
        source: fusion_legend_height_per_row_linx_visualiser
      clusterId:
        source: clusterId_linx_visualiser
      chromosome:
        source: chromosome_linx_visualiser
      threads:
        source: threads_linx_visualiser
      include_line_elements:
        source: include_line_elements_linx_visualiser
      gene:
        source: gene_linx_visualiser
    out:
      - plot_outdir
      - data_outdir
    run: tools/linx-visualiser-1.11.cwl

# Outputs of the workflow
outputs:
  # VCFs
  gridss_vcf:
    type: File
    outputSource: gridss_index_vcf_step/indexed_vcf
  gripss_filtered_vcf:
    type: File
    outputSource: gripss_step/gridss_filtered_vcf
  gripss_hard_filtered_vcf:
    type: File
    outputSource: gripss_hard_filter_vcf_step/gridss_hard_filtered_vcf
  # Useful intermediate outputs
  gridss_assembly_bam:
    type: File
    outputSource: gridss_step/assembly_bam
  amber_outdir:
    type: Directory
    outputSource: amber_step/outdir
  cobalt_outdir:
    type: Directory
    outputSource: cobalt_step/outdir
  purple_outdir:
    type: Directory
    outputSource: purple_step/outdir
  linx_outdir:
    type: Directory
    outputSource: linx_step/outdir
  # Plot outputs
  linx_visualiser_plot_dir:
    type: Directory
    outputSource: linx_visualiser_step/plot_outdir
  linx_visualiser_data_dir:
    type: Directory
    outputSource: linx_visualiser_step/data_outdir