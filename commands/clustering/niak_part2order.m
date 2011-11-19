function [order,part_order,order_c] = niak_part2order(part,S);
% Order objects based on a partition
% 
% SYNTAX :
% [ORDER,PART_ORDER,ORDER_C] = NIAK_PART2ORDER(PART,S)
% 
% _________________________________________________________________________
% INPUTS :
%
% PART
%       (vector length N) find(PART==I) defines the elements in cluster I
%
% S
%       (array, size N*N) a similarity matrix on which the clustering is
%       based.
%
% _________________________________________________________________________
% OUTPUTS :
%
% ORDER     
%       (vector) defines a permutation on the objects to maximize
%       similarity between neighbours.
%
% PART_ORDER
%       (vector) same as part, but the clusters have been re-ordered to
%       match the order found in ORDER.
%
% ORDER_C
%		(vector) defines the order on the cluster.
% _________________________________________________________________________
% COMMENTS :
%
% The algorithm is as follows. First the average similarity between 
% clusters is derived. The cluster with largest difference between his most
% similar alter-cluster and his second most similar alter-cluster is
% selected to initialize a chain. Iteratively, for each element of the
% chain, the most similar alter-cluster is selected as the next element of
% the chain, after eliminating all preceding member of the chain from the
% competition.
% 
% Then, for each cluster D and for each point x in D, let s(x,C1) and 
% s(x,C2) be the average similarity between x and the points in C1 and 
% C2 respecitvely, where C1, C2 are the "neighbours" of cluster D. The 
% values s(x,C1)-s(x,C2) are sorted (ascending order) and define the 
% order of points within D. Note that if C1 or C2 are undefined (D is 
% the first or the last cluster), y1 or y2 is defined as 0.
%
% If some elements of PART equal 0, these points will be absent of ORDER
% and will be ignored in the computation.
%
% Copyright (c) Pierre Bellec, 2011
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering

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

if max(part)==1
    order = 1:length(part);
    order_c = 1;    
    part_order = part;
    return
end

if length(unique(part(part>0)))~=max(part(part>0))
    tmp = zeros([max(part) 1]);
    ind = 1:length(unique(part));
    if any(part==0)
        ind = ind - 1;
        tmp(unique(part)+1) = ind;
        part = tmp(part+1);
    else
        tmp(unique(part)) = ind;
        part = tmp(part);
    end                
end
nb_classes = max(part);
N = sum(part>0);

%% First, sort clusters 
part_order = zeros([1 length(part)]);
S_c = zeros([nb_classes nb_classes]);
for num_c1 = 1:nb_classes
    S_c(num_c1,num_c1) = -Inf;
    for num_c2 = 1:(num_c1-1)
        S_c(num_c1,num_c2) = mean(mean(S(part==num_c1,part==num_c2)));
        S_c(num_c2,num_c1) = S_c(num_c1,num_c2);
    end
end
order_c = zeros([1 nb_classes]);
for num_c = 1:(nb_classes-1)    
    if num_c == 1
        val = sort(S_c,1,'descend');
        val = val(1,:)-val(2,:);
        [val,ind1] = max(val);
        [val,ind2] = max(S_c(ind1,:));
        order_c(num_c) = ind1;
        part_order(part==ind1) = num_c;
        order_c(num_c+1) = ind2;
        part_order(part==ind2) = num_c+1;
    else
        ind1 = order_c(num_c);
        [val,ind2] = max(S_c(ind1,:));        
        order_c(num_c+1) = ind2;
        part_order(part==ind2) = num_c+1;
    end    
    S_c(ind1,:) = -Inf;
    S_c(:,ind1) = -Inf;
end
        
%% Now sort points in clusters
order = zeros([1 N]);
nb_point = 0;
size_classes = niak_build_size_roi(part);
for num_c = 1:length(order_c)
    label_c = order_c(num_c);
    ind = (1+nb_point):(size_classes(label_c)+nb_point);
    ind_c = find(part==label_c);
    if num_c == 1
        x = 0;
        y = mean(S(part == label_c,part == label_c),2)-mean(S(part == label_c,part == order_c(num_c+1)),2);
    elseif num_c == length(order_c)
        x = mean(S(part == label_c,part == label_c),2)-mean(S(part == label_c,part == order_c(num_c-1)),2);
        y = 0;
    else
        x = mean(S(part == label_c,part == label_c),2)-mean(S(part == label_c,part == order_c(num_c-1)),2);
        y = mean(S(part == label_c,part == label_c),2)-mean(S(part == label_c,part == order_c(num_c+1)),2);
    end
    sc = x-y;
    [tmp,order_tmp] =  sort(sc);
    order(ind) = ind_c(order_tmp);
    nb_point = nb_point + length(ind_c);
end
