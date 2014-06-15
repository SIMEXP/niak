function [pipe,opt] = niak_test_connectome_multiscale(path_test,opt)
% Test the NIAK_BRICK_CONNECTOME_MULTISCALE
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_TEST_CONNECTOME_MULTISCALE(PATH_TEST,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_TEST (string) where to store the results of the tests
% OPT.FLAG_TEST (boolean, default false) if FLAG_TEST == true, the demo will 
%   just generate the test PIPELINE.
% OPT.PSOM (structure) the options of the pipeline manager. See the OPT
%   argument of PSOM_RUN_PIPELINE. Note that the field PSOM.PATH_LOGS will be 
%   set up by the pipeline.
%
% _________________________________________________________________________
% OUTPUTS:
%
% PIPELINE (structure) a formal description of the test pipeline. 
%   See PSOM_RUN_PIPELINE.
%
% _________________________________________________________________________
% COMMENTS:
%
% The data for the tests can be generated with 
%   NIAK_TEST_CONNECTOME_MULTISCALE_DATA
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : test, NIAK, connectome

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

%% options
if nargin < 2
    opt = struct();
end
opt = psom_struct_defaults(opt,{'flag_test','psom'},{false,struct()});

%% Check the input paths
if ~ischar(path_test)
    error('PATH_TEST should be a string.')
end
path_test = niak_full_path(path_test);
path_logs = [path_test 'logs'];

%% Generate test data
clear in out jopt
out.ground_truth{1} = [path_test 'ground_truth' filesep 'test_correlation_network4.mat'];
out.ground_truth{2} = [path_test 'ground_truth' filesep 'test_correlation_network16.mat'];
jopt.folder_out = [path_test 'data'];
pipe = psom_add_job(struct(),'build_test_data','niak_test_connectome_multiscale_data',struct(),out,jopt);

%% Running the test
name = 'test_correlation';
pipe.(name).files_in.networks.network4  = pipe.build_test_data.files_out.networks{1};
pipe.(name).files_in.networks.network16 = pipe.build_test_data.files_out.networks{2};
pipe.(name).files_in.fmri.session1.run1 = pipe.build_test_data.files_out.fmri_run{1};
pipe.(name).files_in.fmri.session1.run2 = pipe.build_test_data.files_out.fmri_run{2};
pipe.(name).files_in.model.inter_run = pipe.build_test_data.files_out.inter_run;
pipe.(name).files_in.model.intra_run.session1.run1.covariate = pipe.build_test_data.files_out.intra_run_cov{1};;
pipe.(name).files_in.model.intra_run.session1.run2.covariate = pipe.build_test_data.files_out.intra_run_cov{2};;
pipe.(name).files_in.model.intra_run.session1.run1.event     = pipe.build_test_data.files_out.intra_run_ev{1};;
pipe.(name).files_in.model.intra_run.session1.run2.event     = pipe.build_test_data.files_out.intra_run_ev{2};;
pipe.(name).files_out.network4 = [path_test name '_network4.mat'];
pipe.(name).files_out.network16 = [path_test name '_network16.mat'];

% correlation, run1
pipe.(name).opt.param.run1.inter_run.select.label = 'run';
pipe.(name).opt.param.run1.inter_run.select.values = 1;

% correlation, run2
pipe.(name).opt.param.run2.inter_run.select.label = 'run';
pipe.(name).opt.param.run2.inter_run.select.values = 2;

% correlation, run1 minus run2
pipe.(name).opt.param.run1_minus_run2.inter_run.contrast.run1 = 1;

% correlation, after regressing out motion parameters for each run
pipe.(name).opt.param.run1_motion.inter_run.select.label  = 'run';
pipe.(name).opt.param.run1_motion.inter_run.select.values = 1;
pipe.(name).opt.param.run1_motion.intra_run.projection    = {'motion_tx','motion_ty','motion_tz','motion_rx','motion_ry','motion_rz'};

% correlation run1, after regressing out motor and visual stimuli
pipe.(name).opt.param.run1_motor_visual.inter_run.select.label  = 'run';
pipe.(name).opt.param.run1_motor_visual.inter_run.select.values = 1;
pipe.(name).opt.param.run1_motor_visual.intra_run.projection    = {'motor','visual'};

% correlation run1, after regressing out motion parameters for each run, and selecting the motor volumes
pipe.(name).opt.param.run1_motion_sel_motor.inter_run.select.label    = 'run';
pipe.(name).opt.param.run1_motion_sel_motor.inter_run.select.values   = 1;
pipe.(name).opt.param.run1_motion_sel_motor.intra_run.projection      = {'motion_tx','motion_ty','motion_tz','motion_rx','motion_ry','motion_rz'};
pipe.(name).opt.param.run1_motion_sel_motor.intra_run.select(1).label = 'motor';
pipe.(name).opt.param.run1_motion_sel_motor.intra_run.select(1).min   = 0.95;

% difference of correlation between run1 and run2, selecting the motor volumes. 
pipe.(name).opt.param.run1_minus_run2_sel_motor.inter_run.contrast.run1 = 1;
pipe.(name).opt.param.run1_minus_run2_sel_motor.intra_run.select(1).label = 'motor';
pipe.(name).opt.param.run1_minus_run2_sel_motor.intra_run.select(1).min   = 0.95;

% difference of correlation between run1 and run2, selecting the visual volumes. 
pipe.(name).opt.param.run1_minus_run2_sel_visual.inter_run.contrast.run1 = 1;
pipe.(name).opt.param.run1_minus_run2_sel_visual.intra_run.select(1).label = 'visual';
pipe.(name).opt.param.run1_minus_run2_sel_visual.intra_run.select(1).min   = 0.95;

pipe.(name).command = 'niak_brick_connectome_multiscale(files_in,files_out,opt);';

%% Check that the results are correct
clear in out jopt
name = 'check_test_correlation';
in.source{1} = pipe.build_test_data.files_out.ground_truth{1};
in.source{2} = pipe.build_test_data.files_out.ground_truth{2};
in.target{1} = pipe.test_correlation.files_out.network4;
in.target{2} = pipe.test_correlation.files_out.network16;
out = [path_test 'report_test.csv'];
jopt.flag_source_only = true;
jopt.base_source = [path_test 'ground_truth' filesep];
jopt.base_target = path_test;
pipe = psom_add_job(pipe,name,'niak_test_cmp_files',in,out,jopt);

%% Add some more unit tests on the "select" mechanism
opt_select.rand_seed = 0;
pipe = psom_merge_pipeline(pipe,niak_test_model_select(opt_select),'select_');

%% Run the pipeline
opt.psom.path_logs = path_logs;
if ~opt.flag_test
    psom_run_pipeline(pipe,opt.psom);
end