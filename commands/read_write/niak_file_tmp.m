function file_name = niak_file_tmp(ext)

niak_gb_vars
c_clock = clock;
rand('state',100000*c_clock(end));
flag_tmp = 1;

while flag_tmp == 1;
    file_name = cat(2,gb_niak_tmp,'niak_tmp_',num2str(floor(1000000*rand(1))),ext);
    flag_tmp = exist(file_name)>0;
end