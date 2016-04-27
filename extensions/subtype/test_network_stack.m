%% Wipe
clear;

%% Set up the paths
base_path = '/home/surchs/GDrive/PhD/TeamStuff/Niak_Stuff/subtype_test_data/';
pheno_path = [base_path '/pheno/useful_pheno.csv'];
num_path = [base_path '/pheno/numeric_pheno.csv'];
data_path = [base_path '/raw'];
mask_path = [base_path '/raw/func_mask_group_stereonl.mnc.gz'];
out_path = [base_path 'out/seb'];

%% Get the model and load the files
[model, ~, cat_names, ~] = niak_read_csv(num_path);
pheno = niak_read_csv_cell(num_path);

% Go through the subjects and then make me some files_in struct
go_by = 'Subject';
% Find where that is
for ind = 1:size(pheno,2)
    if strcmp(pheno{1, ind}, go_by)
        go_ind = ind;
    end
end

% Now go through the array again


%% Set up inputs
for ind = 2:size(pheno,1)
    sub_name = ['HCP' pheno{ind, go_ind}];
    % Get the file name and path
    file_name = sprintf('%s_sess1_motLR_stability_maps.mnc.gz', sub_name);
    file_path = [data_path filesep file_name];
    files_in.data.(sub_name) = file_path;
end

files_in.mask = mask_path;
files_in.model = num_path;
files_out = out_path;

opt.network = 3;
opt.regress_conf = {'Gender', 'Age'};
opt.flag_conf = true;
opt.flag_test = false;

%% Run the brick
niak_brick_network_stack(files_in, files_out, opt);