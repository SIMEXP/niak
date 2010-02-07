function [neig,ind] = niak_build_neighbour_subset(mask,subs,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BUILD_NEIGHBOUR_SUBSET
%
% Generate a list of linear indices of spatial neighbours of all voxels in
% a subset of a 3D binary mask.
%
% SYNTAX :
% NEIG = NIAK_BUILD_NEIGHBOUR_SUBSET(MASK,SUBS,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
% MASK    
%       (3D array) binary mask of one 3D-region of interest (1s inside,
%       0s outside)
%
% SUBS
%       (vector) a list of voxels in the mask. These voxels are identified
%       by an integer position in the list find(MASK).
%
% OPT
%       (structure) with the following fields : 
%
%       TYPE_NEIG    
%           (integer value, default 26) 
%           The parameter of neighbourhood. Available options : 6 or 26
%
%       FLAG_POSITION
%           (boolean, default 1) if FLAG_POSITION is true, values in SUBS 
%           and NEIG are positions in the list FIND(MASK), otherwise they 
%           are linear indices in MASK, i.e. elements of FIND(MASK).
%
%       IND
%           (vector, default find(MASK)) The result of "find(MASK)". This
%           option is given to avoid recomputing it at every execution.
%
%       DECXYZ
%           (matrix) defines spatial neighbourhood. See
%           NIAK_BUILD_NEIGHBOUR_MAT. This option is given to avoid
%           recomputing the translation matrix at every execution.
%
% _________________________________________________________________________,
% OUTPUTS :
%
% NEIG     
%       (2D array) NEIG(I,:) is the list of neighbours of SUBS(I). All 
%       numbers refer to a position in FIND(MASK(:)). Because all voxels
%       do not necessarily have the same number of neighbours, 0 are
%       used to pad each line.
%
% IND      
%       (vector) IND(i) is the linear index of the ith voxel in MASK.
%       IND = FIND(MASK(:))
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
gb_list_fields = {'type_neig','flag_position','ind','decxyz'};
gb_list_defaults = {26,1,[],[]};
niak_set_defaults

%% Find linear indices and 3D coordinates of voxels in the mask
if isempty(ind)
    ind = find(mask(:));
end
N = length(subs);
[nx,ny,nz] = size(mask);
if flag_position
    [coordx,coordy,coordz] = ind2sub(size(mask),ind(subs));
else
    [coordx,coordy,coordz] = ind2sub(size(mask),subs);
end
coord = [coordx,coordy,coordz];

%% Generation of the neighborhood matrix
if isempty(decxyz)
    decxyz = niak_build_neighbour_mat(type_neig);
end
long_neig = length(decxyz);

%% Generating the matrix of neighbors
neigx = coord(:,1)*ones([1 long_neig]) + ones([N 1])*(decxyz(:,1)');
neigy = coord(:,2)*ones([1 long_neig]) + ones([N 1])*(decxyz(:,2)');
neigz = coord(:,3)*ones([1 long_neig]) + ones([N 1])*(decxyz(:,3)');

%% Get rid of the neighbors outside the volume
in_vol = (neigx>0)&(neigx<=nx)&(neigy>0)&(neigy<=ny)&(neigz>0)&(neigz<=nz);

%% Generation of the neighbour array
neig2 = sub2ind(size(mask),neigx(in_vol),neigy(in_vol),neigz(in_vol));
neig = zeros(size(in_vol),'uint32');
to_keep = mask(neig2)>0;
neig2(to_keep==0) = 0; % Get rid of neighbours that fall outside the mask

%% Converting the linear indices into position within the list IND
if flag_position
    neig3 = neig2(to_keep == 1);
    mask_ind = zeros(size(mask));
    mask_ind(mask>0) = 1:sum(mask(:)>0);
    neig3 = mask_ind(neig3);
    neig2(to_keep == 1) = neig3;
end

%% Reshaping the neighbor matrix
neig(in_vol) = neig2;