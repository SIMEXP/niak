function files = niak_grab_report_preprocess(path_data)
% Grab NIAK fMRI preprocessed files to feed to NIAK_REPORT_FMRI_PREPROCESS
%
% SYNTAX:
% FILES = NIAK_GRAB_REPORT_PREPROCESS( PATH_DATA )
%
% PATH_DATA
%   (string, default [pwd filesep], aka './') full path to the outputs of 
%   NIAK_PIPELINE_FMRI_PREPROCESS
%
% FILES
%   (structure) the list of all expected inputs of NIAK_REPORT_FMRI_PREPROCESS
%
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Geriatrie de Montreal,
%               Departement d'informatique et de recherche operationnelle,
%               Universite de Montreal, 2016.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : grabber

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

if nargin < 1
    path_data = pwd;
end
files_all = niak_grab_all_preprocess(path_data);

%% Pipeline parameters
files.params = files_all.params;

%% Group-level results
files.group.avg_t1            = files_all.quality_control.group_coregistration.anat.stereonl.mean_average;
files.group.avg_func          = files_all.quality_control.group_coregistration.func.mean_average;
files.group.avg_mask_func     = files_all.quality_control.group_coregistration.func.mask_average;
files.group.mask_func_group   = files_all.quality_control.group_coregistration.func.mask_group;
files.group.summary_scrubbing = files_all.quality_control.group_motion.scrubbing;
files.group.summary_func      = files_all.quality_control.group_coregistration.func.csv;
files.group.summary_anat      = files_all.quality_control.group_coregistration.anat.stereonl.csv;

%% Individual results

% fMRI volumes in native and stereotaxic spaces
[fmri_c,labels] = niak_fmri2cell(files_all.resample.fmri);
files.ind.fmri_stereo = files_all.resample.fmri;
for ee = 1:length(labels)
    files.ind.fmri_native.(labels(ee).subject).(labels(ee).session).(labels(ee).run) = ...
    files_all.intermediate.(labels(ee).subject).(labels(ee).session).(labels(ee).run).slice_timing;
end

% Confound variables (including motion parameters, frame displacement and scrubbing
files.ind.confounds = files_all.resample.confounds;

% The individual T1 and BOLD images (after nl registration)
% as well as the intra-subject, inter-run registration
list_subject = unique({labels(:).subject});
for ss = 1:length(list_subject)
    files.ind.anat.(list_subject{ss}) = files_all.anat.(list_subject{ss}).t1.nuc_stereonl;
    files.ind.func.(list_subject{ss}) = files_all.anat.(list_subject{ss}).func.mean_stereonl;
    files.ind.registration.(list_subject{ss}) = files_all.quality_control.individual.(list_subject{ss}).motion.coregister.csv;
end

%% Templates
files.template.anat = files_all.template.anat;
files.template.fmri = files_all.template.fmri;
