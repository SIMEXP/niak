function [mask_part,mask_dense] = niak_clustering_space_density(mask,mask_extra,opt);
%
% _________________________________________________________________________
% SUMMARY NIAK_CLUSTERING_SPACE_DENSITY
%
% Clustering of spatial points in 3D space using spatial density of the
% voxels.
%
% SYNTAX :
% PART = NIAK_CLUSTERING_SPACE_DENSITY(MASK,MASK_EXTRA,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% MASK
%       (3D binary volume) a set of 3D voxels on a regular grid.
%
% MASK_EXTRA
%       (3D volume)  extra voxels to be classified in the region
%       growing process but not in the density estimation. Empty values 
%       will result in no extra voxels.
%
% OPT
%       (structure) with the following fields (absent fields will be
%       assigned a default value):
%
%       NB_EROSIONS
%           (integer, default 0) number of erosions to apply on the mask
%           before defining the spatial density.
%
%       THRE_DENSITY
%           (scalar, default 0.9) the spatial density threshold to define
%           the core clusters.
%
%       TYPE_NEIG_GROW
%           (integer, default 6) defines the spatial neighbourhood in the
%           region growing.
%           Available options 4 (2D), 6 (3D), 8 (2D) and 26 (3D).
%
%       NB_ITER_MAX
%           (integer, default Inf) the maximal number of iteration in the
%           region growing to propagate cluster labels
%
%       NB_CLUSTERS_MAX
%           (integer, default 15) the maximal number of clusters.
%
%       FLAG_VERBOSE
%           (boolean, default 1) if the flag is 1, then the function prints
%           some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% MASK_PART
%       (3D volume) voxels of partition number I is filled with Is, i.e.
%       (MASK_PART==I) is a binary mask of the Ith cluster
%
% MASK_DENSE
%       (3D volume) same as MASK_PART, but only the dense core are
%       represented.
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1 :
%
%   The Outline of the algorithm is as follows. It not for the spatial
%   density idea, the clustering would simply consist in extracting
%   connected components according to a spatial neghbourhood rules.
%   The extraction of connected components is actually applied only to
%   the voxels that have a sufficient number of neighbours. Each of these
%   dense connected components are then growing to propagate their labels
%   to the remaining non-dense voxels. At each iteration, conflicts are
%   solved using the order of size to define precedence of dense clusters.
%   Note that this procedure implicitely defines the number of clusters.
%
% NOTE 2 :
%
%   The principles of this algorithm are a simple adaption of the DBSCAN
%   algorithm :
%
%   Martin Ester, Hans-Peter Kriegel, Jörg Sander, Xiaowei Xu (1996).
%   "A density-based algorithm for discovering clusters in large spatial
%   databases with noise"
%   in Evangelos Simoudis, Jiawei Han, Usama M. Fayyad.
%   Proceedings of the Second International Conference on Knowledge
%   Discovery and Data Mining (KDD-96). AAAI Press. pp. 226–231.
%   ISBN 1-57735-004-9.
%   http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.71.1980.
%
%   The difference is that the density of the neighbourhood of a voxel is
%   defined by spatial smoothing using a Gaussian kernel rather than actual
%   count of edges in a graph. The construction of dense clusters and
%   the propagation of labels to non-dense voxels falls within the DBSCAN
%   algorithm, except that the current implementation fixes an order on the
%   label propagation, while the original version algorithm depended on an
%   arbitrary order of visit of the voxels.
%
% Copyright (c) partierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
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
% THE SOFTWARE IS partROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EdatapartRESS OR
% IMpartLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A partARTICULAR partURpartOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COpartYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'nb_clusters_max','nb_erosions','nb_iter_max','thre_density','type_neig_grow','flag_verbose'};
gb_list_defaults = {15,0,Inf,0.9,6,true};
niak_set_defaults

gb_name_structure = 'opt.fwhm';
gb_list_fields = {'fwhm','voxel_size'};
gb_list_defaults = {2,[1 1 1]};
niak_set_defaults

switch type_neig_grow
    case 4
        arg_m = ' -2D04';
    case 6
        arg_m = ' -3D06';
    case 8
        arg_m = ' -2D06';
    case 26
        arg_m = ' -3D26';
