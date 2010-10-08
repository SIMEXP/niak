function mat = niak_neig2mat(neig);
%
% _________________________________________________________________________
% SUMMARY OF NIAK_NEIG2MAT
%
% Convert a table of spatial neighbours into an adjacency matrix
% representation.
%
% SYNTAX:
% MAT = NIAK_NEIG2MAT(NEIG)
%
% _________________________________________________________________________
% INPUTS:
%
%       (2D array) NEIG(i,:) is the list of neighbours of voxel i. All 
%       numbers refer to a rwo of NEIG. Because all voxels
%       do not necessarily have the same number of neighbours, 0 are
%       used to pad each line.
%
% _________________________________________________________________________
% OUTPUTS:
%
% MAT
%       (sparse matrix) MAT(I,J) equals 1 is J is in the list of neighbours
%       of row I.
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_BUILD_NEIGHBOUR
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : 

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

N = size(neig,1);
ind = find(neig);
[x,y] = ind2sub(size(neig),ind);
mat = sparse(x,neig(ind),ones([length(x) 1]),N,N);