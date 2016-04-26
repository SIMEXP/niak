%% Wipe
clear;

%% Set up paths
stack_path = '/home/surchs/GDrive/PhD/TeamStuff/Niak_Stuff/subtype_test_data/out/seb/stack_file.mat';
out_path = '/home/surchs/GDrive/PhD/TeamStuff/Niak_Stuff/subtype_test_data/out/seb/';

%% Set up inputs
files_in = stack_path;
files_out = out_path;
opt.flag_test = true;

%% Call the thing
niak_brick_similarity_matrix(files_in,files_out,opt);