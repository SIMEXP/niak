function match = niak_match_part(part1,part2)
% Establish a correspondance between two clustering
%
% SYNTAX:
% MATCH = NIAK_M(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
%   PART<1,2> (vector 1xN) (PART1 == I) defines the Ith region of PART1 (same
%      for PART2). Note that any region labels can be used, e.g. 0, 1, 2, etc 
%      or 0, 3, 7, etc or 99100, 99101, etc
%
% OUTPUT:
%   MATCH.INDl<1,2> (vector 1xK<1,2>) is the list of cluster in PART<1,2> 
%      This is the result of find(part<1,2>
%   MATCH.OVLP (vector 1xK2) OVLP(k) is the maximal overlap between the kth 
%      cluster in PART2 and a cluster of PART1.
%   MATCH.IND2_to_1 (vector 1xK2) IND12(k) is the index of the cluster in PART1 
%      that best overlap with cluster IND2(k) in PART2.
%   MATCH.PART2_to_1 (vector 1xN) PART2_to_1(n) is IND2_to_1(k), where PART2(n) is 
%      equal to IND2(k).
%      
% NOTE:
%   PART1 and PART2 can also be N-dimensional array, e.g. an image, a volume, etc.
%
% EXAMPLE:
%   f = fspecial('average', 3);
%   data = imfilter(rand(8,8),f,'same');
%   part1 = reshape(niak_kmeans_clustering(data(:)',struct('nb_classes',2)),size(data));
%   part2 = reshape(niak_kmeans_clustering(data(:)',struct('nb_classes',4)),size(data));
%   match = niak_match_part(part1,part2);
%   figure
%   subplot(1,3,1)
%   imagesc(part1)
%   title('part1 (2 clusters)');
%   subplot(1,3,2)
%   imagesc(part2)
%   title('part2 (4 clusters)');
%   subplot(1,3,3)
%   imagesc(match.part2_to_1)
%   title('part2\_to\_1');
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, 
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, hierarchy, subclusters

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

size_part1 = size(part1);
size_part2 = size(part2);
if (length(part1)~=length(part2))||~min(size_part1==size_part2)
    error('PART1 and PART2 should have the same size');
end

% Extract label information for both partition
part1 = part1(:);
part2 = part2(:);
ind1 = unique(part1);
ind2 = unique(part2);
k1 = length(ind1);
k2 = length(ind2);

ovlp = zeros(1,k2);
ind2_to_1 = zeros(1,k2);
for kk = 1:k2
    mask_kk = part2==ind2(kk);
    ind_ovlp = unique(part1(mask_kk));
    size_kk = sum(mask_kk);
    k12 = length(ind_ovlp);
    ovlp_tmp = zeros(1,k12);
    for ll = 1:k12
        ovlp_tmp(ll) = sum(part1(mask_kk)==ind_ovlp(ll))/k12;
    end
    [ovlp(kk),ind_max] = max(ovlp_tmp);
    ind2_to_1(kk) = ind_ovlp(ind_max(ceil(length(ind_max)*rand(1))));
end

part2_to_1 = zeros(size(part2));
for kk = 1:k2
    part_2_to_1(part2==ind2(kk)) = ind2_to_1(kk);
end

match.ind1 = ind1;
match.ind2 = ind2;
match.ovlp = ovlp;
match.ind2_to_1 = ind2_to_1;
match.part2_to_1 = reshape(part_2_to_1,size_part2);
