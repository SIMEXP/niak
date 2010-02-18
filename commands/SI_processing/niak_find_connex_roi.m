function [mask_c,size_roi] = niak_find_connex_roi(mask,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_FIND_CONNEX_ROI
%
% Find spatially connected rois in a binary mask
%
% SYNTAX :
% [MASK_C,LIST_SIZE] = NIAK_FIND_CONNEX_ROI(MASK,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
% MASK
%       (3D array) binary volume.
% OPT
%       (structure) optional, with the following fields :
%
%       TYPE_NEIG
%           (integer, default 6) the spatial neighbourhood of a
%           voxel, values : 6 or 26.
%
%       THRE_SIZE
%           (integer, default 1) the minimal acceptable size of ROIs.
%
% _________________________________________________________________________
% OUTPUTS :
%
% MASK_C
%       (3D array) (MASK_C==i) is the ith connex region
%
% SIZE_ROI
%       (vector) SIZE_ROI(I) is the size of the Ith region (MASK_C==I).
%
% _________________________________________________________________________
% COMMENTS :
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : spatial neighbour, adjacency matrix, connexity, graph

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included
% in
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
gb_list_fields = {'type_neig','thre_size'};
gb_list_defaults = {6,1};
niak_set_defaults
if max(mask(:))>1
    mask = mask>0;
else
    
    decxyz = niak_build_neighbour_mat(type_neig);
    mask = mask>0;
    ind = find(mask);
    nb_roi = 0;
    mask_c = zeros(size(mask));
    opt_grow.type_neig = type_neig;
    opt_grow.decxyz = decxyz;
    opt_grow.ind = ind;
    
    while any(mask(:))
        
        ind_roi = find(mask,1);
        mask_roi = sub_region_growing(ind_roi,mask,opt_grow);
        mask(mask_roi) = false;
        size_roi_tmp = sum(mask_roi(:));
        if size_roi_tmp>=thre_size;
            nb_roi = nb_roi + 1;
            mask_c(mask_roi) = nb_roi;
            size_roi(nb_roi) = size_roi_tmp;
        end
    end
end
        
%%%%%%%%%%%%%%%%%
%% SUBFUNCTION %%
%%%%%%%%%%%%%%%%%

function mask_roi = sub_region_growing(ind_roi,mask,opt_grow)

mask_roi = false(size(mask));
mask_roi(ind_roi) = true;
is_new = true;
mask_border = mask_roi;

while is_new
    mask_neig = niak_build_neighbour_mask(mask,mask_border,opt_grow);
    mask_border = mask_neig;
    mask_border(mask_roi) = false;        
    is_new = any(mask_border(:));
    if is_new        
        mask_roi(mask_border) = true;        
    end
end
