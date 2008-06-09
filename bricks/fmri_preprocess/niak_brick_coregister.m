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
%       MASK (string)
%           a file with the mask of brain of the anatomical data.
%           If this field is not specified, no mask will be used for the
%           coregistration. The mask needs to be in the same world and
%           voxel space as the anatomical image.
%
%       CSF (string)
%           a segmentation of the cerebro-spinal fluid in the anatomical
%           image. If such a segmentation is provided, it will be used
%           instead of the anatomical image in the coregistration.
%
%       TRANSFORMATION (string, default identity)
%           an initial guess of the transformation between the functional
%           image and the anatomical image (e.g. the transformation from T1
%           native space to stereotaxic linear space if the anat is in
%           stereotaxic linear space). This initial transformation may be
%           combined with an additional guess (see OPT.INIT).
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
%       INIT (string, default 'center') how to set the initial guess
%           of the transformation. 'center': translation to align the
%           center of mass. 'identity' : identity transformation.
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
niak_gb_vars

%% SYNTAX
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak_brick_motion_correction, SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_CORRECTION_WS(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_time_filter'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields = {'anat','functional','mask','csf','transformation'};
gb_list_defaults = {NaN,NaN,NaN,NaN,'gb_niak_omitted'};
niak_set_defaults

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'transformation','anat_hires','anat_lowres'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'flag_zip','flag_test','folder_out','interpolation','flag_verbose','fwhm','init'};
gb_list_defaults = {0,0,'','trilinear',1,8,'center'};
niak_set_defaults

if ~strcmp(opt.init,'center')&~strcmp(opt.init,'identity')
    error('OPT.INIT should be either ''center'' or ''identity''');
end

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
list_fwhm = {8,4};
list_fwhm_func = {4,1};
list_step = {3,3};
list_spline = {20,3};

%% Generating temporary file names
file_func_tmp = niak_file_tmp('_func_blur.mnc');
file_func_init = niak_file_tmp('_func_init.mnc');
file_anat_init = niak_file_tmp('_anat.mnc');
file_anat_tmp = niak_file_tmp('_anat_blur.mnc');
file_transf_tmp = niak_file_tmp('_transf.xfm');
file_transf_init = niak_file_tmp('_transf_init.xfm');

%% Initialization of the transformation
if strcmp(files_in.transformation,'gb_niak_omitted')
    transf = eye(4);
    niak_write_transf(transf,file_transf_init);
else
    [succ,msg] = system(cat(2,'cp ',files_in.transformation,' ',file_transf_init));
    if succ ~= 0
        error(msg);
    end
end

%% Writing the functional image in the anatomical space
if flag_verbose
    fprintf('Resampling the functional image in the anatomical space...\n');
end
clear files_in_res files_out_res opt_res
files_in_res.source = files_in.functional;
files_in_res.target = files_in.anat;
files_in_res.transformation = file_transf_init;
files_out_res = file_func_init;
opt_res.voxel_size = 0;
opt_res.flag_verbose = 0;
opt_res.interpolation = 'sinc';
niak_brick_resample_vol(files_in_res,files_out_res,opt_res);

%% Generating functional mask
if flag_verbose
    fprintf('Building a mask of the functional space...\n');
end

[hdr_func,vol_func] = niak_read_vol(file_func_init);
opt_mask.fwhm = 0;
mask_func = niak_mask_brain(mean(abs(vol_func),4),opt_mask);
mean_func = mean(vol_func(mask_func>0));
file_mask_func_init = niak_file_tmp('_mask_func_init.mnc');
hdr_func.file_name = file_mask_func_init;
niak_write_vol(hdr_func,mask_func);
nb_erode = ceil(6/min(hdr_func.info.voxel_size));
file_mask_func = niak_file_tmp('_mask_func.mnc');
instr_erode = cat(2,'mincmorph -clobber -successive CC',repmat('E',[1 nb_erode]),' ',file_mask_func_init,' ',file_mask_func);
if flag_verbose
    system(instr_erode)
else
    [succ,msg] = system(instr_erode);
    if succ ~= 0
        error(msg)
    end
end

%% Generating anatomical mask
if flag_verbose
    fprintf('Building a mask of the anatomical space...\n');
