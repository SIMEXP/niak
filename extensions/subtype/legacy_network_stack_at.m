%% script to build stack maps with prevent-ad data release 2.0
% 231 subjects with resting-state (concatenated rest 1 and rest 2)

clear all

%% set paths

path_in = '/Users/AngelaTam/Desktop/adsf/scores/rmap_part_20160401_s007_avg/';
path_out = '/Users/AngelaTam/Desktop/subtype_pipeline_test/preventad_test/legacy/';
path_model = '/Users/AngelaTam/Desktop/adsf/model/preventad_model_20160408.csv';
mask_path = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/func_mask_group_stereonl.nii.gz';
scale = 7;

%% Read model
[tab,id,~,~] = niak_read_csv(path_model);

%% Load and read the mask
[hdr_mask,mask] = niak_read_vol(mask_path);

%% Network 4D volumes with M subjects
for ss = 1:scale
    for ii = 1:length(id)
        sub = id{ii};
        path_vol = [path_in sub '*.nii.gz'];
        [hdr,vol] = niak_read_vol(path_vol);
        stack(:,:,:,ii) = vol(:,:,:,ss);
    end
    
%     hdr.file_name = [path_out 'stack_net_' num2str(ss) '.nii.gz'];
%     niak_write_vol(hdr,stack);
    
    %% Transform 4D stack maps to subject x voxel array
    stack_net = ['stack_net_' num2str(ss)];
    stack_net = niak_vol2tseries(stack,mask);
    mat_name = [path_out 'stack_net_' num2str(ss) '.mat'];
    save(mat_name,'stack_net')

end
