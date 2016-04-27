%% Wipe
clear;

%% Set up the paths
base_path = '/home/surchs/GDrive/PhD/TeamStuff/Niak_Stuff/';
sim_path = [base_path '/subtype_test_data/out/seb/similarity_matrix.mat'];
mask_path = [base_path '/subtype_test_data/raw/func_mask_group_stereonl.mnc.gz'];
model_path = [base_path '/subtype_test_data/pheno/numeric_pheno.csv'];
out_path = [base_path '/subtype_test_data/out/seb/'];

%% Set up inputs
files_in = struct;
files_in.data = sim_path;
files_in.mask = mask_path;
files_in.model = model_path;

files_out = out_path;

opt = struct;

%% Call the brick
niak_brick_subtyping(files_in,files_out,opt)