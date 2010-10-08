function P = niak_build_partial_correlation(tseries,flag_vec);
% Compute the partial correlation matrix from regional time series.
%
% SYNTAX:
% P = NIAK_BUILD_PARTIAL_CORRELATION(TSERIES,FLAG_VEC)
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES       
%       (array) time series. First dimension is time.
%
% FLAG_VEC
%       (boolean, default false) if FLAG_VEC == true, the matrix is
%       "vectorized" and the redundant elements are suppressed. Use
%       NIAK_VEC2MAT to unvectorize it.
%
% _________________________________________________________________________
% OUTPUTS:
%
% P             
%       (square matrix or vector) Empirical partial correlation matrix. P 
%       is symmetrical with ones on the diagonal.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_MEASURE, NIAK_MAT2VEC, NIAK_MAT2LVEC, NIAK_VEC2MAT,
% NIAK_LVEC2MAT, NIAK_BUILD_COVARIANCE, NIAK_BUILD_CORRELATION,
% NIAK_BUILD_CONCENTRATION, NIAK_BUILD_PARTIAL_CORRELATION.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : statistics, correlation

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
if nargin < 2
    flag_vec = false;
end
[S,R,U,P] = niak_build_srup(tseries,flag_vec);