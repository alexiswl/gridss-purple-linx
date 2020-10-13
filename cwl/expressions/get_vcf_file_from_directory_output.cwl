class: ExpressionTool
cwlVersion: v1.1

requirements:
  InlineJavascriptRequirement:
    expressionLib:
      - var get_file_name_from_directory = function(input_directory, file_basename, secondary_files_suffixes){
          /*
          Iterate through a until the file of
          interest is found
          */
          let f_obj_r = null;
          input_directory.listing.forEach(function(f_obj){
            if (f_obj.class === "File" && f_obj.basename === file_basename){
              f_obj_r = f_obj;
            }
          });

          if (secondary_files_suffixes !== null){
            /*
            Iterate through each file ending and add to object
            */
            let secondary_file_objs = [];
            secondary_files_suffixes.forEach(function(suffix){
              /*
              Resolve file_basename
              */
              let secondary_file_basename = resolveSecondary(file_basename, suffix);
              /*
              Get secondary files as file objects
              */
              input_directory.listing.forEach(function(f_obj){
                if (f_obj.class === "File" && f_obj.basename === secondary_file_basename){
                  secondary_file_objs.push(f_obj);
                }
              });
            });
            f_obj_r["secondaryFiles"] = secondary_file_objs;
          }
          return f_obj_r;
        }
      - var resolveSecondary = function(base, secPattern) {
          /*
          Extract secondary files
          From https://github.com/illusional/cwl-v1.2/blob/a650fd43afd6e2bd866657727cd735e3cf4dfb7d/tests/secondaryfiles/rename-outputs.cwl
          */
          if (secPattern[0] == "^") {
            let spl = base.split(".");
            /*
            Long hand form of 'var endIndex = spl.length > 1 ? spl.length - 1 1;'
            */
            let endIndex = null;
            if (spl.length > 1){
              endIndex = spl.length -1;
            } else {
              endIndex = 1;
            }
            return resolveSecondary(spl.slice(undefined, endIndex).join("."), secPattern.slice(1));
          }
          return base + secPattern;
        }

inputs:
  directory:
    type: Directory
    doc: |
      The directory that contains the file we're looking for
    loadListing: shallow_listing
  file_basename:
    type: string
    doc: |
      The file known to exist, the basename of the file
  secondary_files:
    type: string[]
    doc: |
      List of secondary files to pull out
    default:
      - ".tbi"

outputs:
  vcf_file:
    type: File

expression: >-
  ${
    return {'vcf_file': (get_file_name_from_directory(inputs.directory, inputs.file_basename, inputs.secondary_files))};
  }