function pipeline = niak_report_fmri_preprocess(in,opt)
% Generate a report for the fMRI preprocessing pipeline
%
% SYNTAX: PIPE = NIAK_REPORT_FMRI_PREPROCESS(IN,OPT)
%
% IN.PARAMS (string) 
%   The name of a .mat file with two variables FILES_IN (the input files) and 
%   OPT (the options), describing the parameters of the pipeline. 
%
% IN.GROUP (structure)
%   with the following fields:
%   AVG_T1 (string) the file name of the average T1 of all subjects, 
%     after non-linear coregistration in stereotaxic space. 
%   AVG_FUNC (string) the file name of the average BOLD volume of all subjects, 
%     after non-linear coregistration in stereotaxic space. 
%   AVG_MASK_FUNC (string) the file name of the average indivudal BOLD mask,
%     after non-linear coregistration in stereotaxic space. 
%   MASK_FUNC_GROUP (string) the file name of the group mask for BOLD data, 
%     in non-linear stereotaxic space. 
%   SUMMARY_SCRUBBING (string) the file name of a .csv file with a summary of 
%     scrubbing of fMRI time series. 
%   SUMMARY_FUNC (string) the file name of a .csv file with a summary of
%     BOLD registration. 
%   SUMMARY_ANAT (string) the file name of a .csv file with a summary of
%     T1 registration. 
%
% IN.IND (structure)
%   with the following fields:
%   FMRI_NATIVE.(SUBJECT).(SESSION).(RUN) (string) file name of an fMRI dataset
%     in native space (before resampling for motion). 
%   FMRI_STEREO.(SUBJECT).(SESSION).(RUN) (string) file name of an fMRI dataset
%     after spatial resampling to correct for motion. 
%   CONFOUNDS.(SUBJECT).(SESSION).(RUN) (string) file name of a .tsv file
%     with confound variables (motion parameters, FD and scrubbing mask).  
%   ANAT.(SUBJECT) (string) the file name of an individual T1 volume (in stereotaxic space).
%   FUNC.(SUBJECT) (string) the file name of an individual functional volume (in stereotaxic space)
%   REGISTRATION.(SUBJECT) (string) the file name of a .csv file with measures of 
%     intra-subject, inter-run coregistration quality. 
%
% IN.TEMPLATE.ANAT (string) 
%   the file name of the template used for registration in stereotaxic space.
% IN.TEMPLATE.FMRI (string) 
%   the file name of the template used to resample fMRI data.
%
% OPT
%   (structure) with the following fields:
%   FOLDER_OUT (string) where to generate the outputs. 
%   COORD (array N x 3) Coordinates for the registration figures. 
%     The default is:
%     [-30 , -65 , -15 ; 
%       -8 , -25 ,  10 ;  
%       30 ,  45 ,  60];    
%   PSOM (structure) options for PSOM. See PSOM_RUN_PIPELINE.
%   FLAG_VERBOSE (boolean, default true) if true, verbose on progress. 
%   FLAG_TEST (boolean, default false) if the flag is true, the pipeline will 
%     be generated but no processing will occur.
%
% Note:
%   Labels SUBJECT, SESSION and RUN are arbitrary but need to conform to matlab's 
%   specifications for field names. 
%
%   This pipeline needs the PSOM library to run. 
%   http://psom.simexp-lab.org/
% 
% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de griatrie de Montral, 2016.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : visualization, montage, 3D brain volumes

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

psom_gb_vars;

%% Defaults

% Inputs
in = psom_struct_defaults( in , ...
    { 'params' , 'group' , 'ind' , 'template' }, ...
    { NaN      , NaN     , NaN   , NaN        });

in.group = psom_struct_defaults( in.group , ...
    { 'avg_t1' , 'avg_func' , 'avg_mask_func' , 'mask_func_group' , 'summary_func' , 'summary_anat' , 'summary_scrubbing' }, ...
    { NaN      , NaN        , NaN             , NaN               , NaN            , NaN            , NaN                 });

in.ind = psom_struct_defaults( in.ind , ...
    { 'fmri_native' , 'fmri_stereo' , 'confounds' , 'anat' , 'func' , 'registration' }, ...
    { NaN           , NaN           , NaN         , NaN    , NaN    , NaN            });

in.template = psom_struct_defaults( in.template , ...
    { 'anat' , 'fmri' }, ...
    { NaN    , NaN    });

list_subject = fieldnames(in.ind.anat);

%% Options 
if nargin < 2
    opt = struct;
end
coord_def =[-30 , -65 , -15 ; 
             -8 , -25 ,  10 ;  
             30 ,  45 ,  60];
