%% Wipe
clear;

%% Set up the paths
base_path = '/home/surchs/GDrive/PhD/TeamStuff/Niak_Stuff/subtype_test_data/';
stack_path = [base_path '/out/seb/network_stack.mat'];
subtype_path = [base_path '/out/seb/subtypes.mat'];
mask_path = [base_path '/raw/func_mask_group_stereonl.mnc.gz'];
out_path = [base_path 'out/seb'];

%% At a later time I'll implement the network iterator here

%% Set up inputs
files_in.data.net1 = stack_path;
files_in.subtype.net1 = subtype_path;
files_out = out_path;

opt.flag_test = false;

%% Run the brick
niak_brick_subtype_weight(files_in, files_out, opt);