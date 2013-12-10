function [tseries,opt,X,B,E] = niak_sample_hlm(opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_SAMPLE_HLM
%
% Generate a sample of a hierarchical linear model.
%
% TSERIES = X1*B1 + ... XK*BK
%
% where Xk are support representation of clusters with a weight specific
% to each cluster, and Bk are time series sampled from a Gaussian model
% with an AR1 structure.
%
% SYNTAX : 
% [TSERIES,OPT] = NIAK_SAMPLE_HLM(OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% OPT
%       (structure) with the following fields :
%
%       TIME
%           (structure) with the following fields : 
%
%           T  
%               (integer), number of time samples
%
%           TR
%               (scalar, default 3s), the time between two volumes
%
%           RHO 
%               (scalar) : The coefficient of an exponential model, see 
%                   the help of NIAK_CORR_MODEL_EXPONENTIAL.
%
%       SPACE
%           (structure) with the following fields :
%
%           PART
%               (cell of vector) PART{K} is a partition of regions into a
%               number of clusters. 
%
%           VARIANCE
%               (cell of vector) VARIANCE{K}(L) is the variance of the
%               signal in cluster L at scale K.
%
% _________________________________________________________________________
% OUTPUTS:
%
% TSERIES 
%       (array, size T*N) the simulated time series (in columns) (Y).
%
% OPT
%       (structure) same as the input, but with default values updated.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : simulation, Gaussian model

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

%%%%%%%%%%%%%%%%%%%%%%%
%% Setting up inputs %%
%%%%%%%%%%%%%%%%%%%%%%%

% Setting up default for option fields
gb_name_structure = 'opt';
gb_list_fields = {'time','space'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

% Setting up default for the time model
gb_name_structure = 'opt.time';
gb_list_fields = {'t','tr','rho'};
gb_list_defaults = {NaN,3,NaN};
niak_set_defaults

% Setting up default for the space model
gb_name_structure = 'opt.space';
gb_list_fields = {'part','variance'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generation of the linear mixtures %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

K = length(part);
N = length(part{1});
tseries = zeros([opt.time.t,N]);
opt_t.space.type = 'independent';
opt_t.time.type = 'exponential';
opt_t.time.par.tr = opt.time.tr;
opt_t.time.t = opt.time.t;
opt_t.time.par = opt.time.rho;

for num_k = 1:K
    opt_t.space.nb_rois = K;
    X{num_k} = niak_part2supp(part{num_k});
    B{num_k} = niak_correct_mean_var(niak_sample_gsst(opt_t),1);
    tseries = tseries + X*B{num_k};
end
