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
%       CSF (string, default not used)
%           a segmentation of the cerebro-spinal fluid in the anatomical
%           image. If such a segmentation is provided, it will be used
%           instead of the anatomical image in the coregistration.
%
%       TRANSFORMATION (string, default identity)
%           an initial guess of the transformation between the functional
%           image and the anatomical image.
%
%   FILES_OUT  (structure) with the following fields. Note that if
%     a field is an empty string, a default value will be used to
%     name the outputs. If a field is ommited, the output won't be
%     saved at all (this is equivalent to setting up the output file
%     names to 'gb_niak_omitted').
%
%       TRANSFORMATION (string, 
%           default: transf_<BASE_FUNCTIONAL>_to_<BASE_ANAT>.XFM)
%           File name for saving the transformation from the functional
%           space to the anatomical space.
%
%       ANAT_HIRES (string, default <BASE_ANAT>_funcspace_hires)
%           File name for saving the anatomical image resampled in the
%           space of the functional space, using native resolution.
%     
%       ANAT_LOWRES (string, default <BASE_ANAT>_funcspace_hires)
%           File name for saving the anatomical image resampled in the
%           space of the functional space, using the target resolution.
%
%   OPT   (structure) with the following fields:
%
%       FWHM (real number, default 8 mm) the fwhm of the blurring kernel
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
gb_list_fields = {'anat','functional','csf','transformation'};
gb_list_defaults = {NaN,NaN,'gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'transformation','anat_hires','anat_lowres'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'flag_zip','flag_test','folder_out','interpolation','flag_verbose','fwhm'};
gb_list_defaults = {0,0,'','trilinear',1,8};
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
    files_out.transformation = cat(2,folder_func,filesep,'transf_',name_func,'_to_',name_anat,'.xfm');
end

if isempty(files_out.anat_lowres)
    files_out.anat_lowres = cat(2,folder_anat,filesep,name_anat,'_funcspace_lowres',ext_anat);
end

if isempty(files_out.anat_hires)
    files_out.anat_hires = cat(2,folder_anat,filesep,name_anat,'_funcspace_hires',ext_anat);
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Coregistration of the anatomical and functional images %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
list_fwhm = {8,3};
list_step = {3,3};
list_spline = {30,3};

%% Generating temporary file names
file_func_tmp = niak_file_tmp('_func_blur.mnc');
file_transf_tmp = niak_file_tmp('_transf.xfm');
file_anat_tmp = niak_file_tmp('_anat_blur.mnc');

%% Generating a mask of the functional volume
[hdr_func,vol] = niak_read_vol(files_in.functional);
mask = niak_mask_brain(abs(vol));
file_mask_func = niak_file_tmp('_mask.mnc');
hdr_func.file_name = file_mask_func;
niak_write_vol(hdr_func,mask);

%% Initialization of the transformation
if strcmp(files_in.transformation,'gb_niak_omitted')
    transf = eye(4);
    niak_write_transf(transf,file_transf_tmp);
else
    [succ,msg] = system(cat(2,'cp ',files_in.transformation,' ',file_transf_tmp));
    if succ ~= 0
        error(msg);
    end
end

for num_i = 1:length(list_fwhm)

    fwhm = list_fwhm{num_i};
    step = list_step{num_i};
    spline = list_spline{num_i};
    
    if flag_verbose
        fprintf('\n*************\nIteration %i, smoothing %1.2f, step %1.2f\n*************\n',num_i,fwhm,step);
    end
    
    if flag_verbose
        fprintf('\n*************\nCoregistration of T1 image %s on the T2* image %s\n*************\n',files_in.anat,files_in.functional);
    end

    %% Writing the smoothed anat
    if flag_verbose
        if ~strcmp(files_in.csf,'gb_niak_omitted')
            fprintf('Writting a smoothed version of the csf image ...\n');
        else
            fprintf('Writting a smoothed version of the anatomical image ...\n');
        end
    end
        
    if ~strcmp(files_in.csf,'gb_niak_omitted')
        instr_smooth = cat(2,'mincblur -clobber -no_apodize -quiet -fwhm ',num2str(fwhm),' ',files_in.csf,' ',file_anat_tmp(1:end-9));
    else
        instr_smooth = cat(2,'mincblur -clobber -no_apodize -quiet -fwhm ',num2str(fwhm),' ',files_in.anat,' ',file_anat_tmp(1:end-9));
    end
    if flag_verbose
        system(instr_smooth)
    else
        [succ,msg] = system(instr_smooth);
        if succ ~= 0
            error(msg)
        end
    end    

    %% Writing the smoothed functional image
    if flag_verbose
        fprintf('Writting a smoothed version of the functional image ...\n');
    end    
    instr_smooth = cat(2,'mincblur -clobber -no_apodize -quiet -fwhm ',num2str(fwhm),' ',files_in.functional,' ',file_func_tmp(1:end-9));
    if flag_verbose
        system(instr_smooth)
    else
        [succ,msg] = system(instr_smooth);
        if succ ~= 0
            error(msg)
        end
    end

    %% applying minc tracc    
    %instr_minctracc = cat(2,'minctracc ',file_func_tmp,' ',file_anat_tmp,' ',file_transf_tmp,' -transform ',file_transf_tmp,' -source_mask ',file_mask_func,' -mi -debug -est_center -simplex 30 -tol 0.00005 -step ',num2str(step),' ',num2str(step),' ',num2str(step),' -lsq6 -clobber');
    instr_minctracc = cat(2,'minctracc ',file_func_tmp,' ',file_anat_tmp,' ',file_transf_tmp,' -transform ',file_transf_tmp,' -mi -debug -est_center -simplex ',num2str(spline),' -tol 0.00005 -step ',num2str(step),' ',num2str(step),' ',num2str(step),' -lsq9 -clobber');
    
    if flag_verbose
        fprintf('Spatial coregistration using mutual information : %s\n',instr_minctracc);
    end
    if flag_verbose
        system(instr_minctracc)
    else
        [s,str_log] = system(instr_minctracc);
    end
    

    if ~strcmp(files_out.transformation,'gb_niak_omitted')
        [succ,msg] = system(cat(2,'cp ',file_transf_tmp,' ',files_out.transformation));
        if succ~=0
            error(msg)
        end
    end
end

if  ~strcmp(files_out.anat_hires,'gb_niak_omitted')|~strcmp(files_out.anat_lowres,'gb_niak_omitted')  

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
        opt_res.flag_invert_transf = 1;
        opt_res.voxel_size = 0;
        niak_brick_resample_vol(files_in_res,files_out_res,opt_res);        
        
    end

    %% Resample the anat at low-res
    if ~strcmp(files_out.anat_lowres,'gb_niak_omitted')
        if flag_verbose
            fprintf('Resampling the anatomical image at low resolution in the functional space : %s\n',files_out.anat_lowres);
        end
        files_in_res.source = files_in.anat;
        files_in_res.target = files_in.functional;
        files_in_res.transformation = file_transf_tmp;
        opt_res.flag_invert_transf = 1;
        files_out_res = files_out.anat_lowres;
        opt_res.flag_tfm_space = 1;
        opt_res.voxel_size = [];
        niak_brick_resample_vol(files_in_res,files_out_res,opt_res);                
    end

end

%% Get rid of the temporary file
delete(file_transf_tmp);
delete(file_anat_tmp);
delete(file_func_tmp);
delete(file_mask_func);