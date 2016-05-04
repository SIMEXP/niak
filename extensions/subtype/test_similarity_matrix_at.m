%% test script for niak_brick_similarity_matrix with preventad dataset

clear all

% set up paths

files_in = '/Users/AngelaTam/Desktop/subtype_pipeline_test/preventad_test/network_stack.mat';
files_out = struct;
opt.folder_out = '/Users/AngelaTam/Desktop/subtype_pipeline_test/preventad_test/';

% call the brick
niak_brick_similarity_matrix(files_in,files_out,opt);