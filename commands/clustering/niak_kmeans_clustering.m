function [part,gi,i_intra,i_inter] = niak_kmeans_clustering(data,opt,part);
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
%           in two clusters with k-means, then the biggest cluster is
%           further partitioned in two subclusters, etc until NB_CLASSES
%           clusters have been created.
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
%           'random_partition' : self-explanatory
%           'random_point' : randomly select some data points as
%               centroids.
%           'pca' : use the first principal components as centroids.
%           'user-specified' : use OPT.INIT as inial centroids of the
%           partition.
%
%       INIT
%           (2D array T*K) each column is used as initial centroid of a
%           cluster. Note that this value will be used only if
%           OPT.TYPE_INIT equals 'user-specified'.
%           
%       TYPE_DEATH
%           (string, default 'singleton') the strategy to deal with dead
%           (empty) cluster :
%           'none' let them be empty.
%           'singleton' iteratively replace every empty cluster by the one
%           singleton which is further away from its centroid.
%           'split' iteratively splits the largest cluster in two randomly
%           until the number of clusters is back to the one specified.
%       
%       NB_ITER
%           (integer, default 1) number of iterations of the kmeans (the 
%           best clustering, i.e. with lowest I_INTRA, will be selected).
%
%       NB_ITER_MAX
%           (integer, default 100) Maximal number of iterations of the
%           k-means algorithm.
%
%       NB_ATTEMPTS_MAX
%           (integer, default 5) In bisecting mode, the number of times the
%           algorithm will try to bisect a cluster before moving on to the
%           next one on the list (in decreasing size order).
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
% In this mode, OPT.P, OPT.TYPE_DEATH, OPT.TYPE_INIT and OPT.INIT are ignored. The 
% iteration of the algorithm will still work.
%
% Copyright (c) partierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
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
% THE SOFTWARE IS partROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EdatapartRESS OR
% IMpartLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A partARTICULAR partURpartOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COpartYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%% Options
list_fields    = {'nb_attempts_max' , 'flag_bisecting' , 'init' , 'type_init'        , 'type_death' , 'nb_classes' , 'p' , 'nb_iter' , 'flag_verbose' , 'nb_iter_max' , 'nb_tests_cycle' , 'flag_mex' };
list_defaults  = {5                 , false            , []     , 'random_partition' , 'none'       , NaN          , []  , 1         , 0              , 100           , 5                , false      };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

if opt.nb_iter > 1
    i_inter = 0;
    opt_kmeans = opt;
    opt_kmeans.nb_iter = 1;

    for num_i = 1:opt.nb_iter

        [part_tmp,gi_tmp,i_intra_tmp,i_inter_tmp] = niak_kmeans_clustering(data,opt_kmeans);
        if (i_inter_tmp > i_inter)|~exist('part','var')
            part = part_tmp;
            i_inter = i_inter_tmp;
            gi = gi_tmp;
            i_intra = i_intra_tmp;
        end
    end

