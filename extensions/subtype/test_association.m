%% Wipe
clear;

%% Set up the paths
base_path = '/home/surchs/GDrive/PhD/TeamStuff/Niak_Stuff/subtype_test_data/';
model_path = [base_path '/pheno/numeric_pheno.csv'];
weight_path = [base_path '/out/seb/subtype_weights.mat'];
out_path = [base_path 'out/seb/'];

%% Set up inputs
files_in = struct;
files_in.weight = weight_path;
files_in.model = model_path;
files_out = out_path;

opt.network = 3;
opt.folder_out = out_path;
opt.interaction(1).label = 'test1';
opt.interaction(1).factor = {'Gender', 'Age'};
opt.test_name = 'dumbstuff';
opt.cov = {'Age', 'FD'};
opt.coi = 'Age';
opt.flag_test = false;

%% Run the brick
[files_in, files_out, opt] = niak_brick_association_test(files_in, files_out, opt);