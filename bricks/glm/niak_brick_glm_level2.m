function [files_in,files_out,opt] = niak_brick_glm_level2(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_GLM_LEVEL2
%
% The method is based on linear mixed effect model :
% E = X b + e_fixed + e_random,     
% where b is a vector of unknown coefficients,
%       e_fixed  is normal with mean zero, standard deviation S,
%       e_random is normal with mean zero, standard deviation sigma (unknown).
% The model is fitted by REML using the EM algorithm 
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_GLM_LEVEL2(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN  
%       (structure) with the following fields :
%
%       EFFECT
%           (cell of strings) 
%     
%       STANDARD_ERROR
%           (cell of strings) 
%
%  * FILES_OUT 
%       (structure) with the following fields. Note that if
%       a field is an empty string, a default value will be used to
%       name the outputs. If a field is omitted, the output won't be
%       saved at all (this is equivalent to setting up the output file
%       names to 'gb_niak_omitted').
%
%       MAG_T 
%           (cell of strings, default <BASE NAME>_<CONTRAST NAME>_mag_t<EXT>)
%           Each entry is a T statistic image =ef/sd for magnitudes associated 
%           with a contrast. 
%           If T > 100, T = 100.
%     
%       MAG_EF 
%           (cell of string, default <BASE NAME>_<CONTRAST NAME>_mag_ef<EXT>)
%           effect (b) image for magnitudes.
%     
%       MAG_SD 
%           (cell of string, default <BASE NAME>_<CONTRAST NAME>_mag_sd<EXT>)
%           standard deviation of the effect for magnitudes. 
%
%       MAG_F 
%           (cell of string, default <BASE NAME>_<CONTRAST NAME>_mag_F<EXT>)
%            F-statistic for test of magnitudes of all rows of OPT.CONTRAST 
%            selected by _mag_F. The degrees of freedom are DF.F. If F > 
%            1000, F = 1000. F statistics are not yet available for delays.
%
%       FWHM 
%           (cell of string, default <BASE NAME>_<CONTRAST NAME>_fwhm<EXT>)
%           FWHM information:
%           Frame 1: effective FWHM in mm of the whitened residuals,
%           as if they were white noise smoothed with a Gaussian filter 
%           whose fwhm was FWHM. FWHM is unbiased so that if it is smoothed  
%           spatially then it remains unbiased. If FWHM > 50, FWHM = 50.
%           Frame 2: resels per voxel, again unbiased.
%           Frames 3,4,5: correlation of adjacent resids in x,y,z directions.
%
%       COR  
%           (cell of string, default <BASE NAME>_<CONTRAST NAME>_cor<EXT>)
%           The temporal autocorrelation(s).
%
%       RESID  
%           (string, default <BASE NAME>_resid<EXT>)
%           the residuals from the model, only for non-excluded frames.
%
%       WRESID 
%           (string, default <BASE NAME>_wresid<EXT>)
%           the whitened residuals from the model normalized by dividing
%           by their root sum of squares, only for non-excluded frames.
%
%       AR 
%           (string, default <BASE NAME>_AR<EXT>) the AR parameter(s) 
%           a_1 ... a_p.
%
% _________________________________________________________________________
% OPT   
%     (structure) with the following fields.
%     Note that if a field is omitted, it will be set to a default
%     value if possible, or will issue an error otherwise.
%
%     CONTRAST 
%           (structure) where each field is a contrast in the design.
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
%     CONFOUNDS 
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
%     FWHM_COR 
%           (vector 1*1 or 1*2, default -100)  
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
%     EXCLUDE 
%           (vector, default []) 
%           A list of frames that should be excluded from the
%           analysis. This must be used with Siemens EPI scans to remove the
%           first few frames, which do not represent steady-state images.
%           If OPT.NUMLAGS=1, the excluded frames can be arbitrary, 
%           otherwise they should be from the beginning and/or end.
%
%     NB_TRENDS_SPATIAL 
%           (scalar, default 0) 
%           order of the polynomial in the spatial average (SPATIAL_AV)  
%           weighted by first non-excluded frame; 0 will remove no spatial 
%           trends.
%
%     NB_TRENDS_TEMPORAL 
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
%     NUMLAGS 
%           (integer, default 1)
%           Order (p) of the autoregressive model.
%
%     PCNT 
%           (boolean, default 1)
%           if PCNT=1, then the data is converted to percentages before
%           analysis by dividing each frame by its spatial average, * 100%.
%
%     NUM_HRF_BASES 
%           (row vector; default [1; ... ;1]) 
%           number of basis functions for the hrf for each response, 
%           either 1 or 2 at the moment. At least one basis functions is 
%           needed to estimate the magnitude, but two basis functions are 
%           needed to estimate the delay.
%
%     BASIS_TYPE 
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
%     DF_LIMIT 
%           (integer, default 4)
%           control which method is used for estimating FWHM. 
%           If DF > DF_LIMIT, then the FWHM is calculated assuming the 
%           Gaussian filter is arbitrary. 
%           However if DF is small, this gives inaccurate results, so if 
%           DF <= DF_LIMIT, the FWHM is calculated assuming that the axes 
%           of the Gaussian filter are aligned with the x, y and z 
%           axes of the data. 
%
%     FOLDER_OUT 
%           (string, default: path of FILES_IN) 
%           If present, all default outputs will be created in the folder 
%           FOLDER_OUT. The folder needs to be created beforehand.
%
%     FLAG_VERBOSE 
%           (boolean, default 1) 
%           if the flag is 1, then the function prints some infos during 
%           the processing.
%
%     FLAG_TEST 
%           (boolean, default 0) 
%           if FLAG_TEST equals 1, the brick does not do anything but 
%           update the default values in FILES_IN, FILES_OUT and OPT.
%
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
% NOTE 1:
% This brick is a "NIAKized" overlay of the MULTISTAT function from the
% fMRIstat toolbox by Keith Worsley :
% http://www.math.mcgill.ca/keith/fmristat/
%
% NOTE 2: 
% In its current version, this brick does not produce zipped outputs, even
% if the inputs were zipped.
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

niak_gb_vars

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

    
%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'contrast','confounds','fwhm_cor','exclude','nb_trends_spatial','nb_trends_temporal','numlags','pcnt','num_hrf_bases','basis_type','df_limit','flag_test','folder_out','flag_verbose'};
gb_list_defaults = {NaN,[],-100,[],0,0,1,1,[],'spectral',4,0,'',1};
niak_set_defaults

if isempty(num_hrf_bases)    
    
    if ~exist(files_in.design,'file')
        warning(cat(2,'niak_brick_glm_level1: FILES_IN.DESIGN does not exist (',files_in.design,'), I could not set up default values for OPT.NUM_HRF_BASES.'));        
    else

        design = load(files_in.design);
        if  ~isfield(design,'X_cache')
            error('The file FMRI.DESIGN should be a matrix containing a matlab variable called X_cache')
        end
        nb_response = size(design.X_cache.X,2);
        opt.num_hrf_bases = ones([nb_response 1]);
    end
end

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'df','spatial_av','mag_t','del_t','mag_ef','del_ef','mag_sd','del_sd','mag_f','cor','resid','wresid','ar','fwhm'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults        

%% Parsing base names
[path_f,name_f,ext_f] = fileparts(files_in.fmri);

if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    flag_zip = 1;
end

if isempty(opt.folder_out)
    folder_f = path_f;
else
    folder_f = opt.folder_out;
end
       
%% Generating the default outputs of the FMRILM function and the NIAK brick
list_contrast = fieldnames(opt.contrast);
folder_fmri = niak_path_tmp('_fmristat');
nb_cont = length(list_contrast);

if strcmp(files_out.df,'') % df
    files_out.df = cat(2,folder_f,name_f,'_df.mat');
end

if strcmp(files_out.spatial_av,'')  % spatial_av
    files_out.spatial_av = cat(2,folder_f,name_f,'_spatial_av.mat');
end

%% contrast-dependent outputs
list_outputs = {'_mag_t','_del_t','_mag_ef','_del_ef','_mag_sd','_del_sd','_mag_F','_cor','_fwhm','_resid','_wresid','_AR'};
files_fmri.tmp = '';
which_stats = '';

for num_l = 1:length(list_outputs)

    %% Build the default output name for the NIAK and FMRILM outputs
    str_tmp = cell([nb_cont 1]);
    str_tmp2 = cell([nb_cont 1]);
    for num_c = 1:nb_cont
        str_tmp{num_c} = cat(2,folder_f,name_f,'_',list_contrast{num_c},list_outputs{num_l},ext_f);
        str_tmp2{num_c} = cat(2,folder_fmri,name_f,'_',list_contrast{num_c},list_outputs{num_l},ext_f);
    end

    field_name = lower(list_outputs{num_l}(2:end));
    if strcmp(getfield(files_out,field_name),'')
        files_out = setfield(files_out,field_name,str_tmp);        
    end
    
    %% If the output name is 'gb_niak_omitted' (or actully any string),
    %% do not generate this output
    if ~ischar(getfield(files_out,field_name))
        which_stats = cat(2,which_stats,' ',list_outputs{num_l});
    end
    
    files_fmri = setfield(files_fmri,field_name,str_tmp2);

end
files_fmri = rmfield(files_fmri,'tmp');

if flag_test == 1
    rmdir(folder_fmri);
    return
end

%%%%%%%%%%%%
%% fmrilm %%
%%%%%%%%%%%%

flag_exist = exist('fmrilm');
if ~(flag_exist==2)
    error('I could not find the FMRILM function of the fMRIstat package. Instructions for installation can be found at http://www.math.mcgill.ca/keith/fmristat/')
end

%% Input file

if flag_zip
    file_input = niak_file_tmp(cat(2,'_func.mnc',gb_niak_zip_ext));
    instr_cp = cat(2,'cp ',files_in.fmri,' ',file_input);
    system(instr_cp);
    instr_unzip = cat(2,gb_niak_unzip,' ',file_input);
    system(instr_unzip);
    file_input = file_input(1:end-length(gb_niak_zip_ext));
else
    file_input = files_in.fmri;
end

%% output base name
output_file_base = [];
for num_c = 1:nb_cont
    if size(output_file_base,1)>0
        output_file_base = char(output_file_base,cat(2,folder_fmri,name_f,'_',list_contrast{num_c}));
    else
        output_file_base = cat(2,folder_fmri,name_f,'_',list_contrast{num_c});
    end
end

%% Design
design = load(files_in.design);
if  ~isfield(design,'X_cache')
    error('The file FMRI.DESIGN should be a matrix containing a matlab variable called X_cache')
end

%% contrast
nb_reg = 0;
for num_c = 1:nb_cont
    cont = getfield(opt.contrast,list_contrast{num_c});
    nb_reg = max(nb_reg,length(cont));
end

mat_contrast = zeros([nb_cont nb_reg]);
for num_c = 1:nb_cont
    cont = getfield(opt.contrast,list_contrast{num_c});
    mat_contrast(1:length(cont),:) = cont(:)';
end

%% Actual call to fmrilm   
if (nb_trends_spatial == 0)&(pcnt == 0)
    df = fmrilm(file_input,output_file_base,design.X_cache,mat_contrast,exclude,which_stats,fwhm_cor,[nb_trends_temporal nb_trends_spatial pcnt],confounds,[],num_hrf_bases,basis_type,numlags,df_limit);
    spatial_av = [];
else
    [df,spatial_av] = fmrilm(file_input,output_file_base,design.X_cache,mat_contrast,exclude,which_stats,fwhm_cor,[nb_trends_temporal nb_trends_spatial pcnt],confounds,[],num_hrf_bases,basis_type,numlags,df_limit);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Moving outputs to the right folder %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~strcmp(files_out.df,'gb_niak_omitted');
    save(files_out.df,'df');
end

if ~strcmp(files_out.spatial_av,'gb_niak_omitted');
    save(files_out.spatial_av,'spatial_av');
end

list_fields = fieldnames(files_out);
mask_totej = niak_cmp_str_cell(list_fields,{'df','spatial_av'});
list_fields = list_fields(~mask_totej);

for num_l = 1:length(list_fields)
    
    field_name = list_fields{num_l};
    
    val_field_out = getfield(files_out,field_name);
    val_field_fmri = getfield(files_fmri,field_name);
    
    if ~ischar(val_field_out)
        
        %% Multiple outputs in a cell of strings
        nb_entries = length(val_field_out);
        for num_e = 1:nb_entries
            instr_mv = cat(2,'mv ',val_field_fmri{num_e},' ',val_field_out{num_e});
            [err,msg] = system(instr_mv);
            if err~=0
                warning(msg)
            end
        end
        
    else
        
        %% A single output, maybe an 'omitted' tag
        if ~strcmp(val_field_out,'gb_niak_omitted')
            instr_mv = cat(2,'mv ',val_field_fmri,' ',val_field_out);
            [err,msg] = system(instr_mv);
            if err~=0
                warning(msg)
            end
        end
        
    end
    
end
    
%% Deleting temporary files
system(cat(2,'rm -rf ',folder_fmri));
if flag_zip
    delete(file_input);
end