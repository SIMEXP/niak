function [vol_s,extras] = niak_smooth_vol(vol,opt)

% Spatial smoothing of 3D+t data with a Gaussian kernel
%
% SYNTAX:
% VOL_S = NIAK_SMOOTH_VOL(VOL,OPT)
%
% INPUTS:
% VOL         (4D array) a 3D+t dataset
% OPT         (structure, optional) with the following fields :
%
%             STEP  (vector of size [3 1] or [4 1], default [1 1 1]) the resolution
%                   in the respective dimensions, i.e. the space in mmm
%                   between two voxels in x, y, and z (yet the unit is
%                   irrelevant and just need to be consistent with
%                   the filter width (fwhm)). The fourth element is ignored.
%
%             FWHM  (vector of size [3 1], default [2 2 2]) the full width at half maximum of
%                   the Gaussian kernel, in each dimension. If fwhm has length 1,
%                   an isotropic kernel is implemented.
%
% OUTPUTS:
% VOL_S       (4D array) same as VOL after each volume has been spatially
%                   convolved with a 3D separable Gaussian kernel.
%
% SEE ALSO:
% NIAK_CONV3_SEP
%
% COMMENTS:
%
% Copyright (c) John Ashburner, Tom Nichols 08/02
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, smoothing, fMRI


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

% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'step','fwhm'};
gb_list_defaults = {[1 1 1],[2 2 2]};
niak_set_defaults

if length(step)>3
    step = step(1:3);
end

if length(fwhm)==1
    fwhm = [fwhm,fwhm,fwhm];
end

if length(size(vol))<4
    [nx,ny,nz] = size(vol);
    nt = 1;
else
    [nx,ny,nz,nt] = size(vol);
end

step = abs(step);

% Deriving kernel parameters
s  = fwhm(1:3)./step(1:3);      % fwhm relative to voxel size
s  = max(s,ones(size(s)));	    % lower bound on FWHM
s  = s/sqrt(8*log(2));          % FWHM -> Gaussian parameter

% Building a spatial grid
x  = round(6*s(1)); x = [-x:x];
y  = round(6*s(2)); y = [-y:y];
z  = round(6*s(3)); z = [-z:z];

% Deriving the 1D kernel
fx  = exp(-(x).^2/(2*(s(1)).^2));
fy  = exp(-(y).^2/(2*(s(2)).^2));
fz  = exp(-(z).^2/(2*(s(3)).^2));
fx  = fx/sum(fx);
fy  = fy/sum(fy);
fz  = fz/sum(fz);

% Performing convolution
vol_s = zeros(size(vol));
for num_t = 1:nt
    vol_s(:,:,:,num_t) = niak_conv3_sep(vol(:,:,:,num_t),fx,fy,fz);
end

if nargout == 2
    extras.x = x; extras.y = y; extras.z = z;
    extras.fx = fx; extras.fy = fy; extras.fz = fz;
end