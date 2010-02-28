function [mask_brain,mask_head] = niak_mask_brain_t1(anat,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_MASK_BRAIN_T1
%
% Derive a head and a brain masks from a T1 scan.
%
% SYNTAX:
% [MASK_BRAIN,MASK_HEAD] = NIAK_MASK_BRAIN_T1(ANAT,OPT)
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
%       FWHM 
%           (real value, default 6) the FWHM of the blurring kernel in 
%           the same unit as the voxel size. A value of 0 for FWHM will 
%           skip the smoothing step.
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
%   MASK_HEAD
%       (volume) a binary mask of the head.
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
%   1. Rough segmentation of the head using intensity thresholding followed
%   by morphomathematical operations.
%   
%   2. Classification of brain tissues into CSF/WM/GM using k-means.
%
%   3. Competitive region growing. The seed regions are the bigger
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
%   4. Holes in the brain mask are filled using morphomathematical
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
gb_name_structure = 'opt';
gb_list_fields = {'fwhm','voxel_size','flag_verbose'};
gb_list_defaults = {10,[1 1 1],true};
niak_set_defaults

%% A mask of the brain 
if flag_verbose
    tic;
    fprintf('Deriving a loose mask of the head ...\n')
end

% A simple intensity thresholding
if flag_verbose
    fprintf('     Simple intensity thresholding ...\n')
end
opt_mask.fwhm = 0;
mask_head = niak_mask_brain(anat,opt_mask);

% Get rid of small isolated voxels and fill the bridge between skull
% components
if flag_verbose
    fprintf('     Filling the gaps between skull components by smoothing ...\n')
end
opt_smooth.voxel_size = opt.voxel_size;
opt_smooth.fwhm = opt.fwhm;
opt_smooth.flag_edge = true;
opt_smooth.flag_verbose = false;
mask_head = niak_smooth_vol(mask_head,opt_smooth);
mask_head = mask_head>0.01;

% Fill the holes with morphomath
if flag_verbose
    fprintf('     Filling the holes in the brain with morphomath ...\n')
end
opt_m.voxel_size = opt.voxel_size;
opt_m.pad_size = 1;
opt_m.pad_order = 1;
mask_head = niak_morph(~mask_head,'-successive G',opt_m);
mask_head = round(mask_head)~=1;

% Now compute a distance transform from the outside of the brain to crop
% the effect of smoothing
if flag_verbose
    fprintf('     Using a distance transform to correct the effect of smoothing ...\n')
end
opt_m.voxel_size = opt.voxel_size;
opt_m.pad_size = 15;
opt_m.pad_order = [1 2 3];
mask_head = niak_morph(mask_head,'-successive F',opt_m);
mask_head = mask_head>10/max(voxel_size);

if flag_verbose
    fprintf('     Time elapsed %1.3f sec.\n',toc);
end

%% Get a intensity-based segmentation
if flag_verbose
    tic;
    fprintf('Deriving a segmentation of the T1 image into 3 intensity-based classes using local k-means ...\n   ')
end

% The k-means
vec_anat = anat(mask_head);
opt_kmeans.nb_iter_max = 20;
opt_kmeans.nb_classes = 3;
opt_kmeans.type_death = 'singleton';
opt_kmeans.nb_tests_cycle = 3;
part = niak_kmeans_clustering(vec_anat',opt_kmeans);
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

%% Extract a "confidence" mask by morphomat
if flag_verbose
    tic;
    fprintf('Competitive region growing starting from dense white matter regions ...\n')
end
mask_conf = false(size(mask_head));
mask_conf(mask_head) = anat(mask_head) > ((2/3)*mean_c(2)+(1/3)*mean_c(3));
opt_sdc.smooth.fwhm = 2;
opt_sdc.smooth.voxel_size = opt.voxel_size;
opt_sdc.type_neig = 6;
opt_sdc.thre_density = 0.9;
opt_sdc.nb_iter_max = 10;
opt_sdc.nb_erosions = 0;
opt_sdc.mask_extra = false(size(mask_head));
opt_sdc.mask_extra(mask_head) = (part==2)|(part==3);
opt_sdc.nb_clusters_max = 15;
mask_brain = niak_clustering_space_density(mask_conf,opt_sdc);
mask_brain = round(mask_brain)==1;

if flag_verbose
    fprintf('     Time elapsed %1.3f sec.\n',toc);
end

%% Fill the brain
if flag_verbose
    tic;
    fprintf('Filling holes in the brain ...\n')
end
mask_brain = niak_morph(mask_brain,'-successive DDD');
mask_brain = round(mask_brain);
opt_m.voxel_size = opt.voxel_size;
opt_m.pad_size = 1;
opt_m.pad_order = 1;
mask_brain = niak_morph(~mask_brain,'-successive G',opt_m);
mask_brain = round(mask_brain)~=1;
mask_brain = niak_morph(mask_brain,'-successive EEE');
mask_brain = round(mask_brain);

if flag_verbose
    fprintf('     Time elapsed %1.3f sec.\n',toc);
    fprintf('Done !\n')
end

% %% Get a intensity-based segmentation
% if flag_verbose
%     fprintf('Derive a segmentation of the T1 image into 3 intensity-based classes using local k-means ...\n   ')
% end
% opt_box.nb_box = [2 10 10];
% mask_box = niak_clustering_box(mask,opt_box);
% mask_conf = false(size(mask));
% mask_csf = false(size(mask));
% 
% for num_b = 1:max(mask_box(:))
%     mask_b = mask_box==num_b;
%     if any(mask_b(:));
%         vec_anat = anat(mask_box==num_b);
%         opt_kmeans.nb_iter_max = 20;
%         opt_kmeans.nb_classes = 3;
%         opt_kmeans.type_death = 'singleton';
%         opt_kmeans.nb_tests_cycle = 3;
%         part = niak_kmeans_clustering(vec_anat',opt_kmeans);
%         
%         %% Reorder the partition labels according to the average intensity level
%         if flag_verbose
%             fprintf('Reorder the classes according to their mean intensities ...\n')
%         end
%         mean_c = zeros([3 1]);
%         for num_c = 1:3
%             mean_c(num_c) = mean(vec_anat(part==num_c));
%         end
%         clear vec_anat
%         [mean_c,order] = sort(mean_c);
%         [val,order] = sort(order);
%         part = order(part);
%         mask_csf(mask_box==num_b) = part==1;
%         mask_conf(mask_box==num_b) = anat(mask_box==num_b)>((2/3)*mean_c(2)+(1/3)*mean_c(3));
%     end
% end

% %% Build a bias-corrected anatomical image
% mask_tissue = false(size(mask));
% mask_tissue(mask) = (part==2)|(part==3);
% map_tissue = zeros(size(mask));
% mask_tmp = false(size(mask));
% mask_tmp(mask) = part==2;
% map_tissue(mask_tmp) = anat(mask_tmp)/mean_c(2);
% mask_tmp = false(size(mask));
% mask_tmp(mask) = part==3;
% map_tissue(mask_tmp) = anat(mask_tmp)/mean_c(3);
% clear mask_tmp
% opt_smooth.flag_edge = false;
% opt_smooth.fwhm = 5;
% map_tissue_s = niak_smooth_vol(map_tissue,opt_smooth);
% mask_tissue_s = niak_smooth_vol(mask_tissue,opt_smooth);
% map_tissue_s(~mask_tissue) = 0;
% map_tissue_s(mask_tissue) = map_tissue_s(mask_tissue)./mask_tissue_s(mask_tissue);
% anat(mask_tissue) = anat(mask_tissue)./map_tissue_s(mask_tissue);
% clear mask_tissue mask_tissue_s
%
% %% Refine the GM/WM classification
% vec_anat = anat(mask);
% vec_anat = vec_anat(part~=1);
% opt_kmeans.nb_iter_max = 20;
% opt_kmeans.nb_classes = 2;
% opt_kmeans.type_death = 'singleton';
% opt_kmeans.nb_tests_cycle = 3;
% part2 = niak_kmeans_clustering(vec_anat',opt_kmeans);
% part(part~=1) = part2+1;
% clear part2 vec_anat
% 
% %% Reorder the partition labels according to the average intensity level
% if flag_verbose
%     fprintf('Reorder the classes according to their mean intensities ...\n')
% end
% vec_anat = anat(mask);
% mean_c = zeros([3 1]);
% for num_c = 1:3
%     mean_c(num_c) = mean(vec_anat(part==num_c));
% end
% [mean_c,order] = sort(mean_c);
% [val,order] = sort(order);
% part = order(part);
% clear vec_anat

% %% Build pseudo-PVE maps for each class
% pve = zeros([sum(mask(:)) 4]);
% vec_anat = anat(mask);
% med_c = zeros([4 1]);
% for num_c = 1:4
%     med_c(num_c) = median(vec_anat(part==num_c));    
%     pve(:,num_c) = 1./abs(vec_anat-med_c(num_c));
% end
% 
% pve = pve ./ repmat(sum(pve,2),[1 4]);
% anat2 = zeros(size(anat));
% anat2(mask) = pve*med_c;

% %% Extract a pure white matter mask by morphomat
% if flag_verbose
%     fprintf('Build a rough "white matter" segmentation ...\n')
% end
% mask_wm = zeros(size(mask));
% mask_wm(mask) = part==4;
% mask_wm = niak_morph(mask_wm,'-successive G');
% mask_wm = round(mask_wm);
% mask_wm = mask_wm == 1;

% %% Extract a pure cerebro-spinal fluid mask by morphomat
% if flag_verbose
%     fprintf('Build a rough "cerebro-spinal fluid" segmentation ...\n')
% end
% 
% mask_csf = false(size(mask));
% mask_csf(mask) = part==1;
% 
% %% Iterative growing : initialization
% if flag_verbose
%     fprintf('Iterative region growing of the WM segmentation using boundary conditions ...\n   ')
% end
% 
% clear opt_neig
% %mask_border = niak_build_neighbour_mask(mask,mask_conf,opt_neig); % A mask of the border
% mask_border = niak_morph(mask_conf,'-successive D -3D06');
% mask_border = round(mask_border);
% mask_border = mask_border & ~mask_conf;
% opt_neig.type_neig = 6;
% opt_neig.flag_within_mask = false;
% nb_iter_max = 25;
% std_bord = niak_mad(anat(mask_border));
% alpha = 0;
% mask_brain = mask_conf; % the brain mask initially is the wm rough segmentation
% mask_exclude = false(size(mask_brain));
% nb_iter = 1;
% 
% %% Iterative growing : the loop
% while (any(mask_border(:)))&(nb_iter<=nb_iter_max)
%     if flag_verbose
%         fprintf('%i -',nb_iter);
%     end
%     % Find the list of neighbours of voxels in the border
%     [neig_border,ind_border] = niak_build_neighbour(mask_border,opt_neig); % neighbourhood of the border
%     pos_neig = find(neig_border~=0);
%     [posx,posy] = ind2sub(size(neig_border),pos_neig);
%     ind_neig = neig_border(pos_neig); % list of neighbours in the border
%     
%     % Compute the distance between the intensity of each voxel in the border
%     % and its neighbour within the brain mask
%     mask_neig_brain = mask_brain(ind_neig); % Test if the neighbour are inside or outside the brain mask
%     mask_neig_border = mask_border(ind_neig);
%     mask_neig_out = ~(mask_neig_brain)&~(mask_neig_border);
%     dist_neig_brain = zeros([length(ind_neig) 1]);
%     dist_neig_brain(mask_neig_brain) = anat(ind_border(posx(mask_neig_brain)))-anat(ind_neig(mask_neig_brain)); % get the distance between each voxel of the border and its neighbours
%     dist_neig = zeros(size(neig_border));
%     dist_neig(pos_neig) = dist_neig_brain;
%     
%     % Exclude the voxels of the border whose value is higher on average
%     % than their neighbours within the mask
%     mask_border_exclude = mean(dist_neig,2)>alpha*(std_bord/sqrt(8));
%     mask_exclude(mask_border) = mask_exclude(mask_border)|mask_border_exclude;
%     
%     % Exclude the voxels of the border in the CSF
%     mask_border_exclude = mask_csf(mask_border);
%     mask_exclude(mask_border) = mask_exclude(mask_border)|mask_border_exclude;
%     
%     % Update the mask and the border
%     mask_border = mask_border&~mask_exclude;
%     mask_brain = mask_brain|mask_border;
%     mask_border = false(size(mask_border));
%     ind_neig2 = ind_neig(mask_neig_out&~mask_exclude(ind_border(posx)));
%     mask_border(ind_neig2) = true;
%     mask_border = mask_border&~mask_exclude;
%     nb_iter = nb_iter+1;
% end
% if flag_verbose
%     fprintf('Done !\n');
% end
