function [struct_data2, levels_data2] = niak_database_add_level(struct_data,levels_data,new_level,list_fields,list_vars)

struct_data2 = struct_data;

nb_levels = length(levels_data);

if ~isfield(struct_data,'vars')
    struct_data.vars = struct();
end

vars_root = struct_data.vars;
struct_data = rmfield(struct_data,'vars');
flag_init = 1;
while (length(fieldnames(struct_data))>0)|flag_init
    if length(fieldnames(struct_data))>0
        [struct_data,vars_tmp,labels_tmp] = sub_extract_node(struct_data,vars_root,nb_levels);
    else
        labels_tmp{1} = '';
        nb_levels = 0;
    end
    if ~isempty(labels_tmp{end})|flag_init
        str_fields = sub_node_path(labels_tmp,nb_levels);
        eval(cat(2,'struct_data2',str_fields,' = niak_database_add_fields(struct_data2',str_fields,',list_fields,list_vars);'));       
    end
    flag_init = 0;
end

levels_data2 = levels_data;
levels_data2{end+1} = new_level;

function str_fields = sub_node_path(labels,num_l)

str_fields = '';
if length(labels)>0
    num_f = 1;
    new_field = 'OK';
    while (~isempty(new_field))&(num_f<=num_l)
        new_field = labels{num_f};
        str_fields = cat(2,str_fields,'.',new_field);
        num_f = num_f+1;
    end
end


function [struct_data,vars_tmp,labels_tmp] = sub_extract_node(struct_data,vars_root,nb_levels)

flag_term = 0;
struct_child = struct_data;
vars_tmp = vars_root;
num_l = 0;
labels_tmp = cell([1 nb_levels]);
fields_tmp = fieldnames(struct_child);

while flag_term == 0
    
    num_l = num_l+1;
    labels_tmp{num_l} = fields_tmp{1};
    struct_child = getfield(struct_child,labels_tmp{num_l});
    if ~isfield(struct_child,'vars')
        struct_child.vars = struct();
    end
    vars_tmp = niak_merge_structs(vars_tmp,getfield(struct_child,'vars'));
    struct_child = rmfield(struct_child,'vars');

    fields_tmp = fieldnames(struct_child);   
    flag_term = (length(fields_tmp)==0)|(num_l == nb_levels);
    
end

str_fields = sub_node_path(labels_tmp,num_l-1);

eval(cat(2,'struct_data',str_fields,' = rmfield(struct_data',str_fields,',labels_tmp(num_l));'))
