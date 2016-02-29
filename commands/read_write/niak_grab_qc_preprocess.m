function [files,opt] = niak_grab_qc_preprocess(path_data,opt)
% Grab files created by NIAK_PIPELINE_FMRI_PREPROCESS  needed by 
% NIAK_QC_FMRI_PREPROCESS
%
% SYNTAX:
% FILES_OUT = NIAK_GRAB_QC_PREPROCESS( PATH_DATA , OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DATA
%   (string, default [pwd filesep], aka './') full path to the outputs of 
%   NIAK_PIPELINE_FMRI_PREPROCESS
%
% OPT
%   (structure) with the following fields:
%
%   FILE_EXT
%      (string, default '.mnc.gz') files extension possible esxtention 
%      '.nii' , '.nii.gz' , '.mnc' , '.mnc.gz'
% _________________________________________________________________________
% OUTPUTS:
%
% FILES_OUT
%   (structure) the list of all expected outputs of the fMRI preprocessing
%   pipeline to be fed to NIAK_QC_FMRI_PREPROCESS. 
%
% OPT
%   (structure) with the following fields:
%
%   FLAG_INCOMPLETE
%      (boolean, default false) If the preprocessing pipeline is not completed this 
%       option tuns to true. 
%
% _________________________________________________________________________
% SEE ALSO:
%
% _________________________________________________________________________
% COMMENTS:
%
% This "data grabber" based on the output folder of 
% NIAK_PIPELINE_FMRI_PREPROCESS
% It grabs only things nedded by NIAK_QC_FMRI_PREPROCESS.
%
% The grabber will build a fairly exhaustive list of outputs.
% If FILES_IN is specified, the list can build even if PATH_DATA does not 
% exist. Otherwise, a limited number of outputs actually need to be present 
% for the list to build:
%   * The individual subfolders in the 'quality_control' folder.
%   * The qc_scrubbing_group.csv file in 'quality_control/group_motion'
%   * The preprocessed fMRI datasets in the folder 'fmri'
%
% The "logs" folder is not excluded in the list.
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Griatrie de Montral,
%               Dpartement d'informatique et de recherche oprationnelle,
%               Universit de Montral, 2011-2012.
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

%% Default setting
list_fields     = { 'file_ext'  ,  'flag_incomplete' };
list_defaults = { '.mnc.gz' , false                     };

if nargin<1
    path_data = [pwd filesep];
end
opt = struct();
opt = psom_struct_defaults(opt,list_fields,list_defaults);
path_data = niak_full_path(path_data);

%% Default varaibles
files = struct();
ext= opt.file_ext;

%% List of folders
path_anat  = [path_data 'anat' filesep];
path_qc    = [path_data 'quality_control' filesep];

if ~exist(path_anat,'dir')||~exist(path_qc,'dir')
    error('The specified folder does not contain some expected outputs from the fMRI preprocess (anat ; quality_control)')
end

%% Grab the list of subjects
list_qc = dir(path_anat);
list_qc = {list_qc.name};
list_qc = list_qc(~ismember(list_qc,{'.','..'}));
nb_subject = 0;
for num_q = 1:length(list_qc)
    list_anat = dir([path_anat list_qc{num_q} ]);
    list_anat = {list_anat.name};
    list_anat = list_anat(~ismember(list_anat,{'.','..'}));
    mask_exist =  ismember(list_anat,{ ['anat_' list_qc{num_q} '_nuc_stereonl.mnc.gz'] , ['func_' list_qc{num_q} '_mean_stereonl.mnc.gz']});
    if  ~(sum(mask_exist) < 2)
        nb_subject = nb_subject + 1;
        list_subject{nb_subject} = list_qc{num_q};
    end
end

%% Check if pipeline comp;eted
file_scrub = [path_qc 'group_motion' filesep 'qc_scrubbing_group.csv'];
if exist(file_scrub)
   fprintf('Congrats seems that you completed your preprocessing pepeline\n')
else 
    warning('Seems that your preprocessing pipeline is not fully completed, do not worry you will be able to QC\n')
    opt.flag_incomplete = true;
end

%% Grab the preprocessed anat datasets
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    path_anat_subj = [path_anat subject filesep];
    list_anat = { 'nuc_nativet1'       , ...
                  'nuc_stereolin'      , ...
                  'nuc_stereonl'       , ...
                  'nativefunc_lowres'  , ...
                  'nativefunc_hires'   , ...
                  'classify_stereolin' , ...
                  'mask_stereolin'     , ...
                  'mask_stereonl'};
                   
    list_func = { 'mask_stereonl'  , ...
                  'mean_stereonl'  , ...
                  'std_stereonl'};
    list_transf = { 'nativefunc_to_stereolin' , ...
                    'nativefunc_to_stereonl'  , ...
                    'nativet1_to_stereolin'   , ...
                    'stereolin_to_stereonl'};
    for num_a = 1:length(list_anat)
        files.anat.(subject).t1.(list_anat{num_a}) = [path_anat_subj 'anat_' subject '_' list_anat{num_a} ext];
    end
    for num_f = 1:length(list_func)
        files.anat.(subject).func.(list_func{num_f}) = [path_anat_subj 'func_' subject '_' list_func{num_f} ext];
    end
    for num_t = 1:length(list_transf)
        files.anat.(subject).transf.(list_transf{num_t}) = [path_anat_subj 'transf_' subject '_' list_transf{num_t} '.xfm'];
    end
    
    % Add the grids for non-linear transform
    files.anat.(subject).nativefunc_to_stereonl_grid = [path_anat_subj 'transf_' subject '_nativefunc_to_stereonl_grid_0.mnc'];
    files.anat.(subject).stereolin_to_stereonl_grid  = [path_anat_subj 'transf_' subject '_stereolin_to_stereonl_grid.mnc'];
end

%% Grab the AAL template 
files.template_aal = [path_anat 'template_aal.mnc.gz'];

%% Grab the results of quality control -- Group confounds
list_conf = { 'gse' , 'high' , 'motion' , 'slow_drift' , 'vent' , 'wm' };
for num_f = 1:length(list_conf)
    conf = list_conf{num_f};
    files.quality_control.group_confounds.(conf).pdf  = [path_qc 'group_confounds' filesep 'func_qc_' conf '_stereonl_fit.pdf'];
    files.quality_control.group_confounds.(conf).csv  = [path_qc 'group_confounds' filesep 'func_qc_' conf '_stereonl_fit.csv'];
    files.quality_control.group_confounds.(conf).mean = [path_qc 'group_confounds' filesep 'func_qc_' conf '_stereonl_mean' ext];
    files.quality_control.group_confounds.(conf).std  = [path_qc 'group_confounds' filesep 'func_qc_' conf '_stereonl_std' ext];
end

%% Grab the results of quality control -- Group coregistration
files.quality_control.group_coregistration.anat.stereolin.pdf          = [path_qc 'group_coregistration' filesep 'anat_fig_qc_coregister_stereolin.pdf' ];
files.quality_control.group_coregistration.anat.stereolin.csv          = [path_qc 'group_coregistration' filesep 'anat_tab_qc_coregister_stereolin.csv' ];
files.quality_control.group_coregistration.anat.stereolin.mask_average = [path_qc 'group_coregistration' filesep 'anat_mask_average_stereolin' ext];
files.quality_control.group_coregistration.anat.stereolin.mask_group   = [path_qc 'group_coregistration' filesep 'anat_mask_group_stereolin' ext];
files.quality_control.group_coregistration.anat.stereolin.mean_average = [path_qc 'group_coregistration' filesep 'anat_mean_average_stereolin' ext];
files.quality_control.group_coregistration.anat.stereolin.mean_std     = [path_qc 'group_coregistration' filesep 'anat_mean_std_stereolin' ext];

files.quality_control.group_coregistration.anat.stereonl.pdf          = [path_qc 'group_coregistration' filesep 'anat_fig_qc_coregister_stereonl.pdf' ];
files.quality_control.group_coregistration.anat.stereonl.csv          = [path_qc 'group_coregistration' filesep 'anat_tab_qc_coregister_stereonl.csv' ];
files.quality_control.group_coregistration.anat.stereonl.mask_average = [path_qc 'group_coregistration' filesep 'anat_mask_average_stereonl' ext];
files.quality_control.group_coregistration.anat.stereonl.mask_group   = [path_qc 'group_coregistration' filesep 'anat_mask_group_stereonl' ext];
files.quality_control.group_coregistration.anat.stereonl.mean_average = [path_qc 'group_coregistration' filesep 'anat_mean_average_stereonl' ext];
files.quality_control.group_coregistration.anat.stereonl.mean_std     = [path_qc 'group_coregistration' filesep 'anat_mean_std_stereonl' ext];

files.quality_control.group_coregistration.func.pdf          = [path_qc 'group_coregistration' filesep 'func_fig_qc_coregister_stereonl.pdf'];
files.quality_control.group_coregistration.func.csv          = [path_qc 'group_coregistration' filesep 'func_tab_qc_coregister_stereonl.csv'];
files.quality_control.group_coregistration.func.mask_average = [path_qc 'group_coregistration' filesep 'func_mask_average_stereonl' ext];
files.quality_control.group_coregistration.func.mask_group   = [path_qc 'group_coregistration' filesep 'func_mask_group_stereonl' ext];
files.quality_control.group_coregistration.func.mean_average = [path_qc 'group_coregistration' filesep 'func_mean_average_stereonl' ext];
files.quality_control.group_coregistration.func.mean_std     = [path_qc 'group_coregistration' filesep 'func_mean_std_stereonl' ext];

%% Grab the results of quality control -- MOTION
files.quality_control.group_motion.between_run.csv = [path_qc 'group_motion' filesep 'qc_coregister_between_runs_group.csv'];
files.quality_control.group_motion.within_run.csv  = [path_qc 'group_motion' filesep 'qc_motion_group.csv'];
files.quality_control.group_motion.scrubbing       = [path_qc 'group_motion' filesep 'qc_scrubbing_group.csv'];

%% Grab the results of quality control -- INDIVIDUAL
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    
    %% Subject level   
    
    % CORSICA
    files.quality_control.individual.(subject).corsica.stem = [path_qc subject filesep 'corsica' filesep subject '_mask_stem_funcstereonl' ext];
    files.quality_control.individual.(subject).corsica.vent = [path_qc subject filesep 'corsica' filesep subject '_mask_vent_funcstereonl' ext];
    files.quality_control.individual.(subject).corsica.wm   = [path_qc subject filesep 'corsica' filesep subject '_mask_wm_funcstereonl' ext];
    
    % MOTION
    files.quality_control.individual.(subject).motion.coregister.csv = [path_qc subject filesep 'motion_correction' filesep 'tab_coregister_motion.csv'];
    files.quality_control.individual.(subject).motion.coregister.pdf = [path_qc subject filesep 'motion_correction' filesep 'fig_coregister_motion.pdf'];
    files.quality_control.individual.(subject).motion.mask           = [path_qc subject filesep 'motion_correction' filesep 'func_' subject '_mask_average_stereonl' ext];
    files.quality_control.individual.(subject).motion.within_run     = [path_qc subject filesep 'motion_correction' filesep 'fig_motion_within_run.pdf'];
end
