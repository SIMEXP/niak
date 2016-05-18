%% Wipe
clear;

%% Set up the paths
base_path = '/media/yassinebha/database23/Drive/subtype_test_data';
pheno_path = [base_path '/pheno/numeric_pheno.csv'];
data_path = [base_path '/raw'];
mask_path = [base_path '/raw/func_mask_group_stereonl.mnc.gz'];
out_path = [base_path '/out/ybh/test'];

%% Configure the inputs
pheno = niak_read_csv_cell(pheno_path);

% Go through the subjects and then make me some files_in struct
go_by = 'Subject';
% Find where that is
for ind = 1:size(pheno,2)
    if strcmp(pheno{1, ind}, go_by)
        go_ind = ind;
    end
end

for ind = 2:size(pheno,1)
    sub_name = ['HCP' pheno{ind, go_ind}];
    % Get the file name and path
    file_name = sprintf('%s_sess1_motLR_stability_maps.mnc.gz', sub_name);
    file_path = [data_path filesep file_name];
    files_in.data.(sub_name) = file_path;
end

files_in.mask = mask_path;
files_in.model = pheno_path;

opt.flag_test = false;
opt.scale = 7;
opt.folder_out = out_path;
opt.association.contrast.Gender = 1;
opt.association.contrast.Age = 0;
opt.association.fdr = 0.5;
opt.subtype.group_col_id = 2;
%% Start the pipeline
[pipe,opt] = niak_pipeline_subtype(files_in,opt);