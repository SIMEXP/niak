function coord_v = niak_coord_world2vox(coord_w,mat);
% Convert coordinates from world to voxel space. 
%
% coord_v = niak_coord_world2vox(coord_w,mat)
%
% coord_w (matrix N*3) each row is a vector of 3D coordinates 
%   in world space.
% mat (matrix 4*4) an affine transformation from voxel to world coordinates. 
%   See the help of NIAK_READ_VOL for more infos. It is generally the 
%   hdr.info.mat field of the header of a volume file.
% coord_v (matrix N*3) each row is a vector of 3D coordinates in voxel space.
%
% SEE ALSO:
%   niak_coord_vox2world, niak_read_vol
%
% COMMENTS:
%   Voxel coordinates start from 1, and are not rounded.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : affine transformation, coordinates

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

coord_v = [coord_w ones([size(coord_w,1) 1])]*((mat')^(-1));
coord_v = coord_v(:,1:3)+1;