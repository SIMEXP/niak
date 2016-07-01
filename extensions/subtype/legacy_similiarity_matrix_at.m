%% legacy script for similarity matrix

clear all

% set paths
path_stack = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/pipeline/network_stack.mat';
path_out = '/Users/AngelaTam/Desktop/subtype_pipeline_test/subtype_test_data/legacy/';

% set variables
nb_clus = 3; % number of clusters

% load stack data
load(path_stack);

% Run a cluster analysis on the processed stack
R = niak_build_correlation(stack');
hier = niak_hierarchical_clustering(R);
part = niak_threshold_hierarchy(hier,struct('thresh',nb_clus));
order = niak_hier2order(hier);
save([path_out 'order.mat'],'order');
save([path_out 'part.mat'],'part');

% Visualize the matrices
figure
opt_vr.color_map = 'hot_cold';
opt_vr.limits = [-1 1];
niak_visu_matrix(R(order,order),opt_vr);
namefig = strcat(path_out,'matrix.pdf');
print(namefig,'-dpdf','-r300')

% Visualize dendrograms
figure
niak_visu_dendrogram(hier);
namefig = strcat(path_out,'dendrogram.pdf');
print(namefig,'-dpdf','-r300')

