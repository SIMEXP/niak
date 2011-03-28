function adj = niak_build_adjacency(mask,neig)
% Compute the adjacency matrix of voxels within a region of interest in a
% 3D volume.
%
% SYNTAX :
% ADJ = NIAK_BUILD_ADJACENCY(MASK,NEIG)
%
% _________________________________________________________________________
% INPUTS :
%
% MASK    
%       (3D array) binary mask of one 3D-region of interest (1s inside,
%       0s outside)
%
% NEIG    
%       (integer value, default 26) definition of 3D-connexity (possible 
%       value 6,26)
%
% _________________________________________________________________________
% OUTPUTS :
%
% ADJ     
%       (2D array) adjacency matrix of voxels inside the mask. Order of the 
%       voxels is given by FIND(MASK(:))
%
% _________________________________________________________________________
% COMMENTS :
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : adjacency matrix, connexity,graph

nb_regions = max(mask(:)); % Number of regions

%% Default inputs
if nargin < 2
    neig = 26;
end

%% Find linear indices and 3D coordinates of voxels in the mask
I = find(mask(:));
N = length(I);
[nx,ny,nz] = size(mask);
[coordx,coordy,coordz] = ind2sub(size(mask),I);
coord = [coordx,coordy,coordz];

%% Generation of the neighborhood matrix
if neig == 26
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
elseif neig == 6
    decxyz = [1 0 0;-1 0 0; 0 1 0; 0 -1 0; 0 0 1; 0 0 -1];
end

long_neig = length(decxyz);

%% V is a vector with N 1, then N 2, ..., N N
v = 1/length(decxyz):1/length(decxyz):N;
v = ceil(v);

%% Generating the matrix of neighbors
neigx = ones([long_neig 1])*coord(:,1)' + decxyz(:,1)*ones([1 N]);
neigy = ones([long_neig 1])*coord(:,2)' + decxyz(:,2)*ones([1 N]);
neigz = ones([long_neig 1])*coord(:,3)' + decxyz(:,3)*ones([1 N]);
neig = [neigx(:) neigy(:) neigz(:)];

%% Get rid of the neighbors outside the volume
in_vol = (neigx(:)>0)&(neigx(:)<=nx)&(neigy(:)>0)&(neigy(:)<=ny)&(neigz(:)>0)&(neigz(:)<=nz);
garde = in_vol;
garde(in_vol) = mask(sub2ind(size(mask),neigx(in_vol),neigy(in_vol),neigz(in_vol)));

% Generation of the adjacency matrix
I1 = I(v);
I2 = sub2ind(size(mask),neig(garde,1),neig(garde,2),neig(garde,3));
I1 = I1(garde);
diagx = (1:nx*ny*nz)';
I1 = [diagx;I1];
if ~isempty(I2)
    I2 = [diagx;I2];
    adj = sparse(I1,I2,ones(size(I1)),nx*ny*nz,nx*ny*nz);
    adj = logical(adj);
    adj = adj(I,I);
else
    adj = sparse(length(I),length(I));
    adj = logical(adj);
end