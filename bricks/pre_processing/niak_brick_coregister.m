function [files_in,files_out,opt] = niak_brick_coregister(files_in,files_out,opt)

% Co-register of a T1 image onto a T2* EPI image of the same subject using
% a rigid-body transform. The two images are assumed to come from the same
% session (translation < 2 cm).
%
% SYNTAX:
%   [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_COREGISTER(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
%   FILES_IN 
%
%       FUNCTIONAL (string)
%           a file with one or multiple fMRI volume. If multiple volumes
%           are present, the coregistration will be performed on the
%           average.
%
%       ANAT (string)
%           a file with one T1 volume of the same subject.
%
%   FILES_OUT  (structure) with the following fields. Note that if
%     a field is an empty string, a default value will be used to
%     name the outputs. If a field is ommited, the output won't be
%     saved at all (this is equivalent to setting up the output file
%     names to 'gb_niak_omitted').
%
%       TRANSFORMATION (string, default base
%           name <BASE_FUNCTIONAL>_to_<BASE_ANAT>.XFM)
%           File name for saving the transformation from the functional
%           space to the anatomical space.
%
%       ANAT_RESAMPLED_HIRES (string, default <BASE_ANAT>_hires)
%           File name for saving the anatomical image resampled in the
%           space of the functional space, using native resolution.
%     
%       ANAT_RESAMPLED_LOWRES (string, default <BASE_ANAT>_hires)
%           File name for saving the anatomical image resampled in the
%           space of the functional space, using the target resolution.
%
%   OPT   (structure) with the following fields:
%
%       FWHM (real number, default 5 mm) the fwhm of the blurring kernel
%           applied to all volumes.
%
%       INTERPOLATION (string, default 'trilinear') the spatial
%          interpolation method. Available options : 'trilinear', 'tricubic',
%          'nearest','sinc'.
%
%       FLAG_ZIP   (boolean, default: 0) if FLAG_ZIP equals 1, an
%           attempt will be made to zip the outputs.
%
%       FOLDER_OUT (string, default: path of FILES_IN) If present,
%           all default outputs will be created in the folder FOLDER_OUT.
%           The folder needs to be created beforehand.
%
%       FLAG_TEST (boolean, default: 0) if FLAG_TEST equals 1, the
%           brick does not do anything but update the default
%           values in FILES_IN and FILES_OUT.
%
%       FLAG_VERBOSE (boolean, default: 1) If FLAG_VERBOSE == 1, write
%           messages indicating progress.
%
% OUTPUTS:
%   The structures FILES_IN, FILES_OUT and OPT are updated with default
%   values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% SEE ALSO:
%
% COMMENTS
%
% The core of the function is a MINC tool called MINCTRACC which performs
% rigid-body coregistration.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, filtering, fMRI

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

%% SYNTAX
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak_brick_motion_correction, SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_CORRECTION_WS(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_time_filter'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields = {'anat','functional'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'transformation','functional_resampled','anat_hires','anat_lowres'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'flag_zip','flag_test','folder_out','interpolation','flag_verbose','fwhm'};
gb_list_defaults = {0,0,'','trilinear',1,5};
niak_set_defaults
        
%% Building default output names
[path_anat,name_anat,ext_anat] = fileparts(files_in.anat);

if isempty(path_anat)
    path_anat = '.';
end

if strcmp(ext_anat,'.gz')
    [tmp,name_anat,ext_anat] = fileparts(name_anat);
end

if isempty(opt.folder_out)
    folder_anat = path_anat;
else
    folder_anat = opt.folder_out;
end

[path_func,name_func,ext_func] = fileparts(files_in.functional);

if isempty(path_func)
    path_func = '.';
end

if strcmp(ext_func,'.gz')
    [tmp,name_func,ext_func] = fileparts(name_func);
end

if isempty(opt.folder_out)
    folder_func = path_func;
else
    folder_func = opt.folder_out;
end

if isempty(files_out.transformation)
    files_out.transformation = cat(2,folder_func,filesep,name_func,'_to_',name_anat,'.xfm');
end

if isempty(files_out.functional_resampled)
    files_out.functional_resampled = cat(2,folder_func,filesep,name_func,'_res',ext_func);
end

if isempty(files_out.anat_lowres)
    files_out.anat_lowres = cat(2,folder_anat,filesep,name_anat,'_lowres',ext_anat);
end

if isempty(files_out.anat_hires)
    files_out.anat_hires = cat(2,folder_anat,filesep,name_anat,'_hires',ext_anat);
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Coregistration of the anatomical and functional images %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose 
    fprintf('\n*************\nCoregistration of T1 image %s on the T2* image %s\n*************\n',files_in.anat,files_in.functional);
end
%% Reading inputs
if flag_verbose
    fprintf('Reading inputs ...\n');
end
[hdr_func,func] = niak_read_vol(files_in.functional);
hdr_func.flag_zip = 0;
[hdr_anat,anat] = niak_read_vol(files_in.anat);
hdr_anat.flag_zip = 0;

opt_s.fwhm = fwhm;
hdr_func.flag_zip = 0;

%% Writing the smoothed anat
if flag_verbose
    fprintf('Writting a smoothed version of the anatomical image ...\n');
end
opt_s.voxel_size = hdr_anat.info.voxel_size;
anat = niak_smooth_vol(anat,opt_s);
file_anat_tmp = niak_file_tmp('_anat.mnc');
hdr_anat.file_name = file_anat_tmp;
niak_write_vol(hdr_anat,anat);

%% Writing the smoothed functional image
if flag_verbose
    fprintf('Writting a smoothed version of the functional image ...\n');
end
file_func_tmp = niak_file_tmp('_func.mnc');
func = mean(func,4);
opt_s.voxel_size = hdr_func.info.voxel_size;
func = niak_smooth_vol(func,opt_s);

hdr_func.file_name = file_func_tmp;
niak_write_vol(hdr_func,func);

%% applying minc tracc
file_transf_tmp = niak_file_tmp('_transf.mnc');
instr_minctracc = cat(2,'minctracc ',file_anat_tmp,' ',file_func_tmp,' ',file_transf_tmp,' -mi -debug -simplex 20 -step 5 5 5 -lsq6 -clobber');
if flag_verbose
    fprintf('Spatial coregistration using mutual information : %s\n',instr_minctracc);
end
[s,str_log] = system(instr_minctracc);

if ~strcmp(files_out.transformation,'gb_niak_omitted')
    copyfile(file_transf_tmp,files_out.transformation,'f');
end

if ~strcmp(files_out.functional_resampled,'gb_niak_omitted')|~strcmp(files_out.anat_hires,'gb_niak_omitted')|~strcmp(files_out.anat_lowres,'gb_niak_omitted')

    %% Read the xfm transformation
    hf = fopen(file_transf_tmp);
    xfm_info = fread(hf,Inf,'uint8=>char')';
    cell_info = niak_string2lines(xfm_info);
    transf = eye(4);
    transf(1,:) = str2num(cell_info{end-2});
    transf(2,:) = str2num(cell_info{end-1});
    transf(3,:) = str2num(cell_info{end}(1:end-1));
    transf(4,:) = [0 0 0 1];
    fclose(hf);

    %% Resample the anat at hi-res
    if ~strcmp(files_out.anat_hires,'gb_niak_omitted')
        
        if flag_verbose
            fprintf('Resampling the anatomical image at high resolution in the functional space: %s\n',files_out.anat_hires);
        end
        files_in_res.source = files_in.anat;
        files_in_res.target = files_in.functional;
        files_in_res.transformation = file_transf_tmp;
        files_out_res = files_out.anat_hires;
        opt_res.flag_tfm_space = 1;
        opt_res.voxel_size = 0;
        niak_resample_vol(files_in_res,files_out_res,opt_res);        
        
    end

    %% Resample the anat at low-res
    if ~strcmp(files_out.anat_hires,'gb_niak_omitted')
        if flag_verbose
            fprintf('Resampling the anatomical image at low resolution in the functional space : %s\n',files_out.anat_lowres);
        end
        files_in_res.source = files_in.anat;
        files_in_res.target = files_in.functional;
        files_in_res.transformation = file_transf_tmp;
        files_out_res = files_out.anat_lowres;
        opt_res.flag_tfm_space = 1;
        opt_res.voxel_size = [];
        niak_resample_vol(files_in_res,files_out_res,opt_res);                
    end

end

%% Get rif of the temporary file
delete(file_transf_tmp);
delete(file_anat_tmp);
delete(file_func_tmp);
