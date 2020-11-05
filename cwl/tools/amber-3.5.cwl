#!/usr/bin/env cwl-runner

# Non-functional until secondaryFiles are introduced
cwlVersion: v1.1
class: CommandLineTool

doc: |
  AMBER is designed to generate a tumor BAF file for use in PURPLE from a provided VCF of likely heterozygous SNP sites.

  When using paired reference/tumor bams,
  AMBER confirms these sites as heterozygous in the reference sample bam then calculates the
  allelic frequency of corresponding sites in the tumor bam.
  In tumor only mode, all provided sites are examined in the tumor with additional filtering then applied.

  The Bioconductor copy number package is then used to generate pcf segments from the BAF file.

  When using paired reference/tumor data, AMBER is also able to:
  1. detect evidence of contamination in the tumor from homozygous sites in the reference; and
  2. facilitate sample matching by recording SNPs in the germline

requirements:
  ResourceRequirement:
    coresMin: 16
    ramMin: 32000
  DockerRequirement:
    dockerPull: quay.io/biocontainers/hmftools-amber:3.5--0
  ShellCommandRequirement: {}
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

# Use java -jar as baseCommand and plug in runtime memory options
baseCommand: ["AMBER"]

# Memory options
arguments:
  - prefix: "-Xms"
    separate: false
    valueFrom: "$(get_start_memory())m"
    position: -2
  - prefix: "-Xmx"
    separate: false
    valueFrom: "$(get_max_memory_from_runtime_memory(runtime.ram))m"
    position: -1

inputs:
  # Mandatory arguments
  reference:
    type: string
    doc: |
      Name of reference sample
    inputBinding:
      prefix: "-reference"
  reference_bam:
    type: File
    doc: |
      Path to reference bam file
    inputBinding:
      prefix: "-reference_bam"
    secondaryFiles:
      - pattern: ".bai"
        required: true
  tumor:
    type: string
    doc: |
      Name of tumor sample
    inputBinding:
      prefix: "-tumor"
  tumor_bam:
    type: File
    doc: |
      Path to tumor bam file
    inputBinding:
      prefix: "-tumor_bam"
    secondaryFiles:
      - pattern: ".bai"
        required: true
  output_dir:
    type: string
    doc: |
      Output directory
    inputBinding:
      prefix: "-output_dir"
  loci:
    type: File?
    doc: |
      Path to vcf file containing likely heterozygous sites (see below). Gz files supported.
    inputBinding:
      prefix: "-loci"
  # Optional Arguments
  threads:
    type: int?
    doc: |
      Number of threads
    inputBinding:
      prefix: "-threads"
    default: 16
  min_mapping_quality:
    type: int?
    doc: |
      Minimum mapping quality for an alignment to be used
    inputBinding:
      prefix: "-min_mapping_quality"
  min_base_quality:
    type: int?
    doc: |
      Minimum quality for a base to be considered
    inputBinding:
      prefix: "-min_base_quality"
  min_depth_percent:
    type: float?
    doc: |
      Max percentage of median depth
    inputBinding:
      prefix: "-min_depth_percent"
  max_depth_percent:
    type: float?
    doc: |
      Only include reference sites with read depth
      within max percentage of median reference read depth
    inputBinding:
      prefix: "-max_depth_percent"
  min_het_af_percent:
    type: float?
    doc: |
      Min heterozygous AF%
    inputBinding:
      prefix: "-min_het_af_percent"
  max_het_af_percent:
    type: float?
    doc: |
      Max heterozygous AF%
    inputBinding:
      prefix: "-max_het_af_percent"
  ref_genome:
    type: File?
    doc: |
      Path to the ref genome fasta file. Required only when using CRAM files.
    inputBinding:
      prefix: "-ref_genome"
    secondaryFiles:
      - ".fai"
  validation_stringency:
    type: string?
    doc: |
      SAM validation strategy: STRICT, SILENT, LENIENT [STRICT]
    inputBinding:
      prefix: "-validation_stringency"
    default: "STRICT"
  # Tumour only options
  tumor_only:
    type: boolean?
    doc: |
      Flag to put AMBER into tumor only mode
    inputBinding:
      prefix: "-tumor_only"
    default: false
  tumor_only_min_vaf:
    type: float?
    doc: |
      Min support in ref and alt in tumor only mode
    inputBinding:
      prefix: "-tumor_only_min_vaf"
  tumor_only_min_support:
    type: int?
    doc: |
      Min VAF in ref and alt in tumor only mode
    inputBinding:
      prefix: "-tumor_only_min_support"


outputs:
  outdir:
    type: Directory
    outputBinding:
      glob: "$(inputs.output_dir)"


successCodes:
  - 0