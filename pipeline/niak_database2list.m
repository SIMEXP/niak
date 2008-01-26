function [list_labels,list_vars] = niak_database2list(struct_data,levels_data)

nb_levels = length(levels_data);

if ~isfield(struct_data,'vars')
    struct_data.vars = struct();
end

vars_root = struct_data.vars;
struct_data = rmfield(struct_data,'vars');

while (length(fieldnames(struct_data))>0)
    
    [struct_data,vars_tmp,labels_tmp] = sub_extract_node(struct_data,vars_root,nb_levels);
    
    if ~isempty(labels_tmp{end})
        
        if ~exist('list_labels')
            list_labels = labels_tmp;
            list_vars.vars = vars_tmp;
        else
            list_labels(end+1,:) = labels_tmp;
            list_vars(end+1).vars = vars_tmp;
        end
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

str_fields = '';
num_f = 1;
new_field = labels_tmp{num_f};
while (~isempty(new_field))&(num_f<num_l)
    str_fields = cat(2,str_fields,'.',new_field);
    num_f = num_f+1;
    new_field = labels_tmp{num_f};
end

eval(cat(2,'struct_data',str_fields,' = rmfield(struct_data',str_fields,',labels_tmp(num_l));'))