function mask = niak_mask_brain(vol,opt)
% Create a binary mask of the inside of the brain in an MRI/fMRI dataset
%
% SYNTAX:
% MASK = NIAK_MASK_BRAIN(VOL,OPT)
% 
% _________________________________________________________________________
% INPUTS: 
%
% VOL       
%       (4D array) a 3D or 3D+t dataset
%
% OPT       
%       (structure, optional) with the following fields:   
%       
%       FWHM 
%           (real value, default 0) the FWHM of the blurring kernel in 
%           voxel size unit. A value of 0 for FWHM will skip the smoothing step.
%       
%       VOXEL_SIZE 
%           (vector of size [3 1] or [4 1], default [3 3 3]) the resolution
%           in the respective dimensions, i.e. the space in mmm
%           between two voxels in x, y, and z (yet the unit is
%           irrelevant and just need to be consistent with
%           the filter width (fwhm)). The fourth element is ignored.
%
%       FLAG_REMOVE_EYES 
%           (boolean, default 0) if FLAG_REMOVE_EYES == 1, an
%           attempt is done to remove the eyes from the mask. Work only for
%           fMRI !
%
%       FLAG_VERBOSE
%           (boolean, default false) if the flag is on, print info on the
%           progress.
%
% _________________________________________________________________________
% OUTPUTS:
%
% MASK          
%       (3D array) binary mask of the inside of the brain
%
% _________________________________________________________________________
% REFERENCE:
%
% Otsu, N.
% A Threshold Selection Method from Gray-Level Histograms.
% IEEE Transactions on Systems, Man, and Cybernetics, Vol. 9, No. 1, 1979, 
% pp. 62-66.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_MASK_BRAIN, NIAK_MASK_HEAD_T1, NIAK_MASK_BRAIN_T1,
% NIAK_BRICK_MASK_BRAIN_T1
%
% _________________________________________________________________________
% COMMENTS:
%
% Use the "Otsu" algorithm to separate two Gaussian distributions in an 
% histogram of the mean of the absolute values of all volumes. This is a 
% port from the FORTRAN "spider" library, by Joachim Frank.
%
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

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'fwhm','voxel_size','flag_remove_eyes','flag_verbose'};
gb_list_defaults = {0,[3 3 3],0,false};
niak_set_defaults


%% Getting the mean of absolute values for all volumes
if size(vol,4)>1
    abs_vol_mean = mean(abs(vol),4);
else
    abs_vol_mean = abs(vol);
end
mask_nan = isnan(abs_vol_mean);
abs_vol_mean(mask_nan) = 0;

%% Smoothing the mean
if max(opt.fwhm) ~=0
    opt_smooth.fwhm = opt.fwhm;
    opt_smooth.voxel_size = opt.voxel_size;
    opt_smooth.flag_verbose = false;
    abs_vol_mean = niak_smooth_vol(abs_vol_mean,opt_smooth);
end

%% Building an histogram of the smoothed mean
[Y,X] = hist(abs_vol_mean(:),256);
ind_seuil = min(max(otsu(Y),1),length(X));

%% Building the mask
mask = (abs_vol_mean>X(ind_seuil));
mask = mask & ~mask_nan;

%% Removing the eyes
if flag_remove_eyes
    [mask,list_size] = niak_find_connex_roi(mask);
    [val,ind] = max(list_size);
    mask = mask == ind;
end
 
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