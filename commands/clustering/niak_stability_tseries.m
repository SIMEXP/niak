function stab = niak_stability_tseries(tseries,opt)
% Estimate the stability of a stochastic clustering on time series.
%
% The time series y are modeled as a realization of a random variable Y.
% Let I and J be two regions, the stability of the 2-ensemble {I,J} is
% by definition the probability that these two regions fall in the same
% cluster:
%
%         S_{I,J} = Pr(exist C(y) such that I,J \in C(y) | Y -> y)
%
% The data-generating process is approximated by a circular block bootstrap
% scheme y -> y*, and is used to estimate the stability :
%
%     Schap_{I,J} = Pr(exist C(y*) such that I,J \in C(y*) | y -> y*)
%
% SYNTAX:
% STAB = NIAK_STABILITY_TSERIES(TSERIES,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES
%   (array T*N) TSERIES(:,I) is the time series of region I.
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
%   NORMALIZE
%       (structure, default NORMALIZE.TYPE = 'mean_var') the temporal
%       normalization to apply on the individual time series before
%       clustering. See OPT in NIAK_NORMALIZE_TSERIES.
%
%   SAMPLING
%
%       TYPE
%           (string, default 'bootstrap') how to resample the time series.
%           Available options : 'bootstrap' , 'mplm', 'scenario'
%
%       OPT
%           (structure) the options of the sampling. Depends on
%           OPT.SAMPLING.TYPE : 
%               'bootstrap' : see the description of the OPT
%                   argument in NIAK_BOOTSTRAP_TSERIES. Default is 
%                   OPT.TYPE = 'CBB' (a circular block bootstrap is
%                   applied).
%               'mplm' : see the description of the OPT argument in
%                   NIAK_SAMPLE_MPLM.
%               'scenario' : see the description of the OPT argument in
%                   NIAK_SIMUS_SCENARIO
%
%   CLUSTERING
%       (structure, optional) with the following fields :
%
%       TYPE
%           (string, default 'hierarchical') the clustering algorithm
%           Available options : 
%               'kmeans': k-means (euclidian distance)
%               'hierarchical': a HAC based on a squared euclidian 
%                   distance.
%               'hierarchical_e2' : a HAC based on the eta-square 
%                   distance (see NIAK_BUILD_ETA2)
%
%       OPT
%           (structure, optional) options that will be  sent to the
%           clustering command. The exact list of options depends on
%           CLUSTERING.TYPE:
%               'kmeans' : see OPT in NIAK_KMEANS_CLUSTERING
%               'hierarchical' : see OPT in NIAK_HIERARCHICAL_CLUSTERING
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function prints
%       some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
%   STAB
%       (array) STAB(:,s) is the vectorized version of the stability matrix
%       associated with OPT.NB_CLASSES(s) clusters.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_STABILITY, NIAK_PIPELINE_STABILITY_REST,
% NIAK_BRICK_STABILITY_TSERIES
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
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap, time series

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
opt_normalize.type    = 'mean_var';
opt_clustering.type   = 'hierarchical';
opt_clustering.opt    = struct();
opt_sampling.type     = 'bootstrap';
opt_sampling.opt.type = 'cbb';
list_fields   = {'normalize'   , 'nb_samps' , 'nb_classes' , 'clustering'   , 'sampling'   , 'flag_verbose' };
list_defaults = {opt_normalize , 100        , NaN          , opt_clustering , opt_sampling , true           };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%%%%%%%%%%%%%%%%%%%%%%
%% Stability matrix %%
%%%%%%%%%%%%%%%%%%%%%%
[T,N] = size(tseries); % T is the number of time samples, N the number of regions.
nb_s = length(opt.nb_classes); % The number of clustering parameters to be tested.
stab = zeros([N*(N-1)/2 nb_s]); % Initialize the stability matrix
opt.clustering.opt.flag_verbose = false;

if opt.flag_verbose
    fprintf('Estimate the stability matrix ...\n     Percentage done : ');
    curr_perc = -1;
end

if strcmp(opt.sampling.type,'subsampling')
    L = max(floor(T*opt.sampling.opt),1);
    opt.nb_samps = min(opt.nb_samps,T-L+1);
    delta = (T-L)/(opt.nb_samps-1);
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

    switch opt.sampling.type
        case 'subsampling'
            t1 = floor(1+(num_s-1)*delta);
            t2 = t1+L-1;
            tseries_boot = tseries(t1:t2,:);
        case 'bootstrap'
            tseries_boot = niak_bootstrap_tseries(tseries,opt.sampling.opt);
        case 'mplm'
            tseries_boot = niak_sample_mplm(opt.sampling.opt);
        case 'scenario'
            tseries_boot = niak_simus_scenario(opt.sampling.opt);
        otherwise
            error('%s is not a suppported sampling scheme',opt.sampling.type)
    end
    tseries_boot = niak_normalize_tseries(tseries_boot,opt.normalize);

    if ismember(opt.clustering.type,'hierarchical') % for methods that produce a hierarchy
        
        switch opt.clustering.type
            case 'hierarchical'
                D    = niak_build_distance(tseries_boot).^2;
                hier = niak_hierarchical_clustering(-D,opt.clustering.opt);
            case 'hierarchical_e2'
                D    = niak_build_correlation(tseries_boot);
                D    = 1-niak_build_eta2(D);
                hier = niak_hierarchical_clustering(-D,opt.clustering.opt);
        end
        opt_t.thresh = opt.nb_classes;
        part = niak_threshold_hierarchy(hier,opt_t);
        for num_sc = 1:nb_s
            stab(:,num_sc) = stab(:,num_sc) + niak_mat2vec(niak_part2mat(part(:,num_sc),true));
        end
        
    else % for clustering methods

        for num_sc = 1:nb_s
            switch opt.clustering.type

                case 'kmeans'

                    part = niak_kmeans_clustering(tseries_boot,opt.clustering.opt);

                case 'neural-gas'

                    part = niak_neural_gas(tseries_boot,opt.clustering.opt);

                otherwise

                    error(cat(2,opt.clustering.type,': unknown type of clustering'));

            end
            stab(:,num_sc) = stab(:,num_sc) + niak_mat2vec(niak_part2mat(part,true));
        end
    end
end
stab = stab / opt.nb_samps;
if opt.flag_verbose
    fprintf('\n');
end