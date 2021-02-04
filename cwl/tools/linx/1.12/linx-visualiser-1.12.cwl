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
    dockerPull: quay.io/biocontainers/hmftools-linx:1.12--0
  ShellCommandRequirement: {}
  NetworkAccess:
    networkAccess: true
  InlineJavascriptRequirement:
    expressionLib:
      - var get_linx_version = function(){
          /*
          Get the version of linx used.
          Enables us to find jar path
          */
          return "1.11-0"
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
          return "com.hartwig.hmftools.linx.visualiser.SvVisualiser";
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
    valueFrom: "$(get_jar_file())"
    position: -2
  - valueFrom: "$(get_jar_class())"
    position: -1
  - prefix: "-threads"
    valueFrom: "$(runtime.cores)"
    position: 1

inputs:
    # Required Inputs
    sample:
      type: string
      doc: |
         Specific sample ID
      inputBinding:
        prefix: "-sample"
    plot_out:
      type: string
      doc: |
         Plot output directory
      inputBinding:
        prefix: "-plot_out"
    data_out:
      type: string
      doc: |
        Data output directory
      inputBinding:
        prefix: "-data_out"
    segment:
      type: File
      doc: |
        Path to segment file
      inputBinding:
        prefix: "-segment"
    link:
      type: File
      doc: |
        Path to link file
      inputBinding:
        prefix: "-link"
    protein_domain:
      type: File
      doc: |
        Path to protein_domain file
      inputBinding:
        prefix: "-protein_domain"
    fusion:
      type: File
      doc: |
        Path to fusion file
      inputBinding:
        prefix: "-fusion"
    cna:
      type: File
      doc: |
        Path to copy number alteration file
      inputBinding:
        prefix: "-cna"
    exon:
      type: File
      doc: |
        Path to exon file
      inputBinding:
        prefix: "-exon"
    circos:
      type: string?
      doc: |
        Path to circos binary
      inputBinding:
        prefix: "-circos"
      default: "/usr/local/bin/circos"
    # Radial Arguments
    inner_radius:
      type: float?
      doc: |
        Innermost starting radius of minor-allele ploidy track
      inputBinding:
        prefix: "-inner_radius"
    outer_radius:
      type: float?
      doc: |
        Outermost ending radius of chromosome track
      inputBinding:
        prefix: "-outer_radius"
    gap_radius:
      type: float?
      doc: |
        Radial gap between tracks
      inputBinding:
        prefix: "-gap_radius"
    exon_rank_radius:
      type: float?
      doc: |
        Radial gap left for exon rank labels
    # Relative Track Size
    gene_relative_size:
      type: float?
      doc: |
        Size of gene track relative to segments and copy number alterations
      inputBinding:
        prefix: "-gene_relative_size"
    segment_relative_size:
      type: float?
      doc: |
        Size of segment (derivative chromosome) track relative to copy number alterations and genes
      inputBinding:
        prefix: "-segment_relative_size"
    cna_relative_size:
      type: float?
      doc: |
        Size of gene copy number alterations (including major/minor allele) relative to genes and segments
      inputBinding:
        prefix: "-cna_relative_size"
    # Font Size
    min_label_size:
      type: int?
      doc: |
        Minimum size of labels in pixels
      inputBinding:
        prefix: "-min_label_size"
    max_label_size:
      type: int?
      doc: |
        Maximum size of labels in pixels
      inputBinding:
        prefix: "-max_label_size"
    max_gene_characters:
      type: int?
      doc: |
        Maximum allowed gene length before applying scaling them
      inputBinding:
        prefix: "-max_gene_characters"
    max_distance_labels:
      type: int?
      doc: |
        Maximum number of distance labels before removing them
      inputBinding:
        prefix: "-max_distance_labels"
    max_position_labels:
      type: int?
      doc: |
        Maximum number of position labels before increasing distance between labels
      inputBinding:
        prefix: "-max_position_labels"
    exact_position:
      type: int?
      doc: |
        Display exact positions at all break ends
      inputBinding:
        prefix: "-exact_position"
    # Line Size
    min_line_size:
      type: int?
      doc: |
        Minimum size of lines in pixels
      inputBinding:
        prefix: "-min_line_size"
    max_line_size:
      type: int?
      doc: |
        Maximum size of lines in pixels
      inputBinding:
        prefix: "-max_line_size"
    glyph_size:
      type: int?
      doc: |
        Size of glyphs in pixels
      inputBinding:
        prefix: "-glyph_size"
    # Interpolate Positions
    interpolate_cna_positions:
      type: boolean?
      doc: |
        Interpolate copy number positions rather than adjust scale
      inputBinding:
        prefix: "-interpolate_cna_positions"
    interpolate_exon_positions:
      type: boolean?
      doc: |
        Interpolate exon positions rather than adjust scale
      inputBinding:
        prefix: "-interpolate_exon_positions"
    # Chromosome Panel
    chr_range_height:
      type: int?
      doc: |
        Chromosome range height in pixels per row
      inputBinding:
        prefix: "-chr_range_height"
    chr_range_columns:
      type: int?
      doc: |
        Maximum chromosomes per row
      inputBinding:
        prefix: "-chr_range_columns"
    # Fusion Panel
    fusion_height:
      type: int?
      doc: |
        Height of each fusion in pixels
      inputBinding:
        prefix: "-fusion_height"
    fusion_legend_rows:
      type: int?
      doc: |
        Number of rows in protein domain legend
      inputBinding:
        prefix: "-fusion_legend_rows"
    fusion_legend_height_per_row:
      type: int?
      doc: |
        Height of each row in protein domain legend
      inputBinding:
        prefix: "-fusion_legend_height_per_row"
    # Other Arguments
    clusterId:
      type: boolean?
      doc: |
        Only generate image for specified comma separated clusters
      inputBinding:
        prefix: "-clusterId"
    chromosome:
      type: boolean?
      doc: |
        Only generate images for specified comma separated chromosomes
      inputBinding:
        prefix: "-chromosome"
    threads:
      type: int?
      doc: |
        Number of threads to use
    include_line_elements:
      type: boolean?
      doc: |
        Include line elements in chromosome visualisations (excluded by default)
      inputBinding:
        prefix: "-include_line_elements"
    gene:
      doc: |
        Add canonical transcriptions of supplied comma-separated genes to image.
        Requires config 'gene_transcripts_dir' to be set as well.
      type: boolean?
      inputBinding:
        prefix: "-gene"

outputs:
  plot_outdir:
    type: Directory
    outputBinding:
      glob: "$(inputs.plot_out)"
  data_outdir:
    type: Directory
    outputBinding:
      glob: "$(inputs.data_out)"

successCodes:
  - 0