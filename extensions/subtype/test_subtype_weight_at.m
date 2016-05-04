%% script to test niak_brick_subtype_weight with preventad dataset

clear all

%% Set up the paths
base_path = '/Users/AngelaTam/Desktop/subtype_pipeline_test/';
stack_path = [base_path 'preventad_test/network_stack.mat'];
subtype_path = [base_path 'preventad_test/subtype.mat'];
mask_path = [base_path 'subtype_test_data/func_mask_group_stereonl.nii.gz'];
out_path = [base_path 'preventad_test/'];

%% Set up inputs
files_in.data.net1 = stack_path;
files_in.subtype.net1 = subtype_path;
files_out = struct;

opt.flag_test = false;
opt.folder_out = out_path;
%% Run the brick
[files_in, files_out, opt] = niak_brick_subtype_weight(files_in, files_out, opt);
