function pipeline = niak_report_brain_maps(in,opt)
% Generate a dashboard with brain maps
%
% SYNTAX: PIPE = NIAK_REPORT_FMRI_PREPROCESS(IN,OPT)
%
% IN.BACKGROUND (string or cell of strings) a brain volume to 
%   use as a background for each brain map.
% IN.OVERLAY (string or cell of string) a series of 3D or 4D brain volume
%
% OPT (structure) with the following fields:
%   FOLDER_OUT (string) the path where to store the results.
%   LABELS (cell of strings, default 'map1', 'map2', etc). 
%     Label number I will be used for IN.MAP{I} in the dashboard. 
%   IND (scalar or vector, default 1) if IN.MAP is a 4D volume, the IND-th
%     volume is extracted. If IND is a vector, IND(I) is used for IN.MAP{I}.
%   CLASS_VIEWER (string, default 'col-sm-6') the bootstrap class for the viewer. 
%   BACKGROUND.COLORMAP (string, default 'gray') The type of 
%     colormap. Anything supported by the instruction `colormap` will work.
%   BACKGROUND.NB_COLOR (default 256) the number of colors to use in 
%     quantization. 
%   BACKGROUND.QUALITY (default 90) for jpg images, set the quality of 
%     the background (from 0, bad, to 100, perfect).
%   BACKGROUND.LIMITS (vector 1x2) the limits for the colormap. By defaut it is using [min,max].
%     If a string is specified, the function will implement an adaptative strategy.
%   OVERLAY.COLORMAP (string, default 'hot_cold') The type of colormap. 
%     Anything supported by the instruction `colormap` will work, as well as 
%     'hot_cold' (see niak_hot_cold). This last color map always centers on zero.
%   OVERLAY.NB_COLOR (default 256) the number of colors to use in 
%     quantization. If Inf is specified, all values are included in the 
%     colormap. This is handy for integer values images (e.g. parcellation).
%   OVERLAY.THRESH (scalar, default []) if empty, does nothing. If a scalar, any value
%     below threshold becomes transparent.
%   OVERLAY.LIMITS (vector 1x2) the limits for the colormap. By defaut it is using [min,max].
%     If a string is specified, the function will implement an adaptative strategy.
%   PSOM (structure) options for PSOM. See PSOM_RUN_PIPELINE.
%   FLAG_VERBOSE (boolean, default true) if true, verbose on progress.
%   FLAG_TEST (boolean, default false) if the flag is true, the pipeline will
%     be generated but no processing will occur.
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

%% PSOM/NIAK variables
psom_gb_vars;
niak_gb_vars;

%% Defaults

% Inputs
in = psom_struct_defaults( in , ...
    { 'background' , 'overlay' }, ...
    { NaN          , NaN       });
if ischar(in.overlay)
    in.overlay = {in.overlay};
end

flag_template = ischar(in.background);
if flag_template
    in.background = {in.background};
end

%% Options
if nargin < 2
    opt = struct;
end
opt = psom_struct_defaults ( opt , ...
    { 'folder_out' , 'labels' , 'ind' , 'class_viewer' , 'background' , 'overlay' , 'flag_test' , 'psom'   , 'flag_verbose' }, ...
    { NaN          , {}       , [1]   , 'col-sm-6'     , struct       , struct    , false       , struct() , true           });

opt.background = psom_struct_defaults( opt.background , ...
    { 'colormap' , 'nb_color' , 'quality' , 'limits'     }, ...
    { 'gray'     , 256        , 90        , 'adaptative' });
    
if isempty(opt.labels)
    for oo = 1:length(in.overlay)
        opt.labels{oo} = sprintf('map%i',oo);
    end
end
if length(ind)==1
    ind = repmat(ind,[length(in.overlay) 1]);
end

opt.folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [opt.folder_out 'logs' filesep];

%% Copy the report templates
pipeline = struct;
clear jin jout jopt
niak_gb_vars
path_template = [GB_NIAK.path_niak 'reports' filesep 'brain_map' filesep 'templates' filesep ];
jin = niak_grab_folder( path_template , {'.git','index.html','viewer.html'});
jout = strrep(jin,path_template,opt.folder_out);
jopt.folder_out = opt.folder_out;
pipeline = psom_add_job(pipeline,'cp_report_templates','niak_brick_copy',jin,jout,jopt);

% background images
for bb = 1:length(in.background)
    jname = ['background_' opt.labels{bb}];
    jin.source = in.background{bb};
    jin.target = in.background{bb};
    jout.montage = [opt.folder_out 'img' filesep jname '.jpg'];
    jout.quantization = [opt.folder_out 'img' filesep jname '.mat'];
    jopt.colormap = opt.colormap;
    jopt.colorbar = false;
    jopt.limits = opt.limits;
    jopt.flag_decoration = false;
    pipeline = psom_add_job(pipeline,jname,'niak_brick_montage',jin,jout,jopt);
