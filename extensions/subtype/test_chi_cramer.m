%% multiple scripts to test niak_brick_chi_cramer (testing out multiple scenarios...)

clear all

%% files_out no opt folder out with generated subtypes

% Set up files_in and files_out structures
files_in.model = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/numeric_pheno.csv';
files_in.subtype = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/pipe_out_jun7_3_sub/network_1/network_1_subtype.mat';
files_out = struct;
files_out.stats = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/brick_cramer_sub/group_stats.mat';
files_out.contab = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/brick_cramer_sub/chi2_contingency_table.csv';
files_out.pie = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/brick_cramer_sub/';

% Set up options for brick
opt.group_col_id = 'Gender';

% Call the brick
[files_in,files_out,opt] = niak_brick_chi_cramer(files_in,files_out,opt);

%% files_out no opt folder out calculated with weights

clear all

% Set up files_in and files_out structures
files_in.model = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/numeric_pheno.csv';
files_in.weights = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/pipe_out_jun7_3_sub/subtype_weights.mat';
files_out = struct;
files_out.stats = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/brick_cramer_weights/group_stats.mat';
files_out.contab = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/brick_cramer_weights/chi2_contingency_table.csv';
files_out.pie = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/brick_cramer_weights/';

% Set up options for brick
opt.group_col_id = 'Gender';
opt.flag_weights = 1;
opt.network = 1;

% Call the brick
[files_in,files_out,opt] = niak_brick_chi_cramer(files_in,files_out,opt);


%% opt folder out with generated subtypes

clear all

% Set up files_in and files_out structures
files_in.model = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/numeric_pheno.csv';
files_in.subtype = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/pipe_out_jun7_3_sub/network_1/network_1_subtype.mat';
files_out = struct;

% Set up options for brick
opt.folder_out = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/brick_cramer_sub';
opt.group_col_id = 'Gender';

% Call the brick
[files_in,files_out,opt] = niak_brick_chi_cramer(files_in,files_out,opt);


%% opt folder out calculated with weights

clear all

% Set up files_in and files_out structures
files_in.model = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/numeric_pheno.csv';
files_in.weights = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/pipe_out_jun7_3_sub/subtype_weights.mat';
files_out = struct;

% Set up options for brick
opt.folder_out = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/brick_cramer_weights';
opt.group_col_id = 'Gender';
opt.flag_weights = 1;
opt.network = 1;

% Call the brick
[files_in,files_out,opt] = niak_brick_chi_cramer(files_in,files_out,opt);