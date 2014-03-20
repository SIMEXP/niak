% Template for the NIAK_PIPELINE_GLM_FIR pipeline
%
% To run this pipeline, the fMRI datasets first need to be preprocessed 
% using the NIAK_PIPELINE_FMRI_PREPROCESS, and a set of functional 
% parcellations have to be generated using the NIAK_PIPELINE_STABILITY_FIR pipeline. 
%
% WARNING: This script will clear the workspace
%
% Copyright (c) Pierre Bellec, 
%   Research Centre of the Montreal Geriatric Institute
%   & Department of Computer Science and Operations Research
%   University of Montreal, Québec, Canada, 2010-2012
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

%%%%%%%%%%%%
%% Grabbing the results from BASC
%%%%%%%%%%%%
files_in = niak_grab_stability_fir('/home/toto/database/basc');

%%%%%%%%%%%%
%% Grabbing the results from the NIAK fMRI preprocessing pipeline
%%%%%%%%%%%%
opt_g.min_nb_vol = 100;     % The minimum number of volumes for an fMRI dataset to be included. This option is useful when scrubbing is used, and the resulting time series may be too short.
opt_g.min_xcorr_func = 0.5; % The minimum xcorr score for an fMRI dataset to be included. This metric is a tool for quality control which assess the quality of non-linear coregistration of functional images in stereotaxic space. Manual inspection of the values during QC is necessary to properly set this threshold.
opt_g.min_xcorr_anat = 0.5; % The minimum xcorr score for an fMRI dataset to be included. This metric is a tool for quality control which assess the quality of non-linear coregistration of the anatomical image in stereotaxic space. Manual inspection of the values during QC is necessary to properly set this threshold.
opt_g.exclude_subject = {'subject1','subject2'}; % If for whatever reason some subjects have to be excluded that were not caught by the quality control metrics, it is possible to manually specify their IDs here.
opt_g.type_files = 'glm_connectome'; % Specify to the grabber to prepare the files for the glm_connectome pipeline
opt_g.filter.session = {'session1'}; % Just grab session 1
opt_g.filter.run = {'rest'}; % Just grab the "rest" run
files_in.fmri = niak_grab_fmri_preprocess('/home/toto/database/fmri_preprocess',opt_g).fmri; % Replace the folder by the path where the results of the fMRI preprocessing pipeline were stored. 

%%%%%%%%%%%%
%% Set the model
%%%%%%%%%%%%

%% Group
files_in.model.group = '/home/toto/database/models/model_group.csv';

%% Subject 1
files_in.model.individual.subject1.inter_run = '/home/toto/database/models/individual/subject1/model_inter_run.csv';
files_in.model.individual.subject1.intra_run.session1_rest.event = '/home/toto/database/models/individual/subject1/intra_run/rest/event_rest.csv';
files_in.model.individual.subject1.intra_run.session1_rest.covariate = '/home/toto/database/models/individual/subject1/intra_run/rest/covariate_rest.csv';

% Subject 2
files_in.model.individual.subject2.inter_run = '/home/toto/database/models/individual/subject1/model_inter_run.csv';
files_in.model.individual.subject2.intra_run.session1_rest.event = '/home/toto/database/models/individual/subject1/intra_run/rest/event_rest.csv';
files_in.model.individual.subject2.intra_run.session1_rest.covariate = '/home/toto/database/models/individual/subject1/intra_effect_diseaserun/rest/covariate_rest.csv';

%%%%%%%%%%%%
%% Options 
%%%%%%%%%%%%
opt.folder_out = ['/home/toto/database/glm_connectome']; % Where to store the results
opt.fdr = 0.05; % The maximal false-discovery rate that is tolerated both for individual (single-seed) maps and whole-connectome discoveries, at each particular scale (multiple comparisons across scales are addressed via permutation testing)
opt.fwe = 0.05; % The overall family-wise error, i.e. the probablity to have the observed number of discoveries, agregated across all scales, under the global null hypothesis of no association.
opt.nb_samps = 1000; % The number of samples in the permutation test. This number has to be multiplied by OPT.NB_BATCH below to get the effective number of samples
opt.nb_batch = 10; % The permutation tests are separated into NB_BATCH independent batches, which can run on parallel if sufficient computational resources are available
opt.flag_rand = false; % if the flag is false, the pipeline is deterministic. Otherwise, the random number generator is initialized based on the clock for each job.

%%%%%%%%%%%%
%% Tests
%%%%%%%%%%%%

%% Compare connectivity between two subjects
%% ....
%% Would need a more complicated dataset than the demo_niak one
%% We're going to need a repository of examples for models and tests
%% This will be built internally in the SIMEXP-LAB and incorporated in the toolbox over the summer 2012

opt.test.effect_disease.group.contrast.disease = 1; % add the "disease" covariate to the model, and put a weight of 1 on this covariate in the contrast
opt.test.effect_disease.group.contrast.age = 0;     % add the "age" covariate to the model, and put a weight of 0 on this covariate in the contrast
opt.test.effect_disease.group.contrast.sex = 0;     % add the "sex" covariate to the model, and put a weight of 0 on this covariate in the contrast

opt.test.effect_disease_women.group.contrast.disease = 1; % add the "disease" covariate to the model, and put a weight of 1 on this covariate in the contrast
opt.test.effect_disease_women.group.contrast.age = 0;     % add the "age" covariate to the model, and put a weight of 0 on this covariate in the contrast
opt.test.effect_disease_women.group.select.label = 'sex'; % Select based on sex
opt.test.effect_disease_women.group.select.values = 1;    % Keep only the women, coded as 1

opt.test.effect_disease_women.group.contrast.intercept = 1; % The intercept is added (by default) to any model. A 1 contrast on the intercept is used to derive average connectivity maps
opt.test.effect_disease_women.group.contrast.disease = 0;   % add the "disease" covariate to the model, and put a weight of 0 on this covariate in the contrast
opt.test.effect_disease_women.group.contrast.age = 0;       % add the "age" covariate to the model, and put a weight of 0 on this covariate in the contrast
opt.test.effect_disease_women.group.select.label = 'sex';   % Select based on sex
opt.test.effect_disease_women.group.select.values = 1;      % Keep only the women, coded as 1

%%%%%%%%%%%%
%% Run the pipeline
%%%%%%%%%%%%
opt.flag_test = false; % Put this flag to true to just generate the pipeline without running it. Otherwise the region growing will start. 
%opt.psom.max_queued = 10; % Uncomment and change this parameter to set the number of parallel threads used to run the pipeline
[pipeline,opt] = niak_pipeline_glm_connectome(files_in,opt); 