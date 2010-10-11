function [files_in,files_out,opt] = niak_brick_motion_parameters(files_in,files_out,opt)
% Estimate rigid-body motion parameters on fMRI volumes.
%
% SYNTAX:
%   [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_PARAMETERS(FILES_IN,FILES_OUT,OPT)
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
%       with a '_mp.mat' suffix) the file name for the estimated motion
%       parameters. It is a matlab file with one variable TRANSF.
%       TRANSF(:,:,I) is the rigid-body transformation from volume number 
%       I to the target. 
%
%   OPT
%       (structure) with the following fields:
%
%       IGNORE_SLICE
%           (integer, default 1) ignore the first and last IGNORE_SLICE
%           slices of the volume in the coregistration process.
%
%       FWHM
%           (real number, default 5 mm) the fwhm of the blurring kernel
%           applied to all volumes.
%
%       STEP
%           (real number, default 10) The step argument for MINCTRACC.
%
%       TOL
%           (real number, default 0.0005) The tolerance level for
%           convergence in MINCTRACC.
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
%   NIAK_PIPELINE_MOTION_CORRECTION
%
% _________________________________________________________________________
% COMMENTS
%
% NOTE 1:
% All volumes are converted to smoothed volumes.
%
% NOTE 2:
% The rigid-body coregistration is performed using MINCTRACC and an xcorr
% cost function.
%
% NOTE 3:
% The TRANSF variables are standard 4*4 matrix array representation of 
% an affine transformation [M T ; 0 0 0 1] for (y=M*x+T) 
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

%% FILES IN
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
gb_list_fields   = {'ignore_slice' ,'folder_out' ,'flag_test' ,'flag_verbose' ,'fwhm' ,'step' ,'tol'};
gb_list_defaults = {1              ,''           ,false       ,true           ,5      ,10     ,0.0005};
niak_set_defaults

%% Building default output names

if isempty(files_out)
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

    files_out = cat(2,folder_write,filesep,name_f,'_mp.mat');
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Estimation of motion parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

msg1 = sprintf('Within-run rigid-body motion estimation');
msg2 = sprintf('Source file: %s',files_in.fmri);
msg3 = sprintf('Target file: %s',files_in.target);
stars = repmat('*',[1 max([length(msg1)])]);
if flag_verbose
    fprintf('\n%s\n%s\n%s\n%s\n%s\n',stars,msg1,stars,msg2,msg3);
end

%% Generating temporary folder
path_tmp = niak_path_tmp('_motion_correction');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generating the target volume %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Generating a blurred target...\n');
end

%% Generating source mask
[hdr_target,vol_target] = niak_read_vol(files_in.target);
mask_target = niak_mask_brain(vol_target);
mask_target = niak_dilate_mask(mask_target);
if ignore_slice > 0
    mask_target(:,:,1:ignore_slice) = 0;
    mask_target(:,:,end-ignore_slice+1:end) = 0;
end
file_mask_target = [path_tmp 'mask_target.mnc'];
hdr_target.file_name = file_mask_target;
niak_write_vol(hdr_target,mask_target);

%% writting the target
file_target = [path_tmp 'target_blur.mnc'];
file_target_tmp = [path_tmp 'target_tmp.mnc'];
hdr_target.file_name = file_target_tmp;
niak_write_vol(hdr_target,vol_target);
[succ,mesg] = system(cat(2,'mincblur -clobber -no_apodize -quiet -fwhm ',num2str(opt.fwhm),' ',file_target_tmp,' ',file_target(1:end-9)));
if succ ~= 0
    error(mesg);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Looping over every volume to perform motion parameters estimation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Reading volumes %s...\n',files_in.fmri);
end

%% read volumes
[hdr,data] = niak_read_vol(files_in.fmri);

if length(hdr.info.dimensions)==4
    nb_vol = hdr.info.dimensions(4);
else
    nb_vol = 1;
end

%% Generating file names
file_vol = [path_tmp 'vol_source_blur.mnc'];
file_vol_model = [path_tmp 'vol_source_model.mnc'];
file_vol_tmp = [path_tmp 'vol_source_tmp.mnc'];
file_raw_tmp = [path_tmp 'vol_source_raw.dat'];
file_xfm_tmp = [path_tmp 'vol_source_dxyz.xfm'];
hdr.file_name = file_vol;
hdr.raw = file_raw_tmp;

for num_v = 1:nb_vol

    vol_source = data(:,:,:,num_v);

    %% writting the source
    if num_v == 1
        hdr.file_name = file_vol_model;
        niak_write_vol(hdr,vol_source);
        hdr.like = file_vol_model;
    end

    hdr.file_name = file_vol_tmp;
    niak_write_vol(hdr,vol_source);

    %% Blur
    [succ,mesg] = system(cat(2,'mincblur -clobber -no_apodize -quiet -fwhm ',num2str(opt.fwhm),' ',file_vol_tmp,' ',file_vol(1:end-9)));
    if succ ~= 0
        error(mesg);
    end

    %% Perform rigid-body coregistration
    instr_minctracc = cat(2,'minctracc ',file_vol,' ',file_target,' ',file_xfm_tmp,' -xcorr  -source_mask ',file_mask_target,' -model_mask ',file_mask_target,' -forward -transformation ',file_xfm_tmp,' -clobber -lsq6 -speckle 0 -est_center -tol ',num2str(opt.tol,7),' -tricubic -simplex 10 -model_lattice -step ',num2str(opt.step),' ',num2str(opt.step),' ',num2str(opt.step));
    if (num_v == 1)
        [fail,msg] = system(cat(2,'param2xfm ',file_xfm_tmp,' -translation 0 0 0 -rotations 0 0 0 -clobber'));

        if fail
            error('There was a problem with PARAM2XFM : %s',msg)
        end

        if flag_verbose
            fprintf('MINCTRACC call : %s\n',instr_minctracc);
            fprintf('Performing motion correction estimation on volume : ');
        end
    end

    if flag_verbose
        fprintf('%i ',num_v);
    end

    [fail,str_log] = system(instr_minctracc);
    if fail~=0
        error('There was a problem with MINCTRACC : %s',str_log)
    end

    %% Reading the transformation
    if num_v == 1
        transf = niak_read_transf(file_xfm_tmp);
    else
        transf(:,:,num_v) = niak_read_transf(file_xfm_tmp);
    end    
end

if flag_verbose
    fprintf('\nDone!\n')
end

save(files_out,'transf')

% Cleaning temporary files
if exist('OCTAVE_VERSION','builtin')
    instr_rm = ['rm -rf ' path_tmp];
    [succ,msg] = system(instr_rm);
else
    [succ,msg] = rmdir(path_tmp,'s');
end