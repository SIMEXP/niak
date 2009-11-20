function mask2 = niak_erode_mask(mask,type_neig)
%
% _________________________________________________________________________
% SUMMARY NIAK_ERODE_MASK
%
% Apply an erosion operation to a binary mask.
%
% SYNTAX :
% MASK2 = NIAK_ERODE_MASK(MASK,TYPE_NEIGH)
%
% _________________________________________________________________________
% INPUTS :
%
% MASK    
%       (3D array) 
%       binary mask of one 3D-region of interest (1s inside, 0s outside)
%
% TYPE_NEIG    
%       (integer value, default 26) 
%       definition of 3D-connexity (possible value 6,26)
%
% _________________________________________________________________________
% OUTPUTS :
%
% MASK2 
%       (3D array) 
%       binary mask, comprising all voxels of mask that do not have a 
%       neighbour outside of mask
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

mask_interior = sub_build_neighbour(mask,type_neig);
mask2 = zeros(size(mask));
mask2(mask>0) = mask_interior;
mask2 = mask2 > 0;

%%%%%%%%%%%%%%%%%%%
%% Subfunctions %%%
%%%%%%%%%%%%%%%%%%%

function neig = sub_build_neighbour(mask,type_neig);

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
in_mask = ismember(neig2,ind);
neig2(~in_mask) = Inf;
neig(~isnan(neig)) = neig2; 
neig(isnan(neig)) = 0;
neig = min(~isinf(neig),[],2);