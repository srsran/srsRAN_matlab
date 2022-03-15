% CONVERT_ARRAY_TO_STRING:
%   Function converting an array of numeric values to a string.
%
%   Call details:
%     OUTPUT_STRING = CONVERT_ARRAY_TO_STRING(INPUT ARRAY) receives the input parameters
%         * double array INPUT_ARRAY - set of numeric values
%     and returns
%         * string OUTPUT_STRING - string generated from the input numeric values

function output_string = convert_array_to_string(input_array)
    output_string = '';
    for data_value=input_array
        output_string = [output_string, sprintf('%d,', data_value)];
    end
    output_string = output_string(1:end-1);
end
