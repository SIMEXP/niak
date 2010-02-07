function mask_neig = niak_build_neighbour_mask(mask,mask_sub,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BUILD_NEIGHBOUR_MASK
%
% Generate a mask of the spatial neighbour of the voxels within a mask that
% are included in another mask.
%
% SYNTAX :
% MASK_NEIG = NIAK_BUILD_NEIGHBOUR_SUBSET(MASK,MASK_SUB,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
% MASK    
%       (3D array) binary mask of one 3D-region of interest (1s inside,
%       0s outside)
%
% MASK_NEIG
%       (3D array) subpart of MASK. 
%
% OPT
%       (structure) with the following fields : 
%
%       TYPE_NEIG    
%           (integer value, default 26) 
%           The parameter of neighbourhood. Available options : 6 or 26
%
%       IND
%           (vector, default find(MASK)) The result of "find(MASK)". This
%           option is given to avoid recomputing it at every execution.
%
% _________________________________________________________________________,
% OUTPUTS :
%
% MASK_NEIG
%       (3D array) binary mask of the neighbour of MASK_SUB included in
%       MASK. Note that voxels within MASK_SUB are excluded from MASK_NEIG.
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
gb_list_fields = {'type_neig','ind','decxyz'};
gb_list_defaults = {26,[],[]};
niak_set_defaults

if isempty(ind)
    ind = find(mask);
end

opt_sub = opt;
opt_sub.flag_position = false;
neig = niak_build_neighbour_subset(mask,find(mask_sub),opt_sub);
mask_neig = false(size(mask));
mask_neig(neig(neig~=0)) = true;
mask_neig(mask_sub) = false;
