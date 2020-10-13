class: ExpressionTool
cwlVersion: v1.1

requirements:
  InlineJavascriptRequirement:
    expressionLib:
      - var get_string_or_default = function(defined_string, fall_back_string){
          /*
          Determine if first input has been determined.
          Fall back to default, something like a samplename
          */
          if (defined_string !== null){
            return defined_string;
          } else {
            return fall_back_string;
          }
        }

inputs:
  defined_string:
    type: string?
    doc: |
      Could be defined, if not use the output of the second string
  fall_back_string:
    type: string
    doc: |
      Parameter known to be non-null.

outputs:
  out_string:
    type: string

expression: >-
  ${
    return {'out_string': (get_string_or_default(inputs.defined_string, inputs.fall_back_string))};
  }