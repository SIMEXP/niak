function [files_in,files_out,opt] = niak_brick_boot_mean_vols(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_BOOT_MEAN_VOLS
%
% Build the mean/std volumes of multiple volumes, as well as a bootstrap
% estimate of the standard deviation of the mean.
%
% SYNTAX :
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_BOOT_MEAN_VOLS(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
%  * FILES_IN
%       (structure) with the following fields :
%
%       VOL
%           (cell of strings) Each entry is a 3D of a 3D+t dataset.
%      
%       TRANSFORMATION
%           (cell of strings, default identity) Each entry is a spatial
%           transformation to apply on the corresponding entry of VOL. The
%           target space is the MNI152 space, with a 2 mm isotropic
%           resolution.
%
%  * FILES_OUT 
%       (structure) with the following fields.  Note that if a field is an 
%       empty string, a default value will be used to name the outputs. 
%       If a field is ommited, the output won't be saved at all (this is 
%       equivalent to setting up the output file names to 
%       'gb_niak_omitted'). 
%
%       MEAN (string, default <BASE FILE IN 1>_mean.mnc)
%           The mean volume of all 3D volumes in FILES_IN
%
%       STD (string, default <BASE FILE IN 1>_std.mnc)
%           The standard-deviation volume of all 3D volumes in FILES_IN
%
%       MEANSTD  (string, default <BASE FILE IN 1>_meanstd.mnc)
%           The standard-deviation volume of the mean of all 3D volumes 
%           in FILES_IN. This standard-deviation is estimated through
%           i.i.d. bootstap of input volumes.
%
%  * OPT           
%       (structure) with the following fields.  
%
%       FWHM
%           (real number, default 0) a smoothing applied to each map before
%           averaging. 
%       
%       FLAG_MASK 
%           (boolean, default 1) if FLAG_MASK equals one, the
%           standard deviation will only be evaluated in a mask of the 
%           brain (that's speeding up bootstrap calculations).
%
%       NB_SAMPS
%           (integer, default 1000) the number of bootstrap samples used to
%           compute the standard-deviation-of-the-mean map.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present, all default 
%           outputs will be created in the folder FOLDER_OUT. The folder 
%           needs to be created beforehand.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function 
%           prints some info during the processing.
%
%       FLAG_TEST 
%           (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN, 
%           FILES_OUT and OPT.
%           
% _________________________________________________________________________
% OUTPUTS :
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO :
%
% _________________________________________________________________________
% COMMENTS :
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, slice timing, fMRI

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

niak_gb_vars % Load some important NIAK variables
file_mni152 = cat(2,gb_niak_path_niak,'template',filesep,'roi_aal.mnc');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_BOOT_MEAN_VOLS(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_boot_mean_vols'' for more info.')
end

%% Output files
gb_name_structure = 'files_in';
gb_list_fields = {'vol','transformation'};
gb_list_defaults = {NaN,'gb_niak_omitted'};
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'fwhm','nb_samps','flag_mask','flag_test','folder_out','flag_verbose'};
gb_list_defaults = {0,1000,1,0,'',1};
niak_set_defaults

%% Output files
gb_name_structure = 'files_out';
gb_list_fields = {'mean','std','meanstd'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% Input files
if ~iscellstr(files_in.vol)
    error('FILES_IN should be a cell of strings');
end

%% Building default output names
[path_f,name_f,ext_f] = fileparts(files_in.vol{1});
if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end

if strcmp(opt.folder_out,'')
    opt.folder_out = path_f;
end

if isempty(files_out.mean)
    files_out.mean = cat(2,opt.folder_out,filesep,name_f,'_mean',ext_f);
end

if isempty(files_out.std)
    files_out.std = cat(2,opt.folder_out,filesep,name_f,'_std',ext_f);
end

if isempty(files_out.meanstd)
    files_out.meanstd = cat(2,opt.folder_out,filesep,name_f,'_meanstd',ext_f);
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Computing mean/std volumes %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\n_______________________________________\n\nComputing mean/std volumes of %s\n_______________________________________\n',char(files_in.vol{:})');
end

nb_files = length(files_in.vol);

%% If necessary, resample the images in the MNI152 space
files_in_orig = files_in;

if ~ischar(files_in.transformation)
    
    if flag_verbose
        fprintf('\nResampling the individual volumes in the MNI152 space...');
    end
    
    if length(files_in.transformation)~=nb_files
        error('Please specify one transformation per volume !');
    end
    
    files_in_tmp = cell(size(files_in.transformation));
    for num_f = 1:nb_files
        if flag_verbose
            fprintf(' %i',num_f)
        end
        files_in_tmp{num_f} = niak_file_tmp(sprintf('_vol_%i.mnc',num_f));
        files_in_r.source = files_in.vol{num_f};
        files_in_r.target = file_mni152;
        files_in_r.transformation = files_in.transformation{num_f};
        files_out_r = files_in_tmp{num_f};
        opt_r.interpolation = 'trilinear';
        opt_r.flag_verbose = 0;
        [flag,mes] = niak_brick_resample_vol(files_in_r,files_out_r,opt_r);
    end
    if flag_verbose
        fprintf('\n')
    end
    files_in.vol = files_in_tmp;
    
end

%% Checking the size of input volumes
if flag_verbose
    fprintf('\nChecking the size of input volumes ...\n');
end

nb_vols = 0;

for num_f = 1:nb_files
    hdr = niak_read_vol(files_in.vol{num_f});
    if length(hdr.info.dimensions)==4
        nb_vols = nb_vols + hdr.info.dimensions(4);
    else
        nb_vols = nb_vols+1;
    end
    if num_f == 1
        hdr_ref = hdr;
        nx = hdr.info.dimensions(1);
        ny = hdr.info.dimensions(2);
        nz = hdr.info.dimensions(3);
    else
        if min([nx ny nz] == hdr.info.dimensions(1:3))==0
            error('All volumes need to be in the same voxel space !')
        end
    end
end

%% Reading all volumes
if flag_verbose
    fprintf('\nReading all volumes ...\n');
end
vol_all = zeros([nx ny nz nb_vols]);
num_vol = 0;

if opt.fwhm>0
    file_vol_tmp = niak_file_tmp('_vol_smooth.mnc');
end

for num_f = 1:nb_files
    
    if opt.fwhm>0
        files_in_s = files_in.vol{num_f};
        files_out_s = file_vol_tmp;
        opt_s.fwhm = opt.fwhm;
        opt_s.flag_verbose = 0;
        niak_brick_smooth_vol(files_in_s,files_out_s,opt_s);
        [hdr,vol] = niak_read_vol(file_vol_tmp);
    else
        [hdr,vol] = niak_read_vol(files_in.vol{num_f});
    end
    
    if length(hdr.info.dimensions)==4
        vol_all(:,:,:,num_vol+1:num_vol+hdr.info.dimensions(4)) = vol;
        num_vol = num_vol + hdr.info.dimensions(4);
    else
        vol_all(:,:,:,num_vol+1) = vol;
        num_vol = num_vol + 1;
    end
    clear vol
end


if opt.fwhm>0
    delete(file_vol_tmp);
end

%% Computing mean volume
mean_vol = mean(vol_all,4);
if ~strcmp(files_out.mean,'gb_niak_omitted')
    if flag_verbose
        fprintf('\nComputing mean volume ...\n');
    end

    hdr_ref.file_name = files_out.mean;
    niak_write_vol(hdr_ref,mean_vol);
end

%% Computing std volume

if ~strcmp(files_out.std,'gb_niak_omitted')
    if flag_verbose
        fprintf('\nComputing std volume ...\n');
    end
    std_vol = std(vol_all,0,4);
    hdr_ref.file_name = files_out.std;
    niak_write_vol(hdr_ref,std_vol);
end

%% Deriving a bootstrap estimate of the standard deviation of the mean
if ~strcmp(files_out.meanstd,'gb_niak_omitted')
    if flag_verbose
        fprintf('\nComputing a bootstrap estimate of the standard deviation of the mean with %i samples...\n',nb_samps);
    end

    meanstd_vol = zeros([nx ny nz]);

    if flag_mask == 1
        mask = niak_mask_brain(mean(abs(vol_all),4));
    end

    vol_all = reshape(vol_all,[nx*ny*nz nb_vols]);
    mean_vol = mean_vol(:);
    
    if flag_mask == 1      
        vol_all = vol_all(mask,:);
        mean_vol = mean_vol(mask);
    end
    
    %% Deriving bootstrap samples
    for num_s = 1:nb_samps
        vol_tmp = mean(vol_all(:,ceil(nb_vols*rand([nb_vols 1]))),2);
        if flag_mask == 1
            meanstd_vol(mask) = meanstd_vol(mask) + (vol_tmp-mean_vol).^2;
        else
            meanstd_vol(:) = meanstd_vol(:) + (vol_tmp-mean_vol).^2;
        end
    end
    meanstd_vol = sqrt(meanstd_vol/nb_samps);
    hdr_ref.file_name = files_out.meanstd;
    niak_write_vol(hdr_ref,meanstd_vol);
end

if ~ischar(files_in.transformation)
    for num_f = 1:nb_files
        delete(files_in.vol{num_f});
    end
end
files_in = files_in_orig; %% Restore the initial organization of files_in