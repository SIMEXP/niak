function [files_in,files_out,opt] = niak_brick_fmri_design(files_in,files_out,opt)

% _________________________________________________________________________
% SUMMARY NIAK_BRICK_FMRI_DESIGN
%
% Creates the design matrix for an fMRI general linear model analysis. 
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_FMRI_DESIGN(FILES_IN,FILES_OUT,OPT)
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
%       SLICING
%           (string) the name of a file containing relative slice acquisition 
%           times i.e. absolute acquisition time of a slice is
%           FRAME_TIMES+SLICE_TIMES. (default 0) means that slice timing 
%           correction was already done during pre-processing
%
%       EVENTS
%
%           (string) the name a matlab file containing a description of the
%           events matrix (default [1 0]) rows are events and columns are:
%           1. id - an integer from 1:(number of events) to identify event type;
%           2. times - start of event, synchronised with frame and slice times;
%           3. durations (optional - default is 0) - duration of event;
%           4. heights (optional - default is 1) - height of response for event.
%           For each event type, the response is a box function starting at the 
%           event times, with the specified durations and heights, convolved with 
%           the hemodynamic response function (see below). If the duration is zero, 
%           the response is the hemodynamic response function whose integral is 
%           the specified height - useful for `instantaneous' stimuli such as visual 
%           stimuli. The response is then subsampled at the appropriate frame and 
%           slice times to create a design matrix for each slice, whose columns 
%           correspond to the event id number. EVENT_TIMES=[] will ignore event 
%           times and just use the stimulus design matrix S (see next). 
%
%  FILES_OUT
%       (string) the name a matlab file containing a description of the
%       design matrix in the two following variables : 
%
%       X_CACHE 
%           Describes the covariates of the model. See the help of 
%           FMRIDESIGN in the fMRIstat toolbox and
%           http://www.math.mcgill.ca/keith/fmristat/#making for an 
%           example.
%
%       MATRIX_X 
%           the full design matrix, resulting from concatenating 
%           X_CACHE with the temporal, spatial trends as well as additional 
%           confounds.
%
%  OPT   
%     (structure) with the following fields.
%     Note that if a field is omitted, it will be set to a default
%     value if possible, or will issue an error otherwise.
%
%     TR
%           Time resolution (default read from header of FILES_IN.FMRI)
%
%     SPATIAL_AV
%           (default [] and NB_TRENDS_SPATIAL = 0)
%           colum vector of the spatial average time courses.
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
%     EXCLUDE 
%           (vector, default []) 
%           A list of frames that should be excluded from the
%           analysis. This must be used with Siemens EPI scans to remove the
%           first few frames, which do not represent steady-state images.
%           If OPT.NUMLAGS=1, the excluded frames can be arbitrary, 
%           otherwise they should be from the beginning and/or end.
%
%     NB_TRENDS_SPATIAL 
%           (scalar, default 0 will remove no spatial trends) 
%           order of the polynomial in the spatial average (SPATIAL_AV)  
%           weighted by first non-excluded frame; 
%          
%     NB_TRENDS_TEMPORAL 
%           (scalar, default 3)
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
%       HRF_PARAMETERS
%           (vector, default [5.4 5.2 10.8 7.35 0.35] choosen by 
%           Glover, NeuroImage, 9:416-429 for auditory stimulus ) 
%           The hrf is modeled as the difference of two gamma density functions 
%           The components of HRF_PARAMETERS are:
%           1. PEAK1: time to the peak of the first gamma density;
%           2. FWHM1: approximate FWHM of the first gamma density;
%           3. PEAK2: time to the peak of the second gamma density;
%           4. FWHM2: approximate FWHM of the second gamma density;
%           5. DIP: coefficient of the second gamma density;
%           Final hrf is:   gamma1/max(gamma1)-DIP*gamma2/max(gamma2)
%           scaled so that its total integral is 1. 
%          If PEAK1=0 then there is no smoothing of that event type with the hrf.
%          If PEAK1>0 but FWHM1=0 then the design is simply lagged by PEAK1.
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

niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SYNTAX
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_FMRI_DESIGN(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_fmri_design'' for more info.')
end

%% FILES_IN
if ~isstruct(files_in)
    error('FILES_IN should be a struture!')
else
    if ~isfield(files_in,'fmri')
        error('I could not find the field FILES_IN.%s.FMRI!')
    else
        if ~ischar(files_in.fmri)
            error('niak_brick_fmri_design: FILES_IN.%s.FMRI! should be a string');
        end
    end
    if ~isfield(files_in,'events')
        events = [1 0];
    else
       if ~ischar(files_in.events)
           error('niak_brick_fmri_design: FILES_IN.%s.EVENTS! should be a string');                  
           
       end
    end
    if ~isfield(files_in,'slicing')
        slice_times = 0;
    else
       if ~ischar(files_in.slicing)
           error('niak_brick_fmri_design: FILES_IN.%s.SLICING! should be a string');
       end
    end
end
 
%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields    = {'tr' , 'spatial_av' , 'confounds' , 'exclude' , 'nb_trends_spatial' ,...
    'nb_trends_temporal' , 'num_hrf_bases' , 'basis_type' , 'hrf_parameters' , 'flag_test' , 'folder_out' , 'flag_verbose' };
gb_list_defaults  = {[]   , []           , []          , []        , 0                   ,...
    3                    ,  []           , 'spectral'     , [5.4 5.2 10.8 7.35 0.35], 0    , ''           , 1              };
niak_set_defaults 

if (nb_trends_spatial>=1) && isempty(opt.spatial_av)
    error('Please provide a non empty value for SPATIAL_AV.\n Type ''help niak_brick_fmri_design'' for more info.')
end

%% FILES_OUT
[path_f,name_f,ext_f] = fileparts(files_in.fmri);

if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f] = fileparts(name_f);
end

if isempty(opt.folder_out)
    folder_f = path_f;
else
    folder_f = opt.folder_out;
end

if isempty(files_out)
    files_out = cat(2,folder_f,filesep,name_f,'_design.mat');
end

if flag_test 
    return
end

%% Slice times
slice_times = importdata(files_in.slicing);

%% Events file
events = importdata(files_in.events);

%% Open file_input:
hdr = niak_read_vol(files_in.fmri);

if isempty(opt.tr)
    tr = hdr.info.tr;
end

%% Image dimensions
numslices = hdr.info.dimensions(3);
if length(hdr.info.dimensions)>3
    numframes = hdr.info.dimensions(4);
else
    numframes = 1;
end

%% Creates temporal and spatial trends:
opt_trends.nb_trends_temporal = opt.nb_trends_temporal;
opt_trends.nb_trends_spatial = opt.nb_trends_spatial;
opt_trends.exclude = opt.exclude;
opt_trends.tr = tr;
opt_trends.confounds = opt.confounds;
opt_trends.spatial_av = opt.spatial_av;
opt_trends.nb_slices = numslices;
opt_trends.nb_frames = numframes;
trend = niak_make_trends(opt_trends); 
clear opt.trends

%% Creates x_cache
opt_cache.frame_times = (0:(numframes-1))*tr;
opt_cache.slice_times = slice_times;
opt_cache.events = events;
opt_cache.hrf_parameters = opt.hrf_parameters;
x_cache = niak_fmridesign(opt_cache);
clear opt_cache

if ~isempty(x_cache.x)
    nb_response = size(x_cache.x,2);
else
    nb_response = 0;
end
if isempty(opt.num_hrf_bases)
    opt.num_hrf_bases = ones(1,nb_response);
end

%% Creates matrix_x
opt_x.exclude = opt.exclude;
opt_x.num_hrf_bases = opt.num_hrf_bases;
opt_x.basis_type = opt.basis_type;
matrix_x = niak_full_design(x_cache,trend,opt_x);
clear opt_x;

if ~strcmp(files_out,'gb_niak_omitted');
    save(files_out,'x_cache','matrix_x');
end