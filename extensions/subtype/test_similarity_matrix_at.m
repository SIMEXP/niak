%% test script for niak_brick_similarity_matrix with hcp dataset

clear all

% set up paths

files_in = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/pipeline/network_stack.mat';
files_out = struct;
opt.folder_out = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/pipeline';

% call the brick
niak_brick_similarity_matrix(files_in,files_out,opt);