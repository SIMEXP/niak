%% script to test niak_brick_chi_cramer

clear all

%% Set up files_in and files_out structures
files_in.model = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/numeric_pheno.csv';
files_in.subtype = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/pipe_out_fig_2/network_1/network_1_subtype.mat';
files_out = struct;

%% Set up options for brick
opt.folder_out = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/brick_cramer';
opt.group_col_id = 'Gender';
opt.nb_subtype = 2;

%% Call the brick
[files_in,files_out,opt] = niak_brick_chi_cramer(files_in,files_out,opt);