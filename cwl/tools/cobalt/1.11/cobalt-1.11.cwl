#!/usr/bin/env cwl-runner

# Non-functional until secondaryFiles are introduced
cwlVersion: v1.1
class: CommandLineTool

doc: |
  Count bam lines determines the read depth ratios of the supplied tumor and reference genomes.

  COBALT starts with the raw read counts per 1,000 base window
  for both normal and tumor samples by counting the number of alignment starts in the
  respective bam files with a mapping quality score of at least 10
  that is neither unmapped, duplicated, secondary, nor supplementary.
  Windows with a GC content less than 0.2 or greater than 0.6 or with an average mappability below 0.85
  are excluded from further analysis.

  Next we apply a GC normalization to calculate the read ratios.
  We divide the read count of each window by the median read count of all windows
  sharing the same GC content then normalise further to the ratio of the median to mean read count of all windows.

  The reference sample ratios have a further ‘diploid’ normalization applied to them to remove megabase scale GC biases.
  This normalization assumes that the median ratio of each 10Mb window (minimum 1Mb readable)
  should be diploid for autosomes and haploid for sex chromosomes in males in the germline sample.

  Finally, the Bioconductor copy number package is used to generate segments from the ratio file.

requirements:
  ResourceRequirement:
    coresMin: 4
    ramMin: 16000
  DockerRequirement:
    dockerPull: quay.io/biocontainers/hmftools-cobalt:1.10--0
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
    - var get_threads_val = function(specified_threads){
        /*
        Set thread count number of cores specified
        */
        if (specified_threads === null){
          return runtime.cores;
        } else {
          return specified_threads;
        }
      }

# Use java -jar as baseCommand and plug in runtime memory options
baseCommand: ["COBALT"]

arguments:
  # Mem args
  - prefix: "-Xms"
    separate: false
    valueFrom: "$(get_start_memory())m"
    position: -9
  - prefix: "-Xmx"
    separate: false
    valueFrom: "$(get_max_memory_from_runtime_memory(runtime.ram))m"
    position: -8
  # Samtools JDK options
  - prefix: "-Dsamjdk.reference_fasta="
    separate: false
    valueFrom: "$(inputs.ref_genome.path)"
    position: -7
  - prefix: "-Dsamjdk.use_async_io_read_samtools="
    separate: false
    valueFrom: "true"
    position: -6
  - prefix: "-Dsamjdk.use_async_io_write_samtools="
    separate: false
    valueFrom: "true"
    position: -5
  - prefix: "-Dsamjdk.use_async_io_write_tribble="
    separate: false
    valueFrom: "true"
    position: -4
  - prefix: "-Dsamjdk.buffer_size="
    separate: false
    valueFrom: "4194304"
    position: -3
  - prefix: "-Dsamjdk.async_io_read_threads="
    separate: false
    valueFrom: "$(get_threads_val(inputs.threads))"
    position: -2
  # threads use
  - prefix: "-threads"
    valueFrom: "$(get_threads_val(inputs.threads))"


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
  gc_profile:
    type: File
    doc: |
      Location of GC Profile
    inputBinding:
      prefix: "-gc_profile"
  # Optional Arguments
  threads:
    type: int?
    doc: |
      Number of threads
  min_quality:
    type: int?
    doc: |
      Min quality
    inputBinding:
      prefix: "-min_quality"
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
  validation_stringency:
    type: string
    doc: |
      SAM validation strategy: STRICT, SILENT, LENIENT
    inputBinding:
      prefix: "-validation_stringency"
    default: "STRICT"

outputs:
  outdir:
    type: Directory
    outputBinding:
      glob: "$(inputs.output_dir)"


successCodes:
  - 0