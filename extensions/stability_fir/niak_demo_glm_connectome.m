function [pipeline,opt_pipe,files_in] = niak_demo_glm_connectome(path_demo,opt)
% This function runs NIAK_PIPELINE_GLM_CONNECTOME on the results of NIAK_DEMO_FMRI_PREPROCESS
%
% SYNTAX:
% [PIPELINE,OPT_PIPE,FILES_IN] = NIAK_DEMO_GLM_CONNECTOME(PATH_DEMO,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO
%   (string) the full path to the preprocessed NIAK demo dataset. The dataset 
%   can be found at http://www.nitrc.org/frs/?group_id=411
%
% OPT
%   (structure, optional) Any argument passed to NIAK_PIPELINE_GLM_CONNECTOME
%   will do here. Many parameters are hard-coded though (see code). In addition:
%
%   FILES_IN.FMRI
%      (structure, default grab the preprocessed demoniak) the input files 
%      from the preprocessing to be fed in the glm_connectome pipeline.
%
%   FOLDER_OUT
%      (string, default PATH_DEMO/glm_connectome) where to store the 
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
path_demo = niak_full_path(path_demo);

if nargin < 2
    opt = struct();
end
opt = psom_struct_defaults(opt, ...
      { 'files_in'            , 'folder_out'}, ...
      { 'gb_niak_omitted'     , ''          },false);      
if isempty(opt.folder_out)
    opt.folder_out = [path_demo.stability_fir,'glm_connectome',filesep];
end
opt.folder_out = niak_full_path(opt.folder_out);


%% Grab the results from the NIAK fMRI preprocessing pipeline
if ~isempty(opt.files_in)&&~strcmp(opt.files_in,'gb_niak_omitted')  
    files_in = struct();
    [fmri_c,labels_f] = niak_fmri2cell(opt.files_in.fmri);
    for ee = 1:length(fmri_c)
        if strcmp(labels_f(ee).run,'motor')
            files_in.fmri.(labels_f(ee).subject).(labels_f(ee).session).(labels_f(ee).run) = fmri_c{ee};
        end
    end
else
    %% Grab the results from the NIAK fMRI preprocessing pipeline
    opt_g.min_nb_vol = 30; % the demo dataset is very short, so we have to lower considerably the minimum acceptable number of volumes per run 
    opt_g.type_files = 'fir'; % Specify to the grabber to prepare the files for the stability FIR pipeline
    opt_g.filter.run = {'motor'}; % Just grab the "motor" runs
    files_in = rmfield(niak_grab_fmri_preprocess(path_demo,opt_g),{'mask','areas'}); 
end

%% Duplicate one run
files_du = struct();
files_du.fmri.subject1a.session1.motor = files_in.fmri.subject1.session1.motor;
files_du.fmri.subject1a.session2.motor = files_in.fmri.subject1.session1.motor;
files_du.fmri.subject1b.session1.motor = files_in.fmri.subject1.session1.motor;
files_du.fmri.subject1c.session1.motor = files_in.fmri.subject1.session1.motor;
files_du.fmri.subject1d.session1.motor = files_in.fmri.subject1.session1.motor;
files_du.fmri.subject2a.session1.motor = files_in.fmri.subject2.session1.motor;
files_du.fmri.subject2a.session2.motor = files_in.fmri.subject2.session1.motor;
files_du.fmri.subject2b.session1.motor = files_in.fmri.subject2.session1.motor;
files_du.fmri.subject2c.session1.motor = files_in.fmri.subject2.session1.motor;
files_du.fmri.subject2d.session1.motor = files_in.fmri.subject2.session1.motor;
files_in = files_du;

%% Now use the NIAK Cambridge s100 template twice 
files_in.networks.cambridge100 = [gb_niak_path_niak 'template' filesep 'basc_cambridge_sc100.mnc.gz'];
files_in.networks.cambridge100bis = [gb_niak_path_niak 'template' filesep 'basc_cambridge_sc100.mnc.gz'];

%% Set the timing of events;
files_in.model.group      = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_model_group.csv'];
files_in.model.individual.subject1a.intra_run.session1.motor.event = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
files_in.model.individual.subject1a.intra_run.session2.motor.event = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
files_in.model.individual.subject1b.intra_run.session1.motor.event = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
files_in.model.individual.subject1c.intra_run.session1.motor.event = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
files_in.model.individual.subject1d.intra_run.session1.motor.event = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
files_in.model.individual.subject2a.intra_run.session1.motor.event = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
files_in.model.individual.subject2a.intra_run.session2.motor.event = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
files_in.model.individual.subject2b.intra_run.session1.motor.event = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
files_in.model.individual.subject2c.intra_run.session1.motor.event = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
files_in.model.individual.subject2d.intra_run.session1.motor.event = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];

%% GLM
opt.fdr = 0.05; % The maximal false-discovery rate that is tolerated both for individual (single-seed) maps and whole-connectome discoveries, at each particular scale (multiple comparisons across scales are addressed via permutation testing)
opt.fwe = 0.05; % The overall family-wise error, i.e. the probablity to have the observed number of discoveries, agregated across all scales, under the global null hypothesis of no association.
opt.nb_samps = 10; % The number of samples in the permutation test. This number has to be multiplied by OPT.NB_BATCH below to get the effective number of samples
opt.nb_batch = 2; % The permutation tests are separated into NB_BATCH independent batches, which can run on parallel if sufficient computational resources are available
opt.flag_rand = false; % if the flag is false, the pipeline is deterministic. Otherwise, the random number generator is initialized based on the clock for each job.

%% The tests
opt.test.mean_subjects.group.contrast.intercept  = 1; 

opt.test.effect_subject1.group.contrast.subject1 = 1;

opt.test.mean_motor.group.contrast.intercept     = 1;
opt.test.mean_motor.intra_run.select.label = 'motor';
opt.test.mean_motor.intra_run.select.min   = 0.8;

opt.test.mean_motor_nofisher.group.contrast.intercept = 1;
opt.test.mean_motor_nofisher.intra_run.select.label   = 'motor';
opt.test.mean_motor_nofisher.intra_run.select.min     = 0.8;
opt.test.mean_motor_nofisher.intra_run.flag_fisher    = false;

%% Generate the pipeline
opt = rmfield(opt,'files_in');
[pipeline,opt_pipe] = niak_pipeline_glm_connectome(files_in,opt);
