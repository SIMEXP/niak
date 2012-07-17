function [partition_cores,partition_adjusted,partition_threshold,stability_maps,stability_map_all] = niak_build_stability_maps(part,S,opt)
% Build stability maps and stable cores of a partition.
%
% SYNTAX:
% [STAB_MAPS,STAB_MAPS_ALL,PART_CORES,PART_FINAL] =
% NIAK_BUILD_STABILITY_MAPS(PART,S)
%
% _________________________________________________________________________
% INPUTS:
%   
% PART
%   (vector N*1) PART==I defines the Ith cluster
%
% S
% 	(matrix N*N) S(R,T) is the stability between regions R and T.
%
% OPT
%   (structure) with the following fields.  
%
%   PERCENTILE
%       (string, default 0.5) Value (0 to 1) percentile of stable
%       regions used to build stability maps.
%
%   MIN_SIZE_CORE
%       (integer, default 2) the minimum size of a stability core in terms 
%       of number of atoms (unless the cluster is smaller than the number 
%       specified)
%
%   THRESHOLD
%       (scalar, default 0.5) the threshold to be applied on the stability map to generate
%       the threshold version of the adjusted partition.
%
%   FLAG_VERBOSE
%       (boolean, default true) if FLAG_VERBOSE is true, the function
%       prints some advancement infos.
%
% _________________________________________________________________________
% OUTPUTS:
%   
% PARTITION_CORES
%   (vector N*1) PARTITION_CORES is the core of the consensus partition, 
%   which is to say the OPT.PERCENTILE regions of each cluster that have 
%   the highest average stability with that cluster.
%
% PARTITION_ADJUSTED
%   (vector N*1) PARTITION_ADJUSTED is a partition where each voxel is 
%   associated with the core cluster with maximal average stability with 
%   this voxel, for K clusters.
%
% PARTITION_THRESHOLD
%   (vector N*1) PARTITION_ADJUSTED is a partition identical to 
%   PARTITION_ADJUSTED, except that only those voxels with a stability 
%   score greater than OPT.THRESHOLD in STABILITY_MAP_ALL are assigned to 
%   a cluster. Other voxels have a value of zero.
%
% STABILITY_MAPS
%   (array N*K) STAB_MAPS(K,:) is the stability map associated with the 
%   stable core of cluster K.
%
% STABILITY_MAP_ALL
%   (vetor N*1) STABILITY_MAP_ALL(I) is 
%   STABILITY_MAPS(I,PARTITION_ADJUSTED(I)), i.e. the value of the 
%   stability map associted with the adjusted cluster that includes I.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_STABILITY_MAPS
%
% _________________________________________________________________________
% COMMENTS:
%
% The stable core of a clustering is defined as follows. First, the average
% stability between each region and its cluster is derived. Then, regions
% are ordered by decreasing average stability. The first OPT.PERCENTILE 
% portion of these regions define the stable core of the region.
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal, 2010-2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : stability, maps, clustering, BASC

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

list_fields   = {'flag_verbose' , 'percentile' , 'min_size_core' , 'threshold' };
list_defaults = {true           , 0.5          , 2               , 0.5         };
if nargin < 3
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
else
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
end

%% generate stability maps
K = max(part);
N = length(part);

if (size(S,1)==1)||(size(S,2) == 1)
    S = niak_vec2mat(S);
end

if (size(S,1)~=N)||size(S,2)~=N
    error('The stability matrix should be N*N, where N is the length of PART')
end

if opt.flag_verbose
    fprintf('Generating stable cores and associated maps, cluster : ');
end
partition_cores      = zeros([N 1]); % The stable cores
stability_maps       = zeros([N K]); % Stability maps
stability_map_all    = zeros([N 1]); % compound stability map
for num_c = 1:K
    if opt.flag_verbose
        fprintf(' %i',num_c);
    end   
    stab_vec = mean(S(part==num_c,part==num_c),2); % Average stability within the cluster
    [tmp,order] = sort(stab_vec,'descend'); % Sort regions by decreasing average stability    
    ind_c = find(part==num_c); % Get the indices of regions
    nb_atoms_core = min(max(ceil(opt.percentile * length(order)),opt.min_size_core),length(order));
    ind_core = ind_c(order(1:nb_atoms_core)); % Keep a set percentage of the most stable regions
    partition_cores(ind_core) = num_c; % Build a vector of the core regions        
    stability_maps(partition_cores~=num_c,num_c) = mean(S(partition_cores~=num_c,partition_cores==num_c),2);
    if sum(partition_cores==num_c)~=1
        stability_maps(partition_cores==num_c,num_c) = (sum(S(partition_cores==num_c,partition_cores==num_c),2)-1)/(sum(partition_cores==num_c)-1);
    end        
end

if opt.flag_verbose
    fprintf('\nDone !\n');
end

[stability_map_all,partition_adjusted] = max(stability_maps,[],2);
partition_threshold = partition_adjusted;
partition_threshold(stability_map_all<opt.threshold) = 0;
