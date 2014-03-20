% Template for the BASC-FIR pipeline 
% (bootstrap analysis of stable clusters on finite impulse response estimate)
%
% To run this pipeline, the fMRI datasets first need to be preprocessed 
% using the NIAK fMRI preprocessing pipeline.
%
% WARNING: This script will clear the workspace
%
% Copyright (c) Pierre Bellec, 
%   Research Centre of the Montreal Geriatric Institute
%   & Department of Computer Science and Operations Research
%   University of Montreal, Québec, Canada, 2010-2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : fMRI, FIR, clustering, BASC

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

%%%%%%%%%%%%%%%%%%%%%
%% Grabbing the results from the NIAK fMRI preprocessing pipeline
%%%%%%%%%%%%%%%%%%%%%
opt_g.min_nb_vol = 100;     % The minimum number of volumes for an fMRI dataset to be included. This option is useful when scrubbing is used, and the resulting time series may be too short.
opt_g.min_xcorr_func = 0.5; % The minimum xcorr score for an fMRI dataset to be included. This metric is a tool for quality control which assess the quality of non-linear coregistration of functional images in stereotaxic space. Manual inspection of the values during QC is necessary to properly set this threshold.
opt_g.min_xcorr_anat = 0.5; % The minimum xcorr score for an fMRI dataset to be included. This metric is a tool for quality control which assess the quality of non-linear coregistration of the anatomical image in stereotaxic space. Manual inspection of the values during QC is necessary to properly set this threshold.
opt_g.exclude_subject = {'subject1','subject2'}; % If for whatever reason some subjects have to be excluded that were not caught by the quality control metrics, it is possible to manually specify their IDs here.
opt_g.type_files = 'fir'; % Specify to the grabber to prepare the files for the STABILITY_FIR pipeline
files_in = niak_grab_fmri_preprocess('/home/toto/database/fmri_preprocess',opt_g); % Replace the folder by the path where the results of the fMRI preprocessing pipeline were stored. 

%%%%%%%%%%%%%%%%%%%%%
%% Event times
%% A standard FSL event time in the form of a comma-separated values file will do.
%%
%% time , duration , amplitude
%% 3.5  , 4        , 1
%% 10   , 3.8      , 1
%%
%% Note that the two last columns are ignored. It is also possible to use a csv file with multiple 
%% conditions "a la NIAK"
%%
%%         , time , duration , amplitude
%% neutral , 3.5  , 4        , 1
%% pain    , 10   , 3.5      , 1
%% neutral , 15   , 4.2      , 1
%%
%% Again the two last columns are ignored. The name of the condition of interest is specified with OPT.NAME_CONDITION (by default
%% it is using the first condition). 
%% One last comment is that it is possible to specify the same model for all subjects and runs, or a different model for each subject/session/run.
%%%%%%%%%%%%%%%%%%%%%

% An example with the same file for all subjects. Uncomment the next line to use that approach, and remove the next block of code
% files_in.timing = '/home/toto/database/time_events.csv';

% An example with different event times for each subject/session/run 
files_in.timing.subject1.session1.run1 = '/home/toto/database/time_events_subject1_session1_run1.csv';
files_in.timing.subject1.session1.run2 = '/home/toto/database/time_events_subject1_session1_run2.csv';
files_in.timing.subject1.session2.run1 = '/home/toto/database/time_events_subject1_session2_run1.csv';
files_in.timing.subject2.session1.run1 = '/home/toto/database/time_events_subject2_session1_run1.csv';
files_in.timing.subject2.session1.run2 = '/home/toto/database/time_events_subject2_session1_run2.csv';
files_in.timing.subject2.session1.run3 = '/home/toto/database/time_events_subject2_session1_run3.csv';
files_in.timing.subject2.session2.run1 = '/home/toto/database/time_events_subject2_session2_run1.csv';

%%%%%%%%%%%%%
%% Options %%
%%%%%%%%%%%%%

opt.folder_out = '/home/toto/database/basc/'; % Where to store the results
opt.grid_scales = [10:10:100 120:20:200 240:40:500]'; % Search for stable clusters in the range 10 to 500 
opt.scales_maps = [ 3  2  2  ; ...   % The scales that will be used to generate the maps of brain clusters and stability. 
                    8  9  9  ; ...   % Usually, this is initially left empty. After the pipeline ran a first time, the results
                    21 20 19];       % of the MSTEPS procedure are used to select the final scales
opt.name_condition = 'pain';         % Name of the condition of interest (see FILES_IN.TIMING)
opt.name_baseline  = 'neutral';      % Name of the baseline condition (see FILES_IN.TIMING)
opt.stability_fir.nb_samps = 100;    % Number of bootstrap samples at the individual level. 100: the CI on indidividual stability is +/-0.1
opt.stability_fir.std_noise = 0;     % The standard deviation of the judo noise. The value 0 will not use judo noise. 
opt.stability_group.nb_samps = 500;  % Number of bootstrap samples at the group level. 500: the CI on group stability is +/-0.05

%% FIR estimation 
opt.fir.type_norm     = 'fir';       % The type of normalization of the FIR. FIR: the average baseline is set to zero, and FIR amplitude is expressed as a percentage of the baseline. 
                                     % For the 'fir_shape' option, the energy of the response is in addition set to 1.
opt.fir.time_norm     = 1;           % The time window (in sec) to define the 0 value
opt.fir.time_window   = 20;          % The size (in sec) of the time window to evaluate the response
opt.fir.time_sampling = 1;           % The time between two samples for the estimated response. Do not go below 1/2 TR unless there is a very large number of trials.

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%
opt.flag_test = false; % Put this flag to true to just generate the pipeline without running it. Otherwise the pipeline will start.
%opt.psom.max_queued = 10; % Uncomment and change this parameter to set the number of parallel threads used to run the pipeline
pipeline = niak_pipeline_stability_fir(files_in,opt); 