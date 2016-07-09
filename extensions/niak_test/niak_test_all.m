function [pipe,opt,status] = niak_test_all(path_test,opt)
% Run all main tests available for NIAK
%
% SYNTAX:
% [PIPELINE,OPT,STATUS] = NIAK_TEST_ALL(PATH_TEST,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_TEST.DEMONIAK (string, default download nifti test data in 'test_niak_nii') 
%   the path to the (raw, small) NIAK demo dataset.
% PATH_TEST.TEMPLATE (string, default download the mnc cambridge template from figshare)
% PATH_TEST.TARGET (string, default download minc1 target data in 'target') 
% PATH_TEST.RESULT (string, default 'result') where to store the results of 
%   the tests.
%
% OPT.FLAG_TARGET (boolean, default false) if FLAG_TARGET == true, no comparison
%   with reference version of the results will be performed, but all test 
%   pipelines will still run. If this flag is used, PATH_TEST.TARGET does not 
%   need to be specified.
% OPT.FORMAT (string, default 'nii') the format to use for the test
%   Either 'nii' or 'mnc1'.
% OPT.FLAG_TEST (boolean, default false) if FLAG_TEST == true, the demo will 
%   just generate the test PIPELINE.
%   the folder where the results of reference for the tests have previously 
%   been generated (see OPT.FLAG_TARGET above).
% OPT.PSOM (structure) the options of the pipeline manager. See the OPT
%   argument of PSOM_RUN_PIPELINE. Note that the field PSOM.PATH_LOGS will be 
%   set up by the pipeline. By default OPT.PSOM.FLAG_PAUSE is false (do 
%   not wait for the user to confirm starting the tests).
%
% _________________________________________________________________________
% OUTPUTS:
%
% PIPELINE (structure) a formal description of the test pipeline. 
%   See PSOM_RUN_PIPELINE.
% OPT (structure) same as the input, updated
% STATUS (integer) returns 0 if all tests pass, 1 if there are failures, and 
%    [] if OPT.FLAG_TEST is true.
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
%   * glm_fir NIAK_PIPELINE_GLM_FIR
%   * stability_rest NIAK_PIPELINE_STABILITY_REST
%   * glm_connectome NIAK_PIPELINE_GLM_CONNECTOME
%   * stability cores NIAK_PIPELINE_SCORES
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
% Geriatrie de Montreal, Departement d'informatique et de recherche 
% oprationnelle, Universite de Montreal, 2013-2014.
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
niak_gb_vars
%% Options
if nargin < 2
    opt = struct;
end
opt = psom_struct_defaults(opt, ...
      {'format' , 'flag_target' , 'flag_test', 'psom' }, ...
      {'nii'    , false         , false      , struct });

if ~isfield(opt.psom,'flag_pause')
    opt.psom.flag_pause = false;
end

%% Check the input paths
if nargin < 1
    path_test = struct();
end
path_test = psom_struct_defaults(path_test, ...
    { 'target' , 'template' , 'demoniak' , 'result'}, ...
    { ''       , ''         , ''          , ''     });

%% Check the demoniak data
if isempty(path_test.demoniak)
    % Grab the demoniak dataset    
    [status,err,data_demoniak] = niak_wget(struct('type',['data_test_niak_' opt.format]));
    path_test.demoniak = data_demoniak.path;
    if status
        error('There was a problem downloading the test data');
    end
else
    fprintf('I am going to use the demoniak data at %s', path_test.demoniak);
end

%% Grab the demoniak dataset    
if ~opt.flag_target&&isempty(path_test.target)
    [status,err,data_target] = niak_wget(struct('type',['target_test_niak_' opt.format]));
    path_test.target = data_target.path;
    if status
        error('There was a problem downloading the target data')
    end
end

%% Check the template data
if isempty(path_test.template)
    % Grab the cambridge template
    [status,err,data_demoniak] = niak_wget(struct('type',['cambridge_template_' opt.format]));
    path_test.template = data_demoniak.path;
    if status
        error('There was a problem downloading the template data');
    end
else
    fprintf('I am going to use the template data at %s', path_test.demoniak);
end

if isempty(path_test.result)
    path_test.result = 'result';
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
switch opt.format
    case 'nii'
        ext_t = '.nii.gz';
    case 'mnc1'
        ext_t = '.mnc.gz';
    otherwise
        error('%s is an unkown file format')
end

path_test_fp.demoniak  = path_test.demoniak;
path_test_fp.reference = [path_test.target 'demoniak_preproc'];
path_test_fp.result    = path_test.result;
opt_pipe.build_confounds.thre_fd = 0.4;
opt_pipe.build_confounds.nb_min_vol = 15;
opt_pipe.resample_vol.voxel_size = [10 10 10];
opt_pipe.template.t1           = [path_test.demoniak filesep 'mni_icbm152_asym_09a_5mm' filesep 'mni_icbm152_t1_tal_nlin_asym_09a_5mm' ext_t];
opt_pipe.template.mask         = [path_test.demoniak filesep 'mni_icbm152_asym_09a_5mm' filesep 'mni_icbm152_t1_tal_nlin_asym_09a_mask_5mm' ext_t];
opt_pipe.template.mask_eroded  = [path_test.demoniak filesep 'mni_icbm152_asym_09a_5mm' filesep 'mni_icbm152_t1_tal_nlin_asym_09a_mask_eroded5mm_5mm' ext_t];
opt_pipe.template.mask_avg     = [path_test.demoniak filesep 'mni_icbm152_asym_09a_5mm' filesep 'mni_icbm152_t1_tal_nlin_asym_09a_mask_eroded5mm_5mm' ext_t];
opt_pipe.template.mask_dilated = [path_test.demoniak filesep 'mni_icbm152_asym_09a_5mm' filesep 'mni_icbm152_t1_tal_nlin_asym_09a_mask_dilated5mm_5mm' ext_t];
opt_pipe.template.mask_bold    = [path_test.demoniak filesep 'mni_icbm152_asym_09a_5mm' filesep 'mni_icbm152_t1_tal_nlin_asym_09a_mask_dilated5mm_5mm' ext_t];
opt_pipe.template.mask_wm      = [path_test.demoniak filesep 'mni_icbm152_asym_09a_5mm' filesep 'mni_icbm152_t1_tal_nlin_asym_09a_mask_pure_wm_5mm' ext_t];
opt_pipe.template.fmri         = [gb_niak_path_niak 'template' filesep 'roi_aal_3mm.mnc.gz'];                                                                           
opt_pipe.template.aal          = [gb_niak_path_niak 'template' filesep 'roi_aal_3mm.mnc.gz'];                                                                           
opt_pipe.template.mask_vent    = [gb_niak_path_niak 'template' filesep 'roi_ventricle.mnc.gz'];                                                                         
opt_pipe.template.mask_willis  = [gb_niak_path_niak 'template' filesep 'roi_stem.mnc.gz'];                                                                              
[pipe_fp,opt_p,files_fp] = niak_test_fmripreproc_demoniak(path_test_fp,opt_pipe);
pipe = psom_merge_pipeline(pipe,pipe_fp,'fp_');

%% Add the test of the region growing pipeline
if opt.flag_target
    % In target mode, grab the results of the preprocessing and carry on with region growing
    files_all = niak_grab_all_preprocess([path_test_fp.result 'demoniak_preproc'],files_fp);
else
    % In test mode, use the provided target to feed into the region growing pipeline
    files_all = niak_grab_all_preprocess([path_test.target 'demoniak_preproc']);
end
opt_pipe = struct;
opt_pipe.flag_test = true;
opt_pipe.flag_target = opt.flag_target;
files_rf.fmri  = files_all.fmri.vol;
files_rf.mask  = files_all.quality_control.group_coregistration.func.mask_group;
files_rf.areas = files_all.template.aal;
opt_pipe.files_in = files_rf;
path_test_rg.demoniak  = 'gb_niak_omitted'; % The input files are fed directly through opt_pipe.files_in above
path_test_rg.reference = [path_test.target 'demoniak_region_growing'];
path_test_rg.result    = path_test.result;
pipe = psom_merge_pipeline(pipe,niak_test_region_growing_demoniak(path_test_rg,opt_pipe),'rg_');

%% Add the test of the connectome pipeline
path_test_con.demoniak  = 'gb_niak_omitted'; % The input files are fed directly through opt_pipe.files_in above
path_test_con.reference = [path_test.target 'demoniak_connectome'];
path_test_con.result    = path_test.result;
pipe = psom_merge_pipeline(pipe,niak_test_connectome_demoniak(path_test_con,opt_pipe),'con_');

%% Add the test of the stability_fir pipeline
path_test_fir.demoniak  = 'gb_niak_omitted'; % The input files are fed directly through opt_pipe.files_in above
path_test_fir.reference = [path_test.target 'demoniak_stability_fir'];
path_test_fir.result    = path_test.result;
pipe = psom_merge_pipeline(pipe,niak_test_stability_fir_demoniak(path_test_fir,opt_pipe),'fir_');

%% Add the test of the glm_fir pipeline
path_test_fir.demoniak  = 'gb_niak_omitted'; % The input files are fed directly through opt_pipe.files_in above
path_test_fir.reference = [path_test.target 'demoniak_glm_fir'];
path_test_fir.result    = path_test.result;
pipe = psom_merge_pipeline(pipe,niak_test_glm_fir_demoniak(path_test_fir,opt_pipe),'gfir_');

%% Add the test of the stability_rest pipeline
path_test_fir.demoniak  = 'gb_niak_omitted'; % The input files are fed directly through opt_pipe.files_in above
path_test_fir.reference = [path_test.target 'demoniak_stability_rest'];
path_test_fir.result    = path_test.result;
pipe = psom_merge_pipeline(pipe,niak_test_stability_rest_demoniak(path_test_fir,opt_pipe),'basc_');

%% Add the test of the glm_connectome pipeline
path_test_fir.demoniak  = 'gb_niak_omitted'; % The input files are fed directly through opt_pipe.files_in above
path_test_fir.reference = [path_test.target 'demoniak_glm_connectome'];
path_test_fir.result    = path_test.result;
pipe = psom_merge_pipeline(pipe,niak_test_glm_connectome_demoniak(path_test_fir,opt_pipe),'gcon_');

%% Add the test of the scores pipeline
if opt.flag_target
    % In target mode, grab the results of the preprocessing and use them for scores
    files_all = niak_grab_all_preprocess([path_test_fp.result 'demoniak_preproc'],files_fp);
else
    % In test mode, use the provided target to feed into the scores pipeline
    files_all = niak_grab_all_preprocess([path_test.target 'demoniak_preproc'],files_fp);
end
opt_scores = struct;
opt_scores.flag_test = true;
opt_scores.flag_target = opt.flag_target;
files_sc.data  = files_all.fmri.vol;
files_sc.mask  = files_all.quality_control.group_coregistration.func.mask_group;
files_sc.part = [path_test.template filesep 'template_cambridge_basc_multiscale_sym_scale007' ext_t];
opt_scores.files_in = files_sc;
path_test_sc.demoniak  = 'gb_niak_omitted'; % The input files are fed directly through opt_pipe.files_in above
path_test_sc.reference = [path_test.target 'demoniak_scores'];
path_test_sc.result    = path_test.result;
pipe = psom_merge_pipeline(pipe,niak_test_scores_demoniak(path_test_sc,opt_scores),'sco_');

%% Add the unit tests for GLM-connectome
path_test = [path_test.result 'glm_connectome_unit'];
opt_glm.flag_test = true;
opt_glm.psom = opt.psom;
pipe = psom_merge_pipeline(pipe,niak_test_glm_connectome(path_test,opt_glm),'gun_');

%% Run the tests
if ~opt.flag_test
    status = psom_run_pipeline(pipe,opt.psom);
else 
    status = [];
end
