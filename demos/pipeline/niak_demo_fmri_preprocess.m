% This is a script to demonstrate the usage of :
% NIAK_PIPELINE_FMRI_PREPROCESS
%
% SYNTAX:
% Just type in NIAK_DEMO_FMRI_PREPROCESS
%
% OUTPUT:
%
% This script will clear the workspace !!
% It will apply a 'standard-native' preprocessing pipeline on the functional 
% data of subjects 1 and 2 (rest and motor conditions) as well as their
% anatomical image. This will take about 2 hours on a single machine.
%
% Note that the path to access the demo data is stored in a variable
% called GB_NIAK_PATH_DEMO defined in the NIAK_GB_VARS script.
% 
% The demo database exists in multiple file formats. By default, it is
% using 'minc2' files. You can change that by changing the variable
% GB_NIAK_FORMAT_DEMO in the file NIAK_GB_VARS.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, slice timing, fMRI

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

clear
niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting input/output files %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch gb_niak_format_demo
    
    case 'minc2' % If data are in minc2 format
        
        %% Subject 1
        files_in.subject1.fmri.session1 = {cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc'),cat(2,gb_niak_path_demo,filesep,'func_rest_subject1.mnc')};
        files_in.subject1.anat = cat(2,gb_niak_path_demo,filesep,'anat_subject1.mnc');       
        
        %% Subject 2
        files_in.subject2.fmri.session1 = {cat(2,gb_niak_path_demo,filesep,'func_motor_subject2.mnc'),cat(2,gb_niak_path_demo,filesep,'func_rest_subject2.mnc')};
        files_in.subject2.anat = cat(2,gb_niak_path_demo,filesep,'anat_subject2.mnc');                       
        
    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',gb_niak_format_demo)
        
end

%%%%%%%%%%%%%%%%%%%%%%%
%% Pipeline options  %%
%%%%%%%%%%%%%%%%%%%%%%%
opt.style = 'standard-stereotaxic';
%opt.style = 'fmristat';
opt.size_output = 'quality_control';
%opt.size_output = 'all';
opt.folder_out = cat(2,gb_niak_path_demo,filesep,'fmri_preprocess',filesep);
opt.environment = 'octave';

%%%%%%%%%%%%%%%%%%%%
%% Bricks options %%
%%%%%%%%%%%%%%%%%%%%

%% These options correspond to the 'standard-stereotaxic' style of
%% pipeline.
%% This style is adapted for group-level connectivity analysis, 
%% but is not optimal for individual studies or general linear model analysis. 
%%
%% The options presented here are only a subset of available options.
%% Exhaustive list of options can be found in the help of respective
%% bricks.
%% The options listed here are the ones which depend on the dataset or 
%% that were subjectively considered as the most important.

%% 1. Motion correction (niak_brick_motion_correction)
opt.bricks.motion_correction.suppress_vol = 0; % There is no dummy scan to supress.
opt.bricks.motion_correction.vol_ref = 25; % The runs are 50 volumes long, we use the middle volume as a reference.
opt.bricks.motion_correction.run_ref = 1; % The first run of each session is used as a reference.
opt.bricks.motion_correction.session_ref = 'session1'; % The first session is used as a reference.
opt.bricks.motion_correction.flag_session = 0; % Correct for both within and between sessions motion

%% 2. Slice timing correction (niak_brick_slice_timing)
TR = 2.33; % Repetition time in seconds
nb_slices = 42; % Number of slices in a volume
opt.bricks.slice_timing.slice_order = [1:2:nb_slices 2:2:nb_slices]; % Interleaved acquisition of slices
opt.bricks.slice_timing.timing(1)=TR/nb_slices; % Time beetween slices
opt.bricks.slice_timing.timing(2)=TR/nb_slices; % Time between the last slice of a volume and the first slice of next volume
opt.bricks.slice_timing.suppress_vol = 1; % Remove the first volume after slice-timing correction to prevent edges effects.

%% 3. Coregistration between T1 and T2 (niak_brick_coregister)

%% 4. Temporal filetring (niak_brick_time_filter)
opt.bricks.time_filter.hp = 0.01; % Apply a high-pass filter at cut-off frequency 0.01Hz (slow time drifts)
opt.bricks.time_filter.lp = Inf; % Do not apply low-pass filter. Low-pass filter induce a big loss in degrees of freedom without sgnificantly improving the SNR.

%% 5. Spatial smoothing (niak_brick_smooth_vol)
opt.bricks.smooth_vol.fwhm = 6; % Apply an isotropic 6 mm gaussin smoothing.

%% 6. Linear and non-linear fit of the anatomical image in the stereotaxic
%% space (niak_brick_civet)
opt.bricks.civet.n3_distance = 200; % Parameter for non-uniformity correction. 200 is a suggested value for 1.5T images, 25 for 3T images. If you find that this stage did not work well, this parameter is usually critical to improve the results.


%% 7-8. Resampling in the stereotaxic space (niak_brick_concat_transf and niak_brick_resample_vol)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Building pipeline using the fmri_preprocess template  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pipeline = niak_pipeline_fmri_preprocess(files_in,opt);

%% Initialization of the pipeline
opt_pipe.path_logs = cat(2,opt.folder_out,'logs',filesep);
%file_pipeline = niak_init_pipeline(pipeline,opt_pipe)
%% Note that opt.interpolation_method has been updated, as well as files_out

