function struct12 = niak_merge_structs(struct1,struct2)

list_fields = fieldnames(struct2);
struct12 = struct1;

for num_f = 1:length(list_fields)
    
    struct12 = setfield(struct12,list_fields{num_f},getfield(struct2,list_fields{num_f}));
    
end