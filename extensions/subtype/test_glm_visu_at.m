%% testing niak_brick_visu_subtype_glm brick

clear all

%% set paths
base_path = '/home/atam/scratch/subtype_test/test_results/';
weight_path = [base_path 'subtype_weights.mat'];
association_path = [base_path 'stats_test.mat'];
out_path = '/home/atam/scratch/subtype_test/brick_visu_glm';

% base_path = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/';
% weight_path = [base_path 'pipe_out_jun10_visutest/subtype_weights.mat'];
% association_path = [base_path 'pipe_out_jun10_visutest/association_stats_test.mat'];
% out_path = [base_path 'brick_visu_glm/test1'];

%% set inputs and options

files_in = struct;
files_in.weight = weight_path;
files_in.association = association_path;
files_out = struct;
opt.scale = 7;
opt.data_type = 'categorical';
opt.contrast.Gender = 1;
opt.contrast.FD = 0;
opt.contrast.Age = 0;
opt.folder_out = out_path;

%% call brick
[files_in, files_out, opt] = niak_brick_visu_subtype_glm(files_in, files_out, opt);