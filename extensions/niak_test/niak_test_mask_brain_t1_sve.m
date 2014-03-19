function [pipeline,opt] = niak_test_mask_brain_t1_sve(path_test,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_TEST_MASK_BRAIN_T1_SVE
%
% This function is running a brain extraction on a collection of 40 T1
% scans publicly available as part of the segmentation validation engine
% (SVE, http://sve.loni.ucla.edu/)
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_TEST_MASK_BRAIN_T1_SVE(PATH_TEST,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_TEST
%       (string, default GB_NIAK_PATH_TEST_SVE in the file NIAK_TEST_GB_VARS) 
%       the full path to the NIAK SVE test dataset. Note that the SVE 
%       database is expected to have been converted into MINC format.
%
% OPT
%       (structure, optional) with the following fields : 
%
%       NUM_SUBJECT
%           (vector, default 1:40) the list of subjects that will be
%           processed.
%
%       FLAG_TEST
%           (boolean, default false) if FLAG_TEST == true, the test will 
%           just generate the PIPELINE and OPT structure, otherwise it will 
%           process the pipeline.
%
%       PSOM
%           (structure) the options of the pipeline manager. See the OPT
%           argument of PSOM_RUN_PIPELINE. Default values can be used here.
%           Note that the field PSOM.PATH_LOGS will be set up by the
%           pipeline.
%
% _________________________________________________________________________
% OUTPUTS:
%
% PIPELINE
%       (structure) a formal description of the pipeline. See
%       PSOM_RUN_PIPELINE.
%
% OPT
%       (structure) the update options
%
% _________________________________________________________________________
% COMMENTS:
%
% The test will use the brick NIAK_BRICK_MASK_BRAIN_T1 to extract the brain
% from the 40 subjects of the SVE database.
%
% _________________________________________________________________________
% COMMENT:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, brain segmentation, T1, NIAK

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

niak_test_gb_vars

if ~exist('path_test','var')
    path_test = '';
end

if isempty(path_test)
    path_test = gb_niak_path_test_sve;
end

if ~strcmp(path_test(end),filesep)
    path_test = [path_test filesep];
end

path_out = [path_test 'mask_niak_native_nonuc' filesep];

%% Set up defaults
gb_name_structure = 'opt';
default_psom.path_logs = [path_out filesep 'logs' filesep];
gb_list_fields = {'num_subject','flag_test','psom'};
gb_list_defaults = {1:40,false,default_psom};
niak_set_defaults

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting input/output files %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nb_subject = 40;
list_subject = cell([nb_subject 1]);
for num_s = 1:40
    if num_s<10
        list_subject{num_s} = ['0' num2str(num_s)];
    else
        list_subject{num_s} = [num2str(num_s)];
    end
end

for num_s = num_subject
    clear files_in_tmp files_out_tmp opt_tmp
    subject = list_subject{num_s};
    files_in_tmp = [path_test 'S' subject '.native.mri.mnc.gz'];
    files_out_tmp = [path_out 'S' subject '.native.mri.niak_native_nonuc.mnc.gz'];
    opt_tmp.flag_test = true;
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_mask_brain_t1(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = false;
    
    name_job = ['mask_S' subject];
    pipeline.(name_job).command = 'niak_brick_mask_brain_t1(files_in,files_out,opt);';
    pipeline.(name_job).files_in = files_in_tmp;
    pipeline.(name_job).files_out = files_out_tmp;
    pipeline.(name_job).opt = opt_tmp;
end

if ~flag_test
    psom_run_pipeline(pipeline,opt.psom);
end