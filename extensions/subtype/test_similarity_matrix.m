%% Wipe
clear;

%% Set up paths
base_path = '/home/surchs/GDrive/PhD/TeamStuff/Niak_Stuff/subtype_test_data/';
stack_path = [base_path '/out/seb/network_stack.mat'];
out_path = [base_path '/out/seb/'];

%% Set up inputs
files_in = stack_path;
files_out = struct;

opt = struct;
opt.folder_out = out_path;
opt.flag_test = false;

%% Call the thing
niak_brick_similarity_matrix(files_in,files_out,opt);