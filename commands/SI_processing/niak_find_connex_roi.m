function [mask_c,list_size] = niak_find_connex_roi(mask,opt)

% Find spatially connected rois in a binary mask
%
% SYNTAX :
% [MASK_C,LIST_SIZE] = NIAK_FIND_CONNEX_ROI(MASK,OPT)
%
% INPUTS :
% MASK    (3D array) binary volume.
% OPT     (structure) optional, with the following fields :
%       TYPE_NEIG (integer, default 6) the spatial neighbourhood of a
%           voxel, values : 6 or 26.
%       THRE_SIZE (integer, default 1) the minimal acceptable size of ROIs.
%
% OUTPUTS :
% MASK_C   (3D array) (MASK_C==i) is the ith 
% IND      (vector) IND(i) is the linear index of the ith voxel in MASK.
%             I = FIND(MASK(:))
%
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

[neig,ind] = niak_build_neighbour(mask>0);

is_neig = max(neig,[],2)>0;
nb_roi = 0;
mask_c = zeros(size(mask));

while max(is_neig)>0
    nb_roi = nb_roi + 1;
    
    list_is_neig = find(is_neig);
    ind_roi = list_is_neig(1);    
    neig_roi = neig(ind_roi,:);    
    neig_roi = neig_roi(neig_roi~=0);
    neig_roi = unique(neig_roi(:));
    is_neig_roi = ismember(neig_roi,ind_roi);
    neig_roi = neig_roi(~is_neig_roi);
    
    while min(is_neig_roi)==0
        
        neig_tmp = neig(neig_roi,:); % Have a look to the neighbours of the new voxels
        
        ind_roi = union(ind_roi,neig_roi); % The new roi comprises all neighbours of the roi at last iteration
        
        %% Update the neighbourhood of the new voxels
        neig_roi = neig_tmp(neig_tmp~=0);
        neig_roi = unique(neig_roi(:));
        is_neig_roi = ismember(neig_roi,ind_roi);
        neig_roi = neig_roi(~is_neig_roi);
        
    end
    
    mask_c(ind(ind_roi)) = nb_roi;
    list_size(nb_roi) = length(ind_roi);
    is_neig(ind_roi) = 0;
end

        
        