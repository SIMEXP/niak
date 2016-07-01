%% Wipe
clear;

%% Set up the paths
base_path = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/';
pheno_path = [base_path 'numeric_pheno.csv'];
data_path = [base_path 'raw_nii/'];
mask_path = [base_path 'raw_nii/func_mask_group_stereonl.nii.gz'];
subtype_path = [base_path 'pipe_out_jun9_3_sub/'];
out_path = [base_path 'pipe_out_jun28/'];

%% Configure the inputs
pheno = niak_read_csv_cell(pheno_path);

% Go through the subjects and then make me some files_in struct
go_by = '';
% Find where that is
for ind = 1:size(pheno,2)
    if strcmp(pheno{1, ind}, go_by)
        go_ind = ind;
    end
end

for ind = 2:size(pheno,1)
    sub_name = ['HCP' pheno{ind, go_ind}];
    % Get the file name and path
    file_name = sprintf('%s_sess1_motLR_stability_maps.nii.gz', sub_name);
    file_path = [data_path filesep file_name];
    files_in.data.(sub_name) = file_path;
end

files_in.mask = mask_path;
files_in.model = pheno_path;
files_in.subtype.network_1 = [subtype_path 'network_1/network_1_subtype.mat'];
files_in.subtype.network_2 = [subtype_path 'network_2/network_2_subtype.mat'];
files_in.subtype.network_3 = [subtype_path 'network_3/network_3_subtype.mat'];
files_in.subtype.network_4 = [subtype_path 'network_4/network_4_subtype.mat'];
files_in.subtype.network_5 = [subtype_path 'network_5/network_5_subtype.mat'];
files_in.subtype.network_6 = [subtype_path 'network_6/network_6_subtype.mat'];
files_in.subtype.network_7 = [subtype_path 'network_7/network_7_subtype.mat'];

opt.flag_test = false;
opt.scale = 7;
opt.folder_out = out_path;
opt.chi2.group_col_id = 'Gender';
opt.chi2.flag_weights = true;
opt.stack.regress_conf = {'Age'};
opt.association.contrast.Gender = 1;
opt.visu.data_type = 'categorical';
% opt.subtype.nb_subtype = 3;
% opt.association.contrast.Age_by_Gender = 1;
% opt.association.interaction(1).label = 'Age_by_Gender';
% opt.association.interaction(1).factor = {'Age','Gender'};
opt.association.fdr = 0.5;
%% Start the pipeline
[pipe,opt] = niak_pipeline_subtype(files_in,opt);