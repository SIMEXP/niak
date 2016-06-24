%% Wipe
clear;

%% Set up the paths
base_path = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/';
model_path = [base_path 'niak_pheno.csv'];
weight_path = [base_path 'pipe_out/subtype_weights.mat'];
out_path = [base_path 'brick_association/'];

%% Set up inputs
files_in = struct;
files_in.weight = weight_path;
files_in.model = model_path;
files_out = struct;

opt.scale = 7;
opt.network = 3;
opt.folder_out = out_path;
opt.interaction(1).label = 'test1';
opt.interaction(1).factor = {'Gender', 'Age'};
opt.contrast.Age = 0;
opt.contrast.FD = 0;
opt.contrast.test1 = 1;
opt.test_name = 'dumbstuff';
opt.flag_test = false;

%% Run the brick
[files_in, files_out, opt] = niak_brick_association_test(files_in, files_out, opt);