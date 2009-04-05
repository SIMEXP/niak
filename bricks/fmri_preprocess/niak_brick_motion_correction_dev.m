function [files_in,files_out,opt] = niak_brick_motion_correction_ws(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_MOTION_CORRECTION
%
% Estimate rigid-body motion parameters on fMRI volumes.
%
% SYNTAX:
%   [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_CORRECTION(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%   FILES_IN 
%       (structure) with the following fields :
%
%       RUN
%           (string) a series of fMRI volumes.
%
%       TARGET
%           (string) one fMRI volume.
%       
%   FILES_OUT  
%       (string, default same as FILES_IN.RUN but without extension and 
%       with a '_mp.dat' suffix) the file name for the estimated motion 
%       parameters. The first line describes the content of each column. 
%       Each subsequent line I+1 is a representation of the motion 
%       parameters estimated for session I.
%
%   OPT   
%       (structure) with the following fields:
%
%       IGNORE_SLICE
%           (integer, default 1) ignore the first and last IGNORE_SLICE
%           slices of the volume in the coregistration process.
%
%       FWHM 
%           (real number, default 8 mm) the fwhm of the blurring kernel
%           applied to all volumes.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present,
%           all default outputs will be created in the folder FOLDER_OUT.
%           The folder needs to be created beforehand.
%
%       FLAG_TEST 
%           (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN and 
%           FILES_OUT.
%
%       FLAG_VERBOSE 
%           (boolean, default: 1) If FLAG_VERBOSE == 1, write messages 
%           indicating progress.
%
% _________________________________________________________________________
% OUTPUTS:
%
%   The structures FILES_IN, FILES_OUT and OPT are updated with default
%   values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
%
%   NIAK_PIPELINE_MOTION_CORRECTION, NIAK_DEMO_MOTION_CORRECTION
%
% _________________________________________________________________________
% COMMENTS
%
% NOTE 1:
% All volumes are converted to smoothed gradient volumes.
%
% NOTE 2:
% The rigid-body coregistration is performed using MINCTRACC and an xcorr
% cost function.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, motion, fMRI, MINCTRACC

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

flag_gb_niak_fast_gb = true;
niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SYNTAX
if ~exist('files_in','var')
    error('niak_brick_motion_correction, SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_CORRECTION(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_motion_correction_ws'' for more info.')
end

%% OPTIONS
gb_name_structure = 'files_in';
gb_list_fields = {'fmri','target'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

%% FILES_OUT
if ~exist('files_out','var')
    files_out = '';    
end

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'ignore_slice','folder_out','flag_test','flag_verbose','fwhm'};
gb_list_defaults = {1,'',false,true,8};
niak_set_defaults

%% Building default output names

[path_f,name_f,ext_f] = fileparts(files_in.fmri);

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

files_out = cat(2,folder_write,filesep,name_f,'_mp.dat');

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Estimation of motion parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

msg = sprint('Rigid-body motion estimation.\nSource file: %s\nTarget file: %s\n',files_in.fmri,files_out);
stars = repmat('*',size(msg));
if flag_verbose
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
end

%% Generating temporary folder
path_tmp = niak_folder_tmp('_motion_correction');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generating the target volume %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Generating the target...\n');
end

%% Generating source mask
[hdr_target,vol_target] = niak_read_vol(files_in.target);
mask_target = niak_mask_brain(vol_target);
mask_target = niak_dilate_mask(mask_target);
if ignore_slice > 0
    mask_target(:,:,1:ignore_slice) = 0;
    mask_target(:,:,end-ignore_slice+1:end) = 0;
end
file_mask_source = [path_tmp 'mask_target.mnc'];
hdr.file_name = file_mask_source;
niak_write_vol(hdr_target,mask_target);

%% writting the target
file_target = [path_tmp 'target_dxyz.mnc'];
file_target_tmp = [path_tmp 'target_tmp.mnc'];
hdr.file_name = file_target_tmp;
niak_write_vol(hdr,vol_target);
[succ,mesg] = system(cat(2,'mincblur -clobber -no_apodize -quiet -fwhm ',num2str(opt.fwhm),' -gradient ',file_target_tmp,' ',file_target(1:end-9)));
if succ ~= 0
    error(mesg);
end                   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Looping over every volume to perform motion parameters estimation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    fprintf('Performing motion correction estimation on volume :');
end

%% read volumes
[hdr,data] = niak_read_vol(files_in.fmri);

if length(hdr.info.dimensions)==4
    nb_vol = hdr.info.dimensions(4);
else
    nb_vol = 1;
end

%% Set up options for smoothing
opt_s.voxel_size = hdr.info.voxel_size;
opt_s.fwhm = opt.fwhm;

%% Initialize the array for motion parameters
tab_parameters = zeros([nb_vol(num_r) 8]);
hf_mp = fopen(files_out,'w');
fprintf(hf_mp,'pitch roll yaw tx ty tz XCORR_init XCORR_final\n');


%% Generating file names
file_vol = [path_tmp 'vol_source_dxyz.mnc'];
file_vol_tmp = [path_tmp 'vol_source_tmp.mnc'];
file_xfm_tmp = [path_tmp 'vol_source_dxyz.xfm'];
hdr.file_name = file_vol;

for num_v = 1:nb_vol

    if flag_verbose
        fprintf('%i ',num_v);
    end

    vol_source = data(:,:,:,num_v);

    %% writting the source
    hdr.file_name = file_vol_tmp;
    niak_write_vol(hdr,vol_source);

    [succ,mesg] = system(cat(2,'mincblur -clobber -no_apodize -quiet -fwhm ',num2str(opt.fwhm),' -gradient ',file_vol_tmp,' ',file_vol(1:end-9)));
    if succ ~= 0
        error(mesg);
    end

    delete(cat(2,file_vol(1:end-9),'_blur.mnc'));
    delete(file_vol_tmp);

    if (num_v == vol_ref) & (num_r == run_ref)

        transf = eye(4);
        [flag,str_log] = system(cat(2,'param2xfm ',xfm_tmp,' -translation 0 0 0 -rotations 0 0 0 -clobber'));

    else

        if num_v == list_vols(1)
            [flag,str_log] = system(cat(2,'minctracc ',file_vol,' ',file_target,' ',xfm_tmp,' -xcorr -source_mask ',file_mask_source,' -model_mask ',file_mask_target,' -forward -clobber -debug -lsq6 -identity -speckle 0 -est_center -tol 0.0005 -tricubic -simplex 10 -model_lattice -step 7 7 7'));
        else
            [flag,str_log] = system(cat(2,'minctracc ',file_vol,' ',file_target,' ',xfm_tmp,' -xcorr  -source_mask ',file_mask_source,' -model_mask ',file_mask_target,' -forward -transformation ',xfm_tmp,' -clobber -debug -lsq6 -speckle 0 -est_center -tol 0.0005 -tricubic -simplex 10 -model_lattice -step 7 7 7'));
        end

        %% Reading the transformation
        transf = niak_read_transf(xfm_tmp);

        %% Keeping record of the objective function values before and after
        %% optimization
        cell_log = niak_string2lines(str_log);
        line_log = niak_string2words(cell_log{end-1});
        tab_parameters(num_v,7) = str2num(line_log{end});
        line_log = niak_string2words(cell_log{end});
        tab_parameters(num_v,8) = str2num(line_log{end});

    end

    %% Converting the xfm transformation into a roll/pitch/yaw and
    %% translation format
    [pry,tsl] = niak_transf2param(transf);

    tab_parameters(num_v,1:3) = pry';
    tab_parameters(num_v,4:6) = tsl';

    %% If resampling data has been requested (or deriving the resampled
    %% mean or mask), perform spatial interpolation
    if ~ischar(files_out.motion_corrected_data)

        files_in_res.source = niak_file_tmp('_vol_orig.mnc');
        files_in_res.target = file_target_native;
        files_in_res.transformation = xfm_tmp;
        files_out_res = niak_file_tmp('_vol_r.mnc');
        opt_res.flag_tfm_space = 0;
        opt_res.voxel_size = [];
        opt_res.flag_verbose = 0;
        hdr.file_name = files_in_res.source;
        niak_write_vol(hdr,data(:,:,:,num_v));
        niak_brick_resample_vol(files_in_res,files_out_res,opt_res);
        [hdr_r,vol_r] = niak_read_vol(files_out_res);
        delete(files_out_res);
        delete(files_in_res.source);
        data_r(:,:,:,num_v) = vol_r;

    end

    %% If requested, write the motion parameters in a log file
    if ~strcmp(files_out.motion_parameters,'gb_niak_omitted')
        fprintf(hf_mp,'%s\n',num2str(tab_parameters(num_v,:),12));
    end

    delete(file_vol);

end

if flag_verbose
    fprintf('\n')
end
fclose(hf_mp);

% Cleaning temporary files
delete(file_mask_target);
delete(file_target);
delete(file_target_native);