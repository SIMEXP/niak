% Template to write a script for the NIAK fMRI functional connectivity outcome mesures pipeline
%
%
% Copyright (c) Christian L. Dansereau, 
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal,
% 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, fMRI, preprocessing, pipeline

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Grabbing the results from the NIAK fMRI preprocessing pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt_g.min_nb_vol = 10;      % The minimum number of volumes for an fMRI dataset to be included. This option is useful when scrubbing is used, and the resulting time series may be too short.
opt_g.min_xcorr_func = 0.5; % The minimum xcorr score for an fMRI dataset to be included. This metric is a tool for quality control which assess the quality of non-linear coregistration of functional images in stereotaxic space. Manual inspection of the values during QC is necessary to properly set this threshold.
opt_g.min_xcorr_anat = 0.5; % The minimum xcorr score for an fMRI dataset to be included. This metric is a tool for quality control which assess the quality of non-linear coregistration of the anatomical image in stereotaxic space. Manual inspection of the values during QC is necessary to properly set this threshold.
opt_g.exclude_subject = {}; % If for whatever reason some subjects have to be excluded that were not caught by the quality control metrics, it is possible to manually specify their IDs here.
opt_g.type_files = 'roi'; % Specify to the grabber to prepare the files for the region growing pipeline

files_in = niak_grab_fmri_preprocess('/data/cisl/cdansereau/ad_template/fmri_preprocess',opt_g); % Replace the folder by the path where the results of the fMRI preprocessing pipeline were stored. 

scale = 'sci200_scg200_scf200'; % DO NOT EDIT scale for the outcome mesures!
files_in.ref_param = ['/data/cisl/cdansereau/ad_template' filesep 'group_ref' filesep 'global_params_' scale '.mat']; % you nead to specify the path for global_params_sci200_scg200_scf200.mat

%%%%%%%%%%%%%%%%%%%%%%
%% Pipeline options %%
%%%%%%%%%%%%%%%%%%%%%%

% General
opt.folder_out = [ '/data/cisl/cdansereau/ad_template/fmri_preprocess' filesep 'outcome' filesep];    % Where to store the results
opt.flag_verbose = true;
opt.flag_test = false;
opt.scale = scale;

% Pipeline manager 
opt.psom.mode                  = 'batch'; % Process jobs in the background
opt.psom.mode_pipeline_manager = 'batch'; % Run the pipeline manager in the background : if I unlog, keep working
opt.psom.max_queued            = 15;       % Number of jobs that can run in parallel. In batch mode, this is usually the number of cores.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run the fmri_preprocess pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[pipeline,opt] = niak_pipeline_fcon(files_in,opt);