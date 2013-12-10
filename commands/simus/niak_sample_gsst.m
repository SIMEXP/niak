function [tseries,opt] = niak_sample_gsst(opt)
% Sample from a Gaussian process with a separable space-time structure
%
% SYNTAX : 
% [TSERIES,OPT] = NIAK_SAMPLE_GSST(OPT)
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
%           TYPE
%               (string, default 'exponential') the type of temporal 
%               correlation model. Choices: 'exponential', 'exact',
%               'independent'.
%
%           PAR 
%               (vector) : the parameters of the parametric temporal 
%               correlation model. It depends on OPT.TIME.TYPE:
%
%                   'independent' : no PAR is necessary.
%
%                   'exponential' : PAR is RHO, see the help of
%                   NIAK_CORR_MODEL_EXPONENTIAL.
%
%                   'exact' : PAR is a T*T definite-positive matrix
%                   defining the temporal correlation.
%
%       SPACE
%           (structure) with the following fields :
%
%           N
%               (integer) number of regions. Specification of N is not
%               necessary with the 'homogeneous' model.
%
%           VARIANCE
%               (vector, default 1) VARIANCE(I) is the variance 
%               of region I. If VARIANCE is a scalar, the same variance is
%               used for all regions.
%
%           TYPE
%               (string, default 'exact') the type of spatial correlation
%               model. Choices : 'exact', 'homogeneous',
%               'independent'.
%         
%           PAR 
%               (vector, default 'exact') : the parameters of the 
%               parametric spatial correlation model. It depends 
%               on OPT.SPACE.TYPE:
%
%                   'homogeneous' : two parameters, NB_ROIS and AFC. See 
%                       the help of NIAK_CORR_MODEL_HOMOGENEOUS. 
%
%                   'exact' : PAR is a N*N definite-positive matrix
%                       defining the spatial correlation.
%
%                   'independent' : no PAR is necessary.
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
% Copyright (c) Pierre Bellec, 
% McConnell Brain Imaging Center,Montreal, Neurological Institute, 
% McGill University, 2008-2010
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal, 2010-2011
% Maintainer : pierre.bellec@criugm.qc.ca
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
gb_list_fields    = {'time' , 'space' };
gb_list_defaults  = {NaN    , NaN     };
niak_set_defaults

% Setting up default for the time model
gb_name_structure = 'opt.time';
gb_list_fields    = {'t' , 'tr' , 'par' , 'type'        };
gb_list_defaults  = {NaN , 3    , NaN   , 'exponential' };
niak_set_defaults

% Setting up default for the space model
gb_name_structure = 'opt.space';
gb_list_fields    = {'n' , 'par' , 'type'  , 'variance' };
gb_list_defaults  = {NaN , []    , 'exact' , NaN        };
niak_set_defaults

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generation of the temporal correlation matrix %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch opt.time.type
    
    case 'exponential'
        
        Dt = tr*abs(meshgrid(1:t)-meshgrid(1:t)');
        Rt = niak_corr_model_exponential(Dt,opt.time.par);
        
    case 'exact'
        
        Rt = opt.time.par;
        
    case 'independent'
        
        Rt = eye([t t]);
        
    otherwise
        
        error('%s is an unknown time correlation model',opt.time.type);
        
end

sqrtRt = chol(Rt);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generation of the spatial correlation matrix %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch opt.space.type

    case 'homogeneous'
        
        Rs = niak_corr_model_homogeneous(opt.space.par.afc,opt.space.par.nb_rois);
        n = sum(opt.space.par.nb_rois);
        
    case 'exact'
        
        Rs = opt.space.par;
        
    case 'independent'
        
        Rs = eye([n n]);
        
    otherwise
        
        error('%s is an unkown spatial correlation model.',opt.space.type)
        
end
if isempty(opt.space.variance)
    std_vec = ones([n 1]);
else
    if length(opt.space.variance)==1
        std_vec = sqrt(opt.space.variance) * ones([n 1]);
    else
        std_vec = sqrt(opt.space.variance(:));
    end
end
Rs = repmat(std_vec,[1 n]).*repmat(std_vec',[n 1]).*Rs;
sqrtRs = chol(Rs);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate the time series %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tseries = sqrtRt' * randn([t sum(n)]) * sqrtRs;
