function [files_in,files_out,opt] = niak_brick_anat2func(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_ANAT2FUNC
%
% Coregister a T1 image with a T2* EPI image of the same subject using
% a rigid-body (lsq6) transform. The two images are assumed not to be too
% far from each other.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_ANAT2FUNC(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN
%       (structure) with the following fields :
%
%       FUNC
%           (string) a file with one fMRI volume. 
%
%       MASK_FUNC
%           (string, default 'gb_niak_omitted') a file with a binary mask 
%           of the brain in the functional space. The mask needs 
%           to be in the same voxel & world space as the anatomical image.
%           If not specified a mask will be estimated using
%           NIAK_MASK_BRAIN.
%
%       ANAT
%           (string) a file with one T1 volume of the same subject.
%
%       MASK_ANAT
%           (string) a file with a binary mask of the brain in the 
%           anatomical data. The mask needs to be in the same voxel & world 
%           space as the anatomical image.
%
%       TRANSFORMATION_INIT
%           (string, default identity) an initial guess of the
%           transformation between the functional image and the anatomical
%           image (e.g. the transformation from T1 native space to
%           stereotaxic linear space if the anat is in stereotaxic linear
%           space). 
%
%  * FILES_OUT
%       (structure) with the following fields. Note that if a field is an
%       empty string, a default value will be used to name the outputs. If
%       a field is ommited, the output won't be saved at all (this is
%       equivalent to setting up the output file names to 'gb_niak_omitted').
%
%       TRANSFORMATION
%           (string, default: transf_<BASE_ANAT>_to_<BASE_FUNC>.XFM)
%           File name for saving the transformation from the anatomical 
%           space to the functional space.
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
%       LIST_FWHM
%           (vector, default [16,8,4,8,4]) LIST_FWHM(I) is the FWHM of the
%           Gaussian smoothing applied at iteration I.
%
%       LIST_STEP
%           (vector, default [8,4,4,4,4]) LIST_STEP(I) is the step of
%           MINCTRACC at iteration I.
%
%       LIST_SIMPLEX
%           (vector, default [32,16,8,4,2]) LIST_SIMPLEX(I) is the simplex 
%           parameter of MINCTRACC at iteration I.
%
%       LIST_CROP
%           (vector, default [20 10 5 5 5]) LIST_CROP(I) is the cropping
%           parameter for the functional & anatomical masks at iteration I.
%
%       LIST_MES
%           (cell of string, default {'xcorr','xcorr','xcorr','mi','mi'}) 
%           LIST_MES{I} is the measure (cost function) used to coregister 
%           the two volumes in MINCTRACC at iteration I.
%
%       INIT
%           (string, default 'identity') how to set the initial guess
%           of the transformation. 'center': translation to align the
%           center of mass. 'identity' : identity transformation.
%           The 'center' option usually does more harm than good. Use it
%           only if you have very big misrealignement between the two
%           images (say, > 2 cm).
%
%       FLAG_INVERT_TRANSF
%           (boolean, default false) if the flag is true, the
%           transfonsformation provided in FILES_IN.TRANSFORMATION_INIT
%           will be inverted before being applied.
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
% SEE ALSO:
% NIAK_BRICK_T1_PREPROCESS, NIAK_PIPELINE_FMRI_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS
%
% NOTE 1:
%   The core of the function is a MINC tool called MINCTRACC which performs
%   rigid-body coregistration (lsq6).
%
% NOTE 2:
%   The targets are coregistered first using a cross-correlation cost 
%   function (robust to large displacement) and then mutual information 
%   to account for different tissue-contrast properties in T1 and EPI
%   sequences. Note that the T1 volume is "T2ified", i.e. its histogram is
%   modified to fit the inverse histogram of the T2. This justifies to use
%   "xcorr" in early steps, and improves the effect of blurring with MI.
%
% NOTE 3:
%   The coregistration is done in an iterative way, using large-to-small
%   blurring kernels, and corresponding step & simplex parameters. This
%   approach as well as the default parameters of each iteration have been
%   very largely inspired by a PERL script by Andrew Janke and Claude
%   Lepage, itself inspired by best1stepnlreg.pl by Steve Robinson. See
%   NIAK_BESTLINREG.PL for more details.
%
% NOTE 4:
%   At each iteration, the brain masks of both images (anatomical and 
%   functional) are cropped such that no voxel distant of more than 2 cm
%   of the other mask interfer with the coregistration process. This
%   feature allows the coregistration to be robust to large differences
%   between the fields of view. This cropping parameter can be changed
%   using OPT.LIST_CROP
%
% NOTE 5:
%   The quality of this approach critically relies on the T1 brain mask. 
%   This brick should therefore be used in conjunction with 
%   NIAK_BRICK_T1_PREPROCESS (this is what's being done in 
%   NIAK_PIPELINE_FMRI_PREPROCESSING).
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-10.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, coregistration, rigid-body motion, fMRI, T1

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
if ~exist('files_in','var')|~exist('files_out','var')
    error('niak_brick_anat2func, SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_ANAT2FUNC(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_anat2func'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields = {'anat','func','mask_anat','mask_func','transformation_init'};
gb_list_defaults = {NaN,NaN,NaN,'gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'transformation','anat_hires','anat_lowres'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'flag_invert_transf','list_mes','list_fwhm','list_step','list_simplex','list_crop','flag_test','folder_out','flag_verbose','init'};
gb_list_defaults = {false,{'xcorr','xcorr','xcorr','mi','mi'},[16,8,4,8,4],[8,4,4,4,4],[32,16,8,4,2],[20,10,5,5,5],0,'',1,'identity'};
niak_set_defaults

if ~strcmp(opt.init,'center')&~strcmp(opt.init,'identity')
    error('OPT.INIT should be either ''center'' or ''identity''');
end

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

[path_func,name_func,ext_func] = fileparts(files_in.func);

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
    files_out.transformation = cat(2,folder_func,filesep,'transf_',name_anat,'_to_',name_func,'.xfm');
end

if isempty(files_out.anat_lowres)
    files_out.anat_lowres = cat(2,folder_anat,filesep,name_anat,'_nativefunc_lowres',ext_anat);
end

if isempty(files_out.anat_hires)
    files_out.anat_hires = cat(2,folder_anat,filesep,name_anat,'_nativefunc_hires',ext_anat);
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of volumes and transformations %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    msg = 'T1-T2 COREGISTRATION';    
    stars = repmat('*',[1 length(msg)]);
    fprintf('%s\n%s\n%s\n',stars,msg,stars);
    fprintf('Source : %s\n',files_in.anat);
    fprintf('Target : %s\n',files_in.func);
end

%% Temporary file names

% Generate a temporary folder
path_tmp = niak_path_tmp('_coregister');                % The temporary folder

% Functional stuff ...
file_func_init      = [path_tmp 'func_init.mnc'];       % The original volume
file_func_crop      = [path_tmp 'func_crop.mnc'];       % The cropped volume
file_mask_func      = [path_tmp 'mask_func.mnc'];       % The brain mask 
file_mask_func_crop = [path_tmp 'mask_func_crop.mnc'];  % The cropped brain mask 

% Anatomical stuff ...
file_anat_init      = [path_tmp 'anat_init.mnc'];       % The original volume 
file_anat_crop      = [path_tmp 'anat_crop.mnc'];       % The cropped volume
file_mask_anat      = [path_tmp 'mask_anat.mnc'];       % The brain mask 
file_mask_anat_crop = [path_tmp 'mask_anat_crop.mnc'];  % The cropped brain mask 

% transformations ...
file_transf_init    = [path_tmp 'transf_init.xfm'];     % The initial transformation
file_transf_guess   = [path_tmp 'transf_guess.xfm'];    % The guess transformation
file_transf_est     = [path_tmp 'transf_est.xfm'];      % The estimated transformation
file_transf_tmp     = [path_tmp 'transf_tmp.xfm'];      % Temporary transformation for concatenation

% Scratch files for dirty jobs ...
file_tmp            = [path_tmp 'vol_tmp.mnc'];         % Temporary volume #1
file_tmp2           = [path_tmp 'vol_tmp2.mnc'];        % Temporary volume #2

%% Initial transformation
if strcmp(files_in.transformation_init,'gb_niak_omitted')
    transf = eye(4);
    niak_write_transf(transf,file_transf_init);
else
    if flag_invert_transf
        [succ,msg] = system(cat(2,'xfminvert ',files_in.transformation_init,' ',file_transf_init));
        if succ ~= 0
            error(msg);
        end
    else
        [succ,msg] = system(cat(2,'cp ',files_in.transformation_init,' ',file_transf_init));
        if succ ~= 0
            error(msg);
        end
    end
end

%% Writing the anatomical image in the functional space using the initial
%% transformation
if flag_verbose
    fprintf('Resampling the anatomical image in the functional space ...\n');
end

clear files_in_res files_out_res opt_res
files_in_res.source = files_in.anat;
files_in_res.target = files_in.func;
files_in_res.transformation = file_transf_init;
files_out_res = file_anat_init;
opt_res.voxel_size = 0;
opt_res.flag_tfm_space = 1;
opt_res.flag_verbose = 0;
opt_res.interpolation = 'tricubic';
niak_brick_resample_vol(files_in_res,files_out_res,opt_res);

%% Generating anatomical mask
if flag_verbose
    fprintf('Resampling the anatomical mask of the brain in the functional space ...\n');
end
clear files_in_res files_out_res opt_res
files_in_res.source = files_in.mask_anat;
files_in_res.target = files_in.func;
files_in_res.transformation = file_transf_init;
files_out_res = file_mask_anat;
opt_res.voxel_size = 0;
opt_res.flag_tfm_space = 1;
opt_res.flag_verbose = 0;
opt_res.interpolation = 'nearest_neighbour';
niak_brick_resample_vol(files_in_res,files_out_res,opt_res);

%% Copying the functional mask
if flag_verbose
    fprintf('Creating temporary copies of the functional mask ...\n');
end

% The functional mask
[hdr_func,mask_func] = niak_read_vol(files_in.mask_func);
mask_func = round(mask_func)>0;
hdr_func.file_name = file_mask_func;
niak_write_vol(hdr_func,mask_func);

%% Applying non-uniformity correction on the functional volume
if flag_verbose
    fprintf('Applying non-uniformity correction on the functional volume ...\n');
end
clear files_in_tmp files_out_tmp opt_tmp
files_in_tmp.vol = files_in.func;
files_in_tmp.mask = file_mask_func;
files_out_tmp.vol_nu = file_func_init;
opt_tmp.flag_verbose = false;
niak_brick_nu_correct(files_in_tmp,files_out_tmp,opt_tmp);
[hdr_func,vol_func] = niak_read_vol(file_func_init);

%% "T2ify" the T1 volume
if flag_verbose
    fprintf('"T2ifying" the T1 volume ...\n');
end
% Read anatomical stuff
[hdr_anat,vol_anat] = niak_read_vol(file_anat_init);
[hdr_anat,mask_anat] = niak_read_vol(file_mask_anat);
mask_anat = round(mask_anat)>0;

% Build a cumulative distribution function for the anat
[ya,xa] = hist(vol_anat(mask_anat),100);
ca = cumsum(ya)/sum(mask_anat(:));

% Build a cumulative distribution function for the functional
[yf,xf] = hist(vol_func(mask_func),100);
cf = cumsum(yf)/sum(mask_func(:));
[cf,ind] = unique(cf);
xf = xf(ind);

% Modify the intensity distribution of the T1 to make it more similar to
% the functional
vol_anat2 = zeros(size(vol_anat));
vol_anat2(mask_anat) = interp1(xa,ca,vol_anat(mask_anat));
vol_anat2(mask_anat) = interp1(1-cf,xf,vol_anat2(mask_anat));
hdr_anat.file_name = file_anat_init;
clear vol_anat 
niak_write_vol(hdr_anat,vol_anat2);
clear vol_anat2

%% For large displacement, make a first guess of the transformation by
%% matching the centers of mass
switch opt.init

    case 'center'

        if flag_verbose
            fprintf('Deriving a reasonable guess of the transformation by matching the brain masks ...\n');
        end     
        ind = find(mask_func>0);
        [x,y,z] = ind2sub(size(mask_func),ind);
        coord = (hdr_func.info.mat*[x';y';z';ones([1 length(x)])]);
        center_func = mean(coord,2)';
        ind = find(mask_anat>0);
        [x,y,z] = ind2sub(size(mask_anat),ind);
        coord = (hdr_anat.info.mat*[x';y';z';ones([1 length(x)])]);
        center_anat = mean(coord,2)';
        transf_guess = eye(4);        
        transf_guess(1:3,4) = (center_func(1:3)-center_anat(1:3))';
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

for num_i = 1:length(list_fwhm)

    %% Setting up parameters value for this iteration
    fwhm_val = list_fwhm(num_i);
    step_val = list_step(num_i);
    simplex_val = list_simplex(num_i);
    crop_val = list_crop(num_i);
    mes_val = list_mes{num_i};
    
    if flag_verbose
        fprintf('\n***************\nIteration %i\nSmoothing %1.2f\nStep %1.2f\nSimplex %1.2f\nCropping %1.2f\n***************\n',num_i,fwhm_val,step_val,simplex_val,crop_val);
    end

    %% Crop functional mask
    if flag_verbose
        fprintf('Cropping the functional brain mask ... \n');
    end
   
    % resample anatomical mask in functional space
    clear files_in_res files_out_res opt_res
    files_in_res.source = file_mask_anat;
    files_in_res.target = file_func_init;
    files_in_res.transformation = file_transf_guess;
    files_out_res = file_tmp;
    opt_res.voxel_size = 0;
    opt_res.flag_tfm_space = 0;
    opt_res.flag_invert_transf = false;
    opt_res.flag_verbose = 0;
    opt_res.interpolation = 'nearest_neighbour';
    niak_brick_resample_vol(files_in_res,files_out_res,opt_res);    
    
    % Dilate anatomical mask
    [hdr_func,mask_anat] = niak_read_vol(file_tmp);       
    opt_m.voxel_size = hdr_func.info.voxel_size;
    opt_m.pad_size = 2*crop_val;
    mask_anat = round(mask_anat)>0;
    mask_anat_d = niak_morph(~mask_anat,'-successive F',opt_m);
    mask_anat_d = mask_anat_d<=(crop_val/max(hdr_func.info.voxel_size));    
    
    % Crop functional mask
    [hdr_func,mask_func] = niak_read_vol(file_mask_func);
    mask_func_c = mask_anat_d & round(mask_func);
    hdr_func.file_name = file_mask_func_crop;
    niak_write_vol(hdr_func,mask_func_c);
    
    %% Crop anatomical mask
    if flag_verbose
        fprintf('Cropping the anatomical brain mask ... \n');
    end
   
    % resample anatomical mask in functional space keeping FOV
    clear files_in_res files_out_res opt_res
    files_in_res.source = file_mask_anat;
    files_in_res.target = file_mask_anat;
    files_in_res.transformation = file_transf_guess;
    files_out_res = file_tmp;
    opt_res.voxel_size = 0;
    opt_res.flag_tfm_space = true;
    opt_res.flag_invert_transf = false;
    opt_res.flag_verbose = 0;
    opt_res.interpolation = 'nearest_neighbour';
    niak_brick_resample_vol(files_in_res,files_out_res,opt_res);    
    
    % resample functional mask in anatomical space
    clear files_in_res files_out_res opt_res
    files_in_res.source = file_mask_func;
    files_in_res.target = file_tmp;    
    files_out_res = file_tmp2;
    opt_res.voxel_size = 0;
    opt_res.flag_tfm_space = false;
    opt_res.flag_invert_transf = false;
    opt_res.flag_verbose = 0;
    opt_res.interpolation = 'nearest_neighbour';
    niak_brick_resample_vol(files_in_res,files_out_res,opt_res);    
    
    % Dilate functional mask
    [hdr_anat,mask_func] = niak_read_vol(file_tmp2);
    opt_m.voxel_size = hdr_anat.info.voxel_size;
    opt_m.pad_size = 2*crop_val;
    mask_func = round(mask_func)>0;
    mask_func_d = niak_morph(~mask_func,'-successive F',opt_m);
    mask_func_d = mask_func_d<=(crop_val/max(hdr_anat.info.voxel_size));    
    
    % Crop anatomical mask
    [hdr_anat,mask_anat] = niak_read_vol(file_tmp);
    mask_anat_c = mask_func_d & round(mask_anat);
    hdr_anat.file_name = file_mask_anat_crop;
    niak_write_vol(hdr_anat,mask_anat_c);
    
    %% smooth & crop anat
    if flag_verbose
        fprintf('Cropping & smoothing the anatomical image in the functional space ...\n');
    end
    
    % resample anatomical volume in functional space
    clear files_in_res files_out_res opt_res
    files_in_res.source = file_anat_init;
    files_in_res.target = file_anat_init;
    files_in_res.transformation = file_transf_guess;
    files_out_res = file_tmp;
    opt_res.voxel_size = 0;
    opt_res.flag_tfm_space = 1;
    opt_res.flag_invert_transf = false;
    opt_res.flag_verbose = 0;
    opt_res.interpolation = 'tricubic';
    niak_brick_resample_vol(files_in_res,files_out_res,opt_res);

    % Smooth the anatomical volume
    clear files_in_tmp files_out_tmp opt_tmp
    files_in_tmp = file_tmp;
    files_out_tmp = file_tmp2;
    opt_tmp.fwhm = fwhm_val;
    opt_tmp.flag_verbose = false;
    opt_tmp.flag_edge = true;
    niak_brick_smooth_vol(files_in_tmp,files_out_tmp,opt_tmp);
    
    % Crop the anatomical volume
    [hdr_anat,vol_anat] = niak_read_vol(file_tmp2);
    vol_anat(~mask_anat_c) = 0;
    hdr_anat.file_name = file_anat_crop;
    niak_write_vol(hdr_anat,vol_anat);
    
    %% smooth & crop func
    if flag_verbose
        fprintf('Cropping & smoothing the functional image ...\n');
    end
        
    % Smooth the functional volume
    clear files_in_tmp files_out_tmp opt_tmp
    files_in_tmp = file_func_init;
    files_out_tmp = file_tmp;
    opt_tmp.fwhm = fwhm_val;
    opt_tmp.flag_verbose = false;
    opt_tmp.flag_edge = true;
    niak_brick_smooth_vol(files_in_tmp,files_out_tmp,opt_tmp);
    
    % Crop the functional volume
    [hdr_func,vol_func] = niak_read_vol(file_tmp);
    vol_func(~mask_func_c) = 0;
    hdr_func.file_name = file_func_crop;
    niak_write_vol(hdr_func,vol_func);        

    %% applying MINCTRACC    
    instr_minctracc = cat(2,'minctracc ',file_anat_crop,' ',file_func_crop,' ',file_transf_est,' -',mes_val,' -identity -simplex ',num2str(simplex_val),' -tol 0.00005 -step ',num2str(step_val),' ',num2str(step_val),' ',num2str(step_val),' -lsq6 -clobber');

    if flag_verbose
        fprintf('Spatial coregistration using mutual information :\n     %s\n',instr_minctracc);
    end
    if flag_verbose        
        system(instr_minctracc)
    else
        [s,str_log] = system(instr_minctracc);
        if s~=0
            error('There was a problem with MINCTRACC : %s',str_log);
        end
    end
    
    %% Updating the guess    
    [s,str_err] = system(['xfmconcat ' file_transf_guess ' ' file_transf_est ' ' file_transf_tmp]);
    if s~=0
        error('There was a problem with XFMCONCAT : %s',str_err);
    end
    system(['rm ' file_transf_est]);
    system(['rm ' file_transf_guess]);
    system(['cp ' file_transf_tmp ' ' file_transf_guess]);    

end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Writting the outputs %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\nWritting the outputs\n');
end

if ~strcmp(files_out.transformation,'gb_niak_omitted')
    [succ,msg] = system(cat(2,'xfmconcat ',file_transf_init,' ',file_transf_guess,' ',files_out.transformation));
    if succ~=0
        error(msg)
    end
else
        
    [succ,msg] = system(cat(2,'xfmconcat ',file_transf_init,' ',file_transf_guess,' ',file_transf_est));
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
        files_in_res.target = files_in.func;
        if ~strcmp(files_out.transformation,'gb_niak_omitted')
            files_in_res.transformation = files_out.transformation;
        else
            files_in_res.transformation = file_transf_est;
        end
        files_out_res = files_out.anat_hires;
        opt_res.flag_tfm_space = 1;
        opt_res.flag_invert_transf = 0;
        opt_res.voxel_size = -1;
        niak_brick_resample_vol(files_in_res,files_out_res,opt_res);

    end

    %% Resample the anat at low-res
    if ~strcmp(files_out.anat_lowres,'gb_niak_omitted')
        if flag_verbose
            fprintf('Resampling the anatomical image at low resolution in the functional space : %s\n',files_out.anat_lowres);
        end
        files_in_res.source = files_in.anat;
        files_in_res.target = files_in.func;
        if ~strcmp(files_out.transformation,'gb_niak_omitted')
            files_in_res.transformation = files_out.transformation;
        else
            files_in_res.transformation = file_transf_est;
        end
        opt_res.flag_invert_transf = 1;
        files_out_res = files_out.anat_lowres;
        opt_res.flag_tfm_space = 0;
        opt_res.flag_invert_transf = 0;
        opt_res.voxel_size = 0;
        niak_brick_resample_vol(files_in_res,files_out_res,opt_res);
    end

end

%% Get rid of the temporary file
rmdir(path_tmp,'s');

if flag_verbose
    fprintf('\nDone !\n');
end

