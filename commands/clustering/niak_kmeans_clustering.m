function [part,gi,i_intra,i_inter] = niak_kmeans_clustering(data,opt);
%
% _________________________________________________________________________
% SUMMARY NIAK_KMEANS_CLUSTERING
%
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
%       
%       NB_ITER
%           (integer, default 1) number of iterations of the kmeans (the 
%           best clustering, i.e. with lowest I_INTRA, will be selected).
%
%       NB_ITER_MAX
%           (integer, default 100) Maximal number of iterations of the
%           k-means algorithm.
%
%       NB_TESTS_CYCLE
%           (integer, default 5) the number of partitions kept in memory to
%           check for cycles.
%
%       FLAG_VERBOSE
%           (boolean, default 1) if the flag is 1, then the function prints
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
gb_name_structure = 'opt';
gb_list_fields = {'init','type_init','type_death','nb_classes','p','nb_iter','flag_verbose','nb_iter_max','nb_tests_cycle'};
gb_list_defaults = {[],'random_partition','none',NaN,[],1,1,100,5};
niak_set_defaults

if nb_iter > 1
    i_inter = 0;
    opt_kmeans = opt;
    opt_kmeans.nb_iter = 1;

    for num_i = 1:nb_iter

        [part_tmp,gi_tmp,i_intra_tmp,i_inter_tmp] = niak_kmeans_clustering(data,opt_kmeans);
        if (i_inter_tmp > i_inter)|~exist('part','var')
            part = part_tmp;
            i_inter = i_inter_tmp;
            gi = gi_tmp;
            i_intra = i_intra_tmp;
        end
    end

else
    
    data = data';    
    [N,T] = size(data);
    if isempty(p)
        p = ones([N 1]);
    end

    % Parameters
    %warning off


    %% Initialization
    part = zeros([N nb_tests_cycle]);
    changement = 1;
    N_iter = 1;
    part_curr = 1;

    %% Initialization of cluster centers
    gi = zeros([nb_classes T]);  

    switch type_init

        case 'random_point'

            %% Initialization using random points
            perm_init = randperm(N);
            gi = data(perm_init(1:nb_classes),:);

        case 'random_partition'

            %% Initialization using random partition            
            part(:,part_curr) = ceil(nb_classes*rand([N 1]));
            gi = centre_gravite(data,part(:,1),p,nb_classes);

        case 'pca'

            %% Initialization using eigen vectors
            [eig_val,eig_vec] = niak_pca(data);
            gi = eig_vec(:,1:nb_classes)';

        case 'user-specified'
            
            %% Initialization used the user-specified centroids
            gi = init';
            clear init
            
        otherwise

            error('%s is an unknwon type of initialisation. Please check the value of OPT.TYPE_INIT',type_init);
    end

    if flag_verbose
        fprintf('Number of displacements : ');
    end

    while ( changement == 1 ) && ( N_iter < nb_iter_max )

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Build the partition matching the centers %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        A = attraction(data,gi,p);

        %% look for maximal attraction points
        [A_min,part_bis] = min(A,[],2);
        deplacements = sum(part(:,part_curr)~=part_bis);
        if flag_verbose
            fprintf(' %d -',deplacements);
        end

        %% Update partition and gravity center
        if part_curr == nb_tests_cycle
            part_curr = 1;
        else
            part_curr = part_curr+1;
        end
        part(:,part_curr) = part_bis;
        gi = centre_gravite(data,part_bis,p,nb_classes);
               
        %% Deal with empty clusters
        if ~strcmp(type_death,'none')                                    
            if length(unique(part(:,part_curr)))~=nb_classes
                switch type_death
                    
                    case 'singleton'
                        ind_dead = find(~ismember(1:nb_classes,part(:,part_curr)));
                        ind_dead = ind_dead(1);
                        [val_max,ind_max] = max(A_min);
                        gi(ind_dead,:) = data(ind_max(1),:);                                                
                end
            end
        end      
         %% Check we're not in a cycle
        changement = min(max(abs(part(:,(1:nb_tests_cycle)~=part_curr) - part(:,part_curr)*ones([1 nb_tests_cycle-1])),[],1))>0;
        N_iter = N_iter + 1;
        
    end
    
    if flag_verbose
        if N_iter < nb_iter_max
            fprintf('\n')
        else
            fprintf('The maximal number of iteration was reached.\n')
        end
    end
    %warning on

    % save the final results
    part = part(:,part_curr);
    gi = centre_gravite(data,part,p,nb_classes);
    
    % Final inter-class inertia
    p_classe = zeros([nb_classes 1]);
    for i = 1:nb_classes
        p_classe(i) = sum(p(part==i));
    end
    mask_OK = p_classe~=0;
    gi_OK = gi(mask_OK,:);
    p_classe_OK = p_classe(mask_OK);        
    g = (1/sum(p_classe_OK))*sum(gi_OK.*(p_classe_OK*ones([1,T])),1);
    i_inter = sum(sum(p_classe_OK.*sum((gi_OK-(ones([sum(mask_OK) 1])*g)).^2,2)))/sum(p_classe_OK);

    % Final intra-class inertia
    i_intra = zeros([nb_classes 1]);
    for num_c = 1:nb_classes
        i_intra(num_c) = sum(p(part==num_c).*sum((data(part==num_c,:)-(ones([sum((part==num_c)) 1])*gi(num_c,:))).^2,2));
    end
    i_intra = i_intra/sum(p_classe);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    SUBFUNCTIONS                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Attraction of each object to the centers
function A = attraction(data,gi,p);

nb_classes = size(gi,1);
N = size(data,1);
A = zeros([length(p) nb_classes]);
for i = 1:nb_classes
    A(:,i) = p.*sum((data-ones([N,1])*gi(i,:)).^2,2);
end
return

%% Center of gravity of the classes
function gi = centre_gravite(data,part,p,nb_classes)

[N,T] = size(data);
gi = zeros([nb_classes T]);

for i = 1:nb_classes;
    mask_i = (part == i);
    ind = data(mask_i,:);
    g = (1/sum(p(mask_i)))*sum(ind.*(p(mask_i)*ones([1 T])),1);
    gi(i,:) = g;
end
