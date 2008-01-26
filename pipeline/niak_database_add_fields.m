function struct_data2 = niak_database_add_fields(struct_data,list_fields,list_vars)

if length(list_vars) == 1
    for num_e = 1:length(list_fields)
        list_vars(num_e).vars = list_vars(1).vars;
    end
end

struct_data2 = struct_data;

for num_e = 1:length(list_fields)   
    struct_data2 = setfield(struct_data2,list_fields{num_e},list_vars(num_e));
end