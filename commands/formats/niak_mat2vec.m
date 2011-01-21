function vec = niak_mat2vec(mat);
% Convert a symmetric matrix into a vector (the diagonal elements are lost)
%
% SYNTAX:
% VEC = NIAK_MAT2VEC(MAT)
%
% _________________________________________________________________________
% INPUTS:
%
% MAT           
%       (array) a square matrix. MAT should be symmetric. Diagonal elements 
%       will be lost.
%
% _________________________________________________________________________
% OUTPUTS:
%
% VEC           
%       (vector) a vectorized version of mat. Only off-diagonal 
%       low-triangular values are kept.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_VEC2MAT
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

N = size(mat,1);
vec = mat(tril(true(N),-1));