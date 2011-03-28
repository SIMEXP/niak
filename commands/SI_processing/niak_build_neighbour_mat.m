function decxyz = niak_build_neighbour_mat(type_neig)
% Build a translation matrix to derive spatial neighbour of 3D voxels. 
% Each row of the matrix is a translation that applies to the 3D 
% coordinates of a voxel
%
% SYNTAX :
% DECXYZ = NIAK_BUILD_NEIGHBOUR_MAT(TYPE_NEIG)
%
% _________________________________________________________________________
% INPUTS :
%
% TYPE_NEIG 
%   (scalar or vector 1*4, default 6) the type of spatial connexity. 
%   Possible values for scalars : 4, 6, 8, 18, 26
%   If TYPE_NEIG is a vector, the three first elements are the size of
%   voxels in X, Y and Z directions, and the last element is the radius of
%   an isotropic ball.
%
% _________________________________________________________________________
% OUTPUTS :
%
% DECXYZ
%    (matrix) DECXYZ(I,:) is a translation that applies to the 3D 
%    coordinates of a voxel to get one spatial neighbour. The number of
%    rows of DECXYZ depends on the type of spatial connexity.
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

if length(type_neig)==1
    if type_neig == 26
        dec = [0,1,-1];
        num = 1;
        decxyz = zeros([27 3]);
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
    elseif type_neig == 4
        decxyz = [1 0 0;-1 0 0; 0 1 0; 0 -1 0];
    elseif type_neig == 8
        decxyz = [1 0 0;-1 0 0; 0 1 0; 0 -1 0; 1 1 0; -1 1 0; 1 -1 0; -1 -1 0];
    elseif type_neig == 18
        dec = [-3 -2 -1 1 2 3];
        decxyz = zeros([18 3]);
        for num_d = 1:length(dec)
            decxyz(num_d,:) = [dec(num_d) 0 0];
            decxyz(num_d+6,:) = [0 dec(num_d) 0];
            decxyz(num_d+12,:) = [0 0 dec(num_d)];
        end
    elseif type_neig == 30
        dec = [-10 -4 -3 -2 -1 1 2 3 4 10];
        decxyz = zeros([length(dec)*3 3]);
        for num_d = 1:length(dec)
            decxyz(num_d,:) = [dec(num_d) 0 0];
            decxyz(num_d+length(dec),:) = [0 dec(num_d) 0];
            decxyz(num_d+2*length(dec),:) = [0 0 dec(num_d)];
        end
    else
        error('%i : unsupported parameter for a connex neighbourhood',type_neig)
    end
else
    voxel_size = type_neig(1:3);
    radius = type_neig(4);
    
    % Get the voxels in the ball defined by the radius
    mask_neig = ones([ceil(1.2*radius/voxel_size(1))*2 ceil(1.2*radius/voxel_size(2))*2 ceil(1.2*radius/voxel_size(3))*2]);
    ind = find(mask_neig);
    [x,y,z] = ind2sub(size(mask_neig),ind);
    
    % Adjusting the coordinates from voxel space to physical space
    mat = eye(4);
    mat(1:3,1:3) = diag(voxel_size);
    coord_vox = [x y z];
    coord_phy = (mat(1:3,1:3)*(coord_vox') + mat(1:3,4)*ones([1 size(coord_vox,1)]))';
    center_vox = ceil(size(mask_neig)/2)';
    center_phy = mat(1:3,1:3)*center_vox + mat(1:3,4);
    
    % Definition of the distance
    dist = sqrt(sum((coord_phy - ones([size(coord_phy,1) 1])*center_phy').^2,2));
    list_neig = find(dist<=radius);
    decxyz = [x y z];
    decxyz = decxyz(list_neig,:);
    decxyz = decxyz - ones([size(decxyz,1) 1])*ceil(size(mask_neig)/2);
    decxyz=sortrows(decxyz);
    decxyz(ceil(length(decxyz)/2),:)=[];
end
