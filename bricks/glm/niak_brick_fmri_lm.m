function [files_in,files_out,opt] = niak_brick_fmri_lm(files_in,files_out,opt)

% _________________________________________________________________________
% SUMMARY NIAK_BRICK_FMRI_LM
%
% Fits a linear model to fMRI time series data.
%
% The method is based on linear models with correlated AR(p) errors:
% Y = hrf*X b + e, e_t=a_1 e_(t-1) + ... + a_p e_(t-p) + white noise_t. 
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_FMRI_LM(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%  FILES_IN  
%       (structure) with the following fields:
%
%       FMRI 
%           (string) the name of a file containing an fMRI dataset. 
%
%       MASK
%           (string, default 'gb_niak_omitted') the name of a 3D binary 
%           volume that defines a mask of the brain. If non-specified (or
%           equal to 'gb_niak_omitted'), a brain mask is computed 
%           internally.
%
%       DESIGN
%           (string) the name a matlab file containing a description of the
%           design matrix. See the help of NIAK_BRICK_FMRI_DESIGN. 
%
%
%  FILES_OUT
%        (structure) of filenames with the following fields:
%
%        DF
%           (string, default <BASE FMRI>_df.mat) 
%           The name a matlab file containing the variable DF
%
%        FWHM
%           (string, default <BASE FMRI>_fwhm.mat) 
%           The name a matlab file containing the variable FWHM
%
%        MAG_T 
%           (string, default <BASE FMRI>_mag_t.<EXT FMRI>) 
%           The name an image file containing the T statistic image =ef/sd 
%           for magnitudes. If T > 100, T = 100.
%
%        MAG_EF      
%           (string, default <BASE FMRI>_mag_ef.<EXT FMRI>) 
%           The name an image file containing the effect image for 
%           magnitudes.
%
%        MAG_SD      
%           (string, default <BASE FMRI>_mag_sd.<EXT FMRI>) 
%           The name an image file containing the standard deviation of the 
%           effect for magnitudes. 
%
%        MAG_F    
%           (string, default <BASE FMRI>_mag_f.<EXT FMRI>) 
%           The name an image file containing the F-statistic for test of 
%           magnitudes of all rows of OPT.CONTRAST selected by MAG_F. 
%           The degrees of freedom are DF.F. If F > 1000, F = 1000.
%
%        COR
%           (string, default <BASE FMRI>_cor.<EXT FMRI>) 
%           The name an image file containing the temporal 
%           autocorrelation(s). 
%
%        RESID   
%           (string, default <BASE FMRI>_resid.<EXT FMRI>) 
%           The name an image file containing the residuals from the model, 
%           only for non-excluded frames.
%
%        WRESID  
%           (string, default <BASE FMRI>_wresid.<EXT FMRI>) 
%           The name an image file containing the whitened residuals from 
%           the model normalized by dividing by their root sum of squares, 
%           only for non-excluded frames.
%
%        AR
%           (string, default <BASE FMRI>_ar.<EXT FMRI>) 
%           The name an image file containing the AR parameter(s) 
%           a_1 ... a_p.
%         
%  OPT   
%       (structure) with the following fields.
%       Note that if a field is omitted, it will be set to a default
%       value if possible, or will issue an error otherwise.
%
%       MASK_THRESH
%           (scalar, default : computed using NIAK_MASK_THRESHOLD)
%           a scalar value for thresholding a volume and defininig a brain
%           mask. Note that the mask will not be computed if FILES_IN.MASK
%           is specified.
%
%       CONTRAST         
%            matrix of contrast of interest for the responses or a structure
%            with fields x,c,t,s for the contrast associated to the responses,
%            confounds, temporal trends and spatial trends, respectively.
%
%       SPATIAL_AV
%           (vector, default [] and NB_TRENDS_SPATIAL = 0)
%           colum vector of the spatial average time courses.
%
%       CONFOUNDS 
%           (matrix, default [] i.e. no confounds)
%           A matrix or array of extra columns for the design matrix
%           that are not convolved with the HRF, e.g. movement artifacts. 
%           If a matrix, the same columns are used for every slice; if an array,
%           the first two dimensions are the matrix, the third is the slice.
%           For functional connectivity with a single voxel, use
%           FMRI_INTERP to resample the reference data at different slice 
%           times, or apply NIAK_BRICK_SLICE_TIMING to the fMRI data as a
%           preprocessing.
%
%       EXCLUDE 
%           (vector, default []) 
%           A list of frames that should be excluded from the
%           analysis. This must be used with Siemens EPI scans to remove the
%           first few frames, which do not represent steady-state images.
%           If OPT.NUMLAGS=1, the excluded frames can be arbitrary, 
%           otherwise they should be from the beginning and/or end.
%
%       NB_TRENDS_SPATIAL 
%           (scalar, default 0 will remove no spatial trends) 
%           order of the polynomial in the spatial average (SPATIAL_AV)  
%           weighted by first non-excluded frame; 
%          
%       NB_TRENDS_TEMPORAL 
%           (scalar, default 0)
%           number of cubic spline temporal trends to be removed per 6 
%           minutes of scanner time. 
%           Temporal  trends are modeled by cubic splines, so for a 6 
%           minute run, N_TEMPORAL<=3 will model a polynomial trend of 
%           degree N_TEMPORAL in frame times, and N_TEMPORAL>3 will add 
%           (N_TEMPORAL-3) equally spaced knots.
%           N_TEMPORAL=0 will model just the constant level and no 
%           temporal trends.
%           N_TEMPORAL=-1 will not remove anything, in which case the design matrix 
%           is completely determined by X_CACHE.X.
%
%       NUM_HRF_BASES 
%           (row vector; default [1; ... ;1]) 
%           number of basis functions for the hrf for each response, 
%           either 1 or 2 at the moment. At least one basis functions is 
%           needed to estimate the magnitude, but two basis functions are 
%           needed to estimate the delay.
%
%       BASIS_TYPE 
%           (string, 'spectral') 
%           basis functions for the hrf used for delay estimation, or 
%           whenever NUM_HRF_BASES = 2. 
%           These are convolved with the stimulus to give the responses in 
%           Dim 3 of X_CACHE.X:
%           'taylor' - use hrf and its first derivative (components 1&2)
%           'spectral' - use first two spectral bases (components 3&4 of 
%           Dim 3).
%           Ignored if NUM_HRF_BASES = 1, in which case it always uses 
%           component 1, i.e. the hrf is convolved with the stimulus.
%
%       NUMLAGS
%           (integer, default 1) The order (p) of the autoregressive model.
%
%       PCNT
%           (boolean, default 0)
%           if PCNT=1, then the data is converted to percentages 
%           before analysis by dividing each frame by its spatial average,* 100%.
%
%       FWHM
%           (default [], which corresponds to achieving 100 df, but if
%           CONTRAST is empty then the default is 0 i.e. no smoothing.)
%           It is the fwhm in mm of a 3D Gaussian kernel used to smooth the
%           autocorrelation of residuals. Setting it to Inf smooths the 
%           autocorrelation to 0, i.e. it assumes the frames are 
%           uncorrelated (useful for TR>10 seconds). Setting it to 0 does 
%           no smoothing.
%           If FWHM_COR is negative, it is taken as the desired df, and the 
%           fwhm is chosen to achive this df, or 90% of the residual df, 
%           whichever is smaller, for every contrast, up to 50mm. 
%           If a second component is supplied, it is the fwhm in mm of the 
%           data, otherwise this is estimated quickly from the 
%           least-squares residuals. 
%           If FWHM_COR is a file name, e.g. the _cor.ext file created by a
%           previous run, it is used for the autocorrelations - saves 
%           execution time.
%           If df.cor cannot be found in the header or _cor_df.txt file, 
%           Inf is used.           
%
%       DF_LIMIT 
%           (scalar, default 4)
%           Controls which method is used for estimating FWHM. 
%           If DF > DF_LIMIT, then the FWHM is calculated assuming the 
%           Gaussian filter is arbitrary. However if DF is small, this 
%           gives inaccurate results, so if DF <= DF_LIMIT, the FWHM is 
%           calculated assuming that the axes of the Gaussian filter are 
%           aligned with the x, y and z axes of the data. 
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) 
%           If present, all default outputs will be created in the folder 
%           FOLDER_OUT. The folder needs to be created beforehand.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) 
%           if the flag is 1, then the function prints some infos during 
%           the processing.
%
%       FLAG_TEST 
%           (boolean, default 0) 
%           if FLAG_TEST equals 1, the brick does not do anything but 
%           update the default values in FILES_IN, FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS
%
% This function is a NIAKIFIED port of a part of the FMRILM function of the
% fMRIstat project. The original license of fMRIstat was : 
%
%############################################################################
% COPYRIGHT:   Copyright 2002 K.J. Worsley
%              Department of Mathematics and Statistics,
%              McConnell Brain Imaging Center, 
%              Montreal Neurological Institute,
%              McGill University, Montreal, Quebec, Canada. 
%              worsley@math.mcgill.ca, liao@math.mcgill.ca
%
%              Permission to use, copy, modify, and distribute this
%              software and its documentation for any purpose and without
%              fee is hereby granted, provided that the above copyright
%              notice appear in all copies.  The author and McGill University
%              make no representations about the suitability of this
%              software for any purpose.  It is provided "as is" without
%              express or implied warranty.
%##########################################################################
%
% Copyright (c) Felix Carbonell, Montreal Neurological Institute, 2009.
%               Pierre Bellec, McConnell Brain Imaging Center, 2009.
% Maintainers : felix.carbonell@mail.mcgill.ca, pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : fMRIstat, linear model

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

