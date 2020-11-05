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
    dockerPull: quay.io/biocontainers/hmftools-gripss:1.8--0
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
  - valueFrom: "com.hartwig.hmftools.gripss.GripssHardFilterApplicationKt"
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
        required: false
  output_vcf:
    type: string
    doc: |
      Path to output VCF
    inputBinding:
      prefix: "-output_vcf"


outputs:
  gridss_hard_filtered_vcf:
    type: File
    outputBinding:
      glob: "$(inputs.output_vcf)"
    secondaryFiles:
      - ".tbi"

successCodes:
  - 0