function [pipeline,opt_pipe,files_in] = niak_test_fmripreproc_demoniak(path_test,opt)
% Test the fMRI preprocessing pipeline on the DEMONIAK dataset
%
% SYNTAX:
% [PIPELINE,OPT_PIPE,FILES_IN] = NIAK_TEST_FMRIPREPROCESS_DEMONIAK(PATH_TEST,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_TEST.DEMONIAK (string) the path to the NIAK demo dataset.
% PATH_TEST.REFERENCE (string) the full path to a reference version of the 
%   results of the fMRI preprocessing pipeline. 
% PATH_TEST.RESULT (string) where to store the results of the test.
%
% Any field normally passed in OPT to NIAK_PIPELINE_FMRI_PREPROCESS can be used 
% here. In addition the following options are available:
%
% OPT.FLAG_TARGET (boolean, default false) if FLAG_TARGET == true, no comparison
%   with reference version of the results will be performed, but all test 
%   pipelines will still run. If this flag is used, PATH_TEST.REFERENCE
%   does not need to be specified.
% OPT.FLAG_CLEAN_UP (boolean, default true) remove all intermediate outputs.
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
% OPT_PIPE (structure) the options used to call the pipeline.
% FILES_IN (structure) the input files of the pipeline.
%
% _________________________________________________________________________
% COMMENTS:
%
% The DEMONIAK dataset can be found in multiple file formats at the following 
% address: http://www.nitrc.org/frs/?group_id=411
%
% This test will apply the full fMRI preprocessing pipeline on the DEMONIAK
% dataset, and will compare the outputs to a reference version of the
% preprocessing. 
%
% It is possible to configure the pipeline manager to use parallel 
% computing using OPT.PSOM, see : 
% http://code.google.com/p/psom/wiki/PsomConfiguration
%
% OPT.SIZE_OUTPUT is forced to 'all', but the entire content of the preprocessing
% is deleted if the test is successful.
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2012-2013.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : test, NIAK, fMRI preprocessing, pipeline, DEMONIAK

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

%% Check the input paths
path_test = psom_struct_defaults(path_test,{'demoniak','reference','result'},{NaN,'gb_niak_omitted',NaN});
if ~ischar(path_test.demoniak)||~ischar(path_test.reference)||~ischar(path_test.result)
    error('PATH_TEST.{DEMONIAK,REFERENCE,RESULT} should be strings.')
end
path_test.demoniak  = niak_full_path(path_test.demoniak);
path_test.reference = niak_full_path(path_test.reference);
path_test.result    = niak_full_path(path_test.result);
path_logs = [path_test.result 'logs'];

%% Generate the fMRI preprocessing pipeline
if nargin < 2
    opt = struct();
end

if isfield(opt,'flag_cleanup')
    flag_cleanup = opt.flag_cleanup;
    opt_demo = rmfield(opt,'flag_cleanup');
else
    flag_cleanup = true;    
end

if isfield(opt,'flag_target')
    flag_target = opt.flag_target;
    opt_demo = rmfield(opt,'flag_target');
else
    flag_target = false;
    opt_demo = opt;
end
if strcmp(path_test.reference,'gb_niak_omitted')&&flag_target
    error('Please specify PATH_TEST.REFERENCE')
end

opt_demo.folder_out = [path_test.result 'demoniak_preproc' filesep];
opt_demo.size_output = 'all';
opt_demo.flag_test = true;
[pipeline,opt_pipe,files_in] = niak_demo_fmri_preprocess(path_test.demoniak,opt_demo);
list_jobs = fieldnames(pipeline);

if ~flag_target
    %% Add a test: check the presence of expected files in the results of the fMRI preprocessing pipeline
    clear in_c out_c opt_c
    in_c = '';
    out_c = [path_test.result 'report_test_sanity_fmripreproc_demoniak.mat'];
    opt_c.files_in = files_in;
    opt_c.path_results = opt_demo.folder_out;
    pipeline = psom_add_job(pipeline,'test_sanity','niak_test_files_preprocess',in_c,out_c,opt_c,false);
    pipeline.test_sanity.dep = list_jobs;

    %% Add a test: comparison of the result of the preprocessing against the reference
    clear in_c out_c opt_c
    in_c.source = {};
    in_c.target = {};
    out_c = [path_test.result 'report_test_regression_fmripreproc_demoniak.csv'];
    opt_c.base_source = opt_demo.folder_out;
    opt_c.base_target = path_test.reference;
    opt_c.black_list_source = [opt_demo.folder_out 'logs' filesep];
    opt_c.black_list_target = [path_test.reference 'logs' filesep];
    pipeline = psom_add_job(pipeline,'test_regression','niak_test_cmp_files',in_c,out_c,opt_c,false);
    pipeline.test_regression.dep = list_jobs;

    %% Clean-up intermediate outputs
    if flag_cleanup 
        pipeline = psom_add_clean(pipeline,'clean_preproc',opt_demo.folder_out);
        pipeline.clean_preproc.dep = { 'test_regression' , 'test_sanity'};
    end
end

%% Run the pipeline
opt_pipe.psom.path_logs = path_logs;
if ~isfield(opt,'flag_test')||~opt.flag_test
    psom_run_pipeline(pipeline,opt_pipe.psom);
end
