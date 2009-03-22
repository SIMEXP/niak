function [pipeline,opt] = niak_demo_frmi_preprocess(path_demo)
%
% _________________________________________________________________________
% SUMMARY NIAK_DEMO_FMRI_PREPROCESS
%
% This function demonstrates how to use NIAK_PIPELINE_FMRI_PREPROCESS.
%
% SYNTAX:
% NIAK_DEMO_FMRI_PREPROCESS(PATH_DEMO)
%
% _________________________________________________________________________
% INPUT:
%
% PATH_DEMO
%       (string, default GB_NIAK_PATH_DEMO in the file NIAK_GB_VARS) 
%       the full path to the NIAK demo dataset. The dataset can be found in 
%       multiple file formats at the following address : 
%       http://www.bic.mni.mcgill.ca/users/pbellec/demo_niak/
%
% _________________________________________________________________________
% OUTPUT:
%
% The demo will apply a 'standard-native' preprocessing pipeline on the 
% functional data of subjects 1 and 2 (rest and motor conditions) as well 
% as their anatomical image. This will take about 2 hours on a single 
% machine. It is possible to configure the pipeline manager to use parallel
% computing, see : 
% http://code.google.com/p/psom/wiki/HowToUsePsom#PSOM_configuration
%
% _________________________________________________________________________
% COMMENT:
%
% NOTE 1:
% A more detailed description of NIAK_PIPELINE_FMRI_PREPROCESS can be found
% on : 
% http://wiki.bic.mni.mcgill.ca/index.php/NiakFmriPreprocessing
%
% NOTE 2:
% Note that the path to access the demo data is stored in a variable
% called GB_NIAK_PATH_DEMO defined in the NIAK_GB_VARS script.
% 
% NOTE 3:
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

niak_gb_vars

if ~exist('path_demo','var')
    path_demo = '';
end

if isempty(path_demo)
    path_demo = gb_niak_path_demo;
end

if ~strcmp(path_demo(end),filesep)
    path_demo = [path_demo filesep];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting input/output files %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% In which format is the niak demo ?
format_demo = 'minc2';
if exist(cat(2,path_demo,'anat_subject1.mnc'))
    format_demo = 'minc2';
elseif exist(cat(2,path_demo,'anat_subject1.mnc.gz'))
    format_demo = 'minc1';
elseif exist(cat(2,path_demo,'anat_subject1.nii'))
    format_demo = 'nii';
elseif exist(cat(2,path_demo,'anat_subject1.img'))
    format_demo = 'analyze';
end

switch format_demo
    
    case 'minc1' % If data are in minc1 format
        
        %% Subject 1

        % Structural scan
        files_in.subject1.anat = cat(2,path_demo,filesep,'anat_subject1.mnc.gz');

        % fMRI runs
        files_in.subject1.fmri.session1{1} = cat(2,path_demo,filesep,'func_motor_subject1.mnc.gz');
        files_in.subject1.fmri.session1{2} = cat(2,path_demo,filesep,'func_rest_subject1.mnc.gz');

        %% Subject 2

        % Structural scan
        files_in.subject2.anat = cat(2,path_demo,filesep,'anat_subject2.mnc.gz');

        % fMRI runs
        files_in.subject2.fmri.session1{1} = cat(2,path_demo,filesep,'func_motor_subject2.mnc.gz');
        files_in.subject2.fmri.session1{2} = cat(2,path_demo,filesep,'func_rest_subject2.mnc.gz');

    case 'minc2' % If data are in minc2 format
        
        %% Subject 1
        
        % Structural scan 
        files_in.subject1.anat = cat(2,path_demo,filesep,'anat_subject1.mnc');       
        
        % fMRI runs
        files_in.subject1.fmri.session1{1} = cat(2,path_demo,filesep,'func_motor_subject1.mnc');
        files_in.subject1.fmri.session1{2} = cat(2,path_demo,filesep,'func_rest_subject1.mnc');
                
        %% Subject 2
        
        % Structural scan 
        files_in.subject2.anat = cat(2,path_demo,filesep,'anat_subject2.mnc');       
        
        % fMRI runs
        files_in.subject2.fmri.session1{1} = cat(2,path_demo,filesep,'func_motor_subject2.mnc');
        files_in.subject2.fmri.session1{2} = cat(2,path_demo,filesep,'func_rest_subject2.mnc');
        
    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',format_demo)
        
