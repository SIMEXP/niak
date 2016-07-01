%% legacy script for building subtypes with niak_build_subtypes

clear all

%% set up paths

path_stack = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/pipeline/network_stack.mat';
path_out = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/legacy/';
path_mask = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/func_mask_group_stereonl.nii.gz';

%% load data and mask
load(path_stack);
[hdr,mask] = niak_read_vol(path_mask);

%% subtyping the 4D stack map

nb_subt = 3; % number of subtypes
subtype = niak_build_subtypes(stack,nb_subt);

%% Write volumes

% The average per cluster
avg_clust_subt = zeros(max(subtype.part),size(stack,2));
for cc = 1:max(subtype.part)
    avg_clust_subt(cc,:) = mean(stack(subtype.part==cc,:),1);
end
vol_avg_subt = niak_tseries2vol(avg_clust_subt,mask);
hdr.file_name = [path_out 'mean_clusters_net.nii.gz'];
niak_write_vol(hdr,vol_avg_subt);

% The std per subtype
std_clust_subt = zeros(max(subtype.part),size(stack,2));
for cc = 1:max(subtype.part)
    std_clust_subt(cc,:) = std(stack(subtype.part==cc,:),1);
end
vol_std_subt = niak_tseries2vol(std_clust_subt,mask);
hdr.file_name = [path_out 'std_clusters_net.nii.gz'];
niak_write_vol(hdr,vol_std_subt);

% demeaned/z-fied subtype
vol_demean = niak_tseries2vol(subtype.map,mask);
hdr.file_name = [path_out 'demean_clusters_net.nii.gz'];
niak_write_vol(hdr,vol_demean);

% t-test between subtype and mean
vol_ttest = niak_tseries2vol(subtype.ttest,mask);
hdr.file_name = [path_out 'ttest_clusters_net.nii.gz'];
niak_write_vol(hdr,vol_ttest);

%% transform stack tseries to vol
stack_vol = niak_tseries2vol(stack,mask);

%% Mean and std grand average
hdr.file_name = [path_out 'grand_mean_clusters_net.nii.gz'];
gd_avg = mean(stack_vol,4);
niak_write_vol(hdr,gd_avg);

hdr.file_name = [path_out 'grand_std_clusters_net.nii.gz'];
gd_std = std(stack_vol,0,4);
niak_write_vol(hdr,gd_std);

%% Save mat file
file_sub_tseries = [path_out 'subtype_legacy.mat'];
save(file_sub_tseries,'avg_clust_subt','std_clust_subt','gd_avg','gd_std','subtype')

