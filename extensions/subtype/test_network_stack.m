%% Prepare it
% Test script for the niak_brick_network_stack thing

clear;
% Go and load some test subjects by pheno file
pheno_path = '/data1/subtypes/pipeline_test/pheno/useful_pheno.csv';
num_path = '/data1/subtypes/pipeline_test/pheno/numeric_pheno.csv';
data_path = '/data1/subtypes/pipeline_test/big_sample';
mask_path = '/data1/subtypes/pipeline_test/big_sample/func_mask_group_stereonl.mnc.gz';

[model, ~, cat_names, ~] = niak_read_csv(num_path);
pheno = niak_read_csv_cell(num_path);

% Go through the subjects and then make me some files_in struct
go_by = 'Subject';
% Find where that is
for ind = 1:size(pheno,2)
    if strcmp(pheno{1, ind}, go_by)
        go_ind = ind;
    end
end

% Now go through the array again
for ind = 2:size(pheno,1)
    sub_name = ['HCP' pheno{ind, go_ind}];
    % Get the file name and path
    file_name = sprintf('%s_sess1_motLR_stability_maps.mnc.gz', sub_name);
    file_path = [data_path filesep file_name];
    files_in.data.(sub_name) = file_path;
end

files_in.mask = mask_path;
files_in.model = num_path;
files_out = '/data1/subtypes/pipeline_test/test_out';

%% Do it
opt.network = 3;
opt.regress_conf = {'Gender', 'Age'};
opt.flag_conf = true;
opt.flag_test = false;
niak_brick_network_stack(files_in, files_out, opt);