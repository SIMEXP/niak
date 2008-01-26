function ind = niak_findstrcell(cell_str,str)

nb_e = length(cell_str);
bin_mask = zeros(size([nb_e 1]));

for num_e = 1:nb_e
    bin_mask = strcmp(cell_str{num_e},str);
end

ind = find(bin_mask);