else
    
    if (opt.flag_bisecting)
        part = ones([1 size(data,2)]);
        %size_part = zeros([size(data,2) 1]);
        se = zeros([size(data,2) 1]);
        %size_part(1) = size(data,2);
        se(1) = Inf;
        opt_b                = opt;
        opt_b.nb_classes     = 2;
        opt_b.flag_bisecting = false;
        opt_b.flag_verbose   = false;
        if opt.flag_verbose
            fprintf('     Percentage done : 0');
            perc_verb = 0.05;
        end

        for num_i = 1:(opt.nb_classes-1)
            if opt.flag_verbose
                if floor(perc_verb^(-1)*num_i/(opt.nb_classes-1))>floor(perc_verb^(-1)*(num_i-1)/(opt.nb_classes-1))
                    fprintf(' %1.0f',100*(num_i/(opt.nb_classes-1)));
                end
            end
            %[val,order] = sort(size_part);
            [val,order] = sort(se);
            num_t = length(order);
            part_tmp = ones(size(part));
            nb_attempts = 1;
            while (length(unique(part_tmp))==1)
                [part_tmp,gi_tmp] = niak_kmeans_clustering(data(:,part==order(num_t)),opt_b);
                if nb_attempts <= opt.nb_attempts_max
                    nb_attempts = nb_attempts + 1;
                else
                    if (length(unique(part_tmp))==1)
                        num_t = num_t-1;
                    end
                end
            end
            se_tmp = sub_se(data(:,part==order(num_t)),gi_tmp,part_tmp);
            part_tmp2 = part_tmp;
            part_tmp2(part_tmp==1) = order(num_t);
            part_tmp2(part_tmp==2) = 1+num_i;
            %size_part(order(num_t)) = sum(part_tmp==1);
            se(order(num_t)) = se_tmp(1);
            %size_part(1+num_i) = sum(part_tmp==2);
            se(1+num_i) = se_tmp(2);
            part(part==order(num_t)) = part_tmp2;
        end
        if opt.flag_verbose
            fprintf(' Done ! \n');
        end
        
        if nargout>1
            gi = zeros([opt.nb_classes size(data,1)]);
            for num_i = 1:opt.nb_classes
                if any(part==num_i)
                    gi(num_i,:) = mean(data(:,part==num_i),2);
                end
            end
        end
    end

    if (opt.flag_mex)&&(~opt.flag_bisecting)
        [gi,part,mse] = Kmeans(data,opt.nb_classes,0);
        part = part(:);
        gi = gi';
    end
    data = data';    
    [N,T] = size(data);
    if isempty(opt.p)
        opt.p = ones([N 1]);
    end
    if ~opt.flag_mex&&(~opt.flag_bisecting)
        %% Initialization
        part = zeros([N opt.nb_tests_cycle]);
        changement = 1;
        N_iter = 1;
        part_curr = 1;

        %% Initialization of cluster centers
        gi = zeros([opt.nb_classes T]);

        switch opt.type_init

            case 'random_point'

                %% Initialization using random points
                perm_init = randperm(N);
                gi = data(perm_init(1:opt.nb_classes),:);

            case 'random_partition'

                %% Initialization using random partition
                part(:,part_curr) = ceil(opt.nb_classes*rand([N 1]));
                gi = centre_gravite(data,part(:,1),opt.p,opt.nb_classes);

            case 'pca'

                %% Initialization using eigen vectors
                [eig_val,eig_vec] = niak_pca(data);
                gi = eig_vec(:,1:opt.nb_classes)';

            case 'user-specified'

                %% Initialization used the user-specified centroids
                gi = opt.init';
                clear init

            case 'hierarchical'

                if opt.flag_verbose
                    fprintf('Initialization using hierarchical clustering\n')
                end
                dist_mat = niak_build_distance(data');
                opt_h.nb_classes = opt.nb_classes;
                opt_h.flag_verbose = opt.flag_verbose;
                [hier,order] = niak_hierarchical_clustering(dist_mat);
                clear dist_mat
                opt_t.thresh = opt.nb_classes;
                part_init = niak_threshold_hierarchy(hier,opt_t);
                gi = zeros([opt.nb_classes T]);
                for num_i = 1:opt.nb_classes
                    gi(num_i,:) = mean(data(part_init==num_i,:),1);
                end

            otherwise

                error('%s is an unknwon type of initialisation. Please check the value of OPT.TYPE_INIT',opt.type_init);
        end

        if opt.flag_verbose
            fprintf('Number of displacements : ');
        end

        while ( changement == 1 ) && ( N_iter < opt.nb_iter_max )

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Build the partition matching the centers %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            A = attraction(data,gi,opt.p);

            %% look for maximal attraction points
            [A_min,part_bis] = min(A,[],2);
            deplacements = sum(part(:,part_curr)~=part_bis);
            if opt.flag_verbose
                fprintf(' %d -',deplacements);
            end

            %% Update partition and gravity center
            if part_curr == opt.nb_tests_cycle
                part_curr = 1;
            else
                part_curr = part_curr+1;
            end
            part(:,part_curr) = part_bis;
            gi = centre_gravite(data,part_bis,opt.p,opt.nb_classes);

            %% Deal with empty clusters
            if ~strcmp(opt.type_death,'none')
                if length(unique(part(:,part_curr)))~=opt.nb_classes
                    switch opt.type_death

                        case 'singleton'
                            ind_dead = find(~ismember(1:opt.nb_classes,part(:,part_curr)));
                            ind_dead = ind_dead(1);
                            [val_max,ind_max] = max(A_min);
                            gi(ind_dead,:) = data(ind_max(1),:);

                        case 'split'
                            size_part = niak_build_size_roi(part(:,part_curr));
                            [val,order] = sort(size_part);
                            list_ind = find(val==0);
                            list_ind = list_ind(:)';
                            nb_rep = 0;
                            for num_i = list_ind
                                ind_rep = find(part(:,part_curr)==order(end-nb_rep));
                                ind_rep = indrep(randperm(length(ind_rep)));
                                gi(num_i,:) = mean(ind_rep(1:floor(length(ind_rep)),:),1);
                                gi(end-nb_rep,:) = mean(ind_rep(ceil(length(ind_rep)):end,:),1);
                                nb_rep = nb_rep+1;
                            end
                    end
                    changement = true;
                else
                    changement = min(max(abs(part(:,(1:opt.nb_tests_cycle)~=part_curr) - part(:,part_curr)*ones([1 opt.nb_tests_cycle-1])),[],1))>0;
                end
            else
                changement = min(max(abs(part(:,(1:opt.nb_tests_cycle)~=part_curr) - part(:,part_curr)*ones([1 opt.nb_tests_cycle-1])),[],1))>0;
            end
            N_iter = N_iter + 1;

        end

        if opt.flag_verbose
            if N_iter < opt.nb_iter_max
                fprintf('\n')
            else
                fprintf('The maximal number of iteration was reached.\n')		
            end
        end

        % save the final results
        part = part(:,part_curr);
        gi = centre_gravite(data,part,opt.p,opt.nb_classes);
    end
    if nargout>2
        % Final inter-class inertia
        p_classe = zeros([opt.nb_classes 1]);
        for i = 1:opt.nb_classes
            p_classe(i) = sum(opt.p(part==i));
        end
        mask_OK = p_classe~=0;
        gi_OK = gi(mask_OK,:);
        p_classe_OK = p_classe(mask_OK);
        g = (1/sum(p_classe_OK))*sum(gi_OK.*(p_classe_OK*ones([1,T])),1);
        i_inter = sum(sum(p_classe_OK.*sum((gi_OK-(ones([sum(mask_OK) 1])*g)).^2,2)))/sum(p_classe_OK);
        
        % Final intra-class inertia
        i_intra = zeros([opt.nb_classes 1]);
        for num_c = 1:opt.nb_classes
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
function se = sub_se(tseries,gi,part)

se = zeros([max(part) 1]);
for num_p = 1:max(part)
    if any(part==num_p)
        se(num_p) = sum(sum((tseries(:,part==num_p)-repmat(gi(:,num_p),[1 sum(part==num_p)])).^2));
    end
end