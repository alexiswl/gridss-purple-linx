#!/usr/bin/env cwl-runner

# Non-functional until secondaryFiles are introduced
cwlVersion: v1.1
class: CommandLineTool

doc: |
  LINX is an annotation, interpretation and visualisation tool for structural variants.
  The primary function of LINX is grouping together individual SV calls into distinct events
  and properly classify and annotating the event to understand both its mechanism and genomic impact.

requirements:
  ResourceRequirement:
    coresMin: 4
    ramMin: 16000
  DockerRequirement:
    dockerPull: quay.io/biocontainers/hmftools-linx:1.11--0
  ShellCommandRequirement: {}
  InlineJavascriptRequirement:
    expressionLib:
      - var get_linx_version = function(){
          /*
          Used to obtain the jar path
          */
          return "1.11-0";
        }
      - var get_jar_file = function(){
          /*
          Get jar file, going to be different for each version
          */
          return "/usr/local/share/hmftools-linx-" + get_linx_version() + "/sv-linx.jar";
        }
      - var get_jar_class = function(){
          /*
          Difference between linx and linx visualiser
          */
          return "com.hartwig.hmftools.linx.LinxApplication";
        }
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
arguments:
  - valueFrom: "mkdir -p $(inputs.output_dir);"
    shellQuote: false
    position: -6
  - valueFrom: "java"
    position: -5
  - prefix: "-Xms"
    separate: false
    valueFrom: "$(get_start_memory())m"
    position: -4
  - prefix: "-Xmx"
    separate: false
    valueFrom: "$(get_max_memory_from_runtime_memory(runtime.ram))m"
    position: -3
  - prefix: "-cp"
    valueFrom: "$(get_jar_file())"
    position: -2
  - valueFrom: "$(get_jar_class())"
    position: -1

inputs:
    # Required Inputs
    sample:
      type: string
      doc: |
         Specific sample ID
      inputBinding:
        prefix: "-sample"
    sv_vcf:
      type: File
      doc: |
         Full path and filename for the SV VCF (/path/to/purple/vcf/)
      inputBinding:
        prefix: "-sv_vcf"
      secondaryFiles:
        - pattern: ".tbi"
          required: false
    purple_dir:
      type: Directory
      doc: |
        Directory with sample data for structural variant VCF,
        copy number and purity data files as written by GRIDSS and Purple.
        /path_to_purple_data_files/
      inputBinding:
        prefix: "-purple_dir"
    output_dir:
      type: string
      doc: |
        Required: directory where all output files are written /path_to_sample_data/
      inputBinding:
        prefix: "-output_dir"
    # Modes / routines
    check_fusions:
      type: boolean?
      doc: |
        Optional - discover and annotate gene fusions
      inputBinding:
        prefix: "-check_fusions"
      default: false
    check_drivers:
      type: boolean?
      doc: |
        Optional - Discover and annotate gene fusions
      inputBinding:
        prefix: "-check_drivers"
      default: false
    # Database options
    db_user:
      type: string?
      doc: |
        [username]
      inputBinding:
        prefix: "-db_user"
    db_pass:
      type: string?
      doc: |
        [password]
      inputBinding:
        prefix: "-db_pass"
    db_url:
      type: string?
      doc: |
        [db_url]
      inputBinding:
        prefix: "-db_url"
    # Reference files
    fragile_site_file:
      type: File?
      doc: |
        list of known fragile sites - specify Chromosome,PosStart,PosEnd - fragile_sites.csv
      inputBinding:
        prefix: "-fragile_site_file"
    line_element_file:
      type: File?
      doc: |
        list of known LINE elements - specify Chromosome,PosStart,PosEnd - line_elements.csv
      inputBinding:
        prefix: "-line_element_file"
    replication_origins_file:
      type: File?
      doc: |
        optional - Replication timing input - in BED format with replication timing as the 4th column -
        heli_rep_origins.bed
      inputBinding:
        prefix: "-replication_origins_file"
    viral_hosts_file:
      type: File?
      doc: |
        optional - list of known viral hosts - Refseq_id,Virus_name = viral_host_ref.csv
      inputBinding:
        prefix: "-viral_hosts_file"
    gene_transcripts_dir:
      type: Directory?
      doc: |
        Directory for Ensembl reference files - see instructions for generation below.
        /path_to_ensembl_data_cache/
      inputBinding:
        prefix: "-gene_transcripts_dir"
    # Clustering
    proximity_distance:
      type: int?
      doc: |
        Optional - (default = 5000), minimum distance to cluster SVs
      inputBinding:
        prefix: "-proximity_distance"
    chaining_sv_limit:
      type: int?
      doc: |
        threshold for # SVs in clusters to skip chaining routine (default = 2000)
      inputBinding:
        prefix: "-chaining_sv_limit"
    # Fusion analysis
    log_reportable_fusion:
      type: boolean?
      doc: |
        Only log reportable fusions
      inputBinding:
        prefix: "-log_reportable_fusion"
      default: false
    known_fusion_file:
      type: File?
      doc: |
        Known fusion reference data - known pairs, promiscuous 5' and 3' genes, IG regions and exon DELs & DUPs
      inputBinding:
        prefix: "-known_fusion_file"
    fusion_gene_distance:
      type: int?
      doc: |
        Distance upstream of gene to consider a breakend applicable
    restricted_fusion_genes:
      type: string?
      doc: |
        Restrict fusion search to specified genes, separated by ';'
    # Logging
    write_vis_data:
      type: boolean?
      doc: |
        Write output to for generation of Circos clustering and chaining plots
      inputBinding:
        prefix: "-write_vis_data"
      default: true
    log_debug:
      type: boolean?
      doc: |
        logs in debug mode
      inputBinding:
        prefix: "-log_debug"
      default: false

outputs:
  outdir:
    type: Directory
    outputBinding:
      glob: "$(inputs.output_dir)"