function vol_c = niak_correct_vol(vol,mask);

% Correct the distribution of a 3D random field to zero mean and unit
% variance using robust statistics.
%
% SYNTAX:
% VOL_C = NIAK_CORRECT_VOL(VOL,MASK)
%
% INPUTS:
%
% VOL       (3D array)
%
% MASK      (binary 3D array)
%
% OUTPUTS:
% VOL_C     (3D array) same as VOL, with corrected distribution.
%
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

visu = 0;
global X Y

if nargin < 3
    p = 0.05;
end

% Histogram computation and normalization
M = vol(mask);
M = M(:);
[Y,X] = hist(M,length(M)/100);
Y = Y/(length(M)*(max(X)-min(X)))*length(X);

% Gaussian parameters fitting.
%par = fminsearch('gaussien',[median(M);compute_qn_mex(M)]);
par = fminsearch('gaussien',[median(M);1.4826*median(abs(M-median(M)))]);
%par = fminsearch('gaussien',[mean(M);std(M)]);
%par = [median(M),compute_qn_mex(M)];

if visu
    [err,val] = gaussien(par);
    figure
    bar(X,Y); hold on; plot(X,val,'r');
    title('Empirical distribution and fitted gaussian function');
end

% Volume correction
vol_c = zeros(size(vol));
vol_c(mask) = (vol(mask) - par(1))/par(2);

% Threshold computation
if nargout > 1
    t_c = st_normal_inverse_cdf(p/(2*sum(mask(:)>0)));
    t_u = st_normal_inverse_cdf(p/2);
end

% Thresolded volumes

if nargout >3
    z_c = zeros(size(mask));
    z_c(mask) = abs(vol_c(mask))>=t_c;
    z_u = zeros(size(mask));
    z_u(mask) = abs(vol_c(mask))>=t_u;
end
