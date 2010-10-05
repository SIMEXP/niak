function [mask_c,size_roi] = niak_find_connex_roi(mask,opt)
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
%           voxel, possible values : 
%              4             two-dimensional four-connected neighborhood
%              8             two-dimensional eight-connected neighborhood
%              6             three-dimensional six-connected neighborhood
%              10            three-dimensional 10-connected neighborhood
%              18            three-dimensional 18-connected neighborhood
%              26            three-dimensional 26-connected neighborhoodsee 
%           See NIAK_BUILD_NEIGHBOUR_MAT for more options.
%
%       THRE_SIZE
%           (integer, default 1) the minimal acceptable size of ROIs.
%
%       FLAG_INT
%           (boolean, default 1) the mask of connected components is 
%           generated in the 'uint32' type. Otherwise it is a double array.
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
% NOTE 1:
%   The algorithm employed for TYPE_NEIG == 4, 6, 8, 10 and other types are 
%   completely different. With 18 and 26, it is a region growing which
%   is only practical for low resolution volume (say 64*64*30), is greedy
%   both computationally and in terms of memory. It works fine when the 
%   ROIs are small though. With TYPE_NEIG == 4, 6, 8, 10 the algorithm 
%   first works in 2D and then propagates labels between slices. This is 
%   much faster and memory efficient. This depends on the BWLABEL function
%   from the image processing package though.
%
% NOTE 2:
%   The order of the ROIs is completely arbitrary.
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
% in all copies or substantial portions of the Software.
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
gb_list_fields = {'flag_int','type_neig','thre_size'};
gb_list_defaults = {true,6,1};
niak_set_defaults

mask = mask>0;

if flag_int
    mask_c = zeros(size(mask),'uint32');
else
    mask_c = zeros(size(mask));
end

if ismember(type_neig,[4,6,8,10]);
    
    if type_neig == 10
        type_neig = 8;
    elseif type_neig == 6
        type_neig = 4;
    end
    
    [nx,ny,nz] = size(mask);
    
    % Extract connected components in every slices    
    nb_roi_slice = zeros([nz 1]);
    nb_roi = 0;
    for num_z = 1:nz        
        slice = bwlabel(mask(:,:,num_z),type_neig);        
        nb_roi_slice(num_z) = max(slice(:));  
        slice(mask(:,:,num_z)) = slice(mask(:,:,num_z)) + nb_roi;                                      
        nb_roi = nb_roi + nb_roi_slice(num_z);        
        mask_c(:,:,num_z) = slice;
    end
    
    % Propagate labels by ascending slices
    if nz>1
        start_roi = nb_roi_slice(1)+1;
        part = 1:nb_roi;
        for num_z = 2:nz
            if nb_roi_slice(num_z)>0 % if there are rois in the slice
                list_roi = start_roi : (start_roi + nb_roi_slice(num_z)-1); % list of roi in the slice
                start_roi = start_roi + nb_roi_slice(num_z);
                slice1 = mask_c(:,:,num_z-1);
                slice2 = mask_c(:,:,num_z);
                mask1 = mask(:,:,num_z-1);
                for num_r = list_roi
                    to_merge = [unique(part(slice1(mask1&(slice2==num_r)))) num_r];
                    if length(to_merge)>1
                        part(ismember(part,to_merge)) = to_merge(1);
                    end
                end
            end
        end
    end
    [tmp1,tmp2,part] = unique(part);
    mask_c(mask) = part(mask_c(mask));
    if nargout>1
        size_roi = niak_build_size_roi(mask_c);
    end
else
    
    decxyz = niak_build_neighbour_mat(type_neig);
    mask = mask>0;
    ind = find(mask);
    nb_roi = 0;
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
