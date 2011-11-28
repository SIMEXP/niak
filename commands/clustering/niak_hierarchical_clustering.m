function hier = niak_hierarchical_clustering(S,opt)
% Hierarchical agglomerative clustering based on a similarity matrix.
% A variety of between-clusters similarity measures are available.
%
% SYNTAX:
% HIER = NIAK_HIERARCHICAL_CLUSTERING(S,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% S
%       (matrix size N*N) the similarity matrix between individuals
%
% OPT
%       (structure) with the following fields (absent fields will be
%       assigned a default value if possible).
%
%       P       
%           (vector N*1, default ones([N 1])) size associated to each
%           individual.
%
%       TYPE_SIM
%           (string, default 'ward') the type of similarity between 
%           clusters (see COMMENTS below) :
%               
%               'single'
%                   single linkage (maximal similarity)
%
%               'complete'
%                   complete linkage (minimal similarity)
%
%               'average'
%                   unweighted average of similarity between clusters.
%                   (UPGMA).
%               
%               'ward'
%                   The Ward criterion of similarity between clusters.
%
%       NB_CLASSES
%           (integer, default 1) if non-empty, the clustering will stop
%           when the specified number of clusters is reached.    
%
%       FLAG_VERBOSE
%           (boolean, default 1) print an advancement information
%
% _________________________________________________________________________
% OUTPUTS:
%
% HIER
%   (2D array) defining a hierarchy :
%       Column 1: Level of new link
%       Column 2: Entity no x
%       Column 3: joining entity no y
%       Column 4: To form entity no z
%       Column 5: If specified, another distance type between
%                 clusters
%                 Where the entity numbers take the values 1 to number of
%                 entities (N), and the new entity numbers carry on increasing
%                 numerically.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_VISU_DENDROGRAM, NIAK_THRESHOLD_HIERARCHY, NIAK_HIER2ORDER
%
% _________________________________________________________________________
% COMMENTS:
%
% The Ward criterion is applied on an arbitrary similarity as it is on
% arbitrary dissimilarities (which is meaningful as long as the similarity 
% can be seen as A-d, where A is a constant and d a dissimilarity). For the
% generalization of Ward's criterion (a.k.a. minimal inertia) to arbitrary
% dissimilarities, see : 
%
% Batagelj, V. Generalized ward and related clustering problems. In 
% Classification and Related Methods of Data Analysis (1988), pp. 67-74. 
% Edited by H.H. Bock, North-Holland, Amsterdam.
%
% The so-called hierarchical clustering is more precisely an homogeneity 
% based sequential, agglomerative, hierarchical and non-overlapping 
% procedure (hSAHN). See the following reference for a description of 
% cluster-level similarity measures :
%
% János Podani, New Combinatorial Clustering Methods, Vegetatio, Vol. 81, 
% No. 1/2 (Jul. 1, 1989), pp. 61-77 
%
% If symmetric, the matrix can be "vectorized" using NIAK_VEC2MAT.
%
% Copyright (c) Pierre Bellec, 
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal, 2010-2011
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : hierarchical clustering

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
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

if size(S,2) == 1
    S = niak_vec2mat(S);
end
N = size(S,1);

%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'p'         , 'type_sim' , 'flag_verbose' , 'nb_classes' };
gb_list_defaults  = {ones([N,1]) , 'ward'     , true           , 1            };
niak_set_defaults

perc_verb = 0.05;
list_objects = 1:N;             % Initialization of the object list
S(eye(size(S))==1) = -Inf; 
[max_sim,list_nn] = max(S,[],1); % Initializaton of the maximal similarity list
nb_iter = N-nb_classes;
hier = zeros([nb_iter 4]); % Initialization of the hierarchy

perc = 0;

if flag_verbose
    fprintf('     Percentage done : 0');
end

for num_i = 1:nb_iter
    
    if flag_verbose
        if floor(perc_verb^(-1)*num_i/(N-1))>floor(perc_verb^(-1)*(num_i-1)/(N-1))
            fprintf(' %1.0f',100*(num_i/(N-1)));
        end
    end
    
    % Get the couple of nearest neighbours    
    max_sx = max(max_sim);   
    cx = find(max_sim==max_sx);
    if length(cx)>1
        cx = cx(ceil(rand(1)*length(cx)));
    end
    cy = list_nn(cx);
    tmp = [cx cy];
    cx = min(tmp);
    cy = max(tmp);
    
    % Look for the nearest clusters, and merge them        
    hier(num_i,:) = [S(cx,cy) list_objects(cx) list_objects(cy) max(list_objects)+1];    
      
    % Update the distance matrix    
    switch type_sim
            
        case 'complete'
            
            S(cx,:) = min(S(cx,:),S(cy,:));
            
        case 'single'
            
            S(cx,:) = max(S(cx,:),S(cy,:));
            
        case 'average'
            
            S(cx,:) = (p(cx)./(p(cy)+p(cx))).*S(cx,:) + (p(cy)./(p(cx)+p(cy)).*S(cy,:));         
            
        case 'ward'
            
            S(cx,:) = ((p+p(cx))'.*S(cx,:) + (p+p(cy))'.*S(cy,:) - p'*S(cx,cy))./(p+p(cy)+p(cx))';
            
        otherwise
            
            error('%s is an unknown type of cluster-level similarity',type_sim);
            
    end
    S(:,cx) = S(cx,:)';
    S(:,cy) = -Inf;
    S(cy,:) = -Inf;
    S(cx,cx) = -Inf;        
    
    % Update the 'maximal similarity' vector 
    % case 1, the nearest neighbour was cx or cy, but (cx U cy) is not the nearest neighbour anymore
    [max_sim(list_nn==cy),list_nn(list_nn==cy)] = max(S(:,list_nn==cy),[],1);    
    [max_sim(list_nn==cx),list_nn(list_nn==cx)] = max(S(:,list_nn==cx),[],1);
    max_sim(cy) = -Inf;
    list_nn(cy) = NaN;
    
    % Update the 'maximal similarity' vector 
    % case 2, the nearest neighbour was not cx or cy, but (cx U cy) is the nearest neighbour     
    [max_sim,ind_x] = max([max_sim ; S(cx,:)],[],1);
    list_nn(ind_x==2) = cx;       

    % Update the 'maximal similarity' vector 
    % case 3, look for the nearest neighbour of (cx U cy)
    [max_sim(cx),list_nn(cx)] = max(S(cx,:));    
    
    % Update the size vector
    p(cx) = p(cx)+p(cy);    

    % Update object list
    list_objects(cx) = max(list_objects)+1;   
    list_objects(cy) = NaN;
    
end


if flag_verbose
    fprintf(' Done ! \n');
end

        
