cwlVersion: v1.1
class: CommandLineTool

# Metadata
id: tabix
label: tabix
doc: |
  tabix creates an index for a vcf file

# Requirements
requirements:
  ResourceRequirement:
    ramMin: 4000
    coresMin: 1
  DockerRequirement:
    dockerPull: 'quay.io/biocontainers/tabix:0.2.6--ha92aebf_0'
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entryname: /scripts/run-tabix.sh
        entry: |
          #!/usr/bin/env bash

          # Copy over input file
          cp "$(inputs.gzipped_vcf.path)" ./

          # Then run tabix on the basename
          tabix -p vcf "$(inputs.gzipped_vcf.basename)"


baseCommand: ["bash", "/scripts/run-tabix.sh"]

# Get inputs
inputs:
  gzipped_vcf:
    type: File

# Get outputs
outputs:
  indexed_vcf:
    type: File
    outputBinding:
      glob: "$(inputs.gzipped_vcf.basename)"
    secondaryFiles:
      - ".tbi"

# Ensure successful output
successCodes:
  - 0