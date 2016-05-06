%% script to build stack maps with hcp 20 subject dataset

clear all

%% set paths

path_in = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/raw_nii/';
path_out = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/legacy/';
path_model = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/niak_pheno.csv';
mask_path = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/func_mask_group_stereonl.nii.gz';
n_net = 3; % number of the network of interest

%% Read model
[tab,id,~,~] = niak_read_csv(path_model);

%% Load and read the mask
[hdr_mask,mask] = niak_read_vol(mask_path);

%% Network 4D volumes with M subjects
for ii = 1:length(id)
    sub = id{ii};
    path_vol = [path_in 'HCP' sub '*.nii.gz'];
    [hdr,vol] = niak_read_vol(path_vol);
    stack(:,:,:,ii) = vol(:,:,:,n_net);
end

%% Write the volume
% hdr.file_name = [path_out 'stack_net_' num2str(n_net) '.nii.gz'];
% niak_write_vol(hdr,stack);

%% Transform the raw 4D stack maps to subject x voxel array
raw_stack = niak_vol2tseries(stack,mask);

%% regress out confounding variables

model.x = [ones(length(id),1) tab(:,1) tab(:,2)]; % set up model for glm
mask_nnan = ~max(isnan(model.x),[],2);
model.x = model.x(mask_nnan,:);
stack_net = raw_stack(mask_nnan,:,:);  % putting a mask to get rid of NaNs over the newly created variable raw_stack
tab = tab(mask_nnan,:); % mask to get rid of NaNs within tab
id = id(mask_nnan);

for nn = 1:size(stack_net,3)
    model.y = stack_net(:,:,nn);
    model.c = [1 0 0];
    %     opt_glm.test = 'ttest';
    opt_glm.flag_residuals = true;
    glm = niak_glm(model,opt_glm);
    stack_net(:,:,nn) = glm.e;
end

%% Save the mat file
mat_name = [path_out 'stack_net_' num2str(n_net) '.mat'];
save(mat_name,'stack_net')