end

% Group average T1
jin.source = in.group.avg_t1;
jout = [opt.folder_out 'group' filesep 'average_t1_stereotaxic.png'];
jopt.colormap = 'gray';
jopt.limits = 'adaptative';
jopt.flag_decoration = false;
pipeline = psom_add_job(pipeline,'average_t1_stereo','niak_brick_vol2img',jin,jout,jopt);

% Group outline
jin.source = file_outline;
jout = [opt.folder_out 'group' filesep 'outline.png'];
jopt.colormap = 'jet';
jopt.limits = [0 1.1];
jopt.flag_decoration = false;
pipeline = psom_add_job(pipeline,'t1_outline_registration','niak_brick_vol2img',jin,jout,jopt);

% Group average BOLD
jin.source = in.group.avg_func;
jout = [opt.folder_out 'group' filesep 'average_func_stereotaxic.png'];
jopt.colormap = 'jet';
jopt.limits = 'adaptative';
jopt.flag_decoration = false;
pipeline = psom_add_job(pipeline,'average_func_stereo','niak_brick_vol2img',jin,jout,jopt);

% Group BOLD mask
jin.source = in.group.mask_func_group;
jout = [opt.folder_out 'group' filesep 'mask_func_group_stereotaxic.png'];
jopt.colormap = 'jet';
jopt.limits = [0 1];
jopt.flag_decoration = false;
pipeline = psom_add_job(pipeline,'mask_func_group_stereo','niak_brick_vol2img',jin,jout,jopt);

% Average BOLD mask
jin.source = in.group.avg_mask_func;
jout = [opt.folder_out 'group' filesep 'average_mask_func_stereotaxic.png'];
jopt.colormap = 'jet';
jopt.limits = [0 1];
jopt.flag_decoration = false;
pipeline = psom_add_job(pipeline,'avg_mask_func_stereo','niak_brick_vol2img',jin,jout,jopt);

%% Panel on individual registration

% Individual T1 images
jopt.colormap = 'gray';
jopt.limits = 'adaptative';
jopt.method = 'linear';
for ss = 1:length(list_subject)
    jin.source = in.ind.anat.(list_subject{ss});
    jout = [opt.folder_out 'registration' filesep list_subject{ss} '_anat_raw.png'];
    jopt.flag_decoration = false;
    pipeline = psom_add_job(pipeline,['t1_' list_subject{ss}],'niak_brick_vol2img',jin,jout,jopt);
end

% Individual BOLD images
jopt.colormap = 'jet';
jopt.limits = 'adaptative';
jopt.method = 'linear';
for ss = 1:length(list_subject)
    jin.source = in.ind.func.(list_subject{ss});
    jout = [opt.folder_out 'registration' filesep list_subject{ss} '_func.png'];
    jopt.flag_decoration = false;
    pipeline = psom_add_job(pipeline,['bold_' list_subject{ss}],'niak_brick_vol2img',jin,jout,jopt);
end

% Merge individual T1 and outline
for ss = 1:length(list_subject)
    clear jin jout jopt
    jin.background = pipeline.(['t1_' list_subject{ss}]).files_out;
    jin.overlay = pipeline.t1_outline_registration.files_out;
    jout = [opt.folder_out 'registration' filesep list_subject{ss} '_anat.png'];
    jopt.transparency = 0.7;
    jopt.threshold = 0.9;
    pipeline = psom_add_job(pipeline,['t1_' list_subject{ss} '_overlay'],'niak_brick_add_overlay',jin,jout,jopt);
end

% Merge average T1 and outline
clear jin jout jopt
jin.background = pipeline.template_stereo.files_out;
jin.overlay = pipeline.t1_outline_registration.files_out;
jout = [opt.folder_out 'group' filesep 'template_stereotaxic.png'];
jopt.transparency = 0.7;
jopt.threshold = 0.9;
pipeline = psom_add_job(pipeline,'template_stereo_overlay','niak_brick_add_overlay',jin,jout,jopt);

% Add a spreadsheet to write the QC.
clear jin jout jopt
jout = [opt.folder_out 'qc_registration.csv'];
jopt.list_subject = list_subject;
pipeline = psom_add_job(pipeline,'init_report','niak_brick_init_qc_report','',jout,jopt);

%% Panel on motion

% Movies (and target image for all runs)
[list_fmri_native,labels] = niak_fmri2cell(in.ind.fmri_native);
[list_fmri_stereo,labels] = niak_fmri2cell(in.ind.fmri_stereo);
for ll = 1:length(labels)
    clear jin jout jopt

    % Native movie
    jin.source = list_fmri_native{ll};
    jin.target = list_fmri_native{ll};
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
    jin.target = list_fmri_stereo{ll};
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
