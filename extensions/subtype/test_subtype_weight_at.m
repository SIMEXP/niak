%% script to test niak_brick_subtype_weight with hcp dataset

clear all

%% Set up the paths

base_path = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/';
stack_path = [base_path 'pipeline/network_stack.mat'];
subtype_path = [base_path 'pipeline/subtype.mat'];
simmat_path = [base_path 'pipeline/similarity_matrix.mat'];
mask_path = [base_path 'func_mask_group_stereonl.nii.gz'];
out_path = [base_path 'pipeline/'];

%% Set up inputs
files_in.data.net1 = stack_path;
files_in.subtype.net1 = subtype_path;
files_in.sim_matrix.net1 = simmat_path;
files_out = struct;

opt.flag_test = false;
opt.folder_out = out_path;
%% Run the brick
[files_in, files_out, opt] = niak_brick_subtype_weight(files_in, files_out, opt);
