function [direction_cosine,step,start] = niak_hdr_mat2minc(mat)

%
% _________________________________________________________________________
% SUMMARY NIAK_HDR_MAT3MINC
%
% Convert a "voxel-to-world" coordinates affine transformation from the standard
% 4*4 matrix array (y=M*x+T) to the cosines/start/step representation used
% in minc headers.
%
% SYNTAX:
% [DIRECTION_COSINE,STEP,START] = NIAK_HDR_MAT2MINC(MAT)
% 
% _________________________________________________________________________
% INPUTS:
%
% MAT   (4*4 array) An affine transformation, usually seen as a
%           "voxel-to-world" space transform.
%
% _________________________________________________________________________
% OUTPUTS:
%
% DIRECTION_COSINES (array 3*3) gives you the direction assigned to the
%           respective dimensions of the voxel array.
%
% START (vector 3*1) the starting value of each voxel dimension along the
%       DIRECTION_COSINES vector.
%
% STEP  (vector 3*1) the step made at each voxel dimension along the
%       DIRECTION_COSINES vector.
%
% _________________________________________________________________________
% COMMENTS:
%
% This function is based on the description of MINC2 system of coordinates
% that can be found at :
% http://en.wikibooks.org/wiki/MINC/Reference/MINC2.0_File_Format_Reference#MINC_2.0_coordinate_system
%
% There is however no recommended method for this operation in the official
% MINC2 API. This function is a hack that seems to work in all the
% situation that have been tested so far.
% _________________________________________________________________________
% SEE ALSO:
% NIAK_READ_HDR_MINC, NIAK_WRITE_MINC, NIAK_HDR_MINC2MAT
%
% Copyright (c) Pierre Bellec, McConnel Brain Imaging Center, Montreal 
% Neurological Institute, McGill University, Montreal, Canada, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, I/O, affine transformation, minc

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

R = mat(1:3,1:3);
step = sqrt(diag(R'*R));

%% Trying to guess the orientation of axis in voxel space.
%% This is ugly ! but I don't have anything better for now.
[val,ind] = max(abs(R),[],1);
for num_d = 1:3
    step(num_d) = step(num_d) * sign(R(ind(num_d),num_d));    
end

direction_cosine = R * (diag(step.^(-1)));
start = direction_cosine^(-1)*mat(1:3,4);