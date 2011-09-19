function scales_mat = niak_scales2mat(scales,neigh);
% Convert a list of scales into an array scales*(neighbourhood of scales)
%
% SYNTAX:
% SCALES_MAT = NIAK_SCALES2MAT(SCALES,NEIGH)
%
% _________________________________________________________________________
% INPUTS:
%
% SCALES
%   (vector) a list of integers
%
% NEIGH
%   (vector 1*3, default [0.7 0.1 1.3] percentage that define the 
%   neighbourhood of a scale.
%
% _________________________________________________________________________
% OUTPUTS:
%
% SCALES_MAT           
%   (array) For each row, SCALES_MAT(I,2) is a scale and SCALES_MAT(I,1) a
%   neighbour of this scale. All possible pairs of scales/neighbours are
%   listed.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_SCALES2CELL
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2010
% Maintainer : pbellec@criugm.qc.ca
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

if nargin < 2
    neigh = [0.7 0.1 1.3];
end
nb_points = 0;
scales2 = cell([length(scales) 1]);
for num_s = 1:length(scales)    
    scales2{num_s} = unique(ceil(scales(num_s)*(neigh(1):neigh(2):neigh(3))));
    nb_points = nb_points + length(scales2{num_s});   
end

num_p = 0;
scales_mat = zeros([nb_points 2]);
for num_s = 1:length(scales)
    for num_g = 1:length(scales2{num_s})
        scales_mat(num_p+1:num_p+length(scales2{num_s}),1) = scales(num_s);
        scales_mat(num_p+1:num_p+length(scales2{num_s}),2) = scales2{num_s};        
    end    
    num_p = num_p+length(scales2{num_s});
end
