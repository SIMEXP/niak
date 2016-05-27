%% testing niak_brick_visu_subtype_glm brick

clear all

%% set paths
base_path = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/';
weight_path = [base_path 'pipe_out/subtype_weights.mat'];
association_path = [base_path 'brick_association/association_stats.mat'];
out_path = [base_path 'brick_visu_glm/'];

%% set inputs and options

files_in = struct;
files_in.weight = weight_path;
files_in.association = association_path;
files_out = struct;
opt.contrast.Age = 0;
opt.contrast.FD = 0;
opt.contrast.test1 = 1;
opt.folder_out = out_path;

%% call brick
[files_in, files_out, opt] = niak_brick_visu_subtype_glm(files_in, files_out, opt);