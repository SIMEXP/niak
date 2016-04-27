%% Wipe
clear;

%% Set up the paths
base_path = '/home/surchs/GDrive/PhD/TeamStuff/Niak_Stuff/subtype_test_data/';
sim_path = [base_path 'out/seb/similarity_matrix.mat'];
mask_path = [base_path 'raw/func_mask_group_stereonl.mnc.gz'];
model_path = [base_path 'pheno/numeric_pheno.csv'];
out_path = [base_path 'out/seb/'];

%% Set up inputs
files_in = struct;
files_in.data = sim_path;
files_in.mask = mask_path;
files_in.model = model_path;

files_out = out_path;

opt = struct;
opt.nb_subtype = 3;

%% Call the brick
niak_brick_subtyping(files_in,files_out,opt)