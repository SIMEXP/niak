function [tseries,E,opt] = niak_sample_linear_model(X,B,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_SAMPLE_LINEAR_MODEL
%
% Generate a sample of a space-time liner mode :
% Y = X*B + E
% where :
%   Y : T*N matrix of time series
%   X : T*K matrix of (temporal) sources (each column).
%   B : K*N matrix of (spatial) sources (each row).
%   E : T*N matrix of noise.
%
% The following models are available for E : 
%   * Gaussian independent in space and time, with region-specific
%     variances.
%
% SYNTAX : 
% [TSERIES,E,OPT] = NIAK_SAMPLE_LINEAR_MODEL(X,B,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% X
%       (matrix, size T*K) the matrix of time sources (X)
%
% B
%       (matrix, size K*N) the matrix of space sources (B)
%
% OPT
%       (structure) with the following fields : 
%
%       NOISE
%           (string, default 'independent_space_time') the type of
%           noise used in the simulation. Available options : 
%           'independent_space_time'.
%       PAR
%           If OPT.NOISE == 'independent_space_time'
%
%           (vector, size N*1) the vector of space-specific variances.
%           If VARIANCE is a scalar, the same variance will be used in 
%           every region.
%
% _________________________________________________________________________
% OUTPUTS:
%
% TSERIES 
%       (array, size T*N) the simulated time series (in columns) (Y).
%
% E 
%       (array, size T*N) the noise sample.
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
% Keywords : simulation, linear model

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

% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'noise','par'};
gb_list_defaults = {'independent_space_time',NaN};
niak_set_defaults

%% Checking sizes
[T,K] = size(X);

if size(B,1)~=K
    error('size(X,2) should be equal to size(B,1)!')
end
N = size(B,2);

%% Setting up noise parameters
switch opt.noise
    
    case 'independent_space_time'
        
        var_noise = opt.par;
        if length(var_noise) == 1
            std_noise = sqrt(var_noise) * ones([N 1]);
        else
            if length(var_noise) == N
                std_noise = sqrt(var_noise);
            else
                error('the length of OPT.PART should be equal to the number of columns of B !');
            end
        end
        sqrtRt = eye([T T]);
        sqrtRs = diag(std_noise);        
        
    otherwise
        
        error('%s is an unkown type of noise',opt.noise);
end

%% Generating noise
E = sqrtRt * randn([T N]) * sqrtRs;
tseries = X*B+E;