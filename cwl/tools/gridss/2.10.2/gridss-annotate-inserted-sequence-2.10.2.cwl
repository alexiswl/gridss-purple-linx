#!/usr/bin/env cwl-runner

# Non-functional until secondaryFiles are introduced
cwlVersion: v1.1
class: CommandLineTool

doc: |
  Annotate inserted sequence into gridss.
  For the main gridss-purple-linx workflow, this will need to be rerun post-gridss on the viral reference genome

requirements:
  ResourceRequirement:
    coresMin: 2
    ramMin: 16000
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gridss:2.10.2--0
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
      - var get_gridss_version = function(){
          /*
          Return this version of gripss
          */
          return "2.10.2-0";
        }
      - var get_gridss_jar = function(){
          /*
          Return path to gripss jar file
          */
          return "/usr/local/share/gridss-" + get_gridss_version() + "/gridss.jar";
        }

# Use java -jar as baseCommand and plug in runtime memory options
baseCommand: ["java"]

arguments:
  # Java runtime options
  - prefix: "-Xms"
    separate: false
    valueFrom: "$(get_start_memory())m"
    position: -9
  - prefix: "-Xmx"
    separate: false
    valueFrom: "$(get_max_memory_from_runtime_memory(runtime.ram))m"
    position: -8
  # Samtools JDK options
  - prefix: "-Dsamjdk.create_index="
    separate: false
    valueFrom: "true"
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
    valueFrom: "true"
    position: -3
  # Jar path options
  - prefix: "-cp"
    valueFrom: "$(get_gridss_jar())"
    position: -2
  - valueFrom: "gridss.AnnotateInsertedSequence"
    position: -1

inputs:
  # Inputs / outputs
  input_vcf:
    label: input vcf
    doc: |
      VCF file to annotate  Required.
    type: File
    secondaryFiles:
      - pattern: ".tbi"
        required: true
    inputBinding:
      prefix: "INPUT="
      separate: false
  output_vcf_name:
    label: output vcf name
    doc: |
      Annotated VCF file  Required.
    type: string
    inputBinding:
      prefix: "OUTPUT="
      separate: false
  # References
  reference_sequence:
    label: reference sequence
    doc: |
      Path to the reference fasta
    type: File
    secondaryFiles:
      - pattern: ".amb"
        required: true
      - pattern: ".bwt"
        required: true
      - pattern: ".ann"
        required: true
      - pattern: ".fai"
        required: true
      - pattern: ".dict"
        required: true
      - pattern: ".img"
        required: true
      - pattern: ".gridsscache"
        required: true
      - pattern: ".masked"
        required: true
      - pattern: ".sa"
        required: true
      - pattern: ".pac"
        required: true
    inputBinding:
      prefix: "REFERENCE_SEQUENCE="
      separate: false
  # Optional args
  threads:
    label: threads
    doc: |
      Number of worker threads to spawn. Defaults to number of cores available. Note that I/O
      threads are not included in this worker thread count so CPU usage can be higher than the
      number of worker thread.  Default value: 2. This option can be set to 'null' to clear the
      default value.
    type: int?
    inputBinding:
      prefix: "THREADS="
      separate: false
  min_sequence_length:
    label: min sequence length
    doc: |
      Minimum inserted sequence length for realignment. Generally, short read aligners are not
      able to uniquely align sequences shorter than 18-20 bases.  Default value: 20. This option
      can be set to 'null' to clear the default value.
    type: int?
    inputBinding:
      prefix: "MIN_SEQUENCE_LENGTH="
      separate: false
  aligner_command_line:
    label: aligner command line
    doc: |
      Command line arguments to run external aligner. In-process bwa alignment is used if this
      value is null. Aligner output must be written to stdout and the records MUST match the
      input fastq order. The aligner must support using "-" as the input filename when reading
      from stdin.Java argument formatting is used with %1$s being the fastq file to align, %2$s
      the reference genome, and %3$d the number of threads to use.  Default value: null. This
      option may be specified 0 or more times.
    type: string?
    inputBinding:
      prefix: "ALIGNER_COMMAND_LINE="
      separate: false
  aligner_batch_size:
    label: aligner batch size
    doc: |
      Number of records to buffer when performing in-process or streaming alignment. Not
      applicable when performing external alignment.  Default value: 500000. This option can be
      set to 'null' to clear the default value.
    type: int?
    inputBinding:
      prefix: "ALIGNER_BATCH_SIZE="
      separate: false
  alignment:
    label: alignment
    doc: |
      Whether to align inserted sequences to REFERENCE_GENOME. Valid values are:APPEND (Append
      alignments to REFERENCE_GENOME to the BEALN field), REPLACE (Replace all BEALN fields)
      (default),ADD_MISSING (Add alignments to records missing a BEALN field, andSKIP (do not
      align).  Default value: REPLACE. This option can be set to 'null' to clear the default
      value. Possible values: {APPEND, REPLACE, ADD_MISSING, SKIP}
    type:
      - "null"
      - type: enum
        symbols:
          - APPEND
          - REPLACE
          - ADD_MISSING
          - SKIP
  repeat_masker_bed:
    label: repeat master bed file
    doc: |
      Annotate inserted sequences with RepeatMasker annotations. Use bedops rmsk2bed to generate
      the bed file from the RepeatMasker .fa.out file.  Default value: null.
    type: File?
    inputBinding:
      prefix: "REPEAT_MASKER_BED="
      separate: false
  ignore_duplicates:
    label: ignore duplicates
    doc: |
      Ignore reads marked as duplicates.  Default value: true. This option can be set to 'null'
                                    to clear the default value. Possible values: {true, false}
    type: boolean?
    inputBinding:
      prefix: "IGNORE_DUPLICATES="
      separate: false


outputs:
  output_vcf:
    type: File
    outputBinding:
      glob: "$(inputs.output_vcf_name)"
    secondaryFiles:
      - ".tbi"

successCodes:
  - 0