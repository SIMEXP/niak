%% test niak_brick_network_stack with 20 subj hcp dataset

%% Wipe
clear;

%% Set up the paths
data_base = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/';
model = [data_base 'niak_pheno.csv'];
data_path = [data_base 'raw_nii/'];
mask_path = [data_base 'func_mask_group_stereonl.nii.gz'];
out_path = [data_base '/pipeline/'];

%% Get the model and load the files
[tab, ~, cat_names, ~] = niak_read_csv(model);
pheno = niak_read_csv_cell(model);

% Go through the subjects and then make me some files_in struct
go_by = '';
% Find where that is
for ind = 1:size(pheno,2)
    if strcmp(pheno{1, ind}, go_by)
        go_ind = ind;
    end
end

% Now go through the array again

%% Set up inputs
for ind = 2:size(pheno,1)
    sub_name = ['HCP' pheno{ind, go_ind}];
    % Get the file name and path
    file_name = sprintf('%s_sess1_motLR_stability_maps.nii.gz', sub_name);
    file_path = [data_path filesep file_name];
    files_in.data.(sub_name) = file_path;
end

files_in.mask = mask_path;
files_in.model = model;
files_out = '';

opt.network = 3;
opt.folder_out = out_path;
opt.regress_conf = {'Gender', 'Age'};
opt.flag_conf = true;
opt.flag_test = false;

%% Run the brick
[files_in, files_out, opt] = niak_brick_network_stack(files_in, files_out, opt);

