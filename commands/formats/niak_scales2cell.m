function [scales1,scales2] = niak_scales2cell(scales_mat);
% convert pairs of integer into non-redundant lists.
%
% SYNTAX:
% [SCALES1,SCALES2] = NIAK_SCALES2CELL(SCALES_MAT)
%
% _________________________________________________________________________
% INPUTS:
%
% SCALES_MAT
%   (array N*2) each row is a pair of integers
%
% _________________________________________________________________________
% OUTPUTS:
%
% SCALES1
%   (vector) An ordered list of unique values found in SCALES_MAT(:,1)
%
% SCALES2
%   (cell) SCALES2{I} is an ordered list of unique integers found in 
%   SCALES_MAT(:,2) such that SCALES_MAT(:,1) is equal to SCALES1(I).
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_SCALES2MAT
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

scales1 = unique(scales_mat(:,1));
scales2 = cell([length(scales1) 1]);
tmp1 = scales_mat(:,1);
tmp2 = scales_mat(:,2);
for num_x = 1:length(scales1)
    scales2{num_x} = unique(tmp2(tmp1==scales1(num_x)));
end