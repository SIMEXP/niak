function [pipeline,opt] = niak_demo_fmri_preprocess_RegionGrowing(path_demo,opt)
% This function demonstrates how to use NIAK_PIPELINE_FMRI_PREPROCESS
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_DEMO_FMRI_PREPROCESS(PATH_DEMO,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO
%       (string, default GB_NIAK_PATH_DEMO in the file NIAK_GB_VARS) 
%       the full path to the NIAK demo dataset. The dataset can be found in 
%       multiple file formats at the following address : 
%       http://www.bic.mni.mcgill.ca/users/pbellec/demo_niak/
%
% OPT
%       (structure, optional) with the following fields : 
%
%       FLAG_TEST
%           (boolean, default false) if FLAG_TEST == true, the demo will 
%           just generate the PIPELINE and OPT structure, otherwise it will 
%           process the pipeline.
%
%       SIZE_OUTPUT 
%           (string, default 'quality_control') possible values : 
%           'quality_control’, ‘all’.
%
%       PSOM
%           (structure) the options of the pipeline manager. See the OPT
%           argument of PSOM_RUN_PIPELINE. Default values can be used here.
%           Note that the field PSOM.PATH_LOGS will be set up by the
%           pipeline.
%
% _________________________________________________________________________
% OUTPUTS:
%
% PIPELINE
%       (structure) a formal description of the pipeline. See
%       PSOM_RUN_PIPELINE.
%
% OPT
%       (structure) the option to call NIAK_PIPELINE_FMRI_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS:
%
% Note 1:
% The demo will apply the full fMRI preprocessing pipeline on the 
% functional data of subject 1 (rest and motor conditions) as well 
% as their anatomical image. It is possible to configure the pipeline 
% manager to use parallel computing using OPT.PSOM, see : 
% http://code.google.com/p/psom/wiki/PsomConfiguration
%
% NOTE 2:
% The demo database exists in multiple file formats. NIAK looks into the demo 
% path and is supposed to figure out which format you are intending to use 
% by himself. 
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, demo, pipeline, preprocessing, fMRI

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

%% Set up defaults
default_psom.path_logs = '';
gb_name_structure = 'opt';
gb_list_fields    = {'size_output'     , 'flag_test' , 'psom'       };
gb_list_defaults  = {'quality_control' , false       , default_psom };
niak_set_defaults

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
                
        files_in.subject1.anat             = cat(2,path_demo,filesep,'anat_subject1.mnc.gz');        
        files_in.subject1.fmri.session1{1} = cat(2,path_demo,filesep,'func_motor_subject1.mnc.gz');
        files_in.subject1.fmri.session1{2} = cat(2,path_demo,filesep,'func_rest_subject1.mnc.gz');     
        
        files_in.subject2.anat             = cat(2,path_demo,filesep,'anat_subject2.mnc.gz');        
        files_in.subject2.fmri.session1{1} = cat(2,path_demo,filesep,'func_motor_subject2.mnc.gz');
        files_in.subject2.fmri.session1{2} = cat(2,path_demo,filesep,'func_rest_subject2.mnc.gz');
        
    case 'minc2' % If data are in minc2 format
        
        files_in.subject1.anat             = cat(2,path_demo,filesep,'anat_subject1.mnc');        
        files_in.subject1.fmri.session1{1} = cat(2,path_demo,filesep,'func_motor_subject1.mnc');
        files_in.subject1.fmri.session1{2} = cat(2,path_demo,filesep,'func_rest_subject1.mnc');          
        
        files_in.subject2.anat             = cat(2,path_demo,filesep,'anat_subject2.mnc');        
        files_in.subject2.fmri.session1{1} = cat(2,path_demo,filesep,'func_motor_subject2.mnc');
        files_in.subject2.fmri.session1{2} = cat(2,path_demo,filesep,'func_rest_subject2.mnc');
        
    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',format_demo)
        
end

%%%%%%%%%%%%%%%%%%%%%%%
%% Pipeline options  %%
%%%%%%%%%%%%%%%%%%%%%%%

% General
opt.folder_out          = cat(2,path_demo,filesep,'fmri_preprocess',filesep);            % Where to store the results

% Slice timing correction (niak_brick_slice_timing)
opt.slice_timing.type_acquisition = 'interleaved ascending'; % Interleaved ascending (odd first by default)
opt.slice_timing.type_scanner     = 'Bruker';                % Only the value 'Siemens' will actually have an impact
opt.slice_timing.delay_in_tr      = 0;                       % The delay in TR ("blank" time between two volumes)
opt.slice_timing.flag_skip        = 0;                       % Turn on/off the slice timing (here it is on)

% Motion correction (niak_brick_motion_correction)
opt.motion_correction.suppress_vol = 0;          % There is no dummy scan to supress.
opt.motion_correction.session_ref  = 'session1'; % The session that is used as a reference. Use the session corresponding to the acqusition of the T1 scan.
opt.motion_correction.flag_skip    = 0;          % Turn on/off the motion correction

% Linear and non-linear fit of the anatomical image in the stereotaxic
% space (niak_brick_t1_preprocess)
opt.t1_preprocess.nu_correct.arg = '-distance 50'; % Parameter for non-uniformity correction. 200 is a suggested value for 1.5T images, 50 for 3T images. If you find that this stage did not work well, this parameter is usually critical to improve the results.

% T1-T2 coregistration (niak_brick_anat2func)
opt.anat2func.init = 'identity'; % The 'center' option usually does more harm than good. Use it only if you have very big misrealignement between the two images (say, > 2 cm).

% Temporal filtering (niak_brick_time_filter)
opt.time_filter.hp = 0.01; % Apply a high-pass filter at cut-off frequency 0.01Hz (slow time drifts)
opt.time_filter.lp = Inf;  % Do not apply low-pass filter. Low-pass filter induce a big loss in degrees of freedom without sgnificantly improving the SNR.

% Correction of physiological noise (niak_pipeline_corsica)
opt.corsica.sica.nb_comp             = 20;    % Number of components estimated during the ICA. 20 is a minimal number, 60 was used in the validation of CORSICA.
opt.corsica.threshold                = 0.15;  % This threshold has been calibrated on a validation database as providing good sensitivity with excellent specificity.
opt.corsica.flag_skip                = 0;     % Turn on/off the motion correction

% resampling in stereotaxic space
opt.resample_vol.interpolation       = 'tricubic'; % The resampling scheme. The most accurate is 'sinc' but it is awfully slow
opt.resample_vol.voxel_size          = [3 3 3];    % The voxel size to use in the stereotaxic space
opt.resample_vol.flag_skip           = 0;          % Turn on/off the resampling in stereotaxic space

% Spatial smoothing (niak_brick_smooth_vol)
opt.smooth_vol.fwhm      = 6;  % Apply an isotropic 6 mm gaussin smoothing.
opt.smooth_vol.flag_skip = 0;  % Turn on/off the spatial smoothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run the fmri_preprocess pipeline  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[pipeline,opt] = niak_pipeline_fmri_preprocess(files_in,opt);
