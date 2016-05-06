%% Wipe
clear;

%% Set up the paths
base_path = '/home/surchs/GDrive/PhD/TeamStuff/Niak_Stuff/subtype_test_data/';
stack_path = [base_path '/out/seb/network_stack.mat'];
sim_path = [base_path '/out/seb/similarity_matrix.mat'];
mask_path = [base_path '/raw/func_mask_group_stereonl.mnc.gz'];
model_path = [base_path '/pheno/numeric_pheno.csv'];
out_path = [base_path '/out/seb/'];

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