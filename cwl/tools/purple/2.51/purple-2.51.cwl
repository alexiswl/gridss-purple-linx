#!/usr/bin/env cwl-runner

# Non-functional until secondaryFiles are introduced
cwlVersion: v1.1
class: CommandLineTool

doc: |
  PURPLE is a purity ploidy estimator.
  It combines B-allele frequency (BAF) from
  AMBER, read depth ratios from COBALT, somatic variants and structural variants
  to estimate the purity and copy number profile of a tumor sample.

  PURPLE supports both grch 37 and 38 reference assemblies.

requirements:
  ResourceRequirement:
    coresMin: 2
    ramMin: 16000
  DockerRequirement:
    dockerPull: quay.io/biocontainers/hmftools-purple:2.51--1
  NetworkAccess:
    networkAccess: true
  InlineJavascriptRequirement:
    expressionLib:
    - var get_start_memory = function(){
        /*
        Start with 2 Gb
        */
        return 2000;
      }
    - var get_max_memory_from_runtime_memory = function(max_ram){
        /*
        Get Max memory and subtract heap memory
        */
        return max_ram - get_start_memory();
      }
  InitialWorkDirRequirement:
    listing:
      - $(inputs.ref_genome)

# Use java -jar as baseCommand and plug in runtime memory options
baseCommand: ["PURPLE"]

arguments:
  - prefix: "-Xms"
    separate: false
    valueFrom: "$(get_start_memory())m"
    position: -2
  - prefix: "-Xmx"
    separate: false
    valueFrom: "$(get_max_memory_from_runtime_memory(runtime.ram))m"
    position: -1

