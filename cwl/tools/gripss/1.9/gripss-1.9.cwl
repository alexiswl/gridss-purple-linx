#!/usr/bin/env cwl-runner

# Non-functional until secondaryFiles are introduced
cwlVersion: v1.1
class: CommandLineTool

doc: |
  GRIPSS applies a set of filtering and post processing steps on GRIDSS paired tumor-normal output
  to produce a high confidence set of somatic SV for a tumor sample.
  GRIPSS inputs the raw GRIDSS vcf and outputs a somatic vcf.

requirements:
  ResourceRequirement:
    coresMin: 8
    ramMin: 32000
  DockerRequirement:
    dockerPull: quay.io/biocontainers/hmftools-gripss:1.9--0
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
      - var get_gripss_version = function(){
          /*
          Return this version of gripss
          */
          return "1.8-0";
        }
      - var get_gripss_jar = function(){
          /*
          Return path to gripss jar file
          */
          return "/usr/local/share/hmftools-gripss-" + get_gripss_version() + "/gripss.jar";
        }
  InitialWorkDirRequirement:
    listing:
      - $(inputs.ref_genome)

# Use java -jar as baseCommand and plug in runtime memory options
baseCommand: ["java"]

arguments:
  - prefix: "-Xms"
    separate: false
    valueFrom: "$(get_start_memory())m"
    position: -4
  - prefix: "-Xmx"
    separate: false
    valueFrom: "$(get_max_memory_from_runtime_memory(runtime.ram))m"
    position: -3
  - prefix: "-cp"
    valueFrom: "$(get_gripss_jar())"
    position: -2
  - valueFrom: "com.hartwig.hmftools.gripss.GripssApplicationKt"
    position: -1

inputs:
  input_vcf:
    type: File
    doc: |
      Path to GRIDSS VCF input
    inputBinding:
      prefix: "-input_vcf"
    secondaryFiles:
      # Gzipped VCF Index
      - pattern: '.tbi'
        required: true
  output_vcf:
    type: string
    doc: |
      Path to output VCF
    inputBinding:
      prefix: "-output_vcf"
  ref_genome:
    type: File
    doc: |
      Ref genome
    inputBinding:
      prefix: "-ref_genome"
    secondaryFiles:
      - pattern: ".fai"
        required: true
      - pattern: "^.dict"
        required: true
  reference:
    type: string?
    doc: |
      Optional name of reference sample, defaults to first sample in the gridss vcf
    inputBinding:
      prefix: "-reference"
  tumor:
    type: string?
    doc: |
      Optional name of tumor sample, defaults to second sample in the gridss vcf
    inputBinding:
      prefix: "-tumor"
  breakend_pon:
    type: File
    doc: |
      Single breakend pon bed file
    inputBinding:
      prefix: "-breakend_pon"
  breakpoint_pon:
    type: File
    doc: |
      Paired breakpoint pon bedpe file
    inputBinding:
      prefix: "-breakpoint_pon"
  breakpoint_hotspot:
    type: File
    doc: |
      Paired breakpoint hotspot bedpe file
    inputBinding:
      prefix: "-breakpoint_hotspot"
  # Optional inputs
  hard_max_normal_absolute_support:
    type: float?
    doc: |
      Hard max normal absolute support
    inputBinding:
      prefix: "-hard_max_normal_absolute_support"
  hard_max_normal_relative_support:
    type: float?
    doc: |
      Hard max normal relative support
    inputBinding:
      prefix: "-hard_max_normal_relative_support"
  hard_min_tumor_qual:
    type: int?
    doc: |
      Hard min tumor qual
    inputBinding:
      prefix: "-hard_min_tumor_qual"
  max_hom_length_short_inv:
    type: int?
    doc: |
      Max homology length short inversion
    inputBinding:
      prefix: "-max_hom_length_short_inv"
  max_inexact_hom_length_short_del:
    type: int?
    doc: |
      Max inexact homology length short del
    inputBinding:
      prefix: "-max_inexact_hom_length_short_del"
  max_short_strand_bias:
    type: float?
    doc: |
      Max short strand bias
    inputBinding:
      prefix: "-max_short_strand_bias"
  min_length:
    type: int?
    doc: |
      Min length
    inputBinding:
      prefix: "-min_length"
  min_normal_coverage:
    type: int?
    doc: |
      Min normal coverage
    inputBinding:
      prefix: "-min_normal_coverage"
  min_qual_break_end:
    type: int?
    doc: |
      Min qual break end
    inputBinding:
      prefix: "-min_qual_break_end"
  min_qual_break_point:
    type: int?
    doc: |
      Min qual break point
    inputBinding:
      prefix: "-min_qual_break_point"
  min_qual_rescue_mobile_element_insertion:
    type: int?
    doc: |
      Min tumor allelic frequency
    inputBinding:
      prefix: "-min_qual_rescue_mobile_element_insertion"
  min_tumor_af:
    type: float?
    doc: |
      Min tumor allelic frequency [0.005]
    inputBinding:
      prefix: "-min_tumor_af"
  soft_max_normal_relative_support:
    type: float?
    doc: |
      Max normal support
    inputBinding:
      prefix: "-soft_max_normal_relative_support"

outputs:
  gridss_filtered_vcf:
    type: File
    outputBinding:
      glob: "$(inputs.output_vcf)"
    secondaryFiles:
      - pattern: ".tbi"
        required: true


successCodes:
  - 0