function pipe = niak_report_fmri_preprocess(in,opt)
% Generate a report for the fMRI preprocessing pipeline
%
% SYNTAX: PIPE = NIAK_REPORT_FMRI_PREPROCESS(IN,OPT)
%
% IN.PIPE (string) the name of a .mat file with two variables FILES_IN (the 
%   input files) and OPT (the options), describing the parameters of the 
%   pipeline. 
% IN.GROUP.AVG_T1 (string) the file name of the average T1 of all subjects, 
%   after non-linear coregistration in stereotaxic space. 
% IN.GROUP.AVG_FUNC (string) the file name of the average BOLD volume of all subjects, 
%   after non-linear coregistration in stereotaxic space. 
% IN.GROUP.AVG_MASK_FUNC (string) the file name of the average indivudal BOLD mask,
%   after non-linear coregistration in stereotaxic space. 
% IN.GROUP.MASK_FUNC_GROUP (string) the file name of the group mask for BOLD data, 
%   in non-linear stereotaxic space. 
% IN.GROUP.SUMMARY_SCRUBBING (string) the file name of a .csv file with a summary of 
%   scrubbing of fMRI time series. 
% IN.GROUP.SUMMARY_REGISTRATION (string) the file name of a .csv file with a summary of
%   T1 and BOLD registration. 
% IN.IND.FMRI_NATIVE.(SUBJECT).(SESSION).(RUN) (string) file name of an fMRI dataset
%   in native space (before resampling for motion). 
% IN.IND.FMRI_STEREO.(SUBJECT).(SESSION).(RUN) (string) file name of an fMRI dataset
%   after spatial resampling to correct for motion. 
% IN.IND.CONFOUNDS.(SUBJECT).(SESSION).(RUN) (string) file name of a a .tsv file_in_loadpath
%   with confound variables (motion parameters, FD and scrubbing mask).  
% IN.IND.ANAT.(SUBJECT) (string) the file name of an individual T1 volume (in stereotaxic space).
% IN.IND.FUNC.(SUBJECT) (string) the file name of an individual functional volume (in stereotaxic space)
% IN.TEMPLATE (string) the file name of the template used for registration in stereotaxic space.
% OPT.FOLDER_OUT (string) where to generate the outputs. 
% OPT.COORD (array N x 3) Coordinates for the registration figures. 
%   The default is:
%   [-30 , -65 , -15 ; 
%     -8 , -25 ,  10 ;  
%     30 ,  45 ,  60];    
% OPT.PSOM (structure) options for PSOM. See PSOM_RUN_PIPELINE.
% OPT.FLAG_VERBOSE (boolean, default true) if true, verbose on progress. 
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the pipeline will 
%   be generated but no processing will occur.
%
% Note:
%   Labels SUBJECT, SESSION and RUN are arbitrary but need to conform to matlab's 
%   specifications for field names. 
%
%   This pipeline needs the PSOM library to run. 
%   http://psom.simexp-lab.org/
% 
% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2016.
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
    { 'group' , 'ind' }, ...
    { NaN     , NaN   });

in.group = psom_struct_defaults( in.group , ...
    { 'avg_t1' , 'avg_func' , 'avg_mask_func' , 'mask_func_group' , 'summary_registration' , 'summary_scrubbing' }, ...
    { NaN      , NaN        , NaN             , NaN               , NaN                    , NaN                 });

in.ind = psom_struct_defaults( in.ind , ...
    { 'fmri_native' , 'fmri_stereo' , 'confounds' , 'anat' , 'func' }, ...
    { NaN           , NaN           , NaN         , NaN    , NaN    });

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
niak_gb_vars
templates.motion_html  = [gb_niak_path_niak 'reports' filesep 'fmri_preprocess' filesep 'templates' filesep 'motion.html'];
templates.motion_css   = [gb_niak_path_niak 'reports' filesep 'fmri_preprocess' filesep 'templates' filesep 'motion.css'];
templates.index        = [gb_niak_path_niak 'reports' filesep 'fmri_preprocess' filesep 'templates' filesep 'index.html'];
templates.registration = [gb_niak_path_niak 'reports' filesep 'fmri_preprocess' filesep 'templates' filesep 'registration.html'];
templates.group        = [gb_niak_path_niak 'reports' filesep 'fmri_preprocess' filesep 'templates' filesep 'group.html'];

%% Copy and update the templates
pipeline = struct;
clear in out jopt
in = templates;
out = struct;
list_fields = fieldnames(in);
for ee = 1:length(list_fields)
    [~,name_f,ext_f] = fileparts(in.(list_fields{ee}));
    out.(list_fields{ee}) = [opt.folder_out name_f ext_f];
end
jopt.folder_out = opt.folder_out;
pipeline = psom_add_job(pipeline,'report_fp_cp_templates',in,out,jopt);

if ~opt.flag_test
    psom_run_pipeline(pipe,opt.psom);
end

return

%% Add the generation of summary images for all subjects
for ss = 1:length(list_subject)
    clear inj outj optj
    subject = list_subject{ss};
    if opt.flag_verbose
        fprintf('Adding job: QC report for subject %s\n',subject);
    end
    inj.anat = in.anat.(subject);
    inj.func = in.func.(subject);
    inj.template = in.template;
    outj.anat = [opt.folder_out 'summary_' subject '_anat.jpg'];
    outj.func = [opt.folder_out 'summary_' subject '_func.jpg'];
    outj.template = 'gb_niak_omitted';
    outj.report =  [opt.folder_out 'report_coregister_' subject '.html'];
    optj.coord = opt.coord;
    optj.id = subject;
    optj.template = pipe.summary_template.files_out.template;
    pipe = psom_add_job(pipe,['report_' subject],'niak_brick_qc_fmri_preprocess',inj,outj,optj);
end

%% Add a spreadsheet to write the QC. 
clear inj outj optj
outj = [opt.folder_out 'qc_report.csv'];
optj.list_subject = list_subject;
pipe = psom_add_job(pipe,'init_report','niak_brick_init_qc_report','',outj,optj);


