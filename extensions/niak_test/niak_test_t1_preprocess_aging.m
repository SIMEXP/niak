function [pipeline,opt] = niak_test_t1_preprocess_aging(path_test,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_TEST_T1_PREPROCESS_AGING
%
% This function is running a brain extraction on a collection of T1
% scans from the ICBM AGING database.
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_TEST_MASK_BRAIN_T1_AGING(PATH_TEST,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_TEST
%       (string, default GB_NIAK_PATH_TEST_AGING in the file NIAK_TEST_GB_VARS) 
%       the full path to the NIAK AGING test dataset. 
%
% OPT
%       (structure, optional) with the following fields : 
%
%       NUM_SUBJECT
%           (vector, default 1:86) the list of subjects that will be
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
% The test will use the brick NIAK_BRICK_T1_PREPROCESS to perform linear 
% and non-linear coregistration in the MNI152 r2009 space, as well as non
% uniformity correction, intensity normalization, brain extraction and 
% tissue classification.
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

niak_gb_vars
niak_test_gb_vars

if ~exist('path_test','var')
    path_test = '';
end

if isempty(path_test)
    path_test = gb_niak_path_test;
end

if ~strcmp(path_test(end),filesep)
    path_test = [path_test filesep];
end

path_out = [path_test 'AGING' filesep];

%% Set up defaults
gb_name_structure = 'opt';
default_psom.path_logs = [path_out filesep 'logs' filesep];
gb_list_fields = {'num_subject','flag_test','psom'};
gb_list_defaults = {1:86,false,default_psom};
niak_set_defaults
opt.psom.path_logs = [path_out filesep 'logs' filesep];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting input/output files %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
list_subject = [560   561   562   563   564   565   566   567   568   570   571   572   573   574   575   576   579   581  582   584   585   590   591   592   595   596   598   599   600   601   603   604   605   610   611   612   613   614   615   616   618   619   620   621   622   623   624   625   626   627   628   629   630   631   633   634   635   637   638   639   640   641   642   643   644   645   646   647   648   649   650   651   652   653   654   655   656   657   658   659   660   661   663   666   667   668 ];
nb_subject = length(num_subject);
for num_s = num_subject
    subject = ['mni_' num2str(list_subject(num_s))];
    files_in.(subject) = [gb_niak_path_aging filesep 'anat' filesep subject '_t1.mnc.gz'];        
end

opt_t1.flag_test = true;
opt_t1.folder_out = path_out;
opt_t1.psom = opt.psom;
[pipeline,opt] = niak_pipeline_t1_preprocess(files_in,opt_t1);

if ~flag_test
    psom_run_pipeline(pipeline,opt.psom);
end