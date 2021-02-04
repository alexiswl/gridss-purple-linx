#!/usr/bin/env cwl-runner

# Non-functional until secondaryFiles are introduced
cwlVersion: v1.1
class: CommandLineTool

doc: |
  Run the gridss through CWL

requirements:
  ResourceRequirement:
    coresMin: 8
    ramMin: 32000
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gridss:2.9.4--0
  ShellCommandRequirement: {}
  NetworkAccess:
    networkAccess: true
  InitialWorkDirRequirement:
    listing:
      - $(inputs.reference)
      - $(inputs.bwa_reference)
      - $(inputs.gridss_cache)

  InlineJavascriptRequirement:
    expressionLib:
    - var get_start_memory = function(){
        /*
        Start with 4 Gb to run program
        */
        return 4000;
      }
    - var get_max_memory_from_runtime_memory = function(max_ram){
        /*
        Get Max memory and subtract heap memory
        */
        return max_ram - get_start_memory();
      }
    - var get_runtime_threads = function(){
        return runtime.cores
      }
    - var get_threads_val = function(inputs){
        if (inputs.threads === null){
          return get_runtime_threads();
        } else {
          return inputs.threads;
        }
      }
    - var get_jvmheap_val = function(inputs, runtime_ram){
        if (inputs.jvmheap === null){
          return get_max_memory_from_runtime_memory(runtime_ram) + "m";
        } else {
          return inputs.jvmheap;
        }
      }
    - var get_array_paths = function(array_obj, delimiter) {
        return array_obj.map(function(a) {return a.path;}).join(delimiter);
      }

# Set as entrypoint in original dockerfile
baseCommand: ["bash", "/opt/gridss/gridss.sh"]

arguments:
  - valueFrom: "$(get_array_paths(inputs.input_bams, \" \"))"
    # We need these arguments to be separated
    shellQuote: false
    # And ideally at the end of the command
    position: 10000