end

%% Build the core clusters
if flag_verbose
    fprintf('     Building a spatial density map ...\n');
end

if nb_erosions>0
    mask_dense = niak_morph(mask,['-successive ' repmat('E',[1 nb_erosions]) arg_m]);
else
    mask_dense = mask;
end
if ~exist('smooth3','file')
    mask_dense(mask) = sub_density(mask,26)>thre_density;
else
    mask_dense = smooth3(mask_dense,'box',3)>thre_density;
end
mask_dense = mask_dense&mask;

if flag_verbose
    fprintf('     Extracting connected clusters in dense voxels ...');
end
if ~exist('bwconncomp','file')
    mask_dense = niak_morph(mask_dense,['-successive G' arg_m]);
    mask_dense = round(mask_dense);
    mask_dense(mask_dense>nb_clusters_max) = 0;
    nb_cores = max(mask_dense(:));
else
    cc = bwconncomp(mask_dense);
    size_roi = cellfun('length',cc.PixelIdxList);
    [val,order] = sort(size_roi,'descend');
    mask_dense = zeros(size(mask_dense));
    nb_cores = min(nb_clusters_max,length(order));
    for num_c = 1:nb_cores
        mask_dense(cc.PixelIdxList{order(num_c)}) = num_c;
    end
    clear cc
end
if flag_verbose
    fprintf(' %i dense core clusters were found.\n',nb_cores);
end

%% Propagate the cluster labels
if flag_verbose
    fprintf('     Propagation of cluster labels, number of iterations : 0 - ');
end

mask_todo = mask&~mask_dense;
mask_part = mask_dense;
if ~isempty(mask_extra)
    mask_todo = mask_todo|mask_extra;
end

if exist('imdilate','file')
    str_el = sub_strel(type_neig_grow);
end

if any(mask_todo(:))
    mask_border = mask_part;
    nb_iter = 0;
    while (any(mask_border(:)))&&~(nb_iter>nb_iter_max)
        if exist('imdilate','file')
            mask_border_new = imdilate(mask_border,str_el);
        else
            mask_border_new = niak_morph(mask_border,['-successive D' arg_m]); % dilate the border
            mask_border_new = round(mask_border_new);
        end
        mask_border_new(~mask_todo) = 0; % contrain the border in the "to do" mask
        mask_border_new(mask_part>0) = 0;
        mask_border_new(mask_border>0) = 0;
        mask_part(mask_border_new>0) = mask_border_new(mask_border_new>0);
        mask_todo(mask_border_new>0) = 0;
        mask_border = mask_border_new;
        nb_iter = nb_iter+1;
        if flag_verbose&&~(nb_iter>nb_iter_max)
            fprintf('%i - ',nb_iter);
        end
    end
end

if flag_verbose
    fprintf('Done !\n');
end

function str_el = sub_strel(type_neig)
str_el = zeros([3 3 3]);
if type_neig == 6;
    str_el(:,:,1) = [0 0 0; 0 1 0; 0 0 0];
    str_el(:,:,2) = [0 1 0; 1 0 1; 0 1 0];
    str_el(:,:,3) = [0 0 0; 0 1 0; 0 0 0];
elseif type_neig == 26
    str_el(:,:,1) = ones([3 3]);
    str_el(:,:,2) = [1 1 1; 1 0 1; 1 1 1];
    str_el(:,:,3) = ones([3 3]);
end

function vec_dense = sub_density(mask,type_neig)

decxyz = niak_build_neighbour_mat(type_neig);
nb_n = size(decxyz,1);
opt_neig.ind = find(mask);
[coordx,coordy,coordz] = ind2sub(size(mask),opt_neig.ind);
opt_neig.coord = [coordx,coordy,coordz];
clear coordx coordy coordz
opt_neig.type_neig = type_neig;
opt_neig.flag_position = true;
opt_neig.flag_within_mask = true;

for num_n = 1:nb_n
    opt_neig.decxyz = decxyz(num_n,:);
    neig = niak_build_neighbour(mask,opt_neig);
    if num_n == 1
        vec_dense = double(neig>0)+1;
    else
        vec_dense = vec_dense + (neig>0);
    end
end
vec_dense = vec_dense/(nb_n+1);