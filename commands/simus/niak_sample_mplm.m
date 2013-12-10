function [tseries,opt,X,B,E] = niak_sample_mplm(opt)
% Sample from a linear model with a multi-partition spatial distribution.
%
% TSERIES = X1*B1 + ... XK*BK + E
%
% where Bk are support representation of clusters with a weight specific
% to each cluster, and Xk are time series sampled from a Gaussian model
% with an AR1 structure. In this model, there are K independent partitions, 
% with each of them featuring Ck clusters. 
% The support representation can be of various types : 
%   'crisp' : 1 inside the cluster, 0 outside
%   'gaussian': 1 at the medoid of the cluster x, 
%               exp((C/N)^2 ( d(x,y)^2 / var_c) ) for any other y, 
%               where N is the number of regions and C is the number of 
%               clusters, y = 1,...,N are the spatial indices associated
%               with regions, and the points are treated as a circle :
%		d(x,y) = min(x-y,y+N-x) for y<=x
%		d(x,y) = min(y-x,x+N-y) for x>=y
%
% SYNTAX : 
% [TSERIES,OPT,X,B,E] = NIAK_SAMPLE_MPLM(OPT)
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
%           MPART
%               (cell of vector) PART{K} is a partition of regions into a
%               number of clusters. 
%
%           VARIANCE
%               (cell of vector) VARIANCE{K}(L) is the variance of the
%               signal in cluster L at scale K.
%
%           TYPE
%               (string, default 'crisp') the type of spatial support for
%               the clusters. See above for a description. Avaible options
%               are : 'crisp' , 'gaussian'
%
%           VAR_C
%               (scalar, default 1) the variance of the spatial support of
%               each cluster. See the introduction of the function for a
%               description.
%
%       NOISE
%           (structure) with the following fields :
%
%           VARIANCE
%               (vector) VARIANCE(I) is the variance of the region I. If
%               VARIANCE is a scalar, the same variance is used for all
%               regions. If the variance is zero, no noise will be
%               generated.
% _________________________________________________________________________
% OUTPUTS:
%
% TSERIES 
%       (array, size T*N) the simulated time series (in columns) (Y).
%
% OPT
%       (structure) same as the input, but with default values updated.
%
% X
%	(matrix) X(:,s) is the time series associated with one cluster. All 
%	clusters and all partitions are concatenated in columns.
%
% BETA
%	(matrix) BETA(s,N) is the spatial distribution of the component 
%	X(:,s)
%
% E
%	(matrix T*N) the sample of Gaussian noise.
% 
% _________________________________________________________________________
% SEE ALSO:
% NIAK_SAMPLE_GSST
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : simulation, Gaussian model, clustering

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
gb_list_fields    = {'time' , 'space' , 'noise' };
gb_list_defaults  = {NaN    , NaN     , NaN     };
niak_set_defaults

% Setting up default for the time model
gb_name_structure = 'opt.time';
gb_list_fields    = {'t' , 'tr' , 'rho' };
gb_list_defaults  = {NaN , 3    , NaN   };
niak_set_defaults

% Setting up default for the space model
gb_name_structure = 'opt.space';
gb_list_fields    = {'mpart' , 'variance' , 'type'  , 'var_c' };
gb_list_defaults  = {NaN     , NaN        , 'crisp' , 1       };
niak_set_defaults

% Setting up default for the noise
gb_name_structure = 'opt.noise';
gb_list_fields    = {'variance' };
gb_list_defaults  = {NaN        };
niak_set_defaults

N = length(mpart{1});

if length(opt.noise.variance) == 1
    opt.noise.variance = opt.noise.variance * ones([N,1]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generation of the linear mixtures %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

K = length(mpart);
N = length(mpart{1});

opt_t.space.type = 'independent';
opt_t.time.type = 'exponential';
opt_t.time.par.tr = opt.time.tr;
opt_t.time.t = opt.time.t;
opt_t.time.par = opt.time.rho;

nb_clust = zeros([K 1]);
for num_k = 1:K
    nb_clust(num_k) = max(mpart{num_k}(:));
end

nb_comp = sum(nb_clust);
X = zeros([t nb_comp]);
B = zeros([nb_comp N]);
nb_c = 1;
for num_k = 1:K
    opt_t.space.n = nb_clust(num_k);
    opt_t.space.variance = opt.space.variance{num_k};
    X(:,nb_c:(nb_c+nb_clust(num_k)-1)) = niak_sample_gsst(opt_t);
    switch opt.space.type
        case 'crisp'
            B(nb_c:(nb_c+nb_clust(num_k)-1),:) = niak_part2supp(mpart{num_k})';    
        case 'gaussian'
            part = mpart{num_k};
            for num_c = 1:nb_clust(num_k)
                x = median(find(part==num_c));
                y = 1:N;
                d = zeros(size(y));
                d(y>x) = min(y(y>x)-x,x-(y(y>x)-N));
                d(y<x) = min(x-y(y<x),N+y(y<x)-x);
                B(nb_c+num_c-1,:) = exp( - (nb_clust(num_k)/N)^2 * d.^2 / opt.space.var_c);
            end
        otherwise
            error('%s is not a supported type of spatial support for clusters');
    end
    nb_c = nb_c + nb_clust(num_k);
end

if max(opt.noise.variance)>0
    opt_t.space.n = N;
    opt_t.space.variance = opt.noise.variance;
    opt_t.time.type = 'independent';
    E = niak_sample_gsst(opt_t);
    tseries = X*B + E;
else
    tseries = X*B;
end