inputs:
  input_bams:
    type: File[]
    doc: |
      Array of input bam files, should be normal bam, tumour bam
  reference:
    type: File
    doc: |
      reference genome to use. Must have a .fai index file
    secondaryFiles:
      # Fasta index
      - pattern: ".fai"
        required: true
      - pattern: "^.dict"
        required: true
    inputBinding:
      prefix: "--reference"
      valueFrom: "$(inputs.reference.basename)"
  bwa_reference:
    type: File
    doc: |
      Bwa reference files to complement the fasta reference
      Note, tools will need to mount these files in the same directory as the fasta reference.
      Nameroot must equal the basename to the fasta reference for each file.
      Expected the ".bwt" file as input. Must be the same nameroot as the fasta reference
    secondaryFiles:
      - pattern: "^.amb"
        required: true
      - pattern: "^.ann"
        required: true
      - pattern: "^.pac"
        required: true
      - pattern: "^.sa"
        required: true
      - pattern: "^.alt"
        required: false
  reference_cache:
    type: File
    doc: |
      Skips creation of the reference genome in the gridss step if provided.
      Should have suffixes .grdss_cache and .img with the fasta_reference basename as the nameroot.
      Note, tools will need to mount this file in the same directory as the fasta reference
      Expects the ".img" file as input suffix. Must be the same nameroot as the fasta reference
    secondaryFiles:
      - pattern: "^.gridsscache"
        required: true
  output:
    type: string
    doc: |
      Output VCF file, this must end in ".vcf.gz"
    inputBinding:
      prefix: "--output"
  assembly:
    type: string?
    doc: |
      Optional - location of the GRIDSS assembly BAM. This file will be created by GRIDSS.
    inputBinding:
      prefix: "--assembly"
  threads:
    type: int?
    doc: |
      number of threads to use
    inputBinding:
      prefix: "--threads"
      valueFrom: "$(get_threads_val(inputs))"
  jar:
    type: string?
    doc: |
      Optional - location of GRIDSS jar
    inputBinding:
      prefix: "--jar"
  workingdir:
    type: string?
    doc: |
      directory to place GRIDSS intermediate and temporary files. .gridss.working subdirectories will be created.
      Defaults to the current directory.
    inputBinding:
      prefix: "--workingdir"
  blacklist:
    type: File?
    doc: |
      Optional - BED file containing regions to ignore
    inputBinding:
      prefix: "--blacklist"
  repeatmaskerbed:
    type: File?
    doc: |
      Optional - bedops rmsk2bed BED file for genome.
    inputBinding:
      prefix: "--repeatmaskerbed"
  steps:
    type: string?
    doc: |
      Optional - processing steps to run. Defaults to all steps.
      Multiple steps are specified using comma separators.
      Possible steps are: setupreference, preprocess, assemble, call, all.
      WARNING: multiple instances of GRIDSS generating reference files at the same time will result in file corruption.
      Make sure these files are generated before runninng parallel GRIDSS jobs.
      Defaults to 'all'
    inputBinding:
      prefix: "--steps"
  configuration:
    type: File?
    doc: |
      Optional - configuration file use to override default GRIDSS settings.
    inputBinding:
      prefix: "--configuration"
  labels:
    type: string[]?
    doc: |
      comma separated labels to use in the output VCF for the input files.
      Supporting read counts for input files with the same label are aggregated
      (useful for multiple sequencing runs of the same sample).
      Labels default to input filenames, unless a single read group with a non-empty sample name
      exists in which case the read group sample name is used
      (which can be disabled by "useReadGroupSampleNameCategoryLabel=false" in the configuration file).
      If labels are specified, they must be specified for all input files.
    inputBinding:
      prefix: "--labels"
      itemSeparator: ","
  externalaligner:
    type: boolean?
    doc: |
      Optional - use the system version of bwa instead of the in-process version packaged with GRIDSS
    inputBinding:
      prefix: "--externalaligner"
    default: false
  jvmheap:
    type: string?
    doc: |
      size of JVM heap for assembly and variant calling.
    inputBinding:
      prefix: "--jvmheap"
      valueFrom: "$(get_jvmheap_val(inputs, runtime.ram))"
  maxcoverage:
    type: int?
    doc: |
      Optional - maximum coverage. Regions with coverage in excess of this are ignored.
    inputBinding:
      prefix: "--maxcoverage"
  picardoptions:
    type: string?
    doc: |
      Optional - additional standard Picard command line options.
      Useful options include VALIDATION_STRINGENCY=LENIENT and COMPRESSION_LEVEL=0.
      See https://broadinstitute.github.io/picard/command-line-overview.html
    inputBinding:
      prefix: "--picardoptions"
  useproperpair:
    type: boolean?
    doc: |
      use SAM 'proper pair' flag to determine whether a read pair is discordant. Default: use library fragment size distribution to determine read pair concordance
    inputBinding:
      prefix: "--useproperpair"
    default: false
  concordantreadpairdistribution:
    type: float?
    doc: |
      portion of 6 sigma read pairs distribution considered concordantly mapped. Default: 0.995
    inputBinding:
      prefix: "--concordantreadpairdistribution"
  keepTempFiles:
    type: boolean?
    doc: |
      keep intermediate files. Not recommended except for debugging due to the high disk usage.
    inputBinding:
      prefix: "--keepTempFiles"
    default: false
  nojni:
    type: boolean?
    doc: |
      do not use JNI native code acceleration libraries (snappy, GKL, ssw, bwa).
    inputBinding:
      prefix: "--nojni"
    default: false
  jobindex:
    type: boolean?
    doc: |
      zero-based assembly job index (only required when performing parallel assembly across multiple computers)
    inputBinding:
      prefix: "--jobindex"
    default: false
  jobnodes:
    type: boolean?
    doc: |
      total number of assembly jobs (only required when performing parallel assembly across multiple computers). Note than an assembly jobs is required after all indexed jobs have been completed to gather the output files together.
    inputBinding:
      prefix: "--jobnodes"
    default: false

outputs:
  out_vcf:
    type: File
    outputBinding:
      glob: "$(inputs.output)"
    secondaryFiles:
      - pattern: ".tbi"
        required: true
  assembly_bam:
    type: File
    outputBinding:
      glob: "$(inputs.assembly)"
    secondaryFiles:
      - pattern: ".bai"
        required: true


successCodes:
  - 0