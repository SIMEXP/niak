function [R,pce] = niak_build_correlation(tseries,flag_vec);
% Compute the correlation matrix from regional time series.
% R = NIAK_BUILD_CORRELATION(TSERIES,FLAG_VEC)
%
% TSERIES (array) time series. First dimension is time.
% FLAG_VEC (boolean, default false) if FLAG_VEC == true, the matrix is
%   "vectorized" and the redundant elements are suppressed. Use
%   NIAK_VEC2MAT to unvectorize it.
% R (square matrix or vector) Empirical correlation matrix. R is 
%   symmetrical with ones on the diagonal.
% PCE (same size as R) PCE(i) is the p-value of significant testing of R, 
%   under a Gaussian i.i.d. assumption.
%   
% See licensing information in the code.

% Copyright (c) Pierre Bellec, 
% McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% Keywords : statistics, correlation
%
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
[S,R] = niak_build_srup(tseries,flag_vec);
T = sqrt(size(tseries,1)-2)*R(:)./sqrt(1-R(:).^2);
pce(~isnan(T)) = 2*niak_cdf_t(-abs(T(~isnan(T))),size(tseries,1)-2);
pce(isnan(T)) = 0;
pce = reshape(pce,size(R));