function mask = niak_mask_brain(vol,fwhm_kernel)

% Create a binary mask of the inside of the brain in an MRI/fMRI dataset
%
% SYNTAX:
% MASK = NIAK_MASK_BRAIN(VOL)
% 
% INPUT: 
% VOL           (4D array) a 3D or 3D+t dataset
% FWHM_KERNEL   (real value, default 2) the FWHM of the blurring kernel in 
%                   voxel units (can also be a 3*1 vector for anisotropic 
%                   filtering if the voxel size is anisotropic). A value of
%                   0 for FWHM_KERNEL will skip the smoothing step.
%
% OUTPUT:
% MASK          (3D array) binary mask of the inside of the brain
%
% COMMENTS
% Port from the FORTRAN "spider" library, by Joachim Frank. Use the "Otsu" algorithm to
% separate two Gaussian distributions in an histogram of the mean of the
% absolute values of all volumes.
%
% To optimize memory use with 3D+t data, it is better to derive the mean
% of the absolute values and perform the smoothing in the workspace, and to
% run the mask extraction directly on the resulting volume. This prevents
% duplication of the data in the memory.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, segmentation, MRI, fMRI

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

%% Setting up default arguments
if nargin < 2
    opt_smooth.fwhm = 2;
else
    opt_smooth.fwhm = fwhm_kernel;
end

%% Getting the mean of absolute values for all volumes
abs_vol_mean = mean(abs(vol),4);

%% Smoothing the mean
if max(opt_smooth.fwhm) ~=0
    abs_vol_mean = niak_smooth_vol(abs_vol_mean,opt_smooth);
end

%% Building an histogram of the smoothed mean
[Y,X] = hist(abs_vol_mean(:),256);
ind_seuil = otsu(Y);

%% Building the mask
mask = (abs_vol_mean>X(ind_seuil));

function seuil = otsu(hist)
% An implementation of the Otsu algorithm to separate two Gaussian
% distribution in an histogram.

hist = hist/sum(hist);
ngr = length(hist);
somme = sum((1:(ngr)).*hist);

eps = 10^(-10);
seuil = 0;


smax = 0;
p = 0;
a = 0;
for i = 1:(ngr-1)
    a = a+(i)*hist(i);
    p = p+hist(i);
    s = somme*p-a;
    d = p*(1-p);
    if (d>=eps)
        s = s*s/d;        
        if (s >= smax)
            smax = s;
            amax = a;
            pmax = p;
            seuil = i;
        end
    end
end

seuil = seuil-1;