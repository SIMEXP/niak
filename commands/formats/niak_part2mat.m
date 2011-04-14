function mat = niak_part2mat(part,flag_binary);
% Convert a vector partition of integer lables into an adjacency matrix.
%
% SYNTAX:
% MAT = NIAK_PART2MAT(PART,FLAG_BINARY)
%
% _________________________________________________________________________
%
% INPUTS:
%
% PART
%   (vector) PART(i) is the number of the cluster of region i.
%
% FLAG_BINARY
%   (boolean, default false) if FLAG_BINARY is true, the output will be a
%   binary matrix.
%
% _________________________________________________________________________
% OUTPUTS:
%
% MAT           
%    (array) a square matrix. MAT(I,J) equals K (or 1 if FLAG_BINARY)
%    if regions I and J are together in cluster K, and zero otherwise.
%
% _________________________________________________________________________
% SEE ALSO:
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007-2010.
%               Centre de recherche de l'institut de gériatrie de Montréal,
%               Département d'informatique et de recherches opérationnelles,
%               Université de Montréal, 2010.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : partition, adjacency

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

if nargin<2
    flag_binary = false;
end
nb_rois = length(part);
mat = zeros([nb_rois nb_rois]);
list_clusters = unique(part);
list_clusters = list_clusters(list_clusters~=0);
list_clusters = list_clusters(:)';

for num_c = list_clusters
    if flag_binary
        mat(part==num_c,part==num_c) = 1;
    else
        mat(part==num_c,part==num_c) = num_c;
    end
end