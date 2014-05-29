function [part] = niak_kmeans_cores(data,target, target_scale)
% k-means clustering.
%
% SYNTAX :
% [PART] = NIAK_KMEANS_CORES(DATA,TARGET);
%
% _________________________________________________________________________
% INPUTS:
%
% DATA
%       (2D array T*N)
%
% TARGET
%       (partition vector of length N) where max(TARGET) denotes the scale
%       of the partition
%
% TARGET_SCALE
%       (integer, optional) contains the scale of the 
%       target partition
%
% _________________________________________________________________________
% OUTPUTS:
%
% PART
%       (vector N*1) partition (find(part==i) is the list of regions belonging
%       to cluster i.
%
% _________________________________________________________________________
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Gériatrie de Montréal
%   Département d'informatique et de recherche opérationnelle
%   Université de Montréal, 2010-2014
%   Montreal Neurological Institute, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, kmeans, cores

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
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%% Options
if (nargin < 3)
   error('Required input not specified for niak_kmeans_cores. Usage: NIAK_KMEANS_CORES(DATA,TARGET, TARGET_SCALE)');
end

[Dt, Dn] = size(data);
Tn = length(target);
if Dn ~= Tn
    error('Target and data must have the same number of regions');
end

store = zeros(target_scale, Tn);

%% Find the clusters in the data that correspond best to the target
for tar_clust = 1:target_scale
    % Check if the current cluster has any elements
    if ~any(target==tar_clust)
        % Cluster is empty, create an empty map
        store(tar_clust,:) = 0;
    else
        % use the current target cluster as a seed on the data
        seed_glob = mean(data(:, target==tar_clust),2);
        corr_map_glob = corr(seed_glob, data);
        % Build the core of the correlation map with a 3 kmeans clustering
        core_opt = struct;
        core_opt.nb_classes = 3;
        k_ind = niak_kmeans_clustering(corr_map_glob, core_opt);
        % Find the cluster with the highest average connectivity
        k_mean = zeros(3,1);
        for i = 1:3
            k_mean(i,1) = mean(corr_map_glob(k_ind == i));
        end
        [~, k_tar] = max(k_mean);
        % Seed again on the individual core
        t_seed_ind = mean(data(:, k_ind==k_tar), 2);
        corr_map_ind = corr(t_seed_ind, data);
        % Store the vectorized map
        store(tar_clust,:) = corr_map_ind;
    end
end
    
% Find the target cluster that has the maximal correlation map with each 
% location and assign the location to it
[~, part] = max(store);