end

[hdr_mask,mask_anat] = niak_read_vol(files_in.mask);
nb_erode = ceil(6/min(hdr_mask.info.voxel_size));
file_mask_anat = niak_file_tmp('_mask_anat.mnc');

instr_erode = cat(2,'mincmorph -clobber -successive CC',repmat('E',[1 nb_erode]),' ',files_in.mask,' ',file_mask_anat);
if flag_verbose
    system(instr_erode)
else
    [succ,msg] = system(instr_erode);
    if succ ~= 0
        error(msg)
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Iterative coregistration %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for num_i = 1:length(list_fwhm)

    fwhm_val = list_fwhm{num_i};
    fwhm_val_func = list_fwhm_func{num_i};
    step_val = list_step{num_i};
    spline_val = list_spline{num_i};

    if flag_verbose
        fprintf('\n*************\nIteration %i, smoothing anatomical %1.2f, smoothing functional %1.2f, step %1.2f\n*************\n',num_i,fwhm_val,fwhm_val_func,step_val);
    end             
    
    %% adjusting the csf segmentation   
    if flag_verbose
        fprintf('Masking the brain in anatomical space ...\n');
    end    
    [hdr_anat,vol_anat] = niak_read_vol(files_in.csf);
    [hdr_mask_anat,mask_anat] = niak_read_vol(file_mask_anat);    
    if num_i == 1
        %% this is the first iteration : big spline. 
        %% Use a specic class tag for the part
        %% of the volume outside the brain. This will prevent the
        %% coregistration to go completely off the track
        vol_anat(round(mask_anat)==0) = -1;
    else
        %% this is the second iteration : small spline. 
        %% Use the same tag for the part
        %% of the volume outside the brain as the WM and GM. 
        %% This will reduce the weight of edges effect and let the
        %% algorithm concentrate on what really matters (ventricles and
        %% sulci).
        vol_anat(round(mask_anat)==0) = 0;
    end
    hdr_anat.file_name = file_anat_init;
    niak_write_vol(hdr_anat,vol_anat);
    
    %% smoothing anat
    if flag_verbose
        fprintf('Smoothing the anatomical image ...\n');
    end
    instr_smooth = cat(2,'mincblur -clobber -no_apodize -quiet -fwhm ',num2str(fwhm_val),' ',file_anat_init,' ',file_anat_tmp(1:end-9));    
    if flag_verbose
        system(instr_smooth)
    else
        [succ,msg] = system(instr_smooth);
        if succ ~= 0
            error(msg)
        end
    end
    
    %% Masking the brain in functional space
    if flag_verbose
        fprintf('Masking the brain in functional space ...\n');
    end
    [hdr_func,vol_func] = niak_read_vol(file_func_init);
    [hdr_mask_func,mask_func] = niak_read_vol(file_mask_func);
    if num_i == 1
        %% this is the first iteration : big spline. 
        %% Use a specic class tag for the part
        %% of the volume outside the brain. This will prevent the
        %% coregistration to go completely off the track
        vol_func(mask_func==0) = -mean_func;
    else
        %% this is the second iteration : small spline.         
        vol_func(mask_func==0) = 0;
    end
    hdr_func.file_name = file_func_init;
    niak_write_vol(hdr_func,vol_func);
    
    %% Smoothing the functional image
    if flag_verbose
        fprintf('Smoothing the functional image ...\n');
    end
    instr_smooth = cat(2,'mincblur -clobber -no_apodize -quiet -fwhm ',num2str(fwhm_val_func),' ',file_func_init,' ',file_func_tmp(1:end-9));
    if flag_verbose
        system(instr_smooth)
    else
        [succ,msg] = system(instr_smooth);
        if succ ~= 0
            error(msg)
        end
    end

    %% At iteration 1, derive a reasonable guess of the transformation by
    %% matching the centers of mass.
    if num_i == 1
        
        switch opt.init
            
            case 'center'
        
                if flag_verbose
                    fprintf('Deriving a reasonable guess of the transformation by matching the centers of mass ...\n');
                end                
                ind = find(mask_func>0);
                [x,y,z] = ind2sub(size(mask_func),ind);
                coord = (hdr_func.info.mat*[x';y';z';ones([1 length(x)])])';
                center_func = mean(coord,1);                
                ind = find(mask_anat>0);
                [x,y,z] = ind2sub(size(mask_anat),ind);
                coord = (hdr_mask.info.mat*[x';y';z';ones([1 length(x)])])';
                center_anat = mean(coord,1);
                transf = eye(4);
                transf(1:3,4) = (center_anat(1:3)-center_func(1:3))';
                niak_write_transf(transf,file_transf_tmp);
                
            case 'identity'
                
                if flag_verbose
                    fprintf('Initial transformation is the identity...\n');
                end
                transf = eye(4);
                niak_write_transf(transf,file_transf_tmp);
                
        end

        
    end

    %% applying minc tracc    
    if num_i == 1
        instr_minctracc = cat(2,'minctracc ',file_func_tmp,' ',file_anat_tmp,' ',file_transf_tmp,' -transform ',file_transf_tmp,' -mi -debug -simplex ',num2str(spline_val),' -tol 0.00005 -step ',num2str(step_val),' ',num2str(step_val),' ',num2str(step_val),' -lsq6 -clobber');    
    else
        instr_minctracc = cat(2,'minctracc ',file_func_tmp,' ',file_anat_tmp,' ',file_transf_tmp,' -transform ',file_transf_tmp,' -xcorr -debug -simplex ',num2str(spline_val),' -tol 0.00005 -step ',num2str(step_val),' ',num2str(step_val),' ',num2str(step_val),' -lsq6 -clobber');    
    end
    
    if flag_verbose
        fprintf('Spatial coregistration using mutual information : %s\n',instr_minctracc);
    end
    if flag_verbose
        instr_minctracc
        system(instr_minctracc)
    else
        [s,str_log] = system(instr_minctracc);
    end


end

%% Saving the transformation
if ~strcmp(files_out.transformation,'gb_niak_omitted')
    [succ,msg] = system(cat(2,'xfmconcat ',file_transf_init,' ',file_transf_tmp,' ',files_out.transformation));
    if succ~=0
        error(msg)
    end
else
    file_transf_tmp2 = niak_file_tmp('_transf_tmp2.xfm');
    [succ,msg] = system(cat(2,'xfmconcat ',file_transf_init,' ',file_transf_tmp,' ',file_transf_tmp2));
    if succ~=0
        error(msg)
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
        if ~strcmp(files_out.transformation,'gb_niak_omitted')
            files_in_res.transformation = files_out.transformation;
        else
            files_in_res.transformation = file_transf_tmp2;
        end
        files_out_res = files_out.anat_hires;
        opt_res.flag_tfm_space = 1;
        opt_res.flag_invert_transf = 1;
        opt_res.voxel_size = -1;
        niak_brick_resample_vol(files_in_res,files_out_res,opt_res);

    end

    %% Resample the anat at low-res
    if ~strcmp(files_out.anat_lowres,'gb_niak_omitted')
        if flag_verbose
            fprintf('Resampling the anatomical image at low resolution in the functional space : %s\n',files_out.anat_lowres);
        end
        files_in_res.source = files_in.anat;
        files_in_res.target = files_in.functional;
        if ~strcmp(files_out.transformation,'gb_niak_omitted')
            files_in_res.transformation = files_out.transformation;
        else
            files_in_res.transformation = file_transf_tmp2;
        end
        opt_res.flag_invert_transf = 1;
        files_out_res = files_out.anat_lowres;
        opt_res.flag_tfm_space = 1;
        opt_res.flag_invert_transf = 1;
        opt_res.voxel_size = 0;
        niak_brick_resample_vol(files_in_res,files_out_res,opt_res);
    end

end

%% Get rid of the temporary file
if strcmp(files_out.transformation,'gb_niak_omitted')
    delete(file_transf_tmp2);
end

delete(file_mask_anat);
delete(file_mask_func);
delete(file_mask_func_init)
delete(file_transf_init);
delete(file_transf_tmp);
delete(file_anat_tmp);
delete(file_anat_init);
delete(file_func_tmp);
delete(file_func_init);