# Mandatory inputs
inputs:
  reference:
    type: string
    doc: |
       Name of the reference  sample. This  should  correspond to  the value used  in AMBER and  COBALT.
    inputBinding:
      prefix: "-reference"
  tumor:
    type: string
    doc: |
      Name of the tumor sample.  This should  correspond to  the value used  in AMBER and  COBALT.
    inputBinding:
      prefix: "-tumor"
  output_dir:
    type: string
    doc: |
      Path to the output  directory.  Required if  <run_dir> not  set, otherwise  defaults to  run_dir/purple/
    inputBinding:
      prefix: "-output_dir"
  amber:
    type: Directory
    doc: |
      Path to AMBER output. This should correspond to the output_dir used in AMBER.
    inputBinding:
      prefix: "-amber"
  cobalt:
    type: Directory
    doc: |
      Path to COBALT output. This should correspond to the output_dir used in COBALT.
    inputBinding:
      prefix: "-cobalt"
  gc_profile:
    type: File
    doc: |
      Path to GC  profile.
    inputBinding:
      prefix: "-gc_profile"
  ref_genome:
    type: File
    doc: |
      Path to the ref genome fasta file.
    inputBinding:
      prefix: "-ref_genome"
    secondaryFiles:
      - pattern: ".fai"
        required: true
      - pattern: "^.dict"
        required: true
  # Optional arguments
  threads:
    type: int?
    doc: |
      Number of  threads
    inputBinding:
      prefix: "-threads"
    default: 2
  somatic_vcf:
    type: File?
    doc: |
      Optional  location of  somatic variant  vcf to assist  fitting in  highly-diploid  samples.
      Sample name must match tumor parameter. GZ files supported.
    inputBinding:
      prefix: "-somatic_vcf"
    secondaryFiles:
      - .tbi
  structural_vcf:
    type: File?
    doc: |
      Optional location of  structural  variant vcf for  more accurate  segmentation.
      GZ files supported.
    inputBinding:
      prefix: "-structural_vcf"
    secondaryFiles:
      - .tbi
  sv_recovery_vcf:
    type: File?
    doc: |
      Optional  location of  failing  structural  variants that  may be  recovered.
      GZ files supported.
    inputBinding:
      prefix: "-sv_recovery_vcf"
    secondaryFiles:
      - .tbi
  circos:
    type: string?
    doc: |
      Location of circos binary.
      Optional path to circos binary.
      When supplied, circos graphs will be written to <output_dir>/plot
    inputBinding:
      prefix: "-circos"
  db_enabled:
    type: boolean?
    doc: |
      Optionally include if you wish to persist results to a database. Database initialization script can be found here.
    inputBinding:
      prefix: "-db_enabled"
  db_user:
    type: string?
    doc: |
      Database user name. Mandatory if db_enabled.
    inputBinding:
      prefix: "-db_user"
  db_pass:
    type: string?
    doc: |
      Database password. Mandatory if db_enabled.
    inputBinding:
      prefix: "-db_pass"
  db_url:
    type: string?
    doc: |
      Database url in form: mysql://host:port/database
      Mandatory if db_enabled.
    inputBinding:
      prefix: "-db_url"
  max_ploidy:
    type: float?
    doc: |
      Maximum ploidy (default 8.0)
    inputBinding:
      prefix: "-max_ploidy"
  min_ploidy:
    type: float?
    doc: |
      Minimum ploidy (default 1.0)
    inputBinding:
      prefix: "-min_ploidy"
  no_charts:
    type: boolean?
    doc: |
      Disables creation of (non-circos) charts
    inputBinding:
      prefix: "-no_charts"
    default: false
  tumor_only:
    type: boolean?
    doc: |
      Tumor only  mode. Disables  somatic  fitting.
    inputBinding:
      prefix: "-tumor_only"
    default: false
  somatic_min_peak:
    type: int?
    doc: |
      Minimum number  of somatic  variants to  consider a  peak. Default  50.
    inputBinding:
      prefix: "-somatic_min_peak"
  somatic_min_variants:
    type: int?
    doc: |
      Minimum number of somatic  variants  required to  assist highly  diploid fits.  Default 10.
    inputBinding:
      prefix: "-somatic_min_variants"
  somatic_min_purity_spread:
    type: float?
    doc: |
      Minimum spread  within  candidate  purities before  somatics can be  used. Default  0.15
    inputBinding:
      prefix: "-somatic_min_purity_spread"
  somatic_min_purity:
    type: float?
    doc: |
      Somatic fit  will not be  used if both  somatic and  fitted purities  are less than  this value.  Default 0.17
    inputBinding:
      prefix: "-somatic_min_purity"
  somatic_penalty_weight:
    type: float?
    doc: |
      Proportion of somatic  deviation to  include in  fitted purity  score. Default  1.
    inputBinding:
      prefix: "-somatic_penalty_weight"
  highly_diploid_percentage:
    type: float?
    doc: |
      Proportion of  genome that  must be diploid  before using  somatic fit.  Default 0.97.
    inputBinding:
      prefix: "-highly_diploid_percentage"
  # Optional Smoothing Arguments
  min_diploid_tumor_ratio_count:
    type: int?
    doc: |
      Minimum ratio  count while  smoothing  before diploid  regions become  suspect.
    inputBinding:
      prefix: "-min_diploid_tumor_ratio_count"
  min_diploid_tumor_ratio_count_centromere:
    type: int?
    doc: |
      Minimum ratio  count while  smoothing  before diploid  regions become  suspect while  approaching  centromere.
    inputBinding:
      prefix: "-min_diploid_tumor_ratio_count_centromere"
  # Optional Fitting Arguments
  min_purity:
    type: float?
    doc: |
      Minimum purity  (default 0.08)
    inputBinding:
      prefix: "-min_purity"
  max_purity:
    type: float?
    doc: |
      Maximum purity  (default 1.0)
    inputBinding:
      prefix: "-max_purity"
  purity_increment:
    type: float?
    doc: |
      Purity  increment  (default 0.01)
    inputBinding:
      prefix: "-purity_increment"
  # Optional Driver Catalogue Arguments
  driver_catalog:
    type: boolean?
    doc: |
      Persist data to  DB.
    inputBinding:
      prefix: "-driver_catalog"
    default: false
  hotspots:
    type: boolean?
    doc: |
      Database user  name.
    inputBinding:
      prefix: "-hotspots"
    default: false
  # Additional Optional Args
  max_norm_factor:
    type: float?
    doc: |
      Maximum norm factor (default  2.0)
    inputBinding:
      prefix: "-max_norm_factor"
  min_norm_factor:
    type: float?
    doc: |
      Minimum norm factor (default  0.33)
    inputBinding:
      prefix: "-min_norm_factor"
  norm_factor_increment:
    type: float?
    doc: |
      Norm factor increments  (default  0.01)
    inputBinding:
      prefix: "-norm_factor_increment"
  ploidy_penalty_factor:
    type: float?
    doc: |
      Penalty factor to apply to the  number of copy  number events
    inputBinding:
      prefix: "-ploidy_penalty_factor"
  ploidy_penalty_min:
    type: float?
    doc: |
      Minimum ploidy penalty
    inputBinding:
      prefix: "-ploidy_penalty_min"
  ploidy_penalty_min_standard_deviation_per_ploidy:
    type: float?
    doc: |
      Minimum ploidy  penalty  standard  deviation to be  applied
    inputBinding:
      prefix: "-ploidy_penalty_min_standard_deviation_per_ploidy"
  ploidy_penalty_standard_deviation:
    type: float?
    doc: |
      Standard  deviation of  normal  distribution  modelling  ploidy  deviation from  whole number
    inputBinding:
      prefix: "-ploidy_penalty_standard_deviation"
  ploidy_penalty_sub_min_additional:
    type: float?
    doc: |
      Additional  penalty to  apply to major  allele < 1 or  minor allele <  0
    inputBinding:
      prefix: "-ploidy_penalty_sub_min_additional"
  ploidy_penalty_sub_one_major_allele_multiplier:
    type: float?
    doc: |
      Penalty  multiplier  applied to  major allele <  1
    inputBinding:
      prefix: "-ploidy_penalty_sub_one_major_allele_multiplier"

# Set outputs to the -output_dir parameter
outputs:
  outdir:
    type: Directory
    outputBinding:
      glob: "$(inputs.output_dir)"
  purity_file:
    type: File?
    outputBinding:
      glob: "$(inputs.output_dir)/$(inputs.tumor).purple.purity.tsv"
  purity_range_file:
    type: File?
    outputBinding:
      glob: "$(inputs.output_dir)/$(inputs.tumor).purple.purity.range.tsv"
  copy_number_file:
    type: File?
    outputBinding:
      glob: "$(inputs.output_dir)/$(inputs.tumor).purple.cnv.somatic.tsv"
  gene_copy_number_file:
    type: File?
    outputBinding:
      glob: "$(inputs.output_dir)/$(inputs.tumor).purple.cnv.gene.tsv"
  driver_catalog_file:
    type: File?
    outputBinding:
      glob: "$(inputs.output_dir)/$(inputs.tumor).driver.catalogue.tsv"
  structural_vcf_out:
    type: File?
    secondaryFiles:
      - ".tbi"
    outputBinding:
      glob: "$(inputs.output_dir)/$(inputs.tumor).purple.sv.vcf.gz"
  somatic_vcf_out:
    type: File?
    secondaryFiles:
      - ".tbi"
    outputBinding:
      glob: "$(inputs.output_dir)/$(inputs.tumor).purple.somatic.vcf.gz"

successCodes:
  - 0