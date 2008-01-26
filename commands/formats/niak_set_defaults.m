
% Script niak_set_defaults
% This script takes a structure, and assigns default values to each field
% in a list. The fields are transformed into variables in the current
% space.
%
% gb_name_structure   a string with the name of the structure to test.
% gb_list_fields           a cell of strings with names of fields.
% gb_list_defaults         a cell with default values. A Nan will produce an error
%                       message and exit if no value is defined in the field.


flag_structure = exist(gb_name_structure);

if ~flag_structure            
    eval(cat(2,gb_name_structure,' = [];'));
end

nb_fields = length(gb_list_fields);

for num_l = 1:nb_fields
    
    field = gb_list_fields{num_l};
    val = gb_list_defaults{num_l};
    flag_field = eval(cat(2,'isfield(',gb_name_structure,',''',field,''');'));

    if ~flag_field
        if isnumeric(val)
            if isnan(val)
                fprintf('Please specify field %s in structure %s !\n',field,gb_name_structure)
                return
            end
        end
        eval(cat(2,gb_name_structure,'.',field,' = val;'));    
    end    
    
    eval(cat(2,field,' = ',gb_name_structure,'.',field,';'));
    
    flag_empty = eval(cat(2,'isempty(',field,');'));
    if flag_empty 
        eval(cat(2,gb_name_structure,'.',field,' = val;'));    
    end
end
