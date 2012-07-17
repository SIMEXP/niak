function [part,order,sil,intra,inter,hier] = niak_consensus_clustering(stab,opt);
% Consensus clustering based on one or multiple stability matrices
%
% SYNTAX :
% [PART,ORDER,SIL,INTRA,INTER,HIER] = NIAK_CONSENSUS_CLUSTERING(STAB,OPT);
%
% _________________________________________________________________________
% INPUTS:
%
% STAB
%   (2D array K*S) STAB(:,I) is a vectorized stability matrix.
%
% OPT
%   (structure) with the following fields (absent fields will be assigned 
%   a default value):
%
%   NB_CLASSES
%       (vector, default []) NB_CLASSES(I) is the number of clusters to
%       extract in the consensus clustering. If left empty, an optimal
%       scale is selected using a stability contrast criterion.
%
%   CLUSTERING
%       (structure, optional) This structure describes
%       the clustering algorithm used to estimate a consensus clustering on 
%       each stability matrix, with the following fields :
%
%       TYPE
%           (string, default 'hierarchical') the clustering algorithm
%           Available options : 'hierarchical'
%
%       OPT
%           (structure, default see NIAK_HIERARCHICAL_CLUSTERING) options 
%           that will be  sent to the  clustering command. The exact list 
%           of options depends on CLUSTERING.TYPE:
%              'hierarchical' : see NIAK_HIERARCHICAL_CLUSTERING
%
%   FLAG_VERBOSE
%       (boolean, default 0) if the flag is 1, then the function prints
%       some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% PART
%   (matrix N*S) PART(:,s) is the consensus partition associated with 
%   STAB(:,s), with the number of clusters optimized using the summary
%   statistics.
%
% ORDER
%   (matrix N*S) ORDER(:,s) is the order associated with STAB(:,s) and
%   PART(:,s) (see NIAK_PART2ORDER).
%
% SIL
%   (matrix S*N) SIL(s,n) is the mean stability contrast associated with
%   STAB(:,s) and n clusters (the partition being defined using HIER{s}, 
%   see below).
%
% INTRA
%   (matrix, S*N) INTRA(s,n) is the mean within-cluster stability
%   associated with STAB(:,s) and n clusters (the partition being defined 
%   using HIER{s}, see below).
%
% INTER
%   (matrix, S*N) INTER(s,n) is the mean maximal between-cluster stability 
%   associated with STAB(:,s) and n clusters (the partition being defined 
%   using HIER{s}, see below).
%
% HIER
%   (cell of array) HIER{S} is the hierarchy associated with STAB(:,s)
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_SILHOUETTE, NIAK_BUILD_AVG_SILHOUETTE,
% NIAK_HIERARCHICAL_CLUSTERING
%
% _________________________________________________________________________
% COMMENTS:
%
% See NIAK_BUILD_SILHOUETTE for more infos regarding the un-normalized
% silhouette criterion, as well as the inter-cluster average stability and
% the maximal between cluster average stability (noted a and b in the
% documentation, respectively). 
%
% See the following publication regarding consensus clustering on stability
% matrices and the use of stability contrast to select the number of
% clusters : 
%  P. Bellec; P. Rosa-Neto; O.C. Lyttelton; H. Benalib; A.C. Evans,
%  Multi-level bootstrap analysis of stable clusters in resting-State fMRI. 
%  Neuroimage 51 (2010), pp. 1126-1139 
%
% Copyright (c) Pierre Bellec, 
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal, 2010-2011
% Maintainer : pierre.bellec@criugm.qc.ca
% Keywords : consensus, clustering, hierarchical clustering

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
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESSED OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%% Options
list_fields   = {'nb_classes' , 'clustering' , 'flag_verbose' };
list_defaults = {[]           , struct()     , true           };
if nargin<2
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
else
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
end

list_fields   = {'type'         , 'opt'    };
list_defaults = {'hierarchical' , struct() };
opt.clustering = psom_struct_defaults(opt.clustering,list_fields,list_defaults);

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Consensus clustering %%
%%%%%%%%%%%%%%%%%%%%%%%%%%
if opt.flag_verbose
    fprintf('Consensus clustering ...\n     Percentage done : ');
    perc_verb = 0.1;    
end

nb_s = size(stab,2);
hier = cell([nb_s 1]);
tmp = niak_vec2mat(stab);
N = size(tmp,1);
clear tmp
part = zeros([N nb_s]);
order = zeros([N nb_s]);
sil = zeros([N nb_s]);
intra = zeros([N nb_s]);
inter = zeros([N nb_s]);
opt.clustering.opt.flag_verbose = false;
for num_s = 1:nb_s
    if opt.flag_verbose
        if floor(perc_verb^(-1)*(num_s-1)/(nb_s-1))>floor(perc_verb^(-1)*(num_s-2)/(nb_s-1))
            fprintf('%1.0f ',100*(num_s-1)/(nb_s-1));
        end
    end
    mat = niak_vec2mat(stab(:,num_s));
    switch opt.clustering.type

        case 'hierarchical'
            
            hier{num_s} = niak_hierarchical_clustering(mat,opt.clustering.opt);

        otherwise

            error('%s is an unkown type of consensus clustering',opt.clustering.type)

    end    
    if (nargout > 2)||isempty(opt.nb_classes)     
        [sil(:,num_s),intra(:,num_s),inter(:,num_s)] = niak_build_avg_silhouette(mat,hier{num_s},false);
        [sil_max,ind_max] = max(sil(:,num_s));
        opt_t.thresh = ind_max;
    end
    if ~isempty(opt.nb_classes)
        opt_t.thresh = opt.nb_classes(num_s);
    end
    part(:,num_s) = niak_threshold_hierarchy(hier{num_s},opt_t);
    if nargout > 1
        [order(:,num_s),part(:,num_s)] = niak_part2order(part(:,num_s),mat);
    end
end
if opt.flag_verbose
    fprintf('Done !\n');
end