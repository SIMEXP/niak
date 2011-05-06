function [part,gi,i_intra,i_inter] = niak_kmeans_mat(data,opt,flag_opt);
% A .m implementation of k-means clustering.
%
% SYNTAX :
% [PART,GI,I_INTRA,I_INTER] = NIAK_KMEANS_MAT(DATA,OPT);
%
% _________________________________________________________________________
% INPUTS:
%
% DATA
%       (2D array T*N)
%
% OPT
%       (structure) with the following fields (absent fields will be
%       assigned a default value):
%
%       NB_CLASSES
%           (integer) number of classes
%
%       P
%           (vector N*1, default 1/N*ones([N 1])) weightening for each
%           individual.
%
%       TYPE_INIT
%           (string, default 'random_partition') the strategy to
%           initialize the kmeans. Available options are :
%
%           'random_partition' : self-explanatory. 
%
%           'random_point' : randomly select some data points as
%               centroids.
%
%           'pca' : use the first principal components as centroids.
%
%           'hierarchical' : use a hierarchical clustering to find the
%               initial partition. The procedure that is used is
%               NIAK_HIERARCHICAL_CLUSTERING. See OPT.HIERARCHICAL below as
%               well as OPT.TYPE_SIMILARITY.
%
%           'kmeans++' : use the k-means++ method. See  Arthur, D. and
%               Vassilvitskii, S. (2007). "k-means++: the advantages of 
%               careful seeding". Proceedings of the eighteenth annual 
%               ACM-SIAM symposium on Discrete algorithms. pp. 1027–1035.
%
%           'user-specified' : use OPT.INIT as inial centroids of the
%               partition.
%
%       HIERARCHICAL
%           (structure, default struct()) option of 
%           NIAK_HIERARCHICAL_CLUSTERING, if that procedure is used for 
%           initialization (see OPT.TYPE_INIT above).
%
%       TYPE_SIMILARITY
%           (string, default 'product') the similarity measure used to 
%           perform the hierarchical clustering. Available option :
%
%           'euclidian' : use the opposite of the euclidian distance (see
%                 NIAK_BUILD_DISTANCE).
%
%           'correlation' : use the correlation matrix.
%
%           'product' : euclidian product. This is useful if the data has
%               been corrected for the mean and/or variance, in which case
%               the 'product' option is equivalent to the covariance or
%               correlation between observations.
%
%           'manual' : consider DATA as a similarity matrix.
%
%       INIT
%           (2D array T*K) each column is used as initial centroid of a
%           cluster. Note that this value will be used only if
%           OPT.TYPE_INIT equals 'user-specified'.
%
%       TYPE_DEATH
%           (string, default 'none') the strategy to deal with dead
%           (empty) cluster :
%           'none' let them be empty.
%           'singleton' iteratively replace every empty cluster by the one
%           singleton which is further away from its centroid.
%           'split' iteratively splits the cluster with largest inertia
%			in two random subclusters until the number of clusters is
%			back to the one specified.
%           'bisect' iteratively splits the cluster with largest inertia
%			in two subclusters using k-means until the number of
%			clusters is back to the one specified.
%
%       CONVERGENCE_RATE
%           (scalar, 0) the rate of changes in the adjacency matrix
%           representation of the clustering to decide on convergence of
%           the algorithm. The rate of change is defined as the proportion of
%           regions whose associated cluster changed between two
%           iterations.
%
%       NB_ITER_MAX
%           (integer, default 50) Maximal number of iterations of the
%           k-means algorithm.
%
%       NB_TESTS_CYCLE
%           (integer, default 5) the number of partitions kept in memory to
%           check for cycles.
%
%       FLAG_VERBOSE
%           (boolean, default 0) if the flag is 1, then the function prints
%           some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% PART
%       (vector N*1) partition (find(part==i) is the list of regions belonging
%       to cluster i.
%
% GI
%       (2D array) gi(:,i) is the center of gravity of cluster i.
%
% I_INTRA
%       (double) Intra-clusters inertia for the proposed partition.
%
% I_INTER
%       (double) Inter-clusters inertia for the proposed partition.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal, 2010-2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : kmeans, clustering

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%% Options
if (nargin < 3)||(flag_opt)
    list_fields    = {'hierarchical' , 'type_similarity' , 'convergence_rate' , 'init' , 'type_init'        , 'type_death' , 'nb_classes' , 'p' , 'flag_verbose' , 'nb_iter_max' , 'nb_tests_cycle' };
    list_defaults  = {struct()       , 'product'         , 0                  , []     , 'random_partition' , 'none'       , NaN          , []  , 0              , 50            , 5                };
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
end
K = opt.nb_classes;

if isempty(opt.p)
    opt.p = ones([size(data,2) 1]);
end

%% Initialization
data = data';
[N,T] = size(data);
part = zeros([N opt.nb_tests_cycle]);
changement = 1;
N_iter = 1;
part_curr = 1;
ind_change = 1:K;
A = zeros([N K]);

%% The option to resurect clusters
opt_rep = opt;
opt_rep.nb_classes = 2;
opt_rep.type_death = 'none';
opt_rep.flag_verbose = false;

%% Initialization of cluster centers
gi = zeros([K T]);
switch opt.type_init
    
    case 'random_point'
        
        %% Initialization using random points
        perm_init = randperm(N);
        gi = data(perm_init(1:K),:);
        
    case 'random_partition'
        
        %% Initialization using random partition
        part(:,part_curr) = ceil(K*rand([N 1]));
        gi = centre_gravite(data,part(:,1),opt.p,K);
        
    case 'pca'
        
        %% Initialization using eigen vectors
        [eig_val,eig_vec] = niak_pca(data);
        gi = eig_vec(:,1:K)';
        
    case 'user-specified'
        
        %% Initialization used the user-specified centroids
        gi = opt.init';
        clear init
        
    case 'hierarchical'
        
        if opt.flag_verbose
            fprintf('Initialization using hierarchical clustering\n')
        end
        switch opt.type_similarity
            case 'euclidian'
                sim_mat = -niak_build_distance(data');
            case 'correlation'
                sim_mat = niak_build_correlation(data');
            case 'product'
                sim_mat = data*data';
            case 'manual'
                sim_mat = data;
        end
        opt.hierarchical.nb_classes = K;
        opt.hierarchical.flag_verbose = opt.flag_verbose;
        hier = niak_hierarchical_clustering(sim_mat,opt.hierarchical);
        clear sim_mat
        opt_t.thresh = K;
        part_init = niak_threshold_hierarchy(hier,opt_t);
        gi = zeros([K T]);
        for num_i = 1:K
            gi(num_i,:) = mean(data(part_init==num_i,:),1);
        end
        
    case 'kmeans++'
        for num_k = 1:K
            if num_k==1
                gi(num_k,:) = data(1+floor(N*rand(1)),:);
            else
                A_min = min(A(:,1:(num_k-1)),[],2);
                [val,order] = sort(A_min/sum(A_min));
                p = cumsum(val)/sum(val);
                ind = find(p>rand(1));
                gi(num_k,:) = data(order(ind(1+floor(length(ind)*rand(1)))),:);
            end
            A = attraction(data,gi(1:num_k,:),opt.p,num_k,A);
        end
    otherwise
        
        error('%s is an unknwon type of initialisation. Please check the value of OPT.TYPE_INIT',opt.type_init);
end

%%%%%%%%%%%%%%%%%%
%% The big loop %%
%%%%%%%%%%%%%%%%%%
if opt.flag_verbose
    fprintf('Relative change (perc) : ');
end

while ( changement == 1 ) && ( N_iter < opt.nb_iter_max )    
    
    %% Build the centers and the attraction to the centers 
    if N_iter ~= 1
        gi = centre_gravite(data,part(:,part_curr),opt.p,K,ind_change,gi);
    end
    if (N_iter>1)||~strcmp(opt.type_init,'kmeans++')
        A = attraction(data,gi,opt.p,ind_change,A);
    end
    
    %% Update partition
    [A_min,part_bis] = min(A,[],2);     
    part_old = part_curr;
    part_curr = mod(part_curr,opt.nb_tests_cycle)+1;
    part(:,part_curr) = part_bis;    
    
    %% Deal with empty clusters    
    if ~strcmp(opt.type_death,'none')&&(length(unique(part(:,part_curr)))~=K)
        switch opt.type_death            
            case 'singleton'
                
                part(:,part_curr) = sub_singleton(A_min,part(:,part_curr),K);
                
            case 'split'
                
                part(:,part_curr) = sub_split(A,part(:,part_curr),K,opt.p);
                                 
            case 'bisect'
                
                part(:,part_curr) = sub_bisect(data,A,part(:,part_curr),K,opt.p,opt_rep);                              
        end    
    end
    
    %% Check for cycles and list the clusters that have changed    
    mat_curr = niak_part2mat(part(:,part_curr),true);
    mat_old = niak_part2mat(part(:,part_old),true);
    diff = any(mat_curr~=mat_old);
    deplacements = sum(diff)/length(diff);
    changement = deplacements>0.01;        
    N_iter = N_iter + 1;
    ind_change = unique(part(diff>0,part_curr));
    if opt.flag_verbose
        fprintf(' %1.2f -',deplacements);        
    end
end

if opt.flag_verbose
    fprintf('\n')
end
if (N_iter == opt.nb_iter_max)&&opt.flag_verbose
    fprintf('The maximal number of iterations was reached.\n')
end

% save the final results
part = part(:,part_curr);
gi = centre_gravite(data,part,opt.p,K);

if nargout>2
    % Final inter-class inertia
    p_classe = zeros([K 1]);
    for i = 1:K
        p_classe(i) = sum(opt.p(part==i));
    end
    mask_OK = p_classe~=0;
    gi_OK = gi(mask_OK,:);
    p_classe_OK = p_classe(mask_OK);
    g = (1/sum(p_classe_OK))*sum(gi_OK.*(p_classe_OK*ones([1,T])),1);
    i_inter = sum(sum(p_classe_OK.*sum((gi_OK-(ones([sum(mask_OK) 1])*g)).^2,2)))/sum(p_classe_OK);
    
    % Final intra-class inertia
    i_intra = zeros([K 1]);
    for num_c = 1:K
        i_intra(num_c) = sum(opt.p(part==num_c).*sum((data(part==num_c,:)-(ones([sum((part==num_c)) 1])*gi(num_c,:))).^2,2));
    end
    i_intra = i_intra/sum(p_classe);
end
if nargout>1
    gi = gi';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    SUBFUNCTIONS                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Attraction of each object to the centers
function A = attraction(data,gi,p,ind_change,A);

nb_classes = size(gi,1);
N = size(data,1);
for num_e = 1:length(ind_change)
    num_i = ind_change(num_e);
    A(:,num_i) = p.*sum((data-ones([N,1])*gi(num_i,:)).^2,2);
end
return

%% Center of gravity of the classes
function gi = centre_gravite(data,part,p,nb_classes,ind_change,gi)

[N,T] = size(data);
if nargin < 5
    ind_change = 1:nb_classes;
    gi = zeros([nb_classes T]);
end

for num_e = 1:length(ind_change)
    num_i = ind_change(num_e);
    mask_i = (part == num_i);
    if ~any(mask_i)
        gi(num_i,:) = 0;
    else
        ind = data(mask_i,:);
        g = (1/sum(p(mask_i)))*sum(ind.*(p(mask_i)*ones([1 T])),1);
        gi(num_i,:) = g;
    end
end

%% Squared error
function se = sub_se(se_data,gi,part,p)

se = zeros([2 1]);
for num_p = 1:2
    se(num_p) = sum((se_data(part==num_p)))-sum(p(part==num_p))*sum(gi(:,num_p).^2);
end

%% Resurection : singleton
function part = sub_singleton(A_min,part,K);
ind_dead = find(~ismember(1:K,part));
[val,order] = sort(A_min,'descend');
for num_d = 1:length(ind_dead)    
    part(order(num_d)) = ind_dead(num_d);
end

%% Resurrection : split
function part = sub_split(A,part,K,p);

% Compute the sum of squares per cluster
list_sum = zeros([K 1]);
siz_rois = zeros([K 1]);
[siz_rois_tmp,labels_tmp] = niak_build_size_roi(part);
siz_rois(labels_tmp) = siz_rois_tmp;
for num_k = 1:K
    if siz_rois(num_k)>0
        if isempty(p)
            list_sum(num_k) = siz_rois(num_k)*sum(A(part==num_k,num_k));
        else
            list_sum(num_k) = siz_rois(num_k)*sum(A(:,num_k).*p(:));
        end
    end
end
[val,order] = sort(list_sum);

% Randomly split the clusters ordered by decreasing sum of squares
list_ind = order(val==0);
list_ind = list_ind(:)';
num_target = length(order);
nb_rep = 0;
num_r = length(list_ind);
while num_r>0
    ind_rep = find(part==order(num_target));
    if length(ind_rep)>2
        ind_rep = ind_rep(randperm(length(ind_rep)));
        part(ind_rep(1:floor(length(ind_rep)/2))) = list_ind(num_r);        
        nb_rep = nb_rep+1;
        num_r = num_r-1;
    end    
    num_target = num_target-1;
end

%% Resurrection : bisect
function part = sub_bisect(data,A,part,K,p,opt_rep)

% Compute the sum of squares per cluster
list_sum = zeros([K 1]);
siz_rois = zeros([K 1]);
[siz_rois_tmp,labels_tmp] = niak_build_size_roi(part);
siz_rois(labels_tmp) = siz_rois_tmp;
for num_k = 1:K
    if siz_rois(num_k)>0
        if isempty(p)
            list_sum(num_k) = siz_rois(num_k)*sum(A(part==num_k,num_k));
        else
            list_sum(num_k) = siz_rois(num_k)*sum(A(:,num_k).*p(:));
        end
    end
end
[val,order] = sort(list_sum);

% Randomly bisect the clusters ordered by decreasing sum of squares using
% k-means
list_ind = order(val==0);
list_ind = list_ind(:)';
num_target = length(order);
nb_rep = 0;
num_r = length(list_ind);
while (num_r>0)&&(num_target>0)
    ind_rep = find(part==order(num_target));    
    if length(ind_rep)>2
        opt_rep.p = p(part==order(num_target));
        part_tmp = niak_kmeans_clustering(data(part==order(num_target),:)',opt_rep);
        part(ind_rep(part_tmp==2)) = list_ind(num_r);
        nb_rep = nb_rep+1;
        num_r = num_r-1;
    end    
    num_target = num_target-1;    
end
