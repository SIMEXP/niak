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
%       FLAG_MINCMORPH
%           (boolean, default false) force usage of the MINCMORPH tool to
%           perform the operation of extracting all morphomath operations.
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
gb_list_fields = {'flag_mincmorph','voxel_size','flag_verbose','pad_size','thresh_dist','nb_clust_max'};
gb_list_defaults = {false,[1 1 1],true,[],15,10};
niak_set_defaults

opt_neig.type_neig = 6;
opt_neig.flag_int = false;

if isempty(pad_size)
    pad_size = ceil((1.5 * opt.thresh_dist)/min(voxel_size));
end
opt_m.voxel_size = opt.voxel_size;
opt_m.pad_size = pad_size;

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

if pad_size>0
    mask_head = sub_pad(mask_head,pad_size);
end

%% Get rid of small clusters
if flag_verbose
    fprintf('     Sieving small clusters ')
end
if ~exist('bwlabel','file')||flag_mincmorph
    if flag_verbose
        fprintf('using MINCMORPH ...\n')
    end            
    mask_head = niak_morph(mask_head,'-successive PG');
    mask_head = round(mask_head);
    mask_head(mask_head>nb_clust_max) = 0;
else
    if flag_verbose
        fprintf('using NIAK_FIND_CONNEX_ROI ...\n')
    end
    mask_head = niak_find_connex_roi(mask_head,opt_neig);
    size_roi = niak_build_size_roi(mask_head);
    [val,ind] = max(size_roi);
    mask_head = ismember(mask_head,ind(1:min(length(ind),nb_clust_max)));    
end

%% Expanding the mask
if flag_verbose
    fprintf('     Expanding the mask using a distance transform ')
end
if ~exist('bwdist','file')||exist('OCTAVE_VERSION','builtin')||flag_mincmorph
    if flag_verbose
        fprintf('using MINCMORPH ...\n')
    end        
    mask_head = niak_morph(~mask_head,'-successive F',opt_m);
else
    if flag_verbose
        fprintf('using BWDIST ...\n')
    end
    mask_head = bwdist(mask_head);
end
mask_head = mask_head>=(opt.thresh_dist/max(voxel_size));

%% Fill the holes with morphomath
if flag_verbose
    fprintf('     Filling the holes in the brain with morphomath ')
end

if ~exist('bwlabel','file')||flag_mincmorph
    if flag_verbose
        fprintf('using MINCMORPH ...\n')
    end
    mask_head = niak_morph(mask_head,'-successive G',opt_m);
    mask_head = round(mask_head)==1;
else
    if flag_verbose
        fprintf('using NIAK_FIND_CONNEX_ROI ...\n')
    end
    mask_head = niak_find_connex_roi(mask_head,opt_neig);
    size_roi = niak_build_size_roi(mask_head);
    [val,ind] = max(size_roi);
    mask_head = mask_head==ind;
end

%% Now shrink the mask back to correct the expansion
if flag_verbose
    fprintf('     Using a distance transform to correct the effect of expansion ')
end
if ~exist('bwdist','file')||exist('OCTAVE_VERSION','builtin')||flag_mincmorph
    if flag_verbose
        fprintf('using MINCMORPH ...\n')
    end
    mask_head = niak_morph(~mask_head,'-successive F',opt_m);
    mask_head = mask_head>=((opt.thresh_dist)/max(voxel_size));
else
    if flag_verbose
        fprintf('using BWDIST ...\n')
    end
    mask_head = bwdist(mask_head);
    mask_head = mask_head>=((opt.thresh_dist)/max(voxel_size));
end

if pad_size>0
    mask_head = sub_unpad(mask_head,pad_size);
end

if flag_verbose
    fprintf('Time elapsed %1.3f sec.\n',toc);
end

function vol_m = sub_pad(vol,pad_size)
pad_order = [3 2 1];
vol_m = zeros(size(vol)+2*pad_size);
vol_m(pad_size+1:pad_size+size(vol,1),pad_size+1:pad_size+size(vol,2),pad_size+1:pad_size+size(vol,3)) = vol;
for num_d = pad_order
    if num_d == 1
        vol_m(1:pad_size,:,:) = repmat(vol_m(pad_size+1,:,:),[pad_size 1 1]);
        vol_m((size(vol_m,1)-pad_size+1):size(vol_m,1),:,:) = repmat(vol_m(size(vol,1)+pad_size,:,:),[pad_size 1 1]);
    elseif num_d == 2
        vol_m(:,1:pad_size,:) = repmat(vol_m(:,pad_size+1,:),[1 pad_size 1]);
        vol_m(:,(size(vol_m,2)-pad_size+1):size(vol_m,2),:) = repmat(vol_m(:,size(vol,2)+pad_size,:),[1 pad_size 1]);
    elseif num_d == 3
        vol_m(:,:,1:pad_size) = repmat(vol_m(:,:,pad_size+1),[1 1 pad_size]);
        vol_m(:,:,(size(vol_m,3)-pad_size+1):size(vol_m,3)) = repmat(vol_m(:,:,size(vol,3)+pad_size),[1 1 pad_size]);
    end
end

function vol = sub_unpad(vol_m,pad_size);
siz_vol = size(vol_m)-2*pad_size;
vol = vol_m(pad_size+1:pad_size+siz_vol(1),pad_size+1:pad_size+siz_vol(2),pad_size+1:pad_size+siz_vol(3));
