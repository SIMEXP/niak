function files = niak_grab_all_preprocess(path_data,files_in)
% Grab all the files created by NIAK_PIPELINE_FMRI_PREPROCESS
%
% SYNTAX:
% FILES_OUT = NIAK_GRAB_ALL_PREPROCESS( PATH_DATA , [FILES_IN] )
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DATA
%   (string, default [pwd filesep], aka './') full path to the outputs of 
%   NIAK_PIPELINE_FMRI_PREPROCESS
%
% FILES_IN
%   (structure, default struct() ) the FILES_IN structure fed to the fMRI 
%   preprocessing pipeline. If left empty, some minimal information are
%   gathered from the folder to build the list of expected outputs (see
%   the COMMENTS section below). However, if these information are 
%   incomplete or corrupted, the list of expected outputs may be 
%   inaccurate.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FILES_OUT
%   (structure) the list of all expected outputs of the fMRI preprocessing
%   pipeline. 
%
% _________________________________________________________________________
% SEE ALSO:
%
% _________________________________________________________________________
% COMMENTS:
%
% This "data grabber" based on the output folder of 
% NIAK_PIPELINE_FMRI_PREPROCESS
% It grabs way more things than NIAK_GRAB_FMRI_PREPROCESS, but it does not 
% have any filtering features. This grabber was developped to run automated
% reproducibility tests across NIAK versions and production sites.
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

%% Default path for the database
if (nargin<1)||isempty(path_data)
    path_data = [pwd filesep];
end

if nargin<2
    files_in = struct();
    flag_in = false;
    ext_f = '';
else 
    flag_in = true;
    [files_c,label] = niak_fmri2cell(files_in);
    [path_tmp,name_tmp,ext] = niak_fileparts(files_c{1});
end

path_data = niak_full_path(path_data);

%% List of folders
path_anat  = [path_data 'anat' filesep];
path_qc    = [path_data 'quality_control' filesep];
path_fmri  = [path_data 'fmri' filesep];
path_inter = [path_data 'intermediate' filesep];
path_res   = [path_data 'resample' filesep];

if ~flag_in&&(~exist(path_anat,'dir')||~exist(path_qc,'dir')||~exist(path_fmri,'dir')||~exist(path_inter,'dir')||~exist(path_res,'dir'))
    warning('The specified folder does not contain some expected outputs from the fMRI preprocess (anat ; quality_control ; fmri ; intermediate)')
end

%% Grab the list of subjects
if length(fieldnames(files_in))>0
    list_subject = fieldnames(files_in);
else
    list_qc = dir(path_qc);
    nb_subject = 0;
    for num_q = 1:length(list_qc)
        if ~ismember(list_qc(num_q).name,{'group_motion','group_coregistration','group_confounds','group_corsica','.','..'})&&list_qc(num_q).isdir
            nb_subject = nb_subject + 1;
            list_subject{nb_subject} = list_qc(num_q).name;
        end
    end
end

%% Grab the list of sessions and runs
if length(fieldnames(files_in))>0
    for num_s = 1:length(list_subject) % loop over subjects
        subject = list_subject{num_s};
        list_session = fieldnames(files_in.(subject).fmri);
        for num_sess = 1:length(list_session) % loop over sessions
            session = list_session{num_sess};
            list_run = fieldnames(files_in.(subject).fmri.(session));
            for num_r = 1:length(list_run) % loop over runs
                run = list_run{num_r};
                files.fmri.vol.(subject).(session).(run) = '';
            end
        end
     end
else
    file_scrub = [path_qc 'group_motion' filesep 'qc_scrubbing_group.csv'];
    [tab_scrub,labx_scrub,laby_scrub] = niak_read_csv(file_scrub);
    for num_s = 1:nb_subject
        subject = list_subject{num_s};
        ind_r = regexp(labx_scrub,['^' subject '_']);
        ind_r = find(cellfun(@length,ind_r,'UniformOutput',true)>0);
        files.fmri.vol.(subject) = struct();
        if ~isempty(ind_r)
            for num_r = 1:length(ind_r)
                ind_e = regexp(labx_scrub{ind_r(num_r)},'_');
                ind_e = ind_e(end);            
                run = labx_scrub{ind_r(num_r)}((ind_e+1):end);
                session = labx_scrub{ind_r(num_r)}((length(subject)+2):(ind_e-1));
                files.fmri.vol.(subject).(session).(run) = '';
            end
        else
	    error('I could not find any fmri dataset for subject %s, that''s weird.',subject);
        end    
    end
end

%% Grab the preprocessed fMRI datasets
[fmri_c,lc] = niak_fmri2cell(files.fmri.vol);
list_ext = { '.nii' , '.nii.gz' , '.mnc' , '.mnc.gz' };
for num_f = 1:length(lc)
    base_fmri = [path_fmri 'fmri_' lc(num_f).name];
    if ~flag_in
        ext = list_ext{end};
    else
        list_ext = {ext};
    end
    for num_e = 1:length(list_ext)    
        file_fmri = [base_fmri list_ext{num_e}];
        if flag_in||psom_exist(file_fmri)
            ext = list_ext{num_e};
            files.fmri.vol.(lc(num_f).subject).(lc(num_f).session).(lc(num_f).run) = file_fmri;
            files.fmri.extra.(lc(num_f).subject).(lc(num_f).session).(lc(num_f).run) = [base_fmri '_extra.mat'];
        end
     end     
end

%% Grab the templates
files.template.anat = [path_anat 'template_anat_stereo' ext];
files.template.fmri = [path_anat 'template_fmri_stereo' ext];
files.template.aal  = [path_anat 'template_aal' ext];