end

%%%%%%%%%%%%%%%%%%%%%%%
%% Pipeline options  %%
%%%%%%%%%%%%%%%%%%%%%%%

% The style of the pipeline. Available options : 'fmristat',
% 'standard-native', 'standard-stereotaxic'.
opt.style = 'fmristat';

% The quantity of outputs. 
% Available options : 'minimum', 'quality_control', 'all'
opt.size_output = 'minimum';

% Where to store the results
opt.folder_out = cat(2,path_demo,filesep,'fmri_preprocess',filesep); 

% Flag to turn on and off the physiological noise correction
opt.flag_corsica = true; 

% Flag to actually run the pipeline or simply get the pipeline structure
opt.flag_test = false;

%%%%%%%%%%%%%%%%%%%%
%% Bricks options %%
%%%%%%%%%%%%%%%%%%%%

% These options correspond to the 'standard-native' style of
% pipeline, but will also work with 'standard-stereotaxic' and 'fmristat'.
% 
% The options presented here are only the most important ones. A 
% comprehensive list can be found in the help of the respective bricks.

% Linear and non-linear fit of the anatomical image in the stereotaxic
% space (niak_brick_civet)
opt.bricks.civet.n3_distance = 200; % Parameter for non-uniformity correction. 200 is a suggested value for 1.5T images, 25 for 3T images. If you find that this stage did not work well, this parameter is usually critical to improve the results.

% Motion correction (niak_brick_motion_correction)
opt.bricks.motion_correction.suppress_vol = 0; % There is no dummy scan to supress.
opt.bricks.motion_correction.vol_ref = 'median'; % Use the median volume of each run as a target.
opt.bricks.motion_correction.run_ref = 1; % The first run of each session is used as a reference.
opt.bricks.motion_correction.session_ref = 'session1'; % The first session is used as a reference.
opt.bricks.motion_correction.flag_session = 0; % Correct for both within and between sessions motion

% Slice timing correction (niak_brick_slice_timing)
TR = 2.33; % Repetition time in seconds
nb_slices = 42; % Number of slices in a volume
opt.bricks.slice_timing.slice_order = [1:2:nb_slices 2:2:nb_slices]; % Interleaved acquisition of slices
opt.bricks.slice_timing.timing(1)=TR/nb_slices; % Time beetween slices
opt.bricks.slice_timing.timing(2)=TR/nb_slices; % Time between the last slice of a volume and the first slice of next volume
opt.bricks.slice_timing.suppress_vol = 1; % Remove the first and last volume after slice-timing correction to prevent edges effects.

% Temporal filetring (niak_brick_time_filter)
opt.bricks.time_filter.hp = 0.01; % Apply a high-pass filter at cut-off frequency 0.01Hz (slow time drifts)
opt.bricks.time_filter.lp = Inf; % Do not apply low-pass filter. Low-pass filter induce a big loss in degrees of freedom without sgnificantly improving the SNR.

% Correction of physiological noise (niak_pipeline_corsica)
opt.bricks.sica.nb_comp = 20;
opt.bricks.component_supp.threshold = 0.15;

% Spatial smoothing (niak_brick_smooth_vol)
opt.bricks.smooth_vol.fwhm = 6; % Apply an isotropic 6 mm gaussin smoothing.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run the fmri_preprocess template  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pipeline = niak_pipeline_fmri_preprocess(files_in,opt);