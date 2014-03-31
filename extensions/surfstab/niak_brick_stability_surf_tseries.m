function [files_in,files_out,opt] = niak_brick_stability_surf_tseries(files_in,files_out,opt)
% Estimate the stability of a stochastic clustering on time series.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SURF_TSERIES(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (string) the name of the .mat file which contains one variable TSERIES. 
%   TSERIES(:,I) is the time series of region I.
%
% FILES_OUT
%   (string) A .mat file which contains the following variables :
%
%       STAB
%           (array) STAB(:,s) is the vectorized version of the stability matrix
%           associated with OPT.NB_CLASSES(s) clusters.
%
%       NB_CLASSES
%           (vector) Identical to OPT.NB_CLASSES (see below).
%
% OPT           
%   (structure) with the following fields:
%
%   NB_CLASSES
%       (vector of integer) the number of clusters (or classes) that will
%       be investigated. This parameter will overide the parameters
%       specified in CLUSTERING.OPT_CLUST
%
%   NAME_DATA
%       (string, default: 'data') the name of the variable in the
%       input file that contains the timeseries.
%
%   RAND_SEED
%       (scalar, default []) The specified value is used to seed the random
%       number generator with PSOM_SET_RAND_SEED. If left empty, no action
%       is taken.
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
%   CLUSTERING
%       (structure, optional) with the following fields :
%
%       TYPE
%           (string, default 'hierarchical') the clustering algorithm
%           Available options : 
%               'kmeans': k-means (euclidian distance)
%               'hierarchical_e2': a HAC based on the eta-square distance
%                   (see NIAK_BUILD_ETA2)
%               'hierarchical' : a HAC based on a squared
%                   euclidian distance.
%
%       OPT
%           (structure, optional) options that will be  sent to the
%           clustering command. The exact list of options depends on
%           CLUSTERING.TYPE:
%               'kmeans' : see OPT in NIAK_KMEANS_CLUSTERING
%               'hierarchical' or 'hierarchical_e2': see OPT in 
%               NIAK_HIERARCHICAL_CLUSTERING
%
%   SAMPLING
%       (structure, optional) with the following fields:
%           
%       TYPE
%           (string, default 'bootstrap') how to resample the time series see
%           niak_stability_tseries for details on defaults
%           Available options : 'bootstrap' , 'mplm', 'scenario', 'jackid'
%
%       OPT
%           (structure) the options of the sampling. Depends on
%           OPT.SAMPLING.TYPE :
%               'jackid' : jacknife subsampling, identical distribution. By
%                   default uses 60% timepoints. Can be controlled by
%                   opt.sampling.opt.perc.
%               'bootstrap' : see the description of the OPT
%                   argument in NIAK_BOOTSTRAP_TSERIES. Default is 
%                   OPT.TYPE = 'CBB' (a circular block bootstrap is
%                   applied).
%               'mplm' : see the description of the OPT argument in
%                   NIAK_SAMPLE_MPLM.
%               'scenario' : see the description of the OPT argument in
%                   NIAK_SIMUS_SCENARIO
%
%   FLAG_TEST
%       (boolean, default 0) if the flag is 1, then the function does not
%       do anything but update the defaults of FILES_IN, FILES_OUT and OPT.
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function prints
%       some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_STABILITY, NIAK_PIPELINE_STABILITY_REST
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
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Gériatrie de Montréal
%   Département d'informatique et de recherche opérationnelle
%   Université de Montréal, 2010-2014
%   Montreal Neurological Institute, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap, time series, consensus

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SURF_TSERIES(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_surf_tseries'' for more info.\n');
end

%% Files in
if ~ischar(files_in)
    error('FILES_IN should be a string\n!');
end

%% Files out
if ~ischar(files_out)
    error('FILES_OUT should be a string!');
end

%% Options
list_fields   = {'rand_seed' , 'normalize' , 'nb_samps' , 'nb_classes' , 'clustering' , 'sampling' , 'name_data' , 'flag_verbose' , 'flag_test'  };
list_defaults = {[]          , struct()    , 100        , NaN          , struct()     , struct()   , 'data'      , true           , false        };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

% Setup Clustering Defaults
opt.clustering = psom_struct_defaults(opt.clustering,...
                 { 'type'         , 'opt'    },...
                 { 'hierarchical' , struct() });

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Seed the random generator
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

%% Read the time series 
if opt.flag_verbose
    fprintf('Read the time series ...\n');
end

data = load(files_in);
tseries = niak_normalize_tseries(data.(opt.name_data),opt.normalize);

%% Stability matrix 
opt_s = rmfield(opt,{'flag_test','rand_seed' 'name_data'});
stab = niak_stability_tseries(tseries,opt_s);

%% Save outputs
if opt.flag_verbose
    fprintf('Save outputs ...\n');
end
nb_classes = opt.nb_classes;
save(files_out,'stab','nb_classes')
