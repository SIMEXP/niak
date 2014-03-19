function [pipe,opt] = niak_test_glm_connectome(path_test,opt)
% Test the NIAK_PIPELINE_GLM_CONNECTOME
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_TEST_GLM_CONNECTOME(PATH_TEST,OPT)
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
%   NIAK_TEST_GLM_CONNECTOME_DATA
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2013.
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
opt.psom.path_logs = path_logs;

%% Generate test data
clear in out jopt
jopt.folder_out = [path_test 'data'];
pipe = psom_add_job(struct(),'build_test_data','niak_test_glm_connectome_data',struct,struct,jopt);

%% Running the test
clear in out jopt
in.networks.network4  = pipe.build_test_data.files_out.networks{1};
in.networks.network16 = pipe.build_test_data.files_out.networks{2};
in.fmri.subject1.session1.run1 = pipe.build_test_data.files_out.fmri_run{1};
in.fmri.subject2.session1.run1 = pipe.build_test_data.files_out.fmri_run{2};
in.fmri.subject3.session1.run1 = pipe.build_test_data.files_out.fmri_run{3};
in.fmri.subject4.session1.run1 = pipe.build_test_data.files_out.fmri_run{4};
in.model.group = pipe.build_test_data.files_out.group;
jopt.folder_out = [path_test 'results'];
jopt.nb_batch = 2;
jopt.flag_test = true;

% Average correlation for all
jopt.test.avg_corr_all.group.contrast.intercept = 1;

% Average correlation for youngs
jopt.test.avg_corr_young.group.contrast.intercept = 1;
jopt.test.avg_corr_young.group.select.label = {'age'};
jopt.test.avg_corr_young.group.select.max = 40;

% Correlation with age for all 
jopt.test.corr_vs_age.group.contrast.age = 1;
pipe = psom_merge_pipeline(pipe,niak_pipeline_glm_connectome(in,jopt));
list_job = fieldnames(pipe);

%% Check that the results are correct
clear in out jopt
out = [path_test 'report_test.csv'];
jopt.flag_source_only = true;
jopt.base_source = [path_test 'data' filesep 'ground_truth' filesep];
jopt.base_target = [path_test 'results'];
jopt.black_list_target = [path_test 'results' filesep 'logs' filesep];
pipe = psom_add_job(pipe,'check_test_correlation','niak_test_cmp_files',struct,out,jopt,false);
pipe.check_test_correlation.dep = list_job;

%% Run the pipeline

if ~opt.flag_test
    psom_run_pipeline(pipe,opt.psom);
end