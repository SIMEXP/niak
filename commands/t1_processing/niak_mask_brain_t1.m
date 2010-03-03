function mask_brain = niak_mask_brain_t1(anat,mask_head,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_MASK_BRAIN_T1
%
% Derive a head and a brain masks from a T1 scan.
%
% SYNTAX:
% MASK_BRAIN = NIAK_MASK_BRAIN_T1(ANAT,MASK_HEAD,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
%   ANAT
%       (3D volume) a T1 volume of a brain.
%
%   OPT
%       (structure) with the following fields.
%
%       VOXEL_SIZE
%
%       COEFF_GM
%
%       KMEANS
%           (structure) with the following fields :
%
%           NB_ITER_MAX
%               (integer, default 10) the maximal number of iterations in
%               the k-means classification.
%
%           TYPE_DEATH
%               (string, default 'singleton') see NIAK_KMEANS_CLUSTERING.
%
%           NB_TESTS_CYCLE
%               (integer, default 2) the number of partitions kept in
%               memory to test for cycles.
%
%       REGION_GROWING
%           (structure) with the following fields :
%
%           See the OPT field in NIAK_CLUSTERING_SPACE_DENSITY.
%
%   
%       FILL_HOLES
%           (structure) with the following fields : 
%
%       FLAG_VERBOSE
%           (boolean, default 1) if the flag is 1, then the function
%           prints some infos during the processing.
%
%       FLAG_TEST
%           (boolean, default 0) if FLAG_TEST equals 1, the brick does not
%           do anything but update the default values in FILES_IN,
%           FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS :
%
%   MASK_BRAIN
%       (volume) a binary mask of the brain tissues, i.e. gray matter,
%       white matter and inner CSF. Ideally, the veinous sinus and dura
%       should be stripped out, but some of it may be included in the mask.
%       The skull and fat should be masked out.
%
% _________________________________________________________________________
% SEE ALSO :
% NIAK_MASK_BRAIN, NIAK_BRICK_MASK_BRAIN_T1, NIAK_CLUSTERING_SPACE_DENSITY
%
% _________________________________________________________________________
% COMMENTS
%
% The algorithm is similar conceptually to the competitive region growing
% approach proposed in :
%
% J. G. Park & C. Lee (2009). `Skull stripping based on region growing for
% magnetic resonance brain images'. NeuroImage 47(4):1394-1407.
%
% The actual implementation was still markedly different. It is 3D rather
% than 2D, thresholding operations are performed using adaptative
% classification rather than a priori choices, and the competitive region
% growing algorithm exploits the concept of spatial density rather than more
% standard morphomathematical operations. Specifically, the main stages are
% the following :
%
%   1. Classification of brain tissues into CSF/WM/GM using k-means.
%
%   2. Competitive region growing. The seed regions are the bigger
%   connected components within the dense portions of the grey matter. This
%   method is known as DBSCAN and has been proposed in :
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
%   3. Holes in the brain mask are filled using morphomathematical
%   operations.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, t1, mask, segmentation

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Options
opt_tmp.flag_verbose = 1;

gb_name_structure = 'opt';
gb_list_fields = {'region_growing','kmeans','head','voxel_size','flag_verbose'};
gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,[1 1 1],true};
niak_set_defaults

gb_name_structure = 'opt.kmeans';
gb_list_fields = {'flag_verbose','nb_iter_max','nb_tests_cycle','type_death'};
gb_list_defaults = {opt.flag_verbose,10,2,'singleton'};
niak_set_defaults
opt.kmeans.flag_verbose = opt.flag_verbose;

gb_name_structure = 'opt.region_growing';
gb_list_fields = {'flag_verbose','type_neig_dense','type_neig_grow','thre_density','nb_iter_max','nb_erosions','nb_clusters_max'};
gb_list_defaults = {opt.flag_verbose,26,6,0.75,10,0,10};
niak_set_defaults
opt.region_growing.flag_verbose = opt.flag_verbose;

gb_name_structure = 'opt.fill_holes';
gb_list_fields = {'voxel_size','flag_verbose','pad_size','thresh_dist'};
gb_list_defaults = {opt.voxel_size,opt.flag_verbose,[],10};
niak_set_defaults

flag_verbose = opt.flag_verbose;


%% Get a intensity-based segmentation
if flag_verbose
    tic;
    fprintf('Deriving a segmentation of the T1 image into 3 intensity-based classes using local k-means ...\n   ')
end

% The k-means
vec_anat = anat(mask_head);
opt.kmeans.nb_classes = 3;
opt.kmeans.type_init = 'user-specified';
med_head = median(anat(mask_head));
max_head = max(anat(mask_head));
opt.kmeans.init = [0 med_head (med_head+max_head)/2];
part = niak_kmeans_clustering(vec_anat',opt.kmeans);
clear vec_anat

% Reorder the classes according to their mean intensities
if flag_verbose
    fprintf('     Reordering the classes according to their mean intensities ...\n')
end
vec_anat = anat(mask_head);
mean_c = zeros([3 1]);
for num_c = 1:3
    mean_c(num_c) = mean(vec_anat(part==num_c));
end
[mean_c,order] = sort(mean_c);
[val,order] = sort(order);
part = order(part);
clear vec_anat

if flag_verbose
    fprintf('     Time elapsed %1.3f sec.\n',toc);
end

%% Extract the brain mask using competitive region growing
if flag_verbose
    tic;
    fprintf('Competitive region growing starting from dense white matter regions ...\n')
end
mask_conf = false(size(mask_head));
mask_conf(mask_head) = anat(mask_head) > ((2/3)*mean_c(2)+(1/3)*mean_c(3));
mask_extra = false(size(mask_head));
mask_extra(mask_head) = (part==2)|(part==3);

mask_brain = niak_clustering_space_density(mask_conf,mask_extra,opt.region_growing);
mask_brain = round(mask_brain)==1;

if flag_verbose
    fprintf('     Time elapsed %1.3f sec.\n',toc);
end

%% Fill the brain
if flag_verbose
    tic;
    fprintf('Filling holes in the brain ...\n')
end

if isempty(pad_size)
    pad_size = ceil((1.5 * opt.fill_holes.thresh_dist)/min(voxel_size));
end
opt_m.voxel_size = opt.voxel_size;
opt_m.pad_size = pad_size;
if flag_verbose
    fprintf('     Expanding the brain ...\n')
end
mask_brain = niak_morph(~mask_brain,'-successive F',opt_m);
mask_brain = mask_brain>=(opt.fill_holes.thresh_dist/max(voxel_size));

if flag_verbose
    fprintf('     Finding the outside of the brain ...\n')
end
mask_brain = niak_morph(mask_brain,'-successive G',opt_m);
mask_brain = round(mask_brain)~=1;

if flag_verbose
    fprintf('     Shrinking the brain back...\n')
end
mask_brain = niak_morph(mask_brain,'-successive F',opt_m);
mask_brain = mask_brain>opt.fill_holes.thresh_dist/max(voxel_size);

if flag_verbose
    fprintf('     Time elapsed %1.3f sec.\n',toc);
    fprintf('Done !\n')
end
