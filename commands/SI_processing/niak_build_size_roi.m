function [size_roi,labels_roi] = niak_build_size_roi(mask)
%
% _________________________________________________________________________
% SUMMARY NIAK_BUILD_SIZE_ROI
%
% Extract the labels and size of regions of interest in a 3D volume 
%
% [SIZE_ROI,LABELS_ROI] = NIAK_BUILD_SIZE_ROI(MASK)
%
% _________________________________________________________________________
% INPUTS:
%
% MASK      
%       (3D array) voxels belonging to no region are coded with 0, those 
%       belonging to region I are coded with I (I being a positive integer).
%
% _________________________________________________________________________
% OUTPUTS:
%
% SIZE_ROI  
%       (vector) SIZE_ROI(I) is the number of voxels in region number I.
%
% LABELS_ROI 
%       (vector) LABELS_ROI(I) is the label of region I.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : ROI

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

labels_roi = unique(mask(:));
labels_roi = labels_roi(labels_roi~=0);

nb_roi = length(labels_roi);
size_roi = zeros([nb_roi 1]);

mask_v = mask(mask>0);

for num_r = 1:nb_roi
    size_roi(num_r) = sum(mask_v == labels_roi(num_r));
end