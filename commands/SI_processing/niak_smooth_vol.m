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
gb_list_fields = {'voxel_size','fwhm'};
gb_list_defaults = {[1 1 1]',[2 2 2]'};
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
for num_t = 1:nt
    %% Write a temporary volume
    files_in_sm = niak_file_tmp('_vol.mnc');
    hdr.file_name = files_in_sm;
    hdr.info.mat = [[diag(voxel_size) [0;0;0]];[0 0 0 1]];    
    hdr.type = 'minc1';
    niak_write_vol(hdr,vol(:,:,:,num_t));

    %% Apply smoothing
    files_out_sm = '';
    opt_sm.fwhm = opt.fwhm;
    opt_sm.flag_verbose = false;
    [files_in_sm,files_out_sm,opt_sm] = niak_brick_smooth_vol(files_in_sm,files_out_sm,opt_sm);

    %% Read the smoothed volume
    [hdr_tmp,vol_tmp] = niak_read_vol(files_out_sm);
    vol_s(:,:,:,num_t) = vol_tmp;
end

delete(files_in_sm);
delete(files_out_sm);