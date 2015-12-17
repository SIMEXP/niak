function [files_in,files_out,opt] = niak_brick_mask_anat2func(files_in,files_out,opt)
% Adapt a T1 brain mask to fit a typical BOLD brain mask. 
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_ANAT2FUNC(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN.ANAT 
%   (string) a T1 volume (in linear stereotaxic space). 
%
% FILES_IN.MASK_ANAT 
%   (string) a brain mask defined on a T1 image (in linear stereotaxic space). 
%
% FILES_IN.MASK_AVG 
%   (string) an average of many individual BOLD masks (in non-linear 
%   stereotaxic space). This will be thresholded to generate the BOLD mask. 
%
% FILES_IN.MASK_BOLD 
%    (string) a dilated mask that comprises all intra-cranial CSF as 
%    well as meninges (in non-linear stereotaxic space). 
%
% FILES_IN.TRANSF_STEREOLIN2NL 
%    (string) a .xfm non-linear transformation from 
%    linear stereotaxic space to non-linear stereotaxic space. 
%
% FILES_OUT   
%   (string) A T1 brain mask that has been tweaked to better fit a BOLD brain mask.
%   
% OPT           
%   (structure) with the following fields :
%
%   THRESH_AVG (scalar, default 0.65) the threshold used to binarize the average
%      BOLD masks to combine with the T1 mask. 
%
%   Z_CUT (scalar, default 15) only apply the restrictions from MASK_AVG on voxels
%       with z coordinates (in MNI space) below 15 mm. This includes ventromedial 
%       and temporal cortices.
%
%   FLAG_VERBOSE 
%       (boolean, default 1) if the flag is 1, then the function prints 
%       some infos during the processing.
%
%   FLAG_TEST 
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not do 
%       anything but update the default values in FILES_IN, FILES_OUT and 
%       OPT.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% COMMENTS:
%
% The T1 mask is combined with the thresholded BOLD masks. The space that
% is not in the brain mask but is in the dilated mask is segmented into three
% classes using a k-means algorithm. The call with lowest signal is deemed to 
% be CSF and is added to the BOLD brain mask. 
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% geriatrie de Montreal, Montreal, Canada, 2015.
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : brain mask, fMRI, segmentation

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

if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_ANAT2FUNC(FILES_IN,FILES_OUT,OPT)')
end

%% FILES_IN
files_in = psom_struct_defaults( files_in , ...
           { 'anat' , 'mask_anat' , 'mask_avg' , 'mask_dil' , 'transf_stereolin2nl' } , ...
           { NaN    , NaN         , NaN        , NaN        , NaN                   });

%% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string');
end

%% Options
if nargin < 3
    opt = struct;
end

opt = psom_struct_defaults ( opt , ...
      { 'zcut' , 'thresh_avg' , 'flag_verbose' , 'flag_test' }, ...
      { 15     , 0.65         , true           , false       });

if opt.flag_test == 1
    return
end

%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%

% Read the anat volume
[hdr,volt1] = niak_read_vol(files_in.anat);

%% Resample the dilated mask in stereolin space
file_mask_dil_r = niak_file_tmp('_mask_dil_r.mnc');
in.source = files_in.mask_dil;
in.target = files_in.anat;
in.transformation = files_in.transf_stereolin2nl;
opt.flag_invert_transf = true;
opt.interpolation = 'nearest_neighbour';
niak_brick_resample_vol(in,file_mask_dil_r,opt);

%% Read brain masks
[hdr,mask_dil]   = niak_read_vol(file_mask_dil_r);
[hdr,mask_brain] = niak_read_vol(files_in.mask_anat);
mask_dil = mask_dil>0;
mask_brain = mask_brain>0;

%% Extract a csf mask

% First get the values that lie between the brain and skull
val_outside = volt1(mask_dil & ~mask_brain);
% Now run a k-means with 3 classes
nb_classes = 3;
mask_outside = niak_kmeans_clustering(val_outside(:)',struct('nb_classes',3,'flag_verbose',true));
valm = zeros(1,3);
for cc = 1:3
    valm(cc) = mean(val_outside(mask_outside==cc));
end
[val,ind] = min(valm);
% Just extract the class with smallest average values on the T1 image
mask_csf = false(size(volt1));
mask_csf(mask_dil & ~mask_brain) = mask_outside == ind;

%% Extract a group mask of functional data 
file_mask_avg_r = niak_file_tmp('_mask_avg_r.mnc');
in.source = files_in.mask_avg;
in.target = files_in.anat;
in.transformation = files_in.transf_stereolin2nl;
opt.flag_invert_transf = true;
opt.interpolation = 'tricubic';
niak_brick_resample_vol(in,file_mask_avg_r,opt);
[hdr,mask_avg] = niak_read_vol(file_mask_avg_r);
coord_v = niak_coord_world2vox([0 0 opt.zcut],hdr.info.mat);
mask_func = mask_avg>opt.thresh_avg;

%% Combine the bold, csf and brain masks
mask_brain2 = (mask_brain | mask_csf );
mask_brain2(:,:,1:ceil(coord_v(3))) = mask_brain2(:,:,1:ceil(coord_v(3)))&mask_func(:,:,1:ceil(coord_v(3)));

%% Write out the result
hdr.file_name = files_out;
niak_write_vol(hdr,mask_brain2);

%% Clean up
psom_clean({file_mask_avg_r,file_mask_dil_r});