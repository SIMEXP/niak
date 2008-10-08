function [neig,ind] = niak_build_neighbour(mask,type_neig)
%
% _________________________________________________________________________
% SUMMARY NIAK_BUILD_NEIGHBOUR
%
% Generate a list of linear indices of spatial neighbours of all voxels in
% a 3D binary mask.
%
% SYNTAX :
% NEIG = NIAK_BUILD_NEIG(MASK,TYPE_NEIGH)
%
% _________________________________________________________________________
% INPUTS :
%
% MASK    
%       (3D array) binary mask of one 3D-region of interest (1s inside,
%       0s outside)
%
% TYPE_NEIG    
%       (integer value, default 26) 
%       definition of 3D-connexity (possible value 6,26)
%
% _________________________________________________________________________
% OUTPUTS :
%
% NEIG     
%       (2D array) NEIG(i,:) is the list of neiighbours of voxel i. All 
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

%% Default inputs
if nargin < 2
    type_neig = 26;
end

%% Find linear indices and 3D coordinates of voxels in the mask
ind = find(mask(:));
N = length(ind);
[nx,ny,nz] = size(mask);
[coordx,coordy,coordz] = ind2sub(size(mask),ind);
coord = [coordx,coordy,coordz];

%% Generation of the neighborhood matrix
if type_neig == 26
    dec = [0,1,-1];
    num = 1;
    for i = 1:3
        for j = 1:3
            for k = 1:3
                decxyz(num,:) = [dec(i),dec(j),dec(k)];
                num = num + 1;
            end
        end
    end
    decxyz = decxyz(2:27,:);
elseif type_neig == 6
    decxyz = [1 0 0;-1 0 0; 0 1 0; 0 -1 0; 0 0 1; 0 0 -1];
else
    error('%i : unsupported type of neighbourhood',type_neigh)
end

long_neig = length(decxyz);

%% Generating the matrix of neighbors
neigx = coord(:,1)*ones([1 long_neig]) + ones([N 1])*(decxyz(:,1)');
neigy = coord(:,2)*ones([1 long_neig]) + ones([N 1])*(decxyz(:,2)');
neigz = coord(:,3)*ones([1 long_neig]) + ones([N 1])*(decxyz(:,3)');

%% Get rid of the neighbors outside the volume
in_vol = (neigx>0)&(neigx<=nx)&(neigy>0)&(neigy<=ny)&(neigz>0)&(neigz<=nz);
neigx(in_vol==0) = NaN;
neigy(in_vol==0) = NaN;
neigz(in_vol==0) = NaN;

%% Generation of the neighbour array
neig = sub2ind(size(mask),neigx,neigy,neigz);
neig2 = neig(~isnan(neig));
to_keep = mask(neig2)>0;
neig2(to_keep==0) = 0; % Get rid of neighbours that fall outside the mask

%% Converting the linear indices into position within the list IND
neig3 = neig2(to_keep == 1);
mask_ind = zeros(size(mask));
mask_ind(mask>0) = 1:sum(mask(:)>0);
neig3 = mask_ind(neig3);

%% Reshaping the neighbor matrix
neig2(to_keep == 1) = neig3;
neig(~isnan(neig)) = neig2; 
neig(isnan(neig)) = 0;