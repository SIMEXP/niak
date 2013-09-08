function [stab,bias_mean,bias_std,plugin] = niak_stability_fir(fir_all,time_samples,opt)
% Estimate the stability of a stochastic clustering on FIR estimates.
% FIR estimates are a collection of recorded temporal responses to a given
% stimulus that have been resampled on a common temporal grid. The average
% response is an estimate of the finite impulse response (FIR) to the
% stimulus.
%
% SYNTAX:
% [STAB,BIAS_MEAN,BIAS_STD] = NIAK_STABILITY_FIR(FIR_ALL,TIME_SAMPLES,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FIR_ALL
%   (array T*N*S) FIR_ALL(:,I,J) is the time series of region I at trial J.  
%
% TIME_SAMPLES
%   (vector, T*1) TIME_SAMPLES(t) is the time associated with
%   FIR_ALL(t,:,:)
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
%   NB_SAMPS_BIAS
%       (integer, default 100) the number of samples to derive the 
%       estimation of the bias on the distance between average 
%       responses under the null hypothesis of no significant 
%       average responses.
%
%   STD_NOISE
%       (integer, default 4) the standard deviation of the noise
%       added to each sample to cover up the effect of spatially
%       coherent spontaneous fluctuations.
%
%   SAMPLING
%
%       TYPE
%           (string, default 'bootstrap') how to resample the average FIR 
%           response.
%           Available options : 'bootstrap', 'subsample'
%
%       OPT
%           (structure) the options of the sampling. Depends on
%           OPT.SAMPLING.TYPE : 
%               'bootstrap' : none. It is an i.i.d. bootstrap.
%               'subsample' : a scalar representing the percentage of
%                   trials that are used to produce a sample of average
%                   response (default 0.5).
%
%   NORMALIZE.TYPE
%       (string, default 'fir_shape') the type of normalization to apply on the 
%       FIR estimates. See NIAK_NORMALIZE_FIR.
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
%    (array) STAB(:,s) is the vectorized version of the stability matrix
%    associated with OPT.NB_CLASSES(s) clusters.
%
% BIAS_MEAN
%    (vector) a vectorized version of the bias on the distance between 
%    the average response under the null hypothesis of no significant 
%    average response.
%
% BIAS_STD
%    (vector) a vectorized version of the standard deviation on the 
%    distance between the average response under the null hypothesis 
%    of no significant average response.
%
% PLUGIN
%    (vector) a vectorized version of the "plug-in" estimate of the 
%    distance between normalized FIR.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_FIR, NIAK_PIPELINE_STABILITY_FIR
%
% _________________________________________________________________________
% COMMENTS:
%
% For more details, see the description of the stability analysis on a
% FIR estimate in the following reference :
%
% Pierre Orban, Julien Doyon, Rick Hoge, Pierre Bellec, Stable clusters of
% brain regions associated with distinct motor task-evoked hemodynamic 
% responses. To be presented at the 17th International Conference on 
% Functional Mapping of the Human Brain, 2011.
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de Gériatrie de Montréal,
% Département d'informatique et de recherche opérationnelle,
% Université de Montréal, 2010-2011.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap, FIR

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
opt_normalize.type  = 'fir_shape';
opt_clustering.type = 'hierarchical';
opt_clustering.opt  = struct();
opt_sampling.type   = 'bootstrap';
opt_sampling.opt    = [];
list_fields   = {'std_noise' , 'nb_samps_bias' , 'normalize'   , 'nb_samps' , 'nb_classes' , 'clustering'   , 'sampling'   , 'flag_verbose' };
list_defaults = {4           , 100             , opt_normalize , 100        , NaN          , opt_clustering , opt_sampling , true           };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%%%%%%%%%%%%%%%%%%%%%%
%% Bias estimation  %%
%%%%%%%%%%%%%%%%%%%%%%
if opt.flag_verbose
    fprintf('Estimation of the bias on the distance matrix ...\n')
end
time_sampling = time_samples(2)-time_samples(1); % The TR of the temporal grid (assumed to be regular)
bootstrap.name_boot = 'niak_stability_fir_null';
measure.name_mes = 'niak_stability_fir_distance';
measure.opt_mes.time_sampling = time_sampling;
measure.opt_mes.type = opt.normalize.type;
cdf.nb_samps = opt.nb_samps_bias;
cdf.flag_mean_std = true;
[tmp1,tmp2,bias_mean,bias_std] = niak_build_cdf(fir_all,bootstrap,measure,cdf);

%% Plug-in estimate
plugin = niak_stability_fir_distance(fir_all,measure.opt_mes);

%%%%%%%%%%%%%%%%%%%%%%
%% Stability matrix %%
%%%%%%%%%%%%%%%%%%%%%%
[T,N,ne] = size(fir_all); % T is the number of time samples, N the number of regions, ne the number of trials
nb_s = length(opt.nb_classes); % The number of clustering parameters to be tested.
stab = zeros([N*(N-1)/2 nb_s]); % Initialize the stability matrix
opt.clustering.opt.flag_verbose = false;

%% Generate samples
if opt.flag_verbose
    fprintf('Estimation of the stability matrix ...\n     Percentage done : ');
    curr_perc = -1;
end
if strcmp(opt.sampling.type,'subsample')
    nb_fir = ceil(opt.sampling.opt*ne);
end

for num_s = 1:opt.nb_samps

    if opt.flag_verbose
        new_perc = 5*floor(20*num_s/opt.nb_samps);
        if curr_perc~=new_perc
            fprintf(' %1.0f',new_perc);
            curr_perc = new_perc;
        end
    end

    switch opt.sampling.type

        case 'subsample'           

            fir_boot = randperm(ne);                
            fir_all_boot = fir_all(:,:,fir_boot(1:nb_fir));
            
        case 'bootstrap'
            
            fir_all_boot = zeros(size(fir_all));
            for num_n = 1:N
                fir_all_boot(:,num_n,:) = fir_all(:,num_n,ceil(ne*rand([ne 1])));
            end

        otherwise

            error('%s is an unknown sampling scheme',opt.type_resampling);

    end
    if opt.std_noise>0
        fir_all_null = niak_stability_fir_null(fir_all_boot);
        fir_all_null = fir_all_null - repmat(mean(mean(fir_all_null,3),1),[T 1 ne]);
        std_null = std(mean(fir_all_null,3),[],1);
        perm_null = randperm(N);
        weights = repmat(std_null./std_null(perm_null),[T 1 ne]);
        fir_all_null = fir_all_null(:,perm_null,:).*weights;
        D = niak_stability_fir_distance(fir_all_boot+opt.std_noise*fir_all_null,measure.opt_mes);
    else
        D = niak_stability_fir_distance(fir_all_boot,measure.opt_mes);
    end
    switch opt.clustering.type
        case 'hierarchical'
            hier = niak_hierarchical_clustering(-D,opt.clustering.opt);
            opt_t.thresh = opt.nb_classes;
            part = niak_threshold_hierarchy(hier,opt_t);
    end
    
    for num_sc = 1:nb_s
        stab(:,num_sc) = stab(:,num_sc) + niak_mat2vec(niak_part2mat(part(:,num_sc),true));
    end
end
stab = stab / opt.nb_samps;
if opt.flag_verbose
    fprintf('\n');
end
