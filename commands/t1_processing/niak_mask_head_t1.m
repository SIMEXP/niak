function mask_head = niak_mask_head_t1(anat,opt)
% Derive a head mask from a T1 scan.
%
% SYNTAX:
% MASK_HEAD = NIAK_MASK_HEAD_T1(ANAT,OPT)
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
%           (vector 1*3, default [1 1 1]) the size of the voxels.
%
%       PAD_SIZE
%           (real value, default 1.5 the THRESH_DIST converted in voxel
%           size) the number of padded slices in the distance transform.
%
%       NB_CLUSTERS_MAX
%           (integer, default 10) the number of largest connected
%           components in the mask.
%
%       THRESH_DIST
%           (real value, default 15) the distance applied to expand /
%           shrink the head mask.
%
%       FLAG_VERBOSE
%           (boolean, default 1) if the flag is 1, then the function
%           prints some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS :
%
%   MASK_HEAD
%       (volume) a binary mask of the head.
%
% _________________________________________________________________________
% SEE ALSO :
% NIAK_MASK_BRAIN, NIAK_MASK_BRAIN_T1, NIAK_BRICK_MASK_BRAIN_T1
%
% _________________________________________________________________________
% COMMENTS
%
% The steps of the segmentation are the following :
%
%   1. Extraction of a rough mask using intensity thresholding with the
%   Ostu algorithm as implemented in NIAK_MASK_BRAIN
%
%   2. Keep the largest NB_CLUSTERS spatially connected clusters
%
%   3. Expanding the mask with a distance transform (max distance from the
%   mask is THRESH_DIST).
%
%   4. Closure on the mask using morphomath.
%
%   5. Shrinkage of the mask with a distance transform (max distance from
%   ~mask is THRESH_DIST).
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
gb_list_fields = {'voxel_size','flag_verbose','pad_size','thresh_dist','nb_clust_max'};
gb_list_defaults = {[1 1 1],true,[],15,10};
niak_set_defaults

opt_neig.type_neig = 6;
opt_neig.flag_int = false;

if isempty(pad_size)
    pad_size = ceil((1.5 * opt.thresh_dist)/min(voxel_size));
end
opt_m.voxel_size = opt.voxel_size;
opt_m.pad_size = pad_size;
opt_pad.pad_size = pad_size;

if flag_verbose
    tstart = tic;
    fprintf('Deriving a loose mask of the head ...\n')
end

%% Intensity thresholding
if flag_verbose
    fprintf('     Intensity thresholding ...')
end
tic;
opt_mask.fwhm = 0;
mask_head = niak_mask_brain(anat,opt_mask);
if pad_size>0
    mask_head = niak_pad_vol(mask_head,opt_pad);
end
if flag_verbose
    fprintf(' %1.2f sec\n',toc);
end

%% Get rid of small clusters
if flag_verbose
    fprintf('     Sieving small clusters ...')    
end
tic;
mask_head = niak_find_connex_roi(mask_head,opt_neig);
size_roi = niak_build_size_roi(mask_head);
[val,ind] = max(size_roi);
size_mask_head = size(mask_head);
mask_head = reshape(ismember(mask_head,ind(1:min(length(ind),nb_clust_max))),size_mask_head);
if flag_verbose
    fprintf(' %1.2f sec\n',toc);
end

%% Expanding the mask
if flag_verbose
    fprintf('     Expanding and inverting the brain ...')    
end
tic;
mask_head = niak_morph(~mask_head,'-distance',opt_m);
mask_head = mask_head>=ceil(opt.thresh_dist/max(voxel_size));
if flag_verbose
    fprintf(' %1.2f sec\n',toc);
end

%% Fill the holes with morphomath
if flag_verbose
    fprintf('     Finding the outside of the brain ...')
end
tic;
mask_head = niak_find_connex_roi(mask_head,opt_neig);
size_roi = niak_build_size_roi(mask_head);
[val,ind] = max(size_roi);
mask_head = mask_head==ind;
if flag_verbose
    fprintf(' %1.2f sec\n',toc);
end

%% Now shrink the mask back to correct the expansion
if flag_verbose
    fprintf('     Inverting and shrinking the outside of the brain ...')
end
tic;
mask_head = niak_morph(~mask_head,'-distance',opt_m);
mask_head = mask_head>=ceil(opt.thresh_dist/max(voxel_size));

if pad_size>0
    mask_head = niak_unpad_vol(mask_head,pad_size);
end
if flag_verbose
    fprintf(' %1.2f sec\n',toc);
end

if flag_verbose
    fprintf('Total time elapsed %1.3f sec.\n',toc(tstart));
end