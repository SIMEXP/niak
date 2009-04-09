function [files_in,files_out,opt] = niak_brick_coregister(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_COREGISTER
%
% Coregister a T2* EPI image onto a T1 image of the same subject using
% a rigid-body (lsq6) transform. The two images are assumed not to be too
% far from each other (translation < 2 cm).
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_COREGISTER(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN
%       (structure) with the following fields :
%
%       FUNCTIONAL
%           (string) a file with one or multiple fMRI volume. If multiple
%           time frames are present, the coregistration will be performed
%           on the average.
%
%       ANAT
%           (string) a file with one T1 volume of the same subject.
%
%       MASK
%           (string) a file with the mask of brain of the anatomical data.
%           If this field is not specified, no mask will be used for the
%           coregistration. The mask needs to be in the same voxel & world
%           space as the anatomical image.
%
%       CSF
%           (string) a segmentation of the cerebro-spinal fluid in the
%           anatomical image. The CSF volume is used instead of the
%           anatomical image in the coregistration. The segmentation needs
%           to be in the same voxel & world space as the anatomical image.
%
%       TRANSFORMATION
%           (string, default identity) an initial guess of the
%           transformation between the functional image and the anatomical
%           image (e.g. the transformation from T1 native space to
%           stereotaxic linear space if the anat is in stereotaxic linear
%           space). This initial transformation may be combined with an
%           additional guess (see OPT.INIT).
%
%  * FILES_OUT
%       (structure) with the following fields. Note that if a field is an
%       empty string, a default value will be used to name the outputs. If
%       a field is ommited, the output won't be saved at all (this is
%       equivalent to setting up the output file names to 'gb_niak_omitted').
%
%       TRANSFORMATION
%           (string, default: transf_<BASE_FUNCTIONAL>_to_<BASE_ANAT>.XFM)
%           File name for saving the transformation from the functional
%           space to the anatomical space.
%
%       ANAT_HIRES
%           (string, default <BASE_ANAT>_nativefunc_hires)
%           File name for saving the anatomical image resampled in the
%           space of the functional space, using native resolution.
%
%       ANAT_LOWRES
%           (string, default <BASE_ANAT>_nativefunc_hires)
%           File name for saving the anatomical image resampled in the
%           space of the functional space, using the target resolution.
%
%  * OPT
%       (structure) with the following fields:
%
%       INIT
%           (string, default 'identity') how to set the initial guess
%           of the transformation. 'center': translation to align the
%           center of mass. 'identity' : identity transformation.
%           The 'center' option usually does more harm than good. Use it
%           only if you have very big misrealignement between the two
%           images (say, > 2 cm).
%
%       FOLDER_OUT
%           (string, default: path of FILES_IN) If present, all default
%           outputs will be created in the folder FOLDER_OUT. The folder
%           needs to be created beforehand.
%
%       FLAG_TEST
%           (boolean, default: 0) if FLAG_TEST equals 1, the brick does not
%           do anything but update the default values in FILES_IN,
%           FILES_OUT and OPT.
%
%       FLAG_VERBOSE
%           (boolean, default: 1) If FLAG_VERBOSE == 1, write messages
%           indicating progress.
%
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO
%
% NIAK_BRICK_CIVET, NIAK_PIPELINE_FMRI_PREPROCESSING
%
% _________________________________________________________________________
% COMMENTS
%
% The core of the function is a MINC tool called MINCTRACC which performs
% rigid-body coregistration.
%
% The segmentation of the csf and the brain mask are combined to create a
% volume with 0 outside the brain, 1 in the brain outside the CSF, and 2 in
% the CSF. A brain mask is segmented on the functional images, and the
% values inside the mask are divided by the median. These targets are also
% being smoothed and cropped. The brain masks of both images (anatomical
% and functional) are cropped such that no voxel distant of more than 2 cm
% of the other mask interfer with the coregistration process. This
% feature allows the coregistration to be robust to large differences
% between the fields of view. The targets are coregistered using a
% cross-correlation cost function.
%
% This approach for coregistration is designed to be very robust and
% accurate as long as the CSF segmentation and T1 brain mask are good. This
% assumption used to be kind of optimistic, but lattely the CIVET pipeline
% has proved to do a remarkably good job at providing these. This brick
% should therefore itself do a pretty good jobs over a wide range of image
% quality when used in conjunction with NIAK_BRICK_CIVET (this is what's
% being done in NIAK_PIPELINE_FMRI_PREPROCESSING).
%
% _________________________________________________________________________
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
flag_gb_niak_fast_gb = true;
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
gb_list_fields = {'flag_zip','flag_test','folder_out','flag_verbose','init'};
gb_list_defaults = {0,0,'',1,'center'};
niak_set_defaults

%% Building default output names
[path_anat,name_anat,ext_anat] = fileparts(files_in.anat);

if isempty(path_anat)
    path_anat = '.';
end

if strcmp(ext_anat,gb_niak_zip_ext)
    [tmp,name_anat,ext_anat] = fileparts(name_anat);
    ext_anat = cat(2,ext_anat,gb_niak_zip_ext);
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

if strcmp(ext_func,gb_niak_zip_ext)
    [tmp,name_func,ext_func] = fileparts(name_func);
    ext_func = cat(2,ext_func,gb_niak_zip_ext);
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
    files_out.anat_lowres = cat(2,folder_anat,filesep,name_anat,'_nativefunc_lowres',ext_anat);
end

if isempty(files_out.anat_hires)
    files_out.anat_hires = cat(2,folder_anat,filesep,name_anat,'_nativefunc_hires',ext_anat);
end

if ~strcmp(opt.init,'center')&~strcmp(opt.init,'identity')
    error('OPT.INIT should be either ''center'' or ''identity''');
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initializing anatomical and functional volumes %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\nCOREGISTRATION of %s and %s\n\n*************\nInitializing anatomical and functional volumes\n*************\n',files_in.functional,files_in.anat);
end

%% Generating temporary file names

% Generate a temporary folder
path_tmp = niak_path_tmp('_coregister'); 

% Functional stuff ...
file_func_init = [path_tmp 'func_init.mnc']; 
file_func_blur = [path_tmp 'func_blur.mnc'];

% Anatomical stuff ...
file_anat_init = [path_tmp 'anat_init.mnc']; 
file_anat_blur = [path_tmp 'anat_blur.mnc'];

% Masks ...
file_mask_func      = [path_tmp 'mask_func.mnc']; 
file_mask_func_crop = [path_tmp 'mask_func_crop.mnc'];
file_mask_anat      = [path_tmp 'mask_anat.mnc'];
file_mask_anat_crop = [path_tmp 'mask_anat_crop.mnc'];

% transformations ...
file_transf_init  = [path_tmp 'transf_init.xfm']; 
file_transf_guess = [path_tmp 'transf_guess.xfm'];
file_transf_est   = [path_tmp 'transf_est.xfm'];

% Scratch files for dirty jobs ...
file_tmp  = [path_tmp 'vol_tmp.mnc']; 

%% Initial transformation
if strcmp(files_in.transformation,'gb_niak_omitted')
    transf = eye(4);
    niak_write_transf(transf,file_transf_init);
else
    [succ,msg] = system(cat(2,'cp ',files_in.transformation,' ',file_transf_init));
    if succ ~= 0
        error(msg);
    end
end

%% Writing the functional image in the anatomical space using the initial
%% transformation
if flag_verbose
    fprintf('Resampling the functional image in the anatomical space...\n');
end
clear files_in_res files_out_res opt_res
[hdr_func,vol_func] = niak_read_vol(files_in.functional);
hdr_func.file_name = file_tmp;
siz_func = hdr_func.info.voxel_size;
niak_write_vol(hdr_func,vol_func);
files_in_res.source = file_tmp;
files_in_res.target = files_in.anat;
files_in_res.transformation = file_transf_init;
files_out_res = file_func_init;
opt_res.voxel_size = 0;
opt_res.flag_tfm_space = 1;
opt_res.flag_verbose = 0;
opt_res.interpolation = 'trilinear';
niak_brick_resample_vol(files_in_res,files_out_res,opt_res);

%% Generating functional mask
if flag_verbose
    fprintf('Building a mask of the functional space...\n');
end
opt_mask.fwhm = 2;
opt_mask.flag_remove_eyes = 1;
mask_func = niak_mask_brain(mean(abs(vol_func),4),opt_mask);
hdr_func.file_name = file_tmp;
niak_write_vol(hdr_func,mask_func);
instr_res = cat(2,'mincresample -clobber ',file_tmp,' ',file_mask_func,' -like ',file_func_init,' -transform ',file_transf_init,' -trilinear');
[succ,msg] = system(instr_res);

if succ~=0
    error(cat(2,'There was a problem in the resampling of the mask... COMMAND :',instr_res,' ; ERROR :',msg));
end

%% Correct the mean functional
[hdr_func_init,vol_func_init] = niak_read_vol(file_func_init);
[hdr_mask_func,mask_func] = niak_read_vol(file_mask_func);
vol_func_init(mask_func>0) = vol_func_init(mask_func>0)/median(vol_func_init(mask_func>0));
vol_func_init(mask_func==0) = 0;
hdr_func_init.file_name = file_func_init;
niak_write_vol(hdr_func_init,vol_func_init);

%% Generating anatomical mask & image
if flag_verbose
    fprintf('Creating a local copy of the mask of the brain in the anatomical space...\n');
end

[hdr_anat,mask_anat] = niak_read_vol(files_in.mask); % anatomical mask ...
hdr_anat.file_name = file_mask_anat;
mask_anat = round(mask_anat)>0;
niak_write_vol(hdr_anat,mask_anat);

[hdr_anat,vol_anat] = niak_read_vol(files_in.csf); % CSF segmentation ...
vol_anat(mask_anat) = ((vol_anat(mask_anat)>0)*1.5)+1;
hdr_anat.file_name = file_anat_init;
niak_write_vol(hdr_anat,vol_anat);

%% Initial transformation

switch opt.init

    case 'center'

        if flag_verbose
            fprintf('Deriving a reasonable guess of the transformation by matching the brain masks ...\n');
        end
        [hdr_func,mask_func] = niak_read_vol(file_mask_func);
        [hdr_anat,mask_anat] = niak_read_vol(file_mask_anat);
        transf_init = niak_read_transf(file_transf_init);
        ind = find(mask_func>0);
        [x,y,z] = ind2sub(size(mask_func),ind);
        coord = (hdr_func.info.mat*[x';y';z';ones([1 length(x)])]);
        center_func = median(coord,2)';
        ind = find(mask_anat>0);
        [x,y,z] = ind2sub(size(mask_anat),ind);
        coord = (hdr_anat.info.mat*[x';y';z';ones([1 length(x)])]);
        center_anat = median(coord,2)';
        transf_guess = eye(4);
        transf_guess(1:3,4) = (center_anat(1:3)-center_func(1:3))';
        transf_guess(1:3,4) = (center_anat(1:3)-center_func(1:3))';
        niak_write_transf(transf_guess,file_transf_guess);

    case 'identity'

        if flag_verbose
            fprintf('Initial transformation is the identity...\n');
        end
        transf_guess = eye(4);
        niak_write_transf(transf_guess,file_transf_guess);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Iterative coregistration %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Blurring parameters
list_fwhm = {3*siz_func,1.5*siz_func,siz_func};
list_fwhm_func = {[4 4 4],[2 2 2],[0 0 0]};
list_step = {3,3,2};
list_spline = {10,3,3};
list_crop = {20,10,5};

for num_i = 1:length(list_fwhm)

    %% Setting up parameters value for this iteration
    fwhm_val = list_fwhm{num_i};
    fwhm_val_func = list_fwhm_func{num_i};
    step_val = list_step{num_i};
    spline_val = list_spline{num_i};
    crop_val = list_crop{num_i};

    if flag_verbose
        fprintf('\n*************\nIteration %i, smoothing anatomical %1.2f,%1.2f,%1.2f, smoothing functional %1.2f,%1.2f,%1.2f, step %1.2f, spline %1.2f\n*************\n',num_i,fwhm_val(1),fwhm_val(2),fwhm_val(3),fwhm_val_func(1),fwhm_val_func(2),fwhm_val_func(3),step_val,spline_val);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Compute a cropping space common to both volumes %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if flag_verbose
        fprintf('\nCropping the images to a common field of view ... \n');
    end

    %% Cropping anatomical mask
    
    % resample functional mask in the anatomical space
    nb_dilate = ceil(crop_val/min(hdr_anat.info.voxel_size));
    instr_res = cat(2,'mincresample ',file_mask_func,' ',file_tmp,' -like ',file_mask_anat,' -transform ',file_transf_guess,' -trilinear -clobber');
    [succ,msg] = system(instr_res);
        
    %% Interesect the anatomical mask with the dilated functional mask
    [hdr_anat,mask_func_d] = niak_read_vol(file_tmp);
    mask_func_d = mask_func_d>0;
    mask_func_d = niak_dilate_mask(mask_func_d,6,nb_dilate);
    [hdr_anat,mask_anat_d] = niak_read_vol(file_mask_anat);
    hdr_anat.file_name = file_mask_anat_crop;
    niak_write_vol(hdr_anat,round(mask_anat_d) & mask_func_d);

    %% Dilate anatomical mask in the functional space
    
    % resample anatomical mask in functional space
    instr_res = cat(2,'mincresample ',file_mask_anat,' ',file_tmp,' -like ',file_mask_func,' -invert_transform -transform ',file_transf_guess,' -nearest_neighbour -clobber');
    [succ,msg] = system(instr_res);
    
    %% intersect the functional mask with the dilated anatomical mask
    nb_dilate = ceil(crop_val/min(hdr_func.info.voxel_size));
    [hdr_func,mask_anat_d] = niak_read_vol(file_tmp);
    mask_anat_d = mask_anat_d>0;
    mask_anat_d = niak_dilate_mask(mask_anat_d,6,nb_dilate);
    [hdr_func,mask_func_d] = niak_read_vol(file_mask_func);
    hdr_func.file_name = file_mask_func_crop;
    niak_write_vol(hdr_func,mask_anat_d&round(mask_func_d));
    
    %% Smoothing the functional image
    if flag_verbose
        fprintf('Smoothing the functional image ...\n');
    end
    if max(fwhm_val_func)>0
        instr_smooth = cat(2,'mincblur -clobber -no_apodize -quiet -3dfwhm ',num2str(fwhm_val_func),' ',file_func_init,' ',file_func_blur(1:end-9));
        if flag_verbose
            system(instr_smooth)
        else
            [succ,msg] = system(instr_smooth);
        end
    else
        [succ,msg] = copyfile(file_func_init,file_func_blur,'f');
    end
    if succ ~= 0
        error(msg)
    end
    
    %% Cropping the smoothed functional
    [hdr_tmp,vol_func_smooth] = niak_read_vol(file_func_blur);
    [hdr_func,mask_func] = niak_read_vol(file_mask_func_crop);
    vol_func_smooth(mask_func==0) = 0;
    hdr_tmp.file_name = file_func_blur;
    niak_write_vol(hdr_tmp,vol_func_smooth);

    %% smoothing anat
    if flag_verbose
        fprintf('Smoothing the anatomical image ...\n');
    end
    instr_smooth = cat(2,'mincblur -clobber -no_apodize -quiet -3dfwhm ',num2str(fwhm_val),' ',file_anat_init,' ',file_anat_blur(1:end-9));
    if flag_verbose
        system(instr_smooth)
    else
        [succ,msg] = system(instr_smooth);
        if succ ~= 0
            error(msg)
        end
    end

    %% Cropping the smoothed anat
    [hdr_tmp,vol_anat_smooth] = niak_read_vol(file_anat_blur);
    [hdr_func,mask_anat] = niak_read_vol(file_mask_anat_crop);
    vol_anat_smooth(mask_anat==0) = 0;
    %vol_anat_smooth = (vol_anat_smooth/max(vol_anat_smooth(:)))*max(vol_func_smooth(:));
    hdr_tmp.file_name = file_anat_blur;
    niak_write_vol(hdr_tmp,vol_anat_smooth);
    
    %% applying MINCTRACC
    instr_minctracc = cat(2,'minctracc ',file_func_blur,' ',file_anat_blur,' ',file_transf_est,' -transform ',file_transf_guess,' -mi -debug -simplex ',num2str(spline_val),' -tol 0.00005 -step ',num2str(step_val),' ',num2str(step_val),' ',num2str(step_val),' -lsq6 -clobber');    

    if flag_verbose
        fprintf('Spatial coregistration using mutual information : %s\n',instr_minctracc);
    end
    if flag_verbose
        instr_minctracc
        system(instr_minctracc)
    else
        [s,str_log] = system(instr_minctracc);
    end

    %% Updating the guess
    transf_est = niak_read_transf(file_transf_est);
    niak_write_transf(transf_est,file_transf_guess);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Writting the outputs %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\nWritting the outputs\n');
end

if ~strcmp(files_out.transformation,'gb_niak_omitted')
    [succ,msg] = system(cat(2,'xfmconcat ',file_transf_init,' ',file_transf_est,' ',files_out.transformation));
    if succ~=0
        error(msg)
    end
else
    file_transf_guess2 = [path_tmp 'transf_tmp2.xfm'];
    [succ,msg] = system(cat(2,'xfmconcat ',file_transf_init,' ',file_transf_est,' ',file_transf_guess2));
    if succ~=0
        error(msg)
    end
end

if ~strcmp(files_out.anat_hires,'gb_niak_omitted')|~strcmp(files_out.anat_lowres,'gb_niak_omitted')

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
            files_in_res.transformation = file_transf_guess2;
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
            files_in_res.transformation = file_transf_guess2;
        end
        opt_res.flag_invert_transf = 1;
        files_out_res = files_out.anat_lowres;
        opt_res.flag_tfm_space = 0;
        opt_res.flag_invert_transf = 1;
        opt_res.voxel_size = 0;
        niak_brick_resample_vol(files_in_res,files_out_res,opt_res);
    end

end

%% Get rid of the temporary file
rmdir(path_tmp,'s');

if flag_verbose
    fprintf('\nDone !\n');
end