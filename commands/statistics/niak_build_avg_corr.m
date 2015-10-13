function avg_corr = niak_build_avg_corr(mat,part,flag_vec)
% Compute the average similarity within and between clusters. Note that the
% within-cluster similiarity of a singleton is arbitrarily set to zero.
%
% AVG_CORR = NIAK_BUILD_AVG_CORR(MAT,PART,[FLAG_VEC])
%
% MAT (array, size S*L) MAT(s,:) is a vectorized correlation matrix (with NIAK_MAT2VEC)
% PART (vector, size N*1) PART(I) is the number of the cluster unit I
%   belongs to, ie the elements of cluster K are defined by FIND(PART==K).
% AVG_SIM (matrix) AVG_SIM(:,L2) is the average correlation matrix between clusters
%   vectorized with NIAK_MAT2LVEC
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de griatrie de Montral, 
% Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2015
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.

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

%% Syntax
if ~exist('mat','var')||~exist('part','var')
    error('Syntax : AVG_CORR = NIAK_BUILD_AVG_CORR(MAT,PART) ; for more infos, type ''help niak_build_avg_sim''.')
end

N = length(part);
K = max(part(:));
nb_cell = K*(K-1)/2;
ind_cell = niak_vec2mat(1:nb_cell);
mat_cell = zeros(N,N);
for k1 = 1:K
    for k2 = 1:K
        mat_cell(part == k1, part == k2) = ind_cell(k1,k2);
        mat_cell(part == k2, part == k1) = ind_cell(k1,k2);
    end
end
vec_cell = niak_mat2vec(mat_cell);
avg_corr = zeros(size(mat,1),nb_cell);
for cc = 1:nb_cell
    avg_corr(:,cc) = mean(mat(:,vec_cell==cc),2);
end