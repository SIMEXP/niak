%% script to test niak_brick_subtyping with hcp dataset

clear all

%% set up path

base_path = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/';
stack_path = [base_path 'hcp_pipe_jul6/network_1/network_1_stack.mat'];
mask_path = [base_path 'func_mask_group_stereonl.nii.gz'];
out_path = [base_path 'subtyping_brick/'];

%% Set up inputs
files_in = struct;
files_in.data = stack_path;
files_in.mask = mask_path;

files_out = struct;
% files_out.provenance = [out_path 'pro1/provenance.mat'];

opt = struct;
opt.nb_subtype = 3;
opt.folder_out = out_path;
opt.flag_prov = true;
% opt.flag_test = true;

%% Call the brick
[files_in,files_out,opt] = niak_brick_subtyping(files_in,files_out,opt);