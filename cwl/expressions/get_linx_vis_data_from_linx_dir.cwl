class: ExpressionTool
cwlVersion: v1.1

requirements:
  InlineJavascriptRequirement:
    expressionLib:
      - var get_file_name_from_directory = function(input_directory, sample_name, suffix){
          /*
          Iterate through a until the file of
          interest is found
          */
          let f_obj_r = null;
          let file_basename = sample_name + suffix;
          input_directory.listing.forEach(function(f_obj){
            if (f_obj.class === "File" && f_obj.basename === file_basename){
              f_obj_r = f_obj;
            }
          });
          return f_obj_r;
        }

inputs:
  directory:
    type: Directory
    doc: |
      The directory that contains the file we're looking for
    loadListing: shallow_listing
  sample:
    type: string
    doc: |
      The prefix of the linx samples

outputs:
  vis_segments:
    type: File
  vis_sv_data:
    type: File
  vis_gene_exon:
    type: File
  vis_copy_number:
    type: File
  vis_protein_domain:
    type: File
  fusions_detailed:
    type: File

expression: >-
  ${
    return {
             'vis_segments': (get_file_name_from_directory(inputs.directory, inputs.sample, ".linx.vis_segments.tsv")),
             'vis_sv_data': (get_file_name_from_directory(inputs.directory, inputs.sample, ".linx.vis_sv_data.tsv")),
             'vis_gene_exon': (get_file_name_from_directory(inputs.directory, inputs.sample, ".linx.vis_gene_exon.tsv")),
             'vis_copy_number': (get_file_name_from_directory(inputs.directory, inputs.sample, ".linx.vis_copy_number.tsv")),
             'vis_protein_domain': (get_file_name_from_directory(inputs.directory, inputs.sample, ".linx.vis_protein_domain.tsv")),
             'fusions_detailed': (get_file_name_from_directory(inputs.directory, inputs.sample, ".linx.vis_fusion.tsv"))
           };
  }