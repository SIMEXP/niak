function str_simple = niak_database2simplestruct(str_database);

num_n = 0;
str_simple = sub_simple_level(str_database,num_n);

function [str_simple,num_n] = sub_simple_level(str_database,num_n);

str_simple.vars = str_database.vars;
if isfield(str_database,'vars')
    str_database = rmfield(str_database,'vars');
end


list_fields = fieldnames(str_database);

if ~isempty(list_fields)
    
    for num_f = 1:length(list_fields)
        
        num_n = num_n+1;
        lab_num = num2str(num_n);
        lab_num = [repmat('0',[1 max(15-length(lab_num),1)]) lab_num];
        
        lab_field_simple = cat(2,'N',lab_num);
        lab_field = list_fields{num_f};
        str_child = getfield(str_database,lab_field);
        [str_new,num_n] = sub_simple_level(str_child,num_n);
        str_simple = setfield(str_simple,lab_field_simple,str_new);
        
    end
else
    str_simple.vars = [];        
end