%% Grab the preprocessed anat datasets
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    path_anat_subj = [path_anat subject filesep];
    list_anat = { 'nuc_nativet1'       , ...
                  'nuc_stereolin'      , ...
                  'nuc_stereonl'       , ...
                  'mask_register_bold_stereolin' , ...
                  'nativefunc_lowres'  , ...
                  'nativefunc_hires'   , ...
                  'classify_stereolin' , ...
                  'mask_stereolin'     , ...
                  'mask_stereonl' ...
                };
%                  'pve_csf_stereolin'  , ... % Commented out because it is an optional output
%                  'pve_wm_stereolin'   , ... % Commented out because it is an optional output
%                  'pve_gm_stereolin'   , ... % Commented out because it is an optional output
%                  'pve_disc_stereolin' , ... % Commented out because it is an optional output

                   
    list_func = { 'mask_stereonl'  , ...
                  'mean_stereonl'  , ...
                  'std_stereonl'   , ...
                  'mask_stem_stereo' , ...
                  'mask_vent_stereo' , ...
                  'mask_wm_stereo' 
                  };
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
files.quality_control.group_motion.between_run.pdf = [path_qc 'group_motion' filesep 'qc_coregister_between_runs_group.pdf'];
files.quality_control.group_motion.within_run.csv  = [path_qc 'group_motion' filesep 'qc_motion_group.csv'];
files.quality_control.group_motion.within_run.pdf  = [path_qc 'group_motion' filesep 'qc_motion_group.pdf'];
files.quality_control.group_motion.scrubbing       = [path_qc 'group_motion' filesep 'qc_scrubbing_group.csv'];

%% Grab the results of quality control -- INDIVIDUAL
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    
    %% Subject level   

    % MOTION
    files.quality_control.individual.(subject).motion.coregister.csv = [path_qc subject filesep 'motion_correction' filesep 'tab_coregister_motion.csv'];
    files.quality_control.individual.(subject).motion.coregister.pdf = [path_qc subject filesep 'motion_correction' filesep 'fig_coregister_motion.pdf'];
    files.quality_control.individual.(subject).motion.mask           = [path_qc subject filesep 'motion_correction' filesep 'func_' subject '_mask_average_stereonl' ext];
    files.quality_control.individual.(subject).motion.within_run     = [path_qc subject filesep 'motion_correction' filesep 'fig_motion_within_run.pdf'];
end

%% Grab resampled data
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    
    %% Run level
    list_session = fieldnames ( files.fmri.vol.(subject) );
    for num_sess = 1:length(list_session)
        session = list_session{num_sess};
        list_run = fieldnames( files.fmri.vol.(subject).(session) );
        for num_r = 1:length(list_run)
            run = list_run{num_r};
            files.resample.fmri.(subject).(session).(run)  = [path_res filesep 'fmri_' subject '_' session '_' run '_n' ext];
            files.resample.extra.(subject).(session).(run) = [path_res filesep 'fmri_' subject '_' session '_' run '_n_extra.mat'];
            files.resample.confounds.(subject).(session).(run) = [path_res filesep 'fmri_' subject '_' session '_' run '_n_confounds.tsv.gz'];
            files.resample.keys = [path_res filesep 'niak_confounds.json'];
        end
    end
end

%% Grab the intermediate results
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    
    %% Run level
    list_session = fieldnames ( files.fmri.vol.(subject) );
    for num_sess = 1:length(list_session)
        session = list_session{num_sess};
        list_run = fieldnames( files.fmri.vol.(subject).(session) );
        for num_r = 1:length(list_run)
            run = list_run{num_r};
            files.intermediate.(subject).(session).(run).slice_timing       = [path_inter subject filesep 'slice_timing' filesep 'fmri_' subject '_' session '_' run '_a_extra.mat'];
            files.intermediate.(subject).(session).(run).slice_timing_extra = [path_inter subject filesep 'slice_timing' filesep 'fmri_' subject '_' session '_' run '_a' ext];
            files.intermediate.(subject).(session).(run).motion.target      = [path_inter subject filesep 'motion_correction' filesep 'motion_target_' subject '_' session '_' run ext];
            files.intermediate.(subject).(session).(run).motion.with_run    = [path_inter subject filesep 'motion_correction' filesep 'motion_Wrun_' subject '_' session '_' run '.mat'];
            files.intermediate.(subject).(session).(run).motion.parameters  = [path_inter subject filesep 'motion_correction' filesep 'motion_parameters_' subject '_' session '_' run '.mat'];
            files.intermediate.(subject).(session).(run).confounds          = [path_inter subject filesep 'regress_confounds' filesep 'fmri_' subject '_' session '_' run '_cor' ext];
            files.intermediate.(subject).(session).(run).confounds_mask     = [path_inter subject filesep 'regress_confounds' filesep 'fmri_' subject '_' session '_' run '_mask_compcor_stereo' ext];
            files.intermediate.(subject).(session).(run).confounds_extra    = [path_inter subject filesep 'regress_confounds' filesep 'fmri_' subject '_' session '_' run '_cor_extra.mat'];
            files.intermediate.(subject).(session).(run).scrubbing          = [path_inter subject filesep 'regress_confounds' filesep 'scrubbing_' subject '_' session '_' run '.mat'];
            files.intermediate.(subject).(session).(run).filter.high        = [path_inter subject filesep 'time_filter' filesep 'fmri_' subject '_' session '_' run '_n_dc_high.mat'];
            files.intermediate.(subject).(session).(run).filter.low         = [path_inter subject filesep 'time_filter' filesep 'fmri_' subject '_' session '_' run '_n_dc_low.mat'];
        end
    end
end