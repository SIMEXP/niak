function [pipe,opt] = niak_test_all(path_test,opt)
% Run all main tests available for NIAK
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_TEST_ALL(PATH_TEST,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_TEST.DEMONIAK (string) the path to the (raw) NIAK demo dataset.
% PATH_TEST.TARGET (string) the folder where the results of reference for the 
%   tests have previously been generated (see OPT.FLAG_TARGET below).
% PATH_TEST.RESULT (string) where to store the results of the tests.
%
% OPT.FLAG_TARGET (boolean, default false) if FLAG_TARGET == true, no comparison
%   with reference version of the results will be performed, but all test 
%   pipelines will still run. If this flag is used, PATH_TEST.TARGET does not 
%   need to be specified.
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
% The reference datasets can be found on the NITRC repository:
% http://www.nitrc.org/frs/?group_id=411
% 
% This test will apply the following pipeline on the DEMONIAK dataset, and 
% will optionally compare the outputs to a reference version of the
% results:
%   * fMRI preprocessing NIAK_PIPELINE_FMRI_PREPROCESS
%   * region growing NIAK_PIPELINE_REGION_GROWING
%   * connectome NIAK_PIPELINE_CONNECTOME
%   * stability_fir NIAK_PIPELINE_STABILITY_FIR
%
% Note that with OPT.FLAG_TARGET on, the region growing and connectome pipelines
% are fed the output of the preprocessing pipeline. When the flag is off, by contrast,
% these pipelines use the provided target preprocessing results as inputs. 
% This means that even if the preprocessing results do not replicate exactly,
% the region growing and/or connectome pipelines may exactly replicate.
%
% It is possible to configure the pipeline manager to use parallel 
% computing using OPT.PSOM, see : 
% http://code.google.com/p/psom/wiki/PsomConfiguration
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2013-2014.
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

%% Options
if nargin < 2
    opt = struct;
end
opt = psom_struct_defaults(opt, ...
      {'flag_target' , 'flag_test', 'psom' }, ...
      {false         , false      , struct });

%% Check the input paths
path_test = psom_struct_defaults(path_test, ...
    { 'target'          , 'demoniak' , 'result'}, ...
    { 'gb_niak_omitted' , NaN        , NaN     });
    
if ~opt.flag_target && strcmp(path_test.target,'gb_niak_omitted')
    error('Please specify PATH_TEST.TARGET or turn on OPT.FLAG_TARGET')
end
path_test.target   = niak_full_path(path_test.target);
path_test.demoniak = niak_full_path(path_test.demoniak);
path_test.result   = niak_full_path(path_test.result);
opt.psom.path_logs = [path_test.result 'logs'];

%% Initialization
opt_pipe.flag_test = true;
opt_pipe.flag_target = opt.flag_target;
pipe = struct;

%% Add the test of the preprocessing pipeline
path_test_fp.demoniak  = path_test.demoniak;
path_test_fp.reference = [path_test.target 'demoniak_preproc'];
path_test_fp.result    = path_test.result;
[pipe_fp,opt_p,files_fp] = niak_test_fmripreproc_demoniak(path_test_fp,opt_pipe);
pipe = psom_merge_pipeline(pipe,pipe_fp,'fp_');

%% Add the test of the region growing pipeline
if opt.flag_target
    % In target mode, grab the results of the preprocessing and carry on with region growing
    files_all = niak_grab_all_preprocess([path_test_fp.result 'demoniak_preproc'],files_fp);
else
    % In test mode, use the provided target to feed into the region growing pipeline
    files_all = niak_grab_all_preprocess([path_test.target 'demoniak_preproc'],files_fp);
end
files_rf.fmri  = files_all.fmri.vol;
files_rf.mask  = files_all.quality_control.group_coregistration.func.mask_group;
files_rf.areas = files_all.template_aal;
opt_pipe.files_in = files_rf;
path_test_rg.demoniak  = 'gb_niak_omitted'; % The input files are fed directly through opt_pipe.files_in above
path_test_rg.reference = [path_test.target 'demoniak_region_growing'];
path_test_rg.result    = path_test.result;
pipe = psom_merge_pipeline(pipe,niak_test_region_growing_demoniak(path_test_rg,opt_pipe),'rg_');

%% Add the test of the connectome pipeline
path_test_rg.demoniak  = 'gb_niak_omitted'; % The input files are fed directly through opt_pipe.files_in above
path_test_rg.reference = [path_test.target 'demoniak_connectome'];
path_test_rg.result    = path_test.result;
pipe = psom_merge_pipeline(pipe,niak_test_connectome_demoniak(path_test_rg,opt_pipe),'cc_');

%% Add the test of the stability_fir pipeline
path_test_fir.demoniak  = 'gb_niak_omitted'; % The input files are fed directly through opt_pipe.files_in above
path_test_fir.reference = [path_test.target 'demoniak_stability_fir'];
path_test_fir.result    = path_test.result;
pipe = psom_merge_pipeline(pipe,niak_test_stability_fir_demoniak(path_test_fir,opt_pipe),'fir_');

%% Run the tests
if ~opt.flag_test
    psom_run_pipeline(pipe,opt.psom);
end
