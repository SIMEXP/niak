function [size_roi,labels_roi] = niak_build_size_roi(mask,flag_iterative)
% Extract the labels and size of regions of interest in an integer array of
% labels.
%
% [SIZE_ROI,LABELS_ROI] = NIAK_BUILD_SIZE_ROI(MASK)
%
% _________________________________________________________________________
% INPUTS:
%
% MASK      
%       (array) voxels belonging to no region are coded with 0, those 
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
% The function was initially designed for 3D volumes, but should work on
% any dimensional array, including vectors.
%
% Copyright (c) Pierre Bellec, 
%               McConnell Brain Imaging Center,Montreal Neurological 
%               Institute, McGill University, 2008
%               &
%               Centre de recherche de l'institut de geriatrie de Montreal,
%               Universite de Montreal, 2010.
%
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : ROI, connected components, 3D volume

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
    flag_iterative = false;
end

%% test for an empty mask
if ~any(mask(:))
    size_roi = [];
    labels_roi = [];
    return
end

if ~flag_iterative
    
    %% Implementation based on sorting
    vec = sort(mask(mask>0));
    vec = [vec(:) ; vec(end)+1];
    size_roi = find(diff(vec));
    if isempty(size_roi)
        size_roi = length(vec);
        labels_roi = vec(1);
    else
        labels_roi = vec(size_roi);
        if length(size_roi)>1
            size_roi = size_roi - [0 ; size_roi(1:(end-1))];
        end
    end
    
else
    
    %% Implementation based on a loop
    labels_roi = unique(mask(:));
    labels_roi = labels_roi(labels_roi~=0);
    
    nb_roi = length(labels_roi);
    size_roi = zeros([nb_roi 1]);
    
    mask_v = mask(mask>0);
    
    for num_r = 1:nb_roi
        size_roi(num_r) = sum(mask_v == labels_roi(num_r));
    end
    
end