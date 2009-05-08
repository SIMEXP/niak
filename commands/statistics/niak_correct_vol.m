function vol_c = niak_correct_vol(vol,mask)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_CORRECT_VOL
%
% Correct the distribution of a 3D random field to zero mean and unit
% variance using robust statistics (fitted Gaussian distribution, initialized
% the median and the median absolute deviation to the median).
%
% SYNTAX:
% VOL_C = NIAK_CORRECT_VOL(VOL,MASK)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL       
%       (3D array)
%
% MASK      
%       (binary 3D array)
%
% _________________________________________________________________________
% OUTPUTS:
%
% VOL_C     
%       (3D array) same as VOL, with corrected distribution.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging

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

flag_visu = 0;

global niak_gb_X niak_gb_Y

if nargin < 3
    p = 0.05;
end

% Histogram computation and normalization
M = vol(mask);
M = M(:);
M = double(M);
[niak_gb_Y,niak_gb_X] = hist(M,length(M)/100);
niak_gb_Y = niak_gb_Y/(length(M)*(max(niak_gb_X)-min(niak_gb_X)))*length(niak_gb_X);

% Gaussian parameters fitting.
if exist('fminsearch','file')
    par = fminsearch('niak_gaussian_fit',[median(M);1.4826*median(abs(M-median(M)))]);
else
    par = [median(M);1.4826*median(abs(M-median(M)))];
end

if flag_visu
    [err,val] = niak_gaussian_fit(par);
    figure
    bar(niak_gb_X,niak_gb_Y); hold on; plot(niak_gb_X,val,'r');
    title(sprintf('Empirical distribution and fitted gaussian function mean %1.3s std %1.3s',par(1),par(2)));
end

% Volume correction
vol_c = zeros(size(vol));
vol_c(mask) = (vol(mask) - par(1))/par(2);