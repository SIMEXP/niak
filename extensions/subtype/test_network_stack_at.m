%% test niak_brick_network_stack with preventad dataset

%% Wipe
clear;

%% Set up the paths
data_base = '/Users/AngelaTam/Desktop/adsf/';
model = [data_base 'model/preventad_model_20160408.csv'];
data_path = [data_base 'scores/rmap_part_20160401_s007_avg/'];
mask_path = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/func_mask_group_stereonl.nii.gz';
out_path = '/Users/AngelaTam/Desktop/subtype_pipeline_test/preventad_test/';

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
    sub_name = pheno{ind, go_ind};
    % Get the file name and path
    file_name = sprintf('%s_BL00_avg_rmap_part.nii.gz', sub_name);
    file_path = [data_path filesep file_name];
    files_in.data.(sub_name) = file_path;
end

files_in.mask = mask_path;
files_in.model = model;
files_out = '';

opt.network = 7;
opt.folder_out = out_path;
opt.regress_conf = {'gender', 'age'};
opt.flag_conf = true;
opt.flag_test = false;

%% Run the brick
[files_in, files_out, opt] = niak_brick_network_stack(files_in, files_out, opt);