flag_gb_niak_fast_gb = true; % Fast initialization : load only critical global variables
niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SYNTAX
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_FMRI_LM(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_fmri_lm'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields = {'fmri','mask','design'};
gb_list_defaults = {NaN,[],NaN};
niak_set_defaults

if ~ischar(files_in.fmri)
    error('niak_brick_fmri_lm: FILES_IN.FMRI should be a string');
end

if ~ischar(files_in.design)
    error('niak_brick_fmri_lm: FILES_IN.DESIGN should be a string');
end

if isempty(files_in.mask)
    files_in.mask = files_in.fmri;
    flag_mask = 0;
else
    if strcmp(files_in.fmri,files_in.mask)
        flag_mask = 0;
    else
        flag_mask = 1;
    end
end
%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields    = {'mask_thresh' , 'contrast' , 'contrast_names' , 'spatial_av' , 'confounds' , 'exclude' , 'nb_trends_spatial' , 'nb_trends_temporal' , 'num_hrf_bases' , 'basis_type' , 'numlags' , 'pcnt' , 'fwhm' , 'df_limit' , 'flag_test' , 'folder_out' , 'flag_verbose' };
gb_list_defaults  = {[]            , NaN        , []               , []           , []          , []        , 0                   , 3                    , []              , 'spectral'   , 1         , 0      , []     , 4          , 0           , ''           , 1              };
niak_set_defaults

if ((nb_trends_spatial>=1)||(opt.pcnt)) && isempty(opt.spatial_av)
    error('Please provide a non empty value for SPATIAL_AV.\n Type ''help niak_brick_fmri_lm'' for more info.')
end

if isnan(opt.contrast)
    error('Please provide a non empty value for CONTRAST.\n Type ''help niak_brick_fmri_lm'' for more info.')
end

if isempty(opt.contrast_names)
    if isstruct(opt.contrast)
        fn_contrast = fieldnames(opt.contrast);
        numcontrasts = size(opt.contrast.(fn_contrast{1}),1);
        for i=1:numcontrasts
            opt.contrast_names{i} = ['_c',fn_contrast{1},num2str(i)];
        end
    else
        numcontrasts = size(opt.contrast,1);
        for i=1:numcontrasts
            opt.contrast_names{i} = ['_cX',num2str(i)];
        end
    end
else
    numcontrasts = length(opt.contrast_names);
    for i=1:numcontrasts
        opt.contrast_names{i} = ['_',opt.contrast_names{i}];
    end
end
    
if flag_test 
    return
end

%% STATS OUTPUT
which_stats = '';
list_outputs = {'_mag_t','_del_t','_mag_ef','_del_ef','_mag_sd','_del_sd','_mag_f','_cor','_resid','_wresid','_ar'};

for num_l = 1:length(list_outputs)
    field_name = lower(list_outputs{num_l}(2:end));
    if isfield(files_out,field_name)
       which_stats = cat(2,which_stats,' ',list_outputs{num_l});
    end
end
if ~isempty(which_stats)
    which_stats(1) = [];
end

%% Open file_design:

design = load(files_in.design);
matrix_x = design.matrix_x;
x_cache = design.x_cache;

%% Auxiliary defaults:
if ~isempty(x_cache.x)
    nb_response = size(x_cache.x,2);
else
    nb_response = 0;
end
if isempty(opt.num_hrf_bases)
    opt.num_hrf_bases = ones(1,nb_response);
end

if isempty(opt.fwhm)
    opt.fwhm.cor = -100;
end
if isempty(opt.contrast)
    fwhm.cor = 0;
else
    fwhm.cor = opt.fwhm.cor;
end

%% Open file_input:
disp('Loading Data...')
[hdr,vol] = niak_read_vol(files_in.fmri);
Steps = abs(hdr.info.voxel_size);

numframes = size(vol,4);
allpts = 1:numframes;
allpts(opt.exclude) = zeros(1,length(opt.exclude));
keep = allpts( allpts >0 );

%% Brain masking:
disp('Reading the brain mask ...')
if flag_mask
    [hdr_mask,mask] = niak_read_vol(files_in.mask);
    if isempty(opt.mask_thresh)
        mask_thresh1 = 0;
        mask_thresh2 = Inf;
    else
        mask_thresh1 = opt.mask_thresh(1);
        if length(opt.mask_thresh)>=2
            mask_thresh2 = opt.mask_thresh(2);
        else
            mask_thresh2 = Inf;
        end
    end
else
    disp('Defining a brain mask ...')
    if isempty(opt.mask_thresh)
        mask_thresh = niak_mask_threshold(vol);
        mask_thresh1=mask_thresh(1);
        if length(mask_thresh)>=2
            mask_thresh2=mask_thresh(2);
        else
            mask_thresh2=Inf;
        end
    else
        mask_thresh1 = 0;
        mask_thresh2 = Inf;
    end
    mask = squeeze(vol(:,:,:,keep(1)));
end
mask = (mask>mask_thresh1)&(mask<=mask_thresh2);
weighted_mask = squeeze(vol(:,:,:,keep(1))).*mask ;

%% Start Computations:
disp('Starting Computations...')

if isempty(which_stats)
   return
end

nb_trends = [opt.nb_trends_temporal + 1, opt.nb_trends_spatial, size(opt.confounds,2)];

opt_contrast.nb_response = nb_response;
opt_contrast.nb_trends = nb_trends;
contrasts = niak_make_contrasts(opt.contrast,opt_contrast);
clear opt_contrast

opt_which.contrasts = contrasts;
opt_which.which_stats = which_stats; 
opt_which = niak_make_which_stats(opt_which);
contrasts = opt_which.contrasts;
contrast_is_delay = opt_which.contrast_is_delay;
which_stats = opt_which.which_stats;
clear opt_which

disp('Estimating autoregressive model...')
if isnumeric(fwhm.cor) && (fwhm.cor(1)<Inf)
    opt_auto.spatial_av = opt.spatial_av;
    opt_auto.matrix_x = matrix_x;
    opt_auto.pcnt = opt.pcnt;
    opt_auto.exclude = opt.exclude;
    opt_auto.numlags = opt.numlags;
    opt_auto.voxel_size = Steps;
    [rho_vol,opt_auto] = niak_autoregressive(vol,weighted_mask,opt_auto);
    df = opt_auto.df;
    if length(fwhm.cor)==2
      fwhm.data = fwhm.cor(2);
    else
      fwhm.data = opt_auto.fwhm;     
    end
    clear opt_auto
end  

%% Calculate df and fwhm_cor if not specified:
disp('Estimating effective FWHMs...')

if ~isempty(opt.contrast)
    opt_upd.matrix_x = matrix_x;
    opt_upd.contrasts = contrasts;
    opt_upd.numlags = opt.numlags;
    opt_upd.num_hrf_bases = opt.num_hrf_bases;
    opt_upd.nb_response = nb_response;
    opt_upd.which_stats = which_stats;
    opt_upd.df = df;
    opt_upd.fwhm = fwhm;
    opt_upd.exclude = opt.exclude;
    opt_upd = niak_update_fwhm(opt_upd);
    fwhm = opt_upd.fwhm;
    df = opt_upd.df;
    clear opt_upd
end

disp('Smoothing the autoregressive parameter volumes...')
if fwhm.cor>0 && fwhm.cor<Inf
    opt_smooth.fwhm = fwhm.cor./Steps;
    opt_smooth.exclude = opt.exclude;
    rho_vol = niak_smooth_weighted_vol(rho_vol,vol,mask,opt_smooth);
    clear opt_smooth
end

%% Second step to get final estimates
disp('Estimating whitened model...')
opt_whiten.matrix_x = matrix_x;
opt_whiten.spatial_av = opt.spatial_av;
opt_whiten.num_hrf_bases = opt.num_hrf_bases;
opt_whiten.pcnt = opt.pcnt;
opt_whiten.exclude = opt.exclude;
opt_whiten.numlags = opt.numlags;
opt_whiten.nb_response = nb_response;
opt_whiten.nb_trends = nb_trends;
opt_whiten.contrasts = contrasts;
opt_whiten.which_stats = which_stats;
opt_whiten.contrast_is_delay = contrast_is_delay;
[stats_vol] = niak_whiten_glm(vol,rho_vol,opt_whiten);

%% FILES_OUT
[path_f,name_f,ext_f] = fileparts(files_in.fmri);

if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end

if isempty(opt.folder_out)
    folder_f = path_f;
else
    folder_f = opt.folder_out;
end

if ~isfield(files_out,'df')
    full_name = cat(2,folder_f,filesep,name_f,'_df.mat');
    files_out = setfield(files_out,'df',full_name);
end

if ~isfield(files_out,'fwhm')
    full_name = cat(2,folder_f,filesep,name_f,'_fwhm.mat');
    files_out = setfield(files_out,'fwhm',full_name);
end

for num_l = 1:6
    field_name = lower(list_outputs{num_l}(2:end));
    if isfield(files_out,field_name)
       if isempty(files_out.(field_name))
          for i=1:numcontrasts
              full_name = cat(2,folder_f,filesep,name_f,list_outputs{num_l},opt.contrast_names{i},ext_f);
              files_out.(field_name){i} = full_name;
          end
       end
       files_out.(field_name) = files_out.(field_name)(:);
    end
end
for num_l = 7:length(list_outputs)
    field_name = lower(list_outputs{num_l}(2:end));
    if isfield(files_out,field_name)
       if isempty(files_out.(field_name))           
          full_name = cat(2,folder_f,filesep,name_f,list_outputs{num_l},ext_f);
          files_out.(field_name) = full_name; 
       end
    end
end

%% Writing output files
disp('Writing outputs...')
if ~strcmp(files_out.df,'gb_niak_omitted');
    save(files_out.df,'df');
end

if ~strcmp(files_out.fwhm,'gb_niak_omitted');
    save(files_out.fwhm,'fwhm');
end

hdr = hdr(1);

if any(which_stats(:,1))
    for i=1:numcontrasts
        if flag_verbose
           file_name_tmp = files_out.mag_t{i};
           fprintf('Writing the t stats data in %s ...\n',file_name_tmp);
        end
        hdr_out = hdr;
        hdr_out.file_name = files_out.mag_t{i};
        opt_hist.command = 'niak_brick_fmri_lm';
        opt_hist.files_in = files_in;
        opt_hist.files_out = files_out.mag_t{i};
        opt_hist.comment = sprintf('T stats data');
        hdr_out = niak_set_history(hdr_out,opt_hist);
        stats_vol_contr.t = squeeze(stats_vol.t(:,:,:,i));
        niak_write_vol(hdr_out,stats_vol_contr.t);
    end
end

if any(which_stats(:,2))
   for i=1:numcontrasts
        if flag_verbose
            file_name_tmp = files_out.mag_ef{i};
            fprintf('Writing the effects in %s ...\n',file_name_tmp);
        end
        hdr_out = hdr;
        hdr_out.file_name = files_out.mag_ef{i};
        opt_hist.command = 'niak_brick_fmri_lm';
        opt_hist.files_in = files_in;
        opt_hist.files_out = files_out.mag_ef{i};
        opt_hist.comment = sprintf('Magnitude of effects data');
        hdr_out = niak_set_history(hdr_out,opt_hist);
        stats_vol_contr.ef = squeeze(stats_vol.ef(:,:,:,i));
        niak_write_vol(hdr_out,stats_vol_contr.ef);
    end
end

if any(which_stats(:,3))
    for i=1:numcontrasts
        if flag_verbose
            file_name_tmp = files_out.mag_sd{i};
            fprintf('Writing the standard deviations of effects in %s ...\n',file_name_tmp);
        end
        hdr_out = hdr;
        hdr_out.file_name = files_out.mag_sd{i};
        opt_hist.command = 'niak_brick_fmri_lm';
        opt_hist.files_in = files_in;
        opt_hist.files_out = files_out.mag_sd{i};
        opt_hist.comment = sprintf('Standard deviations of effects data');
        hdr_out = niak_set_history(hdr_out,opt_hist);
        stats_vol_contr.sd = squeeze(stats_vol.sd(:,:,:,i));
        niak_write_vol(hdr_out,stats_vol_contr.sd);
    end
end

if any(which_stats(:,4))
    if flag_verbose
        fprintf('Writing the F stats in %s ...\n',files_out.mag_f);
    end
    hdr_out = hdr;
    hdr_out.file_name = files_out.mag_f;
    opt_hist.command = 'niak_brick_fmri_lm';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.mag_f;
    opt_hist.comment = sprintf('F stats data');
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,stats_vol.f);
end

if which_stats(1,6)
    if flag_verbose
        fprintf('Writing the residuals in %s ...\n',files_out.resid);
    end
    hdr_out = hdr;
    hdr_out.file_name = files_out.resid;
    opt_hist.command = 'niak_brick_fmri_lm';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.resid;
    opt_hist.comment = sprintf('Residuals data');
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,stats_vol.resid);
end

if which_stats(1,7)
    if flag_verbose
        fprintf('Writing the whitened residuals in %s ...\n',files_out.wresid);
    end
    hdr_out = hdr;
    hdr_out.file_name = files_out.wresid;
    opt_hist.command = 'niak_brick_fmri_lm';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.wresid;
    opt_hist.comment = sprintf('Whiten residuals data');
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,stats_vol.wresid);
end

if which_stats(1,8)
    if flag_verbose
        fprintf('Writing the auto-regressive terms in %s ...\n',files_out.ar);
    end
    hdr_out = hdr;
    hdr_out.file_name = files_out.ar;
    opt_hist.command = 'niak_brick_fmri_lm';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.ar;
    opt_hist.comment = sprintf('Autoregressive terms data');
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,stats_vol.ar);
end

clear stats_vol
