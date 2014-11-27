function avg_sim = niak_build_avg_sim(mat,part,flag_vec)
% Compute the average similarity within and between clusters. Note that the
% within-cluster similiarity of a singleton is arbitrarily set to zero.
%
% AVG_SIM = NIAK_BUILD_AVG_SIM(MAT,PART,[FLAG_VEC])
%
% MAT (array, size N*N) MAT(I,J) is the similarity between units I and J.
% PART (vector, size N*1) PART(I) is the number of the cluster unit I
%   belongs to, ie the elements of cluster K are defined by FIND(PART==K).
% FLAG_VEC (boolean, default false) If FLAG_VEC is true, the average 
%   similarity matrix is vectorized using NIAK_MAT2VEC
% AVG_SIM (matrix) AVG_SIM(K,L) is the average similarity between networks K
%   and L. 
%
% COMMENTS: The similarity matrix MAT needs to be symmetrical.
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2014
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
    error('Syntax : SIL = NIAK_BUILD_AVG_SIM(MAT,PART) ; for more infos, type ''help niak_build_avg_sim''.')
end

if nargin < 3
    flag_vec = false;
end

N = length(part);

if (size(mat,1)~=N)||(size(mat,2)~=N)
    error('MAT should be a square N*N matrix where N is the length of PART')
end

nb_clust = max(part);

avg_sim = zeros([nb_clust nb_clust]);

for num_k = 1:nb_clust
    for num_l = 1:num_k
        
        if num_l == num_k
            
            mat_tmp = mat(part == num_k,part == num_k);
            avg_sim(num_k,num_k) = mean(niak_mat2vec(mat_tmp));
            
        else
            
            avg_sim(num_k,num_l) = mean(mean(mat(part == num_k,part == num_l)));
            avg_sim(num_l,num_k) = avg_sim(num_k,num_l);
        end
        
    end    
end

if flag_vec
    avg_sim = niak_mat2vec(avg_sim);
end

