function [sil,a,b] = niak_build_silhouette(mat,part,flag_normalize)
% Estimate the silhouette of a clustering based on a similarity matrix.
%
% Let i be a unit, a(i) be the average similarity of i with all units in
% the same cluster as i and b(i) be the maximal average similarity between
% i and all other units in another cluster, the silhouette of i is :
%
% s(i) = {a(i) - b(i)} / {max(a(i),b(i)}                (1)
%
% The unnormalized version is simply :
%
% s(i) = {a(i) - b(i)}                                  (2)
%
% This version is especially relevant stability measures which are bounded
% between 0 and 1.
%
% SYNTAX:
% [SIL,A,B] = NIAK_BUILD_SILHOUETTE(MAT,PART,[FLAG_NORMALIZE])
%
% _________________________________________________________________________
% INPUTS:
%
% MAT
%       (array, size N*N) MAT(I,J) is the similarity between units I and J.
%
% PART
%       (vector, size N*1) PART(I) is the number of the cluster unit I
%       belongs to, ie the elements of cluster K are defined by
%       FIND(PART==K).
%
% FLAG_NORMALIZE
%       (boolean, default true) If FLAG_NORMALIZE is true, the
%       normalization is applied in silhouette (Equation 1), otherwise the
%       unnormalized version is used (Equation 2).
%
% _________________________________________________________________________
% OUTPUTS :
%
% SIL
%   (vector, size N*1) SIL(I) is the silhouette of unit I.
%
% A
%   (vector, size N*1) A(I) is the average stability of I with other
%   regions in the cluster of I.
%
% B 
%   (vector, size N*1) B(I) is the maximal average stability of I with the
%   regions of any cluster that does not include I.
%  
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_AVG_SILHOUETTE, NIAK_BUILD_MAX_SIL
% _________________________________________________________________________
% COMMENTS:
%
% The similarity matrix MAT needs to be symmetrical.
%
% If 0s are found in part, the silhouette will be derived after excluding
% the corresponding regions from the analysis.
%
% _________________________________________________________________________
% REFERENCES:
%
% Peter J. Rousseuw (1987). "Silhouettes: a Graphical Aid to the
% Interpretation and Validation of Cluster Analysis". Computational and
% Applied Mathematics 20: 53–65.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap

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
    error('Syntax : SIL = NIAK_BUILD_SILHOUETTE(MAT,PART) ; for more infos, type ''help niak_build_silhouette''.')
end

if nargin < 3
    flag_normalize = true;
end
if any(part==0)
    mask_include = part~=0;
    mat = mat(mask_include,mask_include);
    part = part(mask_include);
    flag_include = true;
else
    flag_include = false;
end

N = length(part);

if (size(mat,1)~=N)||(size(mat,2)~=N)
    error('MAT should be a square N*N matrix where N is the length of PART')
end

nb_clust = max(part);

size_part = zeros([nb_clust 1]);
for num_p = 1:nb_clust
    size_part(num_p) = sum(part == num_p);
end

sil = zeros([N 1]);
a = zeros([N 1]);
b = zeros([N 1]);

if nb_clust > 1

    for num_u = 1:N

        b(num_u) = -Inf;
        for num_p = 1:nb_clust
            if num_p ~= part(num_u)
                b(num_u) = max(b(num_u),mean(mat(part==num_p,num_u)));
            end
        end

        if size_part(part(num_u)) == 1
            a(num_u) = 0; % Singleton cluster : the within-cluster similarity is set to zero to favour non-trivial clusters
        else
            a(num_u) = sum(mat(part==part(num_u),num_u));
            a(num_u) = a(num_u) - mat(num_u,num_u);
            a(num_u) = a(num_u) / (size_part(part(num_u)) - 1);
        end

        if flag_normalize
            sil(num_u) = (a(num_u) -b(num_u)) / max(a(num_u),b(num_u));
        else
            sil(num_u) = (a(num_u) -b(num_u));
        end
    end

end

if flag_include
    sil_tmp = repmat(NaN,size(mask_include));
    a_tmp   = repmat(NaN,size(mask_include));
    b_tmp   = repmat(NaN,size(mask_include));
    sil_tmp(mask_include) = sil;
    a_tmp(mask_include)   = sil;
    b_tmp(mask_include)   = sil;
    sil = sil_tmp;
    a   = a_tmp;
    b   = b_tmp;
end