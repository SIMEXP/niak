function [files_in,files_out,opt] = niak_brick_glm_level1(files_in,files_out,opt)

% Fit a linear model to an individual run of fMRI time series data.
%
% The method is based on linear models with correlated AR(p) errors:
% Y = hrf*X b + e, e_t=a_1 e_(t-1) + ... + a_p e_(t-p) + white noise_t.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_GLM_LEVEL1(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
%
% FILES_IN  (structure) with the following fields :
%
%     FMRI (string) an fMRI dataset. See NIAK_READ_VOL for supported
%           formats.
%     
%     DESIGN (string) a MAT file containing a unique variable X_CACHE.
%           This structure describes the covariates of the model.
%           See the help of FMRIDESIGN in the fMRIstat toolbox.
%           See http://www.math.mcgill.ca/keith/fmristat/#making for an
%           example of contrast matrix.
%           See http://www.math.mcgill.ca/keith/fmristat/#making for an
%           example of design.
%
% FILES_OUT (structure) with the following fields. Note that if
%     a field is an empty string, a default value will be used to
%     name the outputs. If a field is omitted, the output won't be
%     saved at all (this is equivalent to setting up the output file
%     names to 'gb_niak_omitted').
%
%     DF    (string, default <BASE NAME>_df.mat)
%           a mat file containing a structure called DF:
%           DF.t are the effective df's of the T statistics,
%           DF.F are the numerator and effective denominator dfs of F statistic,
%           DF.resid is the least-squares degrees of freedom of the residuals,
%           DF.cor is the effective df of the temporal correlation model.
%
%     SPATIAL_AV (string, default <BASE NAME>_spatial_av.mat)
%           column vector of the spatial average (SPATIAL_AV) 
%           of the frames weighted by the first non-excluded frame.
%
%     MAG_T (cell of strings, default <BASE NAME>_<CONTRAST NAME>_mag_t<EXT>)
%           Each entry is a T statistic image =ef/sd for magnitudes associated 
%           with a contrast. 
%           If T > 100, T = 100.
%     
%     DEL_T (cell of string, default <BASE NAME>_<CONTRAST NAME>_del_t<EXT>)
%           T statistic image =ef/sd for delays. Delays are shifts of the 
%           time origin of the HRF, measured in seconds. Note that you 
%           cannot estimate delays of the trends or confounds. 
%
%     MAG_EF (cell of string, default <BASE NAME>_<CONTRAST NAME>_mag_ef<EXT>)
%           effect (b) image for magnitudes.
%     
%     DEL_EF (cell of string, default <BASE NAME>_<CONTRAST NAME>_del_ef<EXT>)
%           effect (b) image for delays.
%
%     MAG_SD (cell of string, default <BASE NAME>_<CONTRAST NAME>_mag_sd<EXT>)
%           standard deviation of the effect for magnitudes. 
%
%     DEL_SD (cell of string, default <BASE NAME>_<CONTRAST NAME>_del_sd<EXT>)
%           standard deviation of the effect for delays.
%
%     MAG_F (cell of string, default <BASE NAME>_<CONTRAST NAME>_mag_F<EXT>)
%            F-statistic for test of magnitudes of all rows of OPT.CONTRAST 
%            selected by _mag_F. The degrees of freedom are DF.F. If F > 
%            1000, F = 1000. F statistics are not yet available for delays.
%
%     FWHM (cell of string, default <BASE NAME>_<CONTRAST NAME>_fwhm<EXT>)
%         FWHM information:
%         Frame 1: effective FWHM in mm of the whitened residuals,
%         as if they were white noise smoothed with a Gaussian filter 
%         whose fwhm was FWHM. FWHM is unbiased so that if it is smoothed  
%         spatially then it remains unbiased. If FWHM > 50, FWHM = 50.
%         Frame 2: resels per voxel, again unbiased.
%         Frames 3,4,5: correlation of adjacent resids in x,y,z directions.
%
%     COR  (cell of string, default <BASE NAME>_<CONTRAST NAME>_cor<EXT>)
%           The temporal autocorrelation(s).
%
%     RESID  (string, default <BASE NAME>_resid<EXT>)
%           the residuals from the model, only for non-excluded frames.
%
%     WRESID (string, default <BASE NAME>_wresid<EXT>)
%           the whitened residuals from the model normalized by dividing
%           by their root sum of squares, only for non-excluded frames.
%
%     AR (string, default <BASE NAME>_AR<EXT>)
%           the AR parameter(s) a_1 ... a_p.
%
% OPT   (structure) with the following fields.
%       Note that if a field is omitted, it will be set to a default
%       value if possible, or will issue an error otherwise.
%
%       CONTRAST (structure) where each field is a contrast in the design.
%           The field name of the contrast will be used as a label in
%           default outputs.
%           CONTRAST.<FIELD NAME> is a vector. The first elements of the
%           vector refer to one variable of the model (in the same order as
%           in the variable X_cache.X of FILES_IN.DESIGN).
%           The following elements of the vector can be used to derive
%           contrast  in the temporal and spatial trends, and the confounds 
%           (in that order - see OPT.N_TRENDS_SPATIAL, OPT.NB_TRENDS_TEMPORAL
%           and OPT.CONFOUNDS below).                      
%
%       CONFOUNDS (matrix, default [] i.e. no confounds)
%           A matrix or array of extra columns for the design matrix
%           that are not convolved with the HRF, e.g. movement artifacts. 
%           If a matrix, the same columns are used for every slice; if an array,
%           the first two dimensions are the matrix, the third is the slice.
%           For functional connectivity with a single voxel, use
%           FMRI_INTERP to resample the reference data at different slice 
%           times, or apply NIAK_BRICK_SLICE_TIMING to the fMRI data as a
%           preprocessing.
%
%       FWHM_COR (vector 1*1 or 1*2, default -100)  
%           fwhm in mm of a 3D Gaussian kernel used to smooth the 
%           autocorrelation of residuals. 
%           Setting it to Inf smooths the autocorrelation to 0, i.e. it 
%           assumes the frames are uncorrelated (useful for TR>10 seconds). 
%           Setting it to 0 does no smoothing. 
%           If FWHM_COR is negative, it is taken as the desired df, and the 
%           fwhm is chosen to achive this df, or 90% of the residual df, 
%           whichever is smaller, for every contrast, up to 50mm. 
%           The default is chosen to achieve 100 df. 
%           If a second component is supplied, it is the fwhm in mm of the 
%           data, otherwise this is estimated quickly from the least-squares 
%           residuals.
%
%       EXCLUDE (vector, default []) 
%           A list of frames that should be excluded from the
%           analysis. This must be used with Siemens EPI scans to remove the
%           first few frames, which do not represent steady-state images.
%           If OPT.NUMLAGS=1, the excluded frames can be arbitrary, 
%           otherwise they should be from the beginning and/or end.
%
%       NB_TRENDS_SPATIAL (scalar, default 0) 
%           order of the polynomial in the spatial average (SPATIAL_AV)  
%           weighted by first non-excluded frame; 0 will remove no spatial 
%           trends.
%
%       NB_TRENDS_TEMPORAL (scalar, default 0)
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
%       NUMLAGS (integer, default 1)
%           Order (p) of the autoregressive model.
%
%       PCNT (boolean, default 1)
%           if PCNT=1, then the data is converted to percentages before
%           analysis by dividing each frame by its spatial average, * 100%.
%
%       NUM_HRF_BASES (row vector; default [1; ... ;1]) 
%           number of basis functions for the hrf for each response, 
%           either 1 or 2 at the moment. At least one basis functions is 
%           needed to estimate the magnitude, but two basis functions are 
%           needed to estimate the delay.
%
%       BASIS_TYPE (string, 'spectral') 
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
%       DF_LIMIT (integer, default 4)
%           control which method is used for estimating FWHM. 
%           If DF > DF_LIMIT, then the FWHM is calculated assuming the 
%           Gaussian filter is arbitrary. 
%           However if DF is small, this gives inaccurate results, so if 
%           DF <= DF_LIMIT, the FWHM is calculated assuming that the axes 
%           of the Gaussian filter are aligned with the x, y and z 
%           axes of the data. 
%
%       FOLDER_OUT (string, default: path of FILES_IN) 
%           If present, all default outputs will be created in the folder 
%           FOLDER_OUT. The folder needs to be created beforehand.
%
%       FLAG_VERBOSE (boolean, default 1) 
%           if the flag is 1, then the function prints some infos during 
%           the processing.
%
%       FLAG_TEST (boolean, default 0) 
%           if FLAG_TEST equals 1, the brick does not do anything but 
%           update the default values in FILES_IN, FILES_OUT and OPT.
%
%
% OUTPUTS
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% COMMENTS:
% This brick is a "NIAKized" overlay of the FMRILM function from the
% fMRIstat toolbox by Keith Worsley :
% http://www.math.mcgill.ca/keith/fmristat/
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline, niak, preprocessing, fMRI

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
    error('SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_GLM_LEVEL1(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_glm_level1'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields = {'fmri','design'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

if ~ischar(files_in.fmri)
    error('niak_brick_glm_level1: FILES_IN.FMRI should be a string');
end

if ~ischar(files_in.design)
    error('niak_brick_glm_level1: FILES_IN.DESIGN should be a string');
end

if ~exist(files_in.fmri,'file')
    error(cat(2,'niak_brick_glm_level1: FILES_IN.FMRI does not exist (',files_in.fmri,')');
end

if ~exist(files_in.design,'file')
    error(cat(2,'niak_brick_glm_level1: FILES_IN.DESIGN does not exist (',files_in.design,')');
end
    
%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'contrast','confounds','fwhm_cor','exclude','nb_trends_spatial','nb_trends_temporal','numlags','pcnt','num_hrf_bases','basis_type','df_limit','flag_test','folder_out','flag_verbose'};
gb_list_defaults = {NaN,[],-100,[],0,0,1,1,[],'spectral',4,0,'',1};
niak_set_defaults

if isempty(num_hrf_bases)    
    
    design = load(files_in.design);
    if  ~isfield(design,'X_cache')
        error('The file FMRI.DESIGN should be a matrix containing a matlab variable called X_cache')
    end
    nb_response = size(design.X_cache.X,2);
    opt.num_hrf_bases = ones([nb_response 1]);
    
end

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'df','spatial_av','mag_t','del_t','mag_ef','del_ef','mag_f','corr','resid','wresid','ar','fwhm'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults        

%% Building default output names
[path_f,name_f,ext_f] = fileparts(files_in.fmri);

if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,'.gz')
    [tmp,name_f,ext_f] = fileparts(name_f);
end

if isempty(opt.folder_out)
    folder_f = path_f;
else
    folder_f = opt.folder_out;
end
       
%% Generating the default outputs of the NIAK brick and civet

list_contrast = getfield(contrast);
folder_fmri = niak_path_tmp('_fmristat');
nb_cont = length(list_contrast);

if strcmp(files_out.df,'') % df
    files_out.df = cat(2,folder_f,name_f,'_df.mat');
end

if strcmp(files_out.spatial_av,'')  % spatial_av
    files_out.spatial_av = cat(2,folder_f,name_f,'_spatial_av.mat');
end

if strcmp(files_out.mag_t,'')  % mag_t
    for num_c = 1:nb_cont
        files_out.mag_t{num_c} = cat(2,folder_f,name_f,'_,'list_cont{num_c},'_mag_t',ext_f);
    end
end
for num_c = 1:nb_cont
    files_fmri.mag_t{num_c} = cat(2,civet_fmri,name_f,'_,'list_cont{num_c},'_mag_t',ext_f);
end

if strcmp(files_out.del_t,'')  % del_t
    for num_c = 1:nb_cont
        files_out.del_t{num_c} = cat(2,folder_f,name_f,'_,'list_cont{num_c},'_del_t',ext_f);
    end
end
for num_c = 1:nb_cont
    files_fmri.del_t{num_c} = cat(2,civet_fmri,name_f,'_,'list_cont{num_c},'_del_t',ext_f);
end

if strcmp(files_out.mag_ef,'')  % mag_ef
    for num_c = 1:nb_cont
        files_out.mag_ef{num_c} = cat(2,folder_f,name_f,'_,'list_cont{num_c},'_mag_ef',ext_f);
    end
end
for num_c = 1:nb_cont
    files_fmri.mag_ef{num_c} = cat(2,civet_fmri,name_f,'_,'list_cont{num_c},'_mag_ef',ext_f);
end

if strcmp(files_out.del_f,'')  % del_ef
    for num_c = 1:nb_cont
        files_out.del_ef{num_c} = cat(2,folder_f,name_f,'_,'list_cont{num_c},'_del_ef',ext_f);
    end
end
for num_c = 1:nb_cont
    files_fmri.del_ef{num_c} = cat(2,civet_fmri,name_f,'_,'list_cont{num_c},'_del_ef',ext_f);
end

if strcmp(files_out.mag_sd,'')  % mag_sd
    for num_c = 1:nb_cont
        files_out.mag_sd{num_c} = cat(2,folder_f,name_f,'_,'list_cont{num_c},'_mag_sd',ext_f);
    end
end
for num_c = 1:nb_cont
    files_fmri.mag_sd{num_c} = cat(2,civet_fmri,name_f,'_,'list_cont{num_c},'_mag_sd',ext_f);
end

if strcmp(files_out.del_sd,'')  % del_sd
    for num_c = 1:nb_cont
        files_out.del_sd{num_c} = cat(2,folder_f,name_f,'_,'list_cont{num_c},'_del_sd',ext_f);
    end
end
for num_c = 1:nb_cont
    files_fmri.del_sd{num_c} = cat(2,civet_fmri,name_f,'_,'list_cont{num_c},'_del_sd',ext_f);
end

if strcmp(files_out.mag_f,'')  % mag_f
    for num_c = 1:nb_cont
        files_out.mag_f{num_c} = cat(2,folder_f,name_f,'_,'list_cont{num_c},'_mag_F',ext_f);
    end
end
for num_c = 1:nb_cont
    files_fmri.mag_f{num_c} = cat(2,civet_fmri,name_f,'_,'list_cont{num_c},'_mag_F',ext_f);
end

if strcmp(files_out.cor,'')  % cor
    for num_c = 1:nb_cont
        files_out.cor{num_c} = cat(2,folder_f,name_f,'_,'list_cont{num_c},'_cor',ext_f);
    end
end
for num_c = 1:nb_cont
    files_fmri.cor{num_c} = cat(2,civet_fmri,name_f,'_,'list_cont{num_c},'_cor',ext_f);
end

if strcmp(files_out.fwhm,'')  % fwhm
    for num_c = 1:nb_cont
        files_out.fwhm{num_c} = cat(2,folder_f,name_f,'_,'list_cont{num_c},'_fwhm',ext_f);
    end
end
for num_c = 1:nb_cont
    files_fmri.fwhm{num_c} = cat(2,civet_fmri,name_f,'_,'list_cont{num_c},'_fwhm',ext_f);
end

if strcmp(files_out.resid,'')  % resid
    files_out.resid = cat(2,folder_f,name_f,'_resid',ext_f);
end
files_fmri.resid = cat(2,civet_fmri,name_f,'_resid',ext_f);

if strcmp(files_out.wresid,'')  % wresid
    files_out.wresid = cat(2,folder_f,name_f,'_wresid',ext_f);
end
files_fmri.wresid = cat(2,civet_fmri,name_f,'_wresid',ext_f);

if strcmp(files_out.ar,'')  % ar
    files_out.ar = cat(2,folder_f,name_f,'_ar',ext_f);
end
files_fmri.ar = cat(2,civet_fmri,name_f,'_ar',ext_f);

if flag_test == 1
    rmdir(folder_fmri);
    return
end
