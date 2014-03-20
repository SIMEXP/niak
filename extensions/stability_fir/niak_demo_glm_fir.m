function [pipeline,opt_pipe,files_in] = niak_demo_glm_fir(path_demo,opt)
% This function runs NIAK_PIPELINE_GLM_FIR on the results of NIAK_DEMO_STABILITY_FIR
% and NIAK_DEMO_FMRI_PREPROCESS
% SYNTAX:
% [PIPELINE,OPT_PIPE,FILES_IN] = NIAK_DEMO_GLM_FIR(PATH_DEMO,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO.FMRI_PREPROCESS
%   (string) the full path to the preprocessed NIAK demo dataset. The dataset 
%   can be found at http://www.nitrc.org/frs/?group_id=411
%
% PATH_DEMO.STABILITY_FIR
%   (string) the full path to the results of NIAK_PIPELINE_STABILITY_FIR on the 
%   demo_niak preprocessed dataset.
%
% OPT
%   (structure, optional) Any argument passed to NIAK_PIPELINE_GLM_FIR
%   will do here. The demo only changes one default:
%
%   FOLDER_OUT
%      (string, default PATH_DEMO/connectome) where to store the 
%      results of the pipeline.
%
% _________________________________________________________________________
% OUTPUT
%
% PIPELINE
%   (structure) a formal description of the pipeline. See
%   PSOM_RUN_PIPELINE.
%
% OPT_PIPE
%   (structure) the option to call NIAK_PIPELINE_GLM_FIR
%
% FILES_IN
%   (structure) the description of input files used to call 
%   NIAK_PIPELINE_GLM_FIR
%
% _________________________________________________________________________
% COMMENTS
%
% Note 1:
% It is possible to configure the pipeline manager 
% to use parallel computing using OPT.PSOM, see : 
% http://code.google.com/p/psom/wiki/PsomConfiguration
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : FIR, GLM

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

if nargin < 1
    error('Please specify PATH_DEMO')
end
path_demo = psom_struct_defaults(path_demo,{'fmri_preprocess','stability_fir'},{NaN,NaN});
path_demo.fmri_preprocess = niak_full_path(path_demo.fmri_preprocess);
path_demo.stability_fir = niak_full_path(path_demo.stability_fir);
if nargin < 2
    opt = struct();
end
opt = psom_struct_defaults(opt,{'folder_out'},{[path_demo.stability_fir,'glm_fir',filesep]},false);
opt.folder_out = niak_full_path(opt.folder_out);

%% Grab the results from the NIAK fMRI preprocessing pipeline
opt_g.min_nb_vol = 30; % the demo dataset is very short, so we have to lower considerably the minimum acceptable number of volumes per run 
opt_g.type_files = 'fir'; % Specify to the grabber to prepare the files for the stability FIR pipeline
opt_g.filter.run = {'motor'}; % Just grab the "motor" runs
files_in = rmfield(niak_grab_fmri_preprocess(path_demo.fmri_preprocess,opt_g),{'mask','areas'}); 
files_in.fmri.subject1.session2.motor = files_in.fmri.subject1.session1.motor;

%% Now grab the results from the STABILITY_FIR pipeline
files_in.networks = niak_grab_stability_fir(path_demo.stability_fir).networks;

%% Set the timing of events;
files_in.model.group      = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_model_group.csv'];
files_in.model.individual.subject1.session1.motor = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
files_in.model.individual.subject1.session2.motor = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
files_in.model.individual.subject2.session1.motor = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];

%% FIR estimation
opt.fir.name_condition = 'motor';
opt.fir.name_baseline  = 'rest';
opt.fir.nb_min_baseline = 1; % There is not much data in the demo_niak, so don't set a minimum on the number of points used to estimate the baseline
opt.fir.type_norm     = 'fir_shape'; % The type of normalization of the FIR. Only "fir_shape" is available (starts at zero, unit sum-of-squares)
opt.fir.time_window   = 20;          % The size (in sec) of the time window to evaluate the response
opt.fir.time_sampling = 1;           % The time between two samples for the estimated response. Do not go below 1/2 TR unless there is a very large number of trials.
opt.fir.max_interpolation = 15;      % Allow interpolations of up to 15 seconds to cover for scrubbing. That's because the small demo dataset has hardly any usable time window ...

%% The tests

% Average FIR
opt.test.avg_fir.contrast.intercept = 1;

% FIR subject 1 - FIR subject 2
opt.test.sub1_m_sub2.contrast.intercept = 0;
opt.test.sub1_m_sub2.contrast.subject1  = 1;

% The permutation tests
opt.nb_samps = 100;
opt.nb_batch = 3;

%% Generate the pipeline
[pipeline,opt_pipe] = niak_pipeline_glm_fir(files_in,opt);