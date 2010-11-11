function vol_s = niak_smooth_vol(vol,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_SMOOTH_VOL
%
% Spatial smoothing of 3D+t data with a Gaussian kernel
%
% SYNTAX:
% VOL_S = NIAK_SMOOTH_VOL(VOL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL         
%       (4D array) a 3D+t dataset
%
% OPT         
%       (structure, optional) with the following fields :
%
%       MASK
%           (binary volume, default true(size(VOL))) this volume should 
%           have the same size as VOL and will be used to correct for 
%           edges effects in the smoothing, assuming zero values outside 
%           the mask if OPT.FLAG_EDGE is true (see below).
%
%       VOXEL_SIZE  
%           (vector of size [3 1] or [4 1], default [1 1 1]) the resolution
%           in the respective dimensions, i.e. the space in mmm between 
%           two voxels in x, y, and z (yet the unit is irrelevant and just 
%           needs to be consistent with the filter width (fwhm)). The 
%           fourth element is ignored.
%
%       FWHM  
%           (vector of size [3 1], default [2 2 2]) the full width at half 
%           maximum of the Gaussian kernel, in each dimension. If fwhm has 
%           length 1, an isotropic kernel is implemented.
%
%       FLAG_EDGE
%           (boolean, default 1) if the flag is 1, then a correction is
%           applied for edges effects in the smoothing (such that a volume
%           full of ones is left untouched by the smoothing).
%
%       FLAG_VERBOSE
%           (boolean, default true) if the flag is 1, then the function prints 
%           some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% VOL_S       
%       (4D array) same as VOL after each volume has been spatially
%       convolved with a 3D separable Gaussian kernel.
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_BRICK_SMOOTH_VOL
%
% _________________________________________________________________________
% COMMENTS:
%
% This command is using temporary files on the disk to run MINCBLUR.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, smoothing, fMRI

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

% Setting up default
gb_name_structure = 'opt';
gb_list_fields    = {'mask' , 'flag_edge' , 'flag_verbose' , 'voxel_size' ,'fwhm'   };
gb_list_defaults  = {[]     , true        , true           , [1 1 1]'     ,[2 2 2]' };
niak_set_defaults

if length(voxel_size)>3
    voxel_size = voxel_size(1:3);
end

if length(fwhm)==1
    fwhm = [fwhm,fwhm,fwhm];
end

if length(size(vol))<4
    [nx,ny,nz] = size(vol);
    nt = 1;
else
    [nx,ny,nz,nt] = size(vol);
end

voxel_size = abs(voxel_size);

vol_s = zeros(size(vol),'single');

%% Loop over all volumes
file_in_sm = niak_file_tmp('_vol.mnc');
file_out_sm = niak_file_tmp('_blur.mnc');

if flag_verbose
    fprintf('Smoothing volume :');
end

hdr.file_name = file_in_sm;
hdr.type = 'minc1';
hdr.info.voxel_size = voxel_size;

if flag_edge
    if isempty(mask)
        mask = ones([nx ny nz]);
    end
    mask = mask>0;
    opt_smooth = opt;
    opt_smooth.flag_edge = false;
    opt_smooth.flag_verbose = false;    
    vol_corr = niak_smooth_vol(mask,opt_smooth);    
end

for num_t = 1:nt    

    if flag_verbose
        fprintf('%i ',num_t);
    end

    %% Write a temporary volume    
    if flag_edge
      vol_tmp = vol(:,:,:,num_t);      
      vol_tmp(~mask) = 0;
      niak_write_vol(hdr,vol_tmp);
    else
      niak_write_vol(hdr,vol(:,:,:,num_t));
    end

    %% Apply smoothing
    instr_smooth = cat(2,'mincblur -3dfwhm ',num2str(fwhm),' -no_apodize -clobber ',file_in_sm,' ',file_out_sm(1:end-9));
    [succ,msg] = system(instr_smooth);
    if succ~=0
        error(msg)
    end
    
    %% Read the smoothed volume
    [hdr_tmp,vol_tmp] = niak_read_vol(file_out_sm);
    
    %% Correct for edges effects
    if flag_edge
        vol_tmp(mask>0) = vol_tmp(mask>0)./vol_corr(mask>0);
        vol_tmp(~mask)  = 0;
    end
    vol_s(:,:,:,num_t) = vol_tmp;        
end

if flag_verbose
    fprintf('\n');
end

delete(file_in_sm);
delete(file_out_sm);