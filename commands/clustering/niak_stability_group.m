function [stab,stab_avg] = niak_stability_group(mat_stab,mask,opt)
% Estimate the stability of a clustering on an average stability matrix.
%
% SYNTAX:
% STAB = NIAK_STABILITY_GROUP(MAT_STAB,MASK,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% MAT_STAB
%   (array) STAB(:,S) is the vectorized version of the stability matrix
%   associated with subject S.
%
% MASK
%   (vector) MASK(S) is the number of the strata of subject S (i.e. the
%   subjects in strata K are find(mask==K).
%
% OPT
%   (structure) with the following fields:
%
%   NB_CLASSES
%       (vector of integer) the number of clusters (or classes) that will
%       be investigated. This parameter will overide the parameters
%       specified in CLUSTERING.OPT_CLUST
%
%   NB_SAMPS
%       (integer, default 100) the number of samples to use in the
%       bootstrap Monte-Carlo approximation of stability.
%
%   CLUSTERING
%       (structure, optional) with the following fields :
%
%       TYPE
%           (string, default 'hierarchical') the clustering algorithm
%           Available options : 'hierarchical'
%
%       OPT
%           (structure, optional) options that will be  sent to the
%           clustering command. The exact list of options depends on
%           CLUSTERING.TYPE:
%               'hierarchical' : see OPT in NIAK_HIERARCHICAL_CLUSTERING
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function prints
%       some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% STAB
%   (array) STAB(:,s) is the vectorized version of the stability matrix
%   associated with OPT.NB_CLASSES(s) clusters.
%
% STAB_AVG
%   (array) STAB_AVG is the vectorized version of the individual stability 
%   matrix averaged across all subjects.
%
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_STABILITY_GROUP
%
% _________________________________________________________________________
% COMMENTS:
%
% For more details, see the description of the stability analysis on a
% individual fMRI time series in the following reference :
%
% P. Bellec; P. Rosa-Neto; O.C. Lyttelton; H. Benalib; A.C. Evans,
% Multi-level bootstrap analysis of stable clusters in resting-State fMRI.
% Neuroimage 51 (2010), pp. 1126-1139
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de Gériatrie de Montréal,
% Département d'informatique et de recherche opérationnelle,
% Université de Montréal, 2010-2011.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap

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

%% Options
opt_clustering.type   = 'hierarchical';
opt_clustering.opt    = struct();
list_fields   = {'nb_samps' , 'nb_classes' , 'clustering'   , 'flag_verbose' };
list_defaults = {100        , NaN          , opt_clustering , true           };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%%%%%%%%%%%%%%%%%%%%%%
%% Stability matrix %%
%%%%%%%%%%%%%%%%%%%%%%
[S,N] = size(mat_stab); % S is the length of the vectorized stability matrix, N is the number of subjects
nb_s = length(opt.nb_classes); % The number of clustering parameters to be tested.
stab = zeros([S nb_s]); % Initialize the stability matrix
stab_avg = sub_mean_stab(mat_stab,mask); % The average individual stability_matrix
opt.clustering.opt.flag_verbose = false;

if opt.flag_verbose
    fprintf('Estimate the stability matrix ...\n     Percentage done : ');
    curr_perc = -1;
end

% Generate samples
for num_s = 1:opt.nb_samps
    if opt.flag_verbose
        new_perc = 5*floor(20*num_s/opt.nb_samps);
        if curr_perc~=new_perc
            fprintf(' %1.0f',new_perc);
            curr_perc = new_perc;
        end
    end
    samp_stab = sub_mean_stab(sub_SB(mat_stab,mask),mask);

    if ismember(opt.clustering.type,'hierarchical') % for methods that produce a hierarchy
        
        switch opt.clustering.type
            case 'hierarchical'
                hier = niak_hierarchical_clustering(samp_stab,opt.clustering.opt);
        end
        opt_t.thresh = opt.nb_classes;
        part = niak_threshold_hierarchy(hier,opt_t);
        for num_sc = 1:nb_s
            stab(:,num_sc) = stab(:,num_sc) + niak_mat2vec(niak_part2mat(part(:,num_sc),true));
        end
        
    else % for clustering methods

        error(cat(2,opt.clustering.type,': unknown type of clustering'));
        
    end
end
stab = stab / opt.nb_samps;
if opt.flag_verbose
    fprintf('\n');
end

%%%%%%%%%%%%%%%%%%
%% SUBFUNCTIONS %%
%%%%%%%%%%%%%%%%%%

function mean_stab = sub_mean_stab(mat_stab,mask)
% Compute an average of stability matrices with equal weights on each strata
nb_strata = max(mask);
mean_stab = zeros([size(mat_stab,1) 1]);
for num_e = 1:nb_strata
    mean_stab = mean_stab + mean(mat_stab(:,mask==num_e),2);
end
mean_stab = mean_stab/nb_strata;

function boot_stab = sub_SB(mat_stab,mask)
% Apply a stratified bootstrap on the stability matrices
nb_strata = max(mask);
boot_stab = zeros(size(mat_stab));
for num_e = 1:nb_strata
    ind = find(mask==num_e);
    ind = ind(ceil(length(ind)*rand([length(ind) 1])));
    boot_stab(:,mask==num_e) = mat_stab(:,ind);
end
