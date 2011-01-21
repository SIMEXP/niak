function mat = niak_vec2mat(vec);
% Convert a vectorized symmetric matrix (without diagonal elements) into 
% a matrix form with ones on the diagonal.
%
% SYNTAX:
% MAT = NIAK_VEC2MAT(VEC)
%
% _________________________________________________________________________
%
% INPUTS:
%
% VEC           
%       (vector) a vectorized version of a symmetric matrix (without 
%       diagonal elements).
%
% _________________________________________________________________________
% OUTPUTS:
%
% MAT           
%       (array) a square matrix. MAT is symmetric. Diagonal elements are 
%       one.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_MAT2VEC
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

M = length(vec);
N = round((1+sqrt(1+8*M))/2);

mat = zeros([N N]);
mat(tril(true(N),-1)) = vec;
mat = mat';
mat(tril(true(N),-1)) = vec;
mat(eye(N)==1) = 1;
