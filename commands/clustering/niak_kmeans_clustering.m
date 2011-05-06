function [part,gi,i_intra,i_inter] = niak_kmeans_clustering(data,opt,flag_opt);
% k-means clustering.
%
% SYNTAX :
% [PART,GI,I_INTRA,I_INTER] = NIAK_KMEANS_CLUSTERING(DATA,OPT);
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
%       FLAG_BISECTING
%           (boolean, default false) if FLAG_BISECTING is true, the k-means
%           will follow a bisecting approach. The data is first partitioned
%           in two clusters with k-means, then the cluster with largest 
%           sum-of-square error is further partitioned in two subclusters, 
%           etc until NB_CLASSES clusters have been created.
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
%           (string, default 'euclidian') the similarity measure used to 
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
%           (scalar, 0) the rate of changes to decide on convergence of
%           the algorithm. The rate of change is defined as the proportion of
%           regions whose associated cluster changed between two
%           iterations.
%
%       NB_ITER
%           (integer, default 1) number of iterations of the kmeans (the 
%           best clustering, i.e. with lowest I_INTRA, will be selected).
%
%       NB_ITER_MAX
%           (integer, default 50) Maximal number of iterations of the
%           k-means algorithm.
%
%       NB_ATTEMPTS_MAX
%           (integer, default 5) In bisecting mode, the number of times the
%           algorithm will try to bisect a cluster before moving on to the
%           next one on the list.
%
%       NB_TESTS_CYCLE
%           (integer, default 5) the number of partitions kept in memory to
%           check for cycles.
%
%       FLAG_MEX
%           (boolean, default false) Use a mex implementation of k-means. 
%           See the NOTES section below.
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
% The mex implementation requires to install and compile the mex in the "sparse
% coding neural gas" toolbox : 
% http://www.inb.uni-luebeck.de/tools-demos/scng
% In this mode, OPT.P, OPT.TYPE_DEATH, OPT.TYPE_INIT and OPT.INIT are 
% ignored. The iteration and bisecting version of the algorithm will still 
% work.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
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
    list_fields    = {'hierarchical' , 'type_similarity' , 'convergence_rate' , 'nb_attempts_max' , 'flag_bisecting' , 'init' , 'type_init'        , 'type_death' , 'nb_classes' , 'p' , 'nb_iter' , 'flag_verbose' , 'nb_iter_max' , 'nb_tests_cycle' , 'flag_mex' };
    list_defaults  = {struct()       , 'product'         , 0                  , 5                 , false            , []     , 'random_partition' , 'none'       , NaN          , []  , 1         , 0              , 50            , 5                , false      };
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
end
K = opt.nb_classes;

if opt.nb_iter > 1
    i_inter = 0;
    opt_kmeans = opt;
    opt_kmeans.nb_iter = 1;

    for num_i = 1:opt.nb_iter

        [part_tmp,gi_tmp,i_intra_tmp,i_inter_tmp] = niak_kmeans_clustering(data,opt_kmeans,false);
        if (i_inter_tmp > i_inter)|~exist('part','var')
            part = part_tmp;
            i_inter = i_inter_tmp;
            gi = gi_tmp;
            i_intra = i_intra_tmp;
        end
    end

else
    
    if isempty(opt.p)
        opt.p = ones([size(data,2) 1]);
    end
    
    if (opt.flag_bisecting)
        part = ones([1 size(data,2)]);        
        se_data = sum(repmat(opt.p',[size(data,1) 1]).*data.^2,1);
        se = zeros([size(data,2) 1]);        
        se(1) = Inf;
        opt_b                = opt;
        opt_b.nb_classes     = 2;
        opt_b.flag_bisecting = false;
        opt_b.flag_verbose   = false;
        if opt.flag_verbose
            fprintf('     Percentage done : 0');
            perc_verb = 0.05;
        end

        for num_i = 1:(K-1)
            if opt.flag_verbose
                if floor(perc_verb^(-1)*num_i/(K-1))>floor(perc_verb^(-1)*(num_i-1)/(K-1))
                    fprintf(' %1.0f',100*(num_i/(K-1)));
                end
            end            
            [val,order] = sort(se);
            num_t = length(order);
            part_tmp = ones(size(part));
            nb_attempts = 1;
            flag_bisect = false;
            while (~flag_bisect)&&(num_t>0)
                opt_b.p = opt.p(part==order(num_t));                
                [part_tmp,gi_tmp] = niak_kmeans_clustering(data(:,part==order(num_t)),opt_b,false);
                flag_bisect = (any(part_tmp==1)&&any(part_tmp==2));
                if (~flag_bisect)
                    if nb_attempts <= opt.nb_attempts_max
                        nb_attempts = nb_attempts + 1;
                    else                    
                        num_t = num_t-1;
                    end
                end
            end
            if num_t == 0
                num_t = 1;
            end
            gi_tmp = centre_gravite(data(:,part==order(num_t))',part_tmp,opt.p,2)';
            se_tmp = sub_se(se_data,gi_tmp,part_tmp,opt.p);
            part_tmp2 = part_tmp;
            part_tmp2(part_tmp==1) = order(num_t);
            part_tmp2(part_tmp==2) = 1+num_i;            
            se(order(num_t)) = se_tmp(1);            
            se(1+num_i) = se_tmp(2);
            part(part==order(num_t)) = part_tmp2;
        end
        if opt.flag_verbose
            fprintf(' Done ! \n');
        end
        
        if nargout>1
            gi = zeros([K size(data,1)]);
            for num_i = 1:K
                if any(part==num_i)
                    gi(num_i,:) = mean(data(:,part==num_i),2);
                end
            end
        end
    end
    
    if (opt.flag_mex)&&(~opt.flag_bisecting)
        [gi,part,mse] = Kmeans(data,K,0);
        part = part(:);
        gi = gi';
    end
        
    if ~opt.flag_mex&&(~opt.flag_bisecting)
        [part,gi] = niak_kmeans_mat(data,opt,false);
        part = part(:);
        gi = gi';
    end
    
    if nargout>2
        [T,N] = size(data);
        data = data';
        
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
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    SUBFUNCTIONS                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Attraction of each object to the centers
function A = attraction(data,gi,p);

nb_classes = size(gi,1);
N = size(data,1);
A = zeros([length(p) nb_classes]);
for num_i = 1:nb_classes
    A(:,num_i) = p.*sum((data-ones([N,1])*gi(num_i,:)).^2,2);
end
return

%% Center of gravity of the classes
function gi = centre_gravite(data,part,p,nb_classes)

[N,T] = size(data);
gi = zeros([nb_classes T]);

for i = 1:nb_classes;
    mask_i = (part == i);
    if ~any(mask_i)
        gi(i,:) = 0;
    else
        ind = data(mask_i,:);
        g = (1/sum(p(mask_i)))*sum(ind.*(p(mask_i)*ones([1 T])),1);
        gi(i,:) = g;
    end
end

%% Squared error
function se = sub_se(se_data,gi,part,p)

se = zeros([2 1]);
for num_p = 1:2
    se(num_p) = sum((se_data(part==num_p)))-sum(p(part==num_p))*sum(gi(:,num_p).^2);    
end
