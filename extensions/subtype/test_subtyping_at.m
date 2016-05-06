%% script to test niak_brick_subtyping with preventad dataset

clear all

%% set up path

base_path = '/Users/AngelaTam/Desktop/subtype_pipeline_test/';
stack_path = [base_path 'preventad_test/network_stack.mat'];
sim_path = [base_path 'preventad_test/similarity_matrix.mat'];
mask_path = [base_path 'subtype_test_data/func_mask_group_stereonl.nii.gz'];
model_path = '/Users/AngelaTam/Desktop/adsf/model/preventad_model_20160408.csv';
out_path = [base_path 'preventad_test/'];

%% Set up inputs
files_in = struct;
files_in.data = stack_path;
files_in.matrix = sim_path;
files_in.mask = mask_path;
files_in.model = model_path;

files_out = struct;

opt = struct;
opt.nb_subtype = 3;
opt.folder_out = out_path;
opt.flag_stats = false;

%% Call the brick
[files_in,files_out,opt] = niak_brick_subtyping(files_in,files_out,opt);