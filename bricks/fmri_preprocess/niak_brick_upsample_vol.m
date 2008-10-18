function [files_in,files_out,opt] = niak_brick_upsample_vol(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_UPSAMPLE_VOL
%
% Apply a 3D zero-padding in Fourier space to change the resolution of a 3D
% (or 3D+t) dataset.
%
% _________________________________________________________________________
% SYNTAX
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_UPSAMPLE_VOL(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% * FILES_IN      
%       (string) name of the file to upsample (can be 3D+t).
%
% * FILES_OUT 
%       (string,default <BASE_FILES_IN>_up.<EXT_FILES_IN>) 
%       the name of the output upsampled volume.
%
% * OPT           
%       (structure, optional) has the following fields:
%
%       VOXEL_SIZE 
%           (vector 1*3) The resolution of the upsampled volume will be 
%           used. The new voxel size has to be smaller than the original.
%           Note that the original voxel size should be an exact multiple
%           of the new voxel size. If not, the largest possible resolution
%           which is smaller than the specified resolution and which
%           satisfies this criterion will be used.
%           Note also that the original grid size should be even.
%
%       FLAG_DECONV
%           (boolean, default 1) if FLAG_DECONV is true, the upsampled
%           image will be deconvolved of the voxel averaging effect. This
%           is drastically increasing the power of the noise in high spatial
%           frequencies.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present, all default 
%           outputs will be created in the folder FOLDER_OUT. The folder 
%           needs to be created beforehand.
%
%       FLAG_TEST 
%           (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN and 
%           FILES_OUT.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function prints 
%           some infos during the processing.
%
%
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS:
%
% This is a simple wrapper of MINCRESAMPLE, but is has a couple of
% additional features (i.e. the possibility to change the resolution or to
% get rid of the direction cosines).
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, minc

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

niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Setting up inputs
if ~ischar(files_in)
    error('FILES_IN should be a string !')
end

% Setting up options
gb_name_structure = 'opt';
gb_list_fields = {'flag_deconv','voxel_size','folder_out','flag_test','flag_verbose'};
gb_list_defaults = {true,NaN,'',0,1};
niak_set_defaults

%% Generating default ouputs
[path_f,name_f,ext_f] = fileparts(files_in);

if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end

if isempty(opt.folder_out)
    folder_write = path_f;
else
    folder_write = opt.folder_out;
end

if isempty(files_out)
    files_out = cat(2,folder_write,filesep,name_f,'_up',ext_f);
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reading the source space information %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\nReading source volume %s ...\n',files_in);
end

[hdr_source,vol] = niak_read_vol(files_in);
[dircos1,step1,start1] = niak_hdr_mat2minc(hdr_source.info.mat);
voxel_size1 = abs(step1(:))'; 

nx1 = hdr_source.info.dimensions(1);
ny1 = hdr_source.info.dimensions(2);
nz1 = hdr_source.info.dimensions(3);

if length(hdr_source.info.dimensions)>3
    nt1 = hdr_source.info.dimensions(4);
else
    nt1 = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Deriving the new resolution %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\nDeriving the new resolution ...\n');
end

fr = voxel_size1(:)./voxel_size(:);
if fr~=round(fr);
    fr = ceil(fr);
    voxel_size = voxel_size1(:)./fr;
end

hdr_target = hdr_source;
dircos2 = dircos1;
start2 = start1;
step2 = voxel_size(:).*sign(step1(:));
hdr_target.info.mat = niak_hdr_minc2mat(dircos2,step2,start2);

nx2 = int32(fr(1)*nx1);
ny2 = int32(fr(2)*ny1);
nz2 = int32(fr(3)*nz1);
fr = int32(fr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Upsampling the volume with zero-padding %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\nUpsampling the volume with zero-padding ...\n');
end

vol_up = zeros([nx2 ny2 nz2 nt1],'single');

if flag_deconv
    filter_vox = zeros([nx2 ny2 nz2]);
    filter_vox(1:fr(1),1:fr(2),1:fr(3)) = 1;
    %filter_vox = filter_vox/sqrt(sum(filter_vox(:).^2));
    filter_vox = fftn(filter_vox);
    mask_f = abs(filter_vox)<0.01;
    filter_vox = filter_vox.^(-1);
    filter_vox(mask_f) = 0;
end

for num_t = 1:nt1

    fvol = fftn(vol(:,:,:,num_t));
    fvol_up = zeros([nx2 ny2 nz2],'single');

    for num_z = 1:nz2

        if num_z <= nz1/2

            fvol_up(int32([1:(nx1/2) (nx2-nx1/2+1):nx2]),int32([1:(ny1/2) (ny2-ny1/2+1):ny2]),num_z) = fvol(:,:,num_z);

        elseif num_z >= (nz2-(nz1/2)+1)

            fvol_up(int32([1:(nx1/2) (nx2-nx1/2+1):nx2]),int32([1:(ny1/2) (ny2-ny1/2+1):ny2]),num_z) = fvol(:,:,int32(num_z-(nz2-nz1)));

        end
    end

    if flag_deconv
        fvol_up = filter_vox.*fvol_up;
        vol_up(:,:,:,num_t) = (double((nx2*ny2*nz2))/double((nx1*ny1*nz1)))^2*real(ifftn(fvol_up));
    else
        vol_up(:,:,:,num_t) = (double((nx2*ny2*nz2))/double((nx1*ny1*nz1)))*real(ifftn(fvol_up));
    end

    

end


%%%%%%%%%%%%%%%%%%%%%%
%% Write the output %%
%%%%%%%%%%%%%%%%%%%%%%

%% write the resampled volumes in a 3D+t dataset
if flag_verbose
    fprintf('\nWrite the output\n')
end

hdr_target.file_name = files_out;
niak_write_vol(hdr_target,vol_up);

if flag_verbose
    fprintf('Done!\n')
end
