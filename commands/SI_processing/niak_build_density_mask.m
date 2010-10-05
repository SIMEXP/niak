function vec_dense = niak_build_density_mask(mask,type_neig)
% Derive a map of spatial density for a binary volume.
%
% SYNTAX:
% VEC_DENSE = NIAK_BUILD_DENSITY_MASK(MASK,TYPE_NEIG)
%
% _________________________________________________________________________
% INPUTS :
%
%   MASK
%       (3D volume) a binary volume.
%
%   TYPE_NEIG
%       (integer, default 26) the type of spatial connexity. See
%       NIAK_BUILD_NEIGHBOUR_MAT.
%
% _________________________________________________________________________
% OUTPUTS :
%
%   VEC_DENSE
%       (vector) VEC_DENSE(I) is the spatial density at voxel I in MASK, as
%       numbered using FIND(MASK).
%
% _________________________________________________________________________
% SEE ALSO :
% NIAK_BUILD_NEIGHBOUR_MAT, NIAK_CLUSTERING_SPACE_DENSITY
%
% _________________________________________________________________________
% COMMENTS
%
% Spatial density at each voxel is defined as the proportion of spatial
% neighbours that fall within the mask.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, t1, mask, segmentation

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

decxyz = niak_build_neighbour_mat(type_neig);
nb_n = size(decxyz,1);
opt_neig.ind = find(mask);
[coordx,coordy,coordz] = ind2sub(size(mask),opt_neig.ind);
opt_neig.coord = [coordx,coordy,coordz];
clear coordx coordy coordz
opt_neig.type_neig = type_neig;
opt_neig.flag_position = true;
opt_neig.flag_within_mask = true;

for num_n = 1:nb_n
    opt_neig.decxyz = decxyz(num_n,:);
    neig = niak_build_neighbour(mask,opt_neig);
    if num_n == 1
        vec_dense = double(neig>0)+1;
    else
        vec_dense = vec_dense + (neig>0);
    end
end
vec_dense = vec_dense/(nb_n+1);