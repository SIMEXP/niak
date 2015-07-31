function coord_w = niak_coord_vox2world(coord_v,mat);
% Convert coordinates from voxel to world space 
%
% coord_w = niak_coord_vox2world(coord_v,mat)
%
% coord_v (matrix N*3) each row is a vector of 3D coordinates 
%   in voxel space.
% mat (matrix 4*4) an affine transformation from voxel to world
%   coordinates. See the help of niak_read_vol for more infos. It is 
%   generally the hdr.info.mat field of the header of a volume file.
% coord_w (matrix N*3) each row is a vector of 3D coordinates in 
%   world space.
%
% SEE ALSO:
%   niak_coord_world2vol, niak_read_vol
%
% COMMENTS:
%   Voxel coordinates are expected to start from 1. 
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
coord_w = [coord_v-1 ones([size(coord_v,1) 1])]*(mat');
coord_w = coord_w(:,1:3);