function [pipeline,opt_pipe,files_in] = niak_demo_fmri_preprocess(path_demo,opt)
% This function demonstrates how to use NIAK_PIPELINE_FMRI_PREPROCESS
%
% SYNTAX:
% [PIPELINE,OPT_PIPE,FILES_IN] = NIAK_DEMO_FMRI_PREPROCESS(PATH_DEMO,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO
%   (string, default GB_NIAK_PATH_DEMO in the file NIAK_GB_VARS) 
%   the full path to the NIAK demo dataset. The dataset can be found in 
%   multiple file formats at the following address : 
%   http://www.nitrc.org/frs/?group_id=411
%
% OPT
%   (structure, optional) with the following fields : 
%
%   FOLDER_OUT
%      (string, default PATH_DEMO/fmri_preprocess) where to store the 
%      results of the pipeline.
%
%   FLAG_TEST
%      (boolean, default false) if FLAG_TEST == true, the demo will 
%      just generate the PIPELINE and OPT structure, otherwise it will 
%      process the pipeline.
%
%   FLAG_REGION_GROWING
%      (boolean, default false) if this flag is true, the region growing
%      step of the pipeline will be performed.
%
%   SIZE_OUTPUT 
%      (string, default 'quality_control') possible values : 
%      'quality_control’, ‘all’.
%
%   PSOM
%      (structure) the options of the pipeline manager. See the OPT
%      argument of PSOM_RUN_PIPELINE. Default values can be used here.
%      Note that the field PSOM.PATH_LOGS will be set up by the
%      pipeline.
%
% _________________________________________________________________________
% OUTPUTS:
%
% PIPELINE
%   (structure) a formal description of the pipeline. See
%   PSOM_RUN_PIPELINE.
%
% OPT_PIPE
%   (structure) the option to call NIAK_PIPELINE_FMRI_PREPROCESS
%
% FILES_IN
%   (structure) the description of input files used to call 
%   NIAK_PIPELINE_FMRI_PREPROCESS
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
folder_out = [niak_full_path(path_demo) 'fmri_preprocess' filesep];
default_psom.path_logs = '';
gb_name_structure = 'opt';
gb_list_fields    = { 'folder_out' , 'flag_region_growing' , 'size_output'     , 'flag_test' , 'psom'       };
gb_list_defaults  = { folder_out   , false                 , 'quality_control' , false       , default_psom };
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
                
        files_in.subject1.anat                = cat(2,path_demo,filesep,'anat_subject1.mnc.gz');
        files_in.subject1.fmri.session1.motor = cat(2,path_demo,filesep,'func_motor_subject1.mnc.gz');
        files_in.subject1.fmri.session1.rest  = cat(2,path_demo,filesep,'func_rest_subject1.mnc.gz');     
        
        files_in.subject2.anat                = cat(2,path_demo,filesep,'anat_subject2.mnc.gz');        
        files_in.subject2.fmri.session1.motor = cat(2,path_demo,filesep,'func_motor_subject2.mnc.gz');
        files_in.subject2.fmri.session2.rest  = cat(2,path_demo,filesep,'func_rest_subject2.mnc.gz');
        
    case 'minc2' % If data are in minc2 format
        
        files_in.subject1.anat                = cat(2,path_demo,filesep,'anat_subject1.mnc');
        files_in.subject1.fmri.session1.motor = cat(2,path_demo,filesep,'func_motor_subject1.mnc');
        files_in.subject1.fmri.session1.rest  = cat(2,path_demo,filesep,'func_rest_subject1.mnc');          
        
        files_in.subject2.anat                = cat(2,path_demo,filesep,'anat_subject2.mnc');        
        files_in.subject2.fmri.session1.motor = cat(2,path_demo,filesep,'func_motor_subject2.mnc');
        files_in.subject2.fmri.session2.rest  = cat(2,path_demo,filesep,'func_rest_subject2.mnc');
        
    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',format_demo)
        
end

%%%%%%%%%%%%%%%%%%%%%%%
%% Pipeline options  %%
%%%%%%%%%%%%%%%%%%%%%%%

% Slice timing correction (niak_brick_slice_timing)
opt.slice_timing.type_acquisition = 'interleaved ascending'; % Interleaved ascending (odd first by default)
opt.slice_timing.type_scanner     = 'Bruker';                % Scanner manufacturer. Only the value 'Siemens' will actually have an impact
opt.slice_timing.delay_in_tr      = 0;                       % The delay in TR ("blank" time between two volumes)
opt.slice_timing.suppress_vol     = 0;                       % Number of dummy scans to suppress.
opt.slice_timing.flag_nu_correct  = 1;                       % Apply a correction for non-uniformities on the EPI volumes (1: on, 0: of). This is particularly important for 32-channels coil.
opt.slice_timing.arg_nu_correct   = '-distance 200';         % The distance between control points for non-uniformity correction (in mm, lower values can capture faster varying slow spatial drifts).
opt.slice_timing.flag_center      = 0;                       % Set the origin of the volume at the center of mass of a brain mask. This is useful only if the voxel-to-world transformation from the DICOM header has somehow been damaged. This needs to be assessed on the raw images.
opt.slice_timing.flag_skip        = 0;                       % Skip the slice timing (0: don't skip, 1 : skip). Note that only the slice timing corretion portion is skipped, not all other effects such as FLAG_CENTER or FLAG_NU_CORRECT

% Motion correction (niak_brick_motion_correction)
opt.motion.session_ref  = 'session1'; % The session that is used as a reference. Use the session corresponding to the acqusition of the T1 scan.

% Linear and non-linear fit of the anatomical image in the stereotaxic
% space (niak_brick_t1_preprocess)
opt.t1_preprocess.nu_correct.arg = '-distance 50'; % Parameter for non-uniformity correction. 200 is a suggested value for 1.5T images, 50 for 3T images. If you find that this stage did not work well, this parameter is usually critical to improve the results.

% T1-T2 coregistration (niak_brick_anat2func)
opt.anat2func.init = 'identity'; % The 'center' option usually does more harm than good. Use it only if you have very big misrealignement between the two images (say, > 2 cm).
opt.tune.subject = 'subject1';
opt.tune.param.anat2func.init = 'center'; % Just to show case how to specify a different parameter for one subject (here subject1)

% Temporal filtering (niak_brick_time_filter)
opt.time_filter.hp = 0.01; % Apply a high-pass filter at cut-off frequency 0.01Hz (slow time drifts)
opt.time_filter.lp = Inf;  % Do not apply low-pass filter. Low-pass filter induce a big loss in degrees of freedom without sgnificantly improving the SNR.

% Correction of physiological noise (niak_pipeline_corsica)
opt.corsica.sica.nb_comp             = 20;    % Number of components estimated during the ICA. 20 is a minimal number, 60 was used in the validation of CORSICA.
opt.corsica.threshold                = 0.15;  % This threshold has been calibrated on a validation database as providing good sensitivity with excellent specificity.
opt.corsica.flag_skip                = 0;     % Turn on/off the motion correction

% resampling in stereotaxic space
opt.resample_vol.voxel_size          = [3 3 3];    % The voxel size to use in the stereotaxic space
opt.resample_vol.flag_skip           = 0;          % Turn on/off the resampling in stereotaxic space

% Spatial smoothing (niak_brick_smooth_vol)
opt.smooth_vol.fwhm      = 6;  % Apply an isotropic 6 mm gaussin smoothing.
opt.smooth_vol.flag_skip = 0;  % Turn on/off the spatial smoothing

% Region growing
opt.region_growing.flag_skip = ~flag_region_growing; % Turn on/off the region growing
opt = rmfield(opt,'flag_region_growing');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run the fmri_preprocess pipeline  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[pipeline,opt] = niak_pipeline_fmri_preprocess(files_in,opt);
opt_pipe = opt;