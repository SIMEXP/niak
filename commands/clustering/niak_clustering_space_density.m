function [mask_part,mask_dense] = niak_clustering_space_density(mask,opt);
%
% _________________________________________________________________________
% SUMMARY NIAK_CLUSTERING_SPATIAL_DENSITY
%
% Clustering of spatial points in 3D space using spatial density of the 
% voxels. 
%
% SYNTAX :
% PART = NIAK_CLUSTERING_SPATIAL_DENSITY(MASK,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% MASK
%       (3D binary volume) a set of 3D voxels on a regular grid.
%
% OPT
%       (structure) with the following fields (absent fields will be
%       assigned a default value):
%
%       SMOOTH
%           (structure) with the following fields : 
%
%           FWHM
%               (scalar, default 2) the FWHM of the Gaussian kernel used 
%               to define the spatial density.
%
%           VOXEL_SIZE
%               (vector [1 3], default [1 1 1]) the size of the voxels.
%
%       THRE_DENSITY
%           (scalar, default 0.8) the spatial density threshold to define
%           the core clusters.
%
%       TYPE_NEIG
%           (integer, default 26) defines the spatial neighbourhood. 
%           Available options 4 (2D), 6 (3D), 8 (2D) and 26 (3D).
%
%       NB_ITER_MAX
%           (interger, default Inf) the maximal number of iteration in the
%           region growing to propagate cluster labels
%
%       MASK_EXTRA
%           (3D binary volume) extra voxels to be classified in the region
%           growing process.
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
%   count of edges in a graph. The constructin of dense clusters as well as 
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
gb_list_fields = {'nb_iter_max','thre_density','smooth','type_neig','flag_verbose'};
gb_list_defaults = {Inf,0.9,[],26,true};
niak_set_defaults

gb_name_structure = 'opt.fwhm';
gb_list_fields = {'fwhm','voxel_size'};
gb_list_defaults = {2,[1 1 1]};
niak_set_defaults

%% Build the core clusters
if flag_verbose
    fprintf('Spatial density clustering : building dense core clusters ...\n');
end

if flag_verbose
    fprintf('   Smoothing binary map ...\n');
end
opt.smooth.flag_verbose = false;
mask_dense = niak_smooth_vol(mask,opt.smooth);

if flag_verbose
    fprintf('   Extracting connected clusters in dense voxels ...\n');
end
mask_dense = mask_dense>thre_density;
switch type_neig
    
    case 4
        arg_m = ' -2D04';
    case 6 
        arg_m = ' -3D06';
    case 8
        arg_m = ' -2D06';
    case 26
        arg_m = ' -3D26';
        
end
mask_dense = niak_morph(mask_dense,['-successive G -3D06']);
mask_dense = round(mask_dense);
nb_cores = max(mask_dense(:));
if flag_verbose
    fprintf('   %i dense core clusters were found.\n',nb_cores);
end

%% Propagate the cluster labels
if flag_verbose
    fprintf('Propagation of cluster labels ...\n');
end

mask_todo = mask&~mask_dense;
mask_part = mask_dense;
opt_neig.type_neig = type_neig;
opt_neig.flag_within_mask = false;
opt_neig.flag_position = false;

if flag_verbose
    fprintf('Percentage done : 0 - \n');
    nb_todo = sum(mask_todo);
end

if any(mask_todo(:))
    mask_border = mask_part;
    nb_iter = 1;
    while (any(mask_todo(:)))&~(nb_iter>nb_iter_max)
        mask_border_new = niak_morph(mask_border,['-successive D' arg_m]); % dilate the border
        mask_border_new(~mask_todo) = 0; % contrain the border in the "to do" mask
        mask_border_new(mask_border>0) = 0;       
        mask_part(mask_border_new>0) = mask_border_new;        
        mask_todo(mask_border_new>0) = 0;
        mask_border = mask_border_new;
        nb_iter = nb_iter+1;
    end
end
    
end
