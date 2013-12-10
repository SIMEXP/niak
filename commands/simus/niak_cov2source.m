function source = niak_cov2source(S,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_COV2SOURCE
%
% Find a basis of function whose variance-covariance spatial correlation
% matrix exactly match a given covariance matrix.
%
% SYNTAX 
% SOURCE = NIAK_COV2SOURCE(S,OPT);
%
% _________________________________________________________________________
% INPUTS :
%
% S
%       (matrix, size N*N) a covariance matrix (should be
%       definite-positive).
%
% OPT
%       (structure) with the following fields :
%       
%       NT
%           (integer, default 100) the number of time samples. 
%           Important warning : for this function to work, you need N<T.
%
%       BASIS
%           (string, default 'cos') the type of basis used to build the
%           source. Available options : 
%           'cos' 
%               the basis is cos(2*pi*n*t/T), with n = 1:N
%
% _________________________________________________________________________
% OUTPUTS :
% 
% SOURCE
%       (matrix,NT*N) the matrix of sources (each source is a column). By
%       construction, the spatial covariance matrix of SOURCE is S.
%
% _________________________________________________________________________
% COMMENTS : 
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

if ~exist('S','var')
    error('Syntax SOURCE = NIAK_COV2SOURCE(S,OPT);');
end

%% Setting up options
gb_name_structure = 'opt';
gb_list_fields = {'nt','basis'};
gb_list_defaults = {100,'cos'};
niak_set_defaults
T = opt.nt;

%% Checking size
[M,N] = size(S);
if M~=N
    error('S should be a square matrix !');
end
sqrtS = chol(S);

%% Generating basis
switch opt.basis
    case 'cos'
        
        basis_vec = zeros([T,N]);
        time_vec = 0:(T-1);
        
        for num_v = 1:N
            basis_vec(:,num_v) = cos(2*pi*num_v*time_vec(:)/T);
        end
        
        basis_vec = niak_correct_mean_var(basis_vec,'mean_var');
        basis_vec = sqrt(T/(T-1))*basis_vec; % we control for exact and not empirical covariance
        
    otherwise
        error('Unknown basis type');
end

source = basis_vec*sqrtS;