opt = psom_struct_defaults ( opt , ...
    { 'folder_out' , 'coord'   , 'flag_test' , 'psom'   , 'flag_verbose' }, ...
    { pwd          , coord_def , false       , struct() , true           });

opt.folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [opt.folder_out 'logs' filesep];

%% Build file names 

%% Copy and update the report templates
pipeline = struct;
clear jin jout jopt
niak_gb_vars
path_template = [gb_niak_path_niak 'reports' filesep 'fmri_preprocess' filesep 'templates' filesep ];
jin = niak_grab_folder( path_template , {'.git',[path_template 'motion'],[path_template 'registration'],[path_template 'summary'],[path_template 'group']});
jout = strrep(jin,path_template,opt.folder_out);
jopt.folder_out = opt.folder_out;
pipeline = psom_add_job(pipeline,'cp_report_templates','niak_brick_copy',jin,jout,jopt);

%% Write a text description of the pipeline parameters
clear jin jout jopt
jin = in.params;
jout.list_subject = [opt.folder_out 'group' filesep 'listSubject.js'];
jout.list_run = [opt.folder_out 'group' filesep 'listRun.js'];
jout.files_in = [opt.folder_out 'summary' filesep 'filesIn.js'];
jout.summary = [opt.folder_out 'summary' filesep 'pipeSummary.js'];
pipeline = psom_add_job(pipeline,'params','niak_brick_preproc_params2report',jin,jout);

%% The summary of BOLD registration
clear jin jout jopt
jin = in.group.summary_func;
jout = [opt.folder_out 'summary' filesep 'chartBOLD.js'];
pipeline = psom_add_job(pipeline,'summary_func','niak_brick_preproc_func2report',jin,jout);

%% The summary of T1 registration
clear jin jout jopt
jin = in.group.summary_func;
jout = [opt.folder_out 'summary' filesep 'chartT1.js'];
pipeline = psom_add_job(pipeline,'summary_anat','niak_brick_preproc_anat2report',jin,jout);

%% The summary of FD
clear jin jout jopt
jin = in.group.summary_scrubbing;
jout = [opt.folder_out 'summary' filesep 'fd.js'];
pipeline = psom_add_job(pipeline,'summary_scrubbing','niak_brick_preproc_scrubbing2report',jin,jout);

%% The summary of FD
clear jin jout jopt
jin = in.ind.registration;
jout = [opt.folder_out 'summary' filesep 'chartBrain.js'];
pipeline = psom_add_job(pipeline,'summary_intra','niak_brick_preproc_intra2report',jin,jout);

%% Generate group images
clear jin jout jopt
jin.target = in.template.anat;
jopt.coord = opt.coord;
jopt.colorbar = true;

% Template
jin.source = in.template.anat;
jout = [opt.folder_out 'group' filesep 'template_stereotaxic.png'];
jopt.colormap = 'gray';
jopt.limits = [0 100];
jopt.title = 'T1 Template';
pipeline = psom_add_job(pipeline,'template_stereo','niak_brick_vol2img',jin,jout,jopt);

% Group average T1
jin.source = in.group.avg_t1;
jout = [opt.folder_out 'group' filesep 'average_t1_stereotaxic.png'];
jopt.colormap = 'gray';
jopt.limits = [0 100];
jopt.title = 'Group average T1';
pipeline = psom_add_job(pipeline,'average_t1_stereo','niak_brick_vol2img',jin,jout,jopt);

% Group average BOLD
jin.source = in.group.avg_func;
jout = [opt.folder_out 'group' filesep 'average_func_stereotaxic.png'];
jopt.colormap = 'jet';
jopt.limits = 'adaptative';
jopt.title = 'Group average BOLD';
pipeline = psom_add_job(pipeline,'average_func_stereo','niak_brick_vol2img',jin,jout,jopt);

% Group BOLD mask
jin.source = in.group.mask_func_group;
jout = [opt.folder_out 'group' filesep 'mask_func_group_stereotaxic.png'];
jopt.colormap = 'jet';
jopt.limits = [0 1];
jopt.title = 'Group BOLD mask';
pipeline = psom_add_job(pipeline,'mask_func_group_stereo','niak_brick_vol2img',jin,jout,jopt);

% Average BOLD mask
jin.source = in.group.avg_mask_func;
jout = [opt.folder_out 'group' filesep 'average_mask_func_stereotaxic.png'];
jopt.colormap = 'jet';
jopt.limits = [0 1];
jopt.title = 'Average BOLD mask';
pipeline = psom_add_job(pipeline,'avg_mask_func_stereo','niak_brick_vol2img',jin,jout,jopt);

