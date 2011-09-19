function std_mad = niak_mad(tseries);
% Median absolute deviation to the median.
% This function was designed for time series, and applies a correction 
% factor to derive an estimate of the standard deviation for a Gaussian 
% process
%
% SYNTAX:
% STD_MAD = NIAK_MAD(TSERIES)
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES
%       (2D array) TSERIES(:,I) is a time series.
%
% _________________________________________________________________________
% OUTPUTS:
%
% STD_MAD
%       (vector) STD_MAD(I) is a MAD estimate of the standard deviation of
%       TSERIES(:,I)
%
% _________________________________________________________________________
% SEE ALSO:
%
% _________________________________________________________________________
% COMMENTS:
%
% The MAD estimator of the standard deviation of time series X is :
% 1.4785*median(abs(X-median(X)))
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : statistics, standard deviation, MAD, robust estimation

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

std_mad = 1.4785*median(abs(tseries-repmat(median(tseries,1),[size(tseries,1) 1])),1);
