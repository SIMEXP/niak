%
% _________________________________________________________________________
% SUMMARY NIAK_TEMPLATE_FMRI_PREPROCESS_FMRISTAT
%
% This script demonstrates how to write a script to run an fMRI
% preprocessing pipeline in fMRIstat style.
%
%
% To actually run a demo of the preprocessing data, please see
% NIAK_DEMO_FMRI_PREPROCESS.
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting input/output files %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Subject 1
files_in.subject1.anat             = '/home/pbellec/demo_niak/anat_subject1.mnc.gz';       % Structural scan
files_in.subject1.fmri.session1{1} = '/home/pbellec/demo_niak/func_motor_subject1.mnc.gz'; % fMRI run 1
files_in.subject1.fmri.session1{2} = '/home/pbellec/demo_niak/func_rest_subject1.mnc.gz';  % fMRI run 2

%% Subject 2
files_in.subject1.anat             = '/home/pbellec/demo_niak/anat_subject2.mnc.gz';       % Structural scan
files_in.subject1.fmri.session1{1} = '/home/pbellec/demo_niak/func_motor_subject2.mnc.gz'; % fMRI run 1
files_in.subject1.fmri.session1{2} = '/home/pbellec/demo_niak/func_rest_subject2.mnc.gz';  % fMRI run 2

%%%%%%%%%%%%%%%%%%%%
%% Bricks options %%
%%%%%%%%%%%%%%%%%%%%

%% Linear and non-linear fit of the anatomical image in the stereotaxic
%% space (niak_brick_civet)
opt.bricks.civet.n3_distance = 200; % Parameter for non-uniformity correction. 200 is a suggested value for 1.5T images, 75 for 3T images. If you find that this stage did not work well, this parameter is usually critical to improve the results.

% Motion correction (niak_brick_motion_correction)
opt.bricks.motion_correction.suppress_vol = 0;          % There is no dummy scan to supress.
opt.bricks.motion_correction.vol_ref      = 'median';   % Use the median volume of each run as a target.
opt.bricks.motion_correction.run_ref      = 1;          % The first run of each session is used as a reference.
opt.bricks.motion_correction.session_ref  = 'session1'; % The first session is used as a reference.

% Correction of physiological noise (niak_pipeline_corsica)
opt.flag_corsica = false; % Apply physiological noise correction    

% Spatial smoothing (niak_brick_smooth_vol)
opt.bricks.smooth_vol.fwhm = 6; % Apply an isotropic 6 mm gaussin smoothing.

%%%%%%%%%%%%%%%%%%%%%%%
%% Pipeline options  %%
%%%%%%%%%%%%%%%%%%%%%%%

opt.style = 'fmristat'; % The style of the preprocessing
opt.size_output = 'quality_control'; % The quantity of outputs
opt.folder_out = '/home/pbellec/demo_niak/fmri_preprocess/'; % Where to store the results

pipeline = niak_pipeline_fmri_preprocess(files_in,opt); % Run the pipeline