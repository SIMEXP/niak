%% legacy script for weight extraction

clear all

%% set paths
path_stack = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/pipeline/network_stack.mat';
path_model = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/niak_pheno.csv';
path_simmat = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/pipeline/similarity_matrix.mat';
path_subt = 'Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/pipeline/subtype.mat';
path_out = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/legacy/';

%% load data
load(path_stack)
load(path_simmat)
load(path_subt)
[tab,sub_id,labels_y,labels_id] = niak_read_csv(path_model);

%% calculate weights
for cc = 1:max(part)
    avg_clust(cc,:) = mean(stack(part==cc,:),1);
    weights(:,cc) = corr(stack',avg_clust(cc,:)');
end

save([path_out 'weights.mat'],'weights');
name_clus = {'subt1','subt2','subt3'};
opt.labels_y = name_clus;
opt.labels_x = sub_id;
path = [path_out 'weights.csv'];
opt.precision = 3;
niak_write_csv(path,weights,opt);

%% Visualize weights
figure
opt_vr.limits = [-0.4 0.4];
opt_vr.color_map = 'hot_cold';
niak_visu_matrix(weights(subj_order,:),opt_vr)
namefig = strcat(path_out,'weights.pdf');
print(namefig,'-dpdf','-r300')