%% Panel on individual registration

% Individual T1 images
jopt.colormap = 'gray';
jopt.limits = [0 100];
jopt.method = 'linear';
for ss = 1:length(list_subject)
    jin.source = in.ind.anat.(list_subject{ss});
    jout = [opt.folder_out 'registration' filesep list_subject{ss} '_anat.png'];
    jopt.title = sprintf('Individual T1 subject %s',list_subject{ss});
    pipeline = psom_add_job(pipeline,['t1_' list_subject{ss}],'niak_brick_vol2img',jin,jout,jopt);
end

% Individual BOLD images
jopt.colormap = 'jet';
jopt.limits = 'adaptative';
jopt.method = 'linear';
for ss = 1:length(list_subject)
    jin.source = in.ind.func.(list_subject{ss});
    jout = [opt.folder_out 'registration' filesep list_subject{ss} '_func.png'];
    jopt.title = sprintf('Individual BOLD subject %s',list_subject{ss});
    pipeline = psom_add_job(pipeline,['bold_' list_subject{ss}],'niak_brick_vol2img',jin,jout,jopt);
end

%% Panel on motion

% Movies (and target image for all runs)
[list_fmri_native,labels] = niak_fmri2cell(in.ind.fmri_native);
[list_fmri_stereo,labels] = niak_fmri2cell(in.ind.fmri_stereo);
for ll = 1:length(labels)
    clear jin jout jopt
    
    % Native movie
    jin.source = list_fmri_native{ll};
    jin.target = '';
    jout = [opt.folder_out 'motion' filesep 'motion_native_' labels(ll).name '.png'];
    jopt.coord = 'CEN';
    jopt.colormap = 'jet';
    jopt.flag_vertical = false;
    jopt.limits = 'adaptative';
    jopt.flag_decoration = false;
    pipeline = psom_add_job(pipeline,['motion_native_' labels(ll).name],'niak_brick_vol2img',jin,jout,jopt);
    
    % Native spacer
    jopt.flag_median = true;
    jout = [opt.folder_out 'motion' filesep 'target_native_' labels(ll).name '.png'];
    pipeline = psom_add_job(pipeline,['target_native_' labels(ll).name],'niak_brick_vol2img',jin,jout,jopt);
    
    % Stereotaxic movie
    jopt.flag_median = false;
    jopt.coord = [0 0 0];
    jin.source = list_fmri_stereo{ll};
    jout = [opt.folder_out 'motion' filesep 'motion_stereo_' labels(ll).name '.png'];
    pipeline = psom_add_job(pipeline,['motion_stereo_' labels(ll).name],'niak_brick_vol2img',jin,jout,jopt);
    
    % Stereotaxic spacer
    jopt.flag_median = true;
    jout = [opt.folder_out 'motion' filesep 'target_stereo_' labels(ll).name '.png'];
    pipeline = psom_add_job(pipeline,['target_stereo_' labels(ll).name],'niak_brick_vol2img',jin,jout,jopt);
end    

% Motion parameters
[list_confounds,labels] = niak_fmri2cell(in.ind.confounds);
for ll = 1:length(labels)
    clear jin jout jopt
    jin = list_confounds{ll};
    jout = [opt.folder_out 'motion' filesep 'dataMotion_' labels(ll).name '.js'];
    pipeline = psom_add_job(pipeline,['motion_ind_' labels(ll).name],'niak_brick_preproc_ind_motion2report',jin,jout);
end    

% Pick reference runs
labels_ref = struct;
for ss = 1:length(list_subject)
    session = fieldnames(in.ind.fmri_native.(list_subject{ss}));
    session = session{1};
    run = fieldnames(in.ind.fmri_native.(list_subject{ss}).(session));
    run = run{1};
    labels_ref.(list_subject{ss}) = [list_subject{ss} '_' session '_' run];
end

% Generate the motion report
for ll = 1:length(labels)
    clear jin jout jopt
    jout = [opt.folder_out 'motion' filesep 'motion_report_' labels(ll).name '.html'];
    jopt.label = labels(ll).name;
    jopt.label_ref = labels_ref.(labels(ll).subject);
    jopt.num_run = ll;
    pipeline = psom_add_job(pipeline,['motion_report_' labels(ll).name],'niak_brick_preproc_motion2report','',jout,jopt);
    if ll==1
        jout = [opt.folder_out 'motion' filesep 'motion.html'];
        pipeline = psom_add_job(pipeline,'motion_report','niak_brick_preproc_motion2report','',jout,jopt);
    end
end    

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end