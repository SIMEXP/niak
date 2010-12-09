function mask_thresh = niak_mask_threshold(vol)
% Find a threshold on an fMRI volume to define a brain mask.
% 
% SYNTAX:
% MASK_THRESH = NIAK_MASK_THRESHOLD(VOL)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL         
%       (3D array) A single brain volume.
% 
% _________________________________________________________________________
% OUTPUTS:
%
% MASK_THRESH
%       a scalar value for thresholding the volume to define a brain mask.
%
% _________________________________________________________________________
% COMMENTS:
%
% This function is largely redundant with NIAK_MASK_BRAIN.
%
% This function is a NIAKIFIED port of a part of the FMRILM function of the
% fMRIstat project. The original license of fMRIstat was : 
%
%############################################################################
% COPYRIGHT:   Copyright 2002 K.J. Worsley
%              Department of Mathematics and Statistics,
%              McConnell Brain Imaging Center, 
%              Montreal Neurological Institute,
%              McGill University, Montreal, Quebec, Canada. 
%              worsley@math.mcgill.ca, liao@math.mcgill.ca
%
%              Permission to use, copy, modify, and distribute this
%              software and its documentation for any purpose and without
%              fee is hereby granted, provided that the above copyright
%              notice appear in all copies.  The author and McGill University
%              make no representations about the suitability of this
%              software for any purpose.  It is provided "as is" without
%              express or implied warranty.
%##########################################################################
%
% Copyright (c) Felix Carbonell, Montreal Neurological Institute, McGill 
% University, 2009-2010.
% Maintainers : felix.carbonell@mail.mcgill.ca, pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : fMRIstat, linear model

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

nbin=100;
dbin=10;

[freq, mask]=hist(vol(:),nbin);
fm=freq(1:nbin-2*dbin);
f0=freq(1+dbin:nbin-dbin);
fp=freq(1+2*dbin:nbin);
h=(abs(f0-fm)+abs(f0-fp)).*(f0>fp).*(f0>fm);
if any(h)
    mh=min(find(h==max(h))+dbin);
    mask_thresh=max(mask(find(freq==min(freq(1:mh)))));
else
    mask_thresh=max(mask)/4;
end

