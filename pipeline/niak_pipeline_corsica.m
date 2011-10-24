function [pipeline,opt,files_out] = niak_pipeline_corsica(files_in,opt)
% Pipeline to run CORSICA (correction of the physiological noise) on fMRI
%
% PIPELINE = NIAK_PIPELINE_CORSICA(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields :
%
%   <SUBJECT>.FMRI
%       (cell of strings) a list of fMRI datasets. The field name
%       <SUBJECT> can be any arbitrary string. All data in
%       FILES_IN.<SUBJECT> should come from the same subject.
%
%   <SUBJECT>.MASK_SELECTION
%       (cell of string) each entry is the name of a file with a binary
%       mask coding for one spatial a priori which will be used in the
%       selection.
%
%   <SUBJECT>.TRANSFORMATION
%       (string, default identity) a transformation from the functional
%       space to the "MNI152 non-linear" space.
%
%   <SUBJECT>.MASK_BRAIN
%       (string, default 'gb_niak_omitted') a file name of a binary mask of
%       the brain. If unspecified, NIAK_BRICK_MASK_BRAIN will be used to
%       generate a mask of the brain.
%
%   <SUBJECT>.COMPONENT_TO_KEEP
%       (string, default none) a text file, whose first line is a set of
%       string labels, and each column is otherwise a temporal component of
%       interest. The ICA component with highest correlation with each
%       signal of interest will be automatically attributed a selection
%       score of 0 (i.e. it will not be selected as physiological noise).
%
% OPT
%   (structure) with the following fields :
%
%   THRESHOLD
%       (scalar, default 0.15) a threshold to apply on the score for
%       suppression (scores above the thresholds are selected). This option
%       will be used both for QC_CORSICA and COMPONENT_SUPP.
%
%   PSOM
%       (structure) the options of the pipeline manager. See the OPT
%       argument of PSOM_RUN_PIPELINE. Default values can be used here.
%       Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
%   FLAG_TEST
%       (boolean, default false) If FLAG_TEST is true, the pipeline
%       will just produce a pipeline structure, and will not actually
%       process the data. Otherwise, PSOM_RUN_PIPELINE will be used to
%       process the data.
%
%   FLAG_SKIP
%       (boolean, default false) if FLAG_SKIP is true, the brick does not
%       do anything, just copying the inputs to the outputs (the ICA
%       decomposition will still be generated and the component selection
%       will still be generated for quality control purposes).
%
%   LABELS_MASK
%       (cell of string, default {'mask1','mask2',...}) labels that will be
%       used in the name of the outputs in the selection of noise
%       components with each entry of FILES_IN.MASK_SELECTION.
%
%   SIZE_OUTPUT
%       (string, default 'quality_control') possible values :
%       ‘minimum’, 'quality_control’, ‘all’.
%       The quantity of intermediate results that are generated.
%           * With the option ‘minimum’, only the physiological-noise
%           corrected data is written.
%           * With the option ‘quality_control’, in addition to the outputs
%           of the 'minimum' option, a pdf document recapitulating
%           the ICA components and the score of components in the stepwise
%           regression are generated.
%           * With the option ‘all’, in addition to the outputs of the
%           'minimum' option, the space and time distributions of the ICA
%           are generated.
%
%   FOLDER_OUT
%       (string) folder to write the "denoised" datasets resulting of the
%       pipeline.
%
%   FOLDER_SICA
%       (string, default OPT.FOLDER_OUT) folder to write the results of
%       SICA (the space and time components, the figures as well as the
%       results of the component selection).
%
%   MASK_BRAIN
%       (structure) options of NIAK_BRICK_MASK_BRAIN
%
%   SICA
%       (structure) options of NIAK_BRICK_SICA
%
%       NB_COMP
%           (integer) the number of components (default 60).
%
%   COMPONENT_SEL
%       (structure) options of NIAK_BRICK_COMPONENT_SEL.
%
%   QC_CORSICA
%       (structure) options of NIAK_BRICK_QC_CORSICA.
%
%   COMPONENT_SUPP
%       (structure) options of NIAK_BRICK_COMPONENT_SUPP.
%
% _________________________________________________________________________
% OUTPUTS:
%
% PIPELINE
%   (structure) describe all the jobs that need to be performed in the
%   pipeline.
%
% OPT
%   (structure) same as input, but updated for default values.
%
% FILES_OUT
%   (structure) with the following field :
%
%       SUPPRESS_VOL.<SUBJECT>
%           (cell of strings) the outputs of NIAK_BRICK_SUPPRESS_VOL.
%
%       QC_CORSICA.<SUBJECT>
%           (cell of strings) the outputs of NIAK_BRICK_QC_CORSICA.
%
% _________________________________________________________________________
% COMMENTS:
%
% The steps of the pipeline are the following :
%
%   1.  Individual spatial independent component of each functional run.
%
%   2. Selection of independent component related to physiological noise,
%   using spatial priors (masks of the ventricle and a part of the brain
%   stem).
%
%   3. Generation of a "physiological noise corrected" fMRI dataset for
%   each run, where the effect of the selected independent components has
%   been removed.
%
% The PSOM pipeline manager is used to process the pipeline if
% OPT.FLAG_TEST is false. PSOM has a number of interesting features to deal
% with job failures or pipeline updates. You can read the following
% tutorial for a review of its capabilities :
% http://code.google.com/p/psom/wiki/HowToUsePsom
% http://code.google.com/p/psom/wiki/ConfigurationPsom
%
% _________________________________________________________________________
% REFERENCES:
%
% Perlbarg, V., Bellec, P., Anton, J.-L., Pelegrini-Issac, P., Doyon, J. and
% Benali, H.; CORSICA: correction of structured noise in fMRI by automatic
% identification of ICA components. Magnetic Resonance Imaging, Vol. 25,
% No. 1. (January 2007), pp. 35-46.
%
% MJ Mckeown, S Makeig, GG Brown, TP Jung, SS Kindermann, AJ Bell, TJ
% Sejnowski; Analysis of fMRI data by blind separation into independent
% spatial components. Hum Brain Mapp, Vol. 6, No. 3. (1998), pp. 160-188.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : CORSICA, fMRI, physiological noise, ICA

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

%% import NIAK global variables

niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Input files
if ~exist('files_in','var')||~exist('opt','var')
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_CORSICA(FILES_IN,OPT).\n Type ''help niak_pipeline_corsica'' for more info.')
end

%% Checking that FILES_IN is in the correct format
if ~isstruct(files_in)
    error('FILE_IN should be a struture!')
end

list_subject = fieldnames(files_in);
nb_subject = length(list_subject);

for num_s = 1:nb_subject
    subject = list_subject{num_s};
    
    if ~isstruct(files_in.(subject))
        error('FILE_IN.%s should be a structure!',upper(subject));
    end
        
    gb_name_structure = ['files_in.' subject];
    gb_list_fields    = {'fmri'            , 'mask_selection' , 'mask_brain'      , 'transformation'  , 'component_to_keep' };
    gb_list_defaults  = {NaN               , NaN              , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted'    };
    niak_set_defaults

    if ~iscellstr(files_in.(subject).fmri)
        error(sprintf('FILE_IN.%s.fmri is not a cell of strings!',upper(subject)));
    end
        
    if ~ischar(files_in.(subject).transformation)
        error(sprintf('FILE_IN.%s.TRANSFORMATION is not a string!',upper(subject)));
    end
        
end

%% Options
default_psom.path_logs = '';
opt_tmp.flag_test = 1;
gb_name_structure = 'opt';
gb_list_fields    = { 'threshold' , 'labels_mask' , 'flag_skip' , 'size_output'     , 'psom'       , 'flag_test' , 'folder_out' , 'folder_sica' , 'mask_brain' , 'sica'  , 'component_sel' , 'qc_corsica' , 'component_supp' };
gb_list_defaults  = { 0.15        , {}            , false       , 'quality_control' , default_psom , false       , NaN          , ''            , opt_tmp      , opt_tmp , opt_tmp         , opt_tmp      , opt_tmp          };
niak_set_defaults

if isempty(opt.folder_sica)
    opt.folder_sica = opt.folder_out;
end

if isempty(labels_mask)
    labels_mask = cell([length(files_in.mask_selection) 1]);
    for num_m = 1:length(files_in.mask_selection)
        labels_mask{num_m} = ['mask' num2str(num_m)];
    end
end

opt.psom.path_logs = [opt.folder_sica 'logs' filesep];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = struct([]);

for num_s = 1:nb_subject
    subject = list_subject{num_s};
    if num_s == 1
        [path_f,name_f,ext_f] = niak_fileparts(files_in.(subject).fmri{1});
    end
    files_out.suppress_vol.(subject) = cell([length(files_in.(subject).fmri) 1]);
    files_out.qc_corsica.(subject) = cell([length(files_in.(subject).fmri) 1]);
    
    for num_r = 1:length(files_in.(subject).fmri)        
        run = cat(2,'run',num2str(num_r));
        
        %%%%%%%%%%%%%%%%
        %% Brain Mask %%
        %%%%%%%%%%%%%%%%
        if strcmp(files_in.(subject).mask_brain,'gb_niak_omitted')
            clear files_in_tmp files_out_tmp opt_tmp
            name_job_mask  = ['corsica_mask_brain_' subject '_' run];
            files_in_tmp   = files_in.(subject).fmri{num_r};
            files_out_tmp  = [opt.folder_sica 'mask_brain_' subject '_' run ext_f];
            opt_tmp        = opt.mask_brain;
            pipeline = psom_add_job(pipeline,name_job_mask,'niak_brick_mask_brain',files_in_tmp,files_out_tmp,opt_tmp);
            files_in.(subject).mask_brain = pipeline.(name_job_mask).files_out;
        end
        
        %%%%%%%%%%
        %% SICA %%
        %%%%%%%%%%
        clear files_in_tmp files_out_tmp opt_tmp
        name_job_sica        = cat(2,'sica_',subject,'_',run);
        files_in_tmp.fmri    = files_in.(subject).fmri{num_r};
        files_in_tmp.mask    = files_in.(subject).mask_brain;
        files_out_tmp.space  = '';
        files_out_tmp.time   = '';        
        opt_tmp              = opt.sica;
        opt_tmp.folder_out   = opt.folder_sica;
        pipeline = psom_add_job(pipeline,name_job_sica,'niak_brick_sica',files_in_tmp,files_out_tmp,opt_tmp);
                
        %%%%%%%%%%%%%%%%%%%%%%%%%
        %% COMPONENT SELECTION %%
        %%%%%%%%%%%%%%%%%%%%%%%%%
        name_job_sel = cell([length(files_in.(subject).mask_selection) 1]);
        files_sel = cell([length(files_in.(subject).mask_selection) 1]);
        for num_m = 1:length(files_in.(subject).mask_selection)
            name_job_sel{num_m} = ['component_sel_' labels_mask{num_m} '_',subject,'_' run];
            [path_f,name_f] = niak_fileparts(files_in.(subject).fmri{num_r});
            clear files_in_tmp files_out_tmp opt_tmp
            files_in_tmp.fmri              = files_in.(subject).fmri{num_r};            
            files_in_tmp.component         = pipeline.(name_job_sica).files_out.time;
            files_in_tmp.mask              = files_in.(subject).mask_selection{num_m};
            files_in_tmp.transformation    = files_in.(subject).transformation;
            files_in_tmp.component_to_keep = files_in.(subject).component_to_keep;
            files_out_tmp                  = [opt.folder_sica filesep name_f '_compsel_' labels_mask{num_m} '.mat'];
            opt_tmp                        = opt.component_sel;
            pipeline = psom_add_job(pipeline,name_job_sel{num_m},'niak_brick_component_sel',files_in_tmp,files_out_tmp,opt_tmp);
            files_sel{num_m} = pipeline.(name_job_sel{num_m}).files_out;
        end
        
        %%%%%%%%
        %% QC %%
        %%%%%%%%
        clear files_in_tmp files_out_tmp opt_tmp
        name_job_qc          = cat(2,'qc_corsica_',subject,'_',run);
        files_in_tmp.space   = pipeline.(name_job_sica).files_out.space;
        files_in_tmp.time    = pipeline.(name_job_sica).files_out.time;
        files_in_tmp.score   = files_sel;        
        files_in_tmp.mask    = files_in.(subject).mask_brain;
        files_out_tmp        = '';        
        opt_tmp              = opt.qc_corsica;
        opt_tmp.threshold    = opt.threshold;
        opt_tmp.folder_out   = opt.folder_sica;
        pipeline = psom_add_job(pipeline,name_job_qc,'niak_brick_qc_corsica',files_in_tmp,files_out_tmp,opt_tmp);
        files_out.qc_corsica.(subject){num_r} = pipeline.(name_job_qc).files_out;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% COMPONENT SUPPRESSION %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        if ~flag_skip
            clear files_in_tmp files_out_tmp opt_tmp
            name_job_supp            = ['component_supp_',subject,'_',run];
            files_in_tmp.fmri        = files_in.(subject).fmri{num_r};
            files_in_tmp.space       = pipeline.(name_job_sica).files_out.space;
            files_in_tmp.time        = pipeline.(name_job_sica).files_out.time;
            files_in_tmp.mask_brain  = files_in.(subject).mask_brain;
            files_in_tmp.compsel     = files_sel;            
            files_out_tmp            = '';
            opt_tmp                  = opt.component_supp;
            opt_tmp.threshold        = opt.threshold;
            opt_tmp.folder_out       = cat(2,opt.folder_out,filesep);
            pipeline = psom_add_job(pipeline,name_job_supp,'niak_brick_component_supp',files_in_tmp,files_out_tmp,opt_tmp);
            files_out.suppress_vol.(subject){num_r} = pipeline.(name_job_supp).files_out;
        else
            clear files_in_tmp files_out_tmp opt_tmp
            [path_f,name_f,ext_f] = niak_fileparts(files_in.(subject).fmri{num_r});
            name_job_supp              = ['component_supp_',subject,'_',run];
            files_in_tmp{1}            = files_in.(subject).fmri{num_r};
            files_out_tmp{1}           = [opt.folder_out name_f '_p' ext_f];
            opt_tmp.flag_verbose       = true;            
            pipeline = psom_add_job(pipeline,name_job_supp,'niak_brick_copy',files_in_tmp,files_out_tmp,opt_tmp);
            files_out.suppress_vol.(subject){num_r} = pipeline.(name_job_supp).files_out{1};            
        end
        
        
        %%%%%%%%%%%%%%
        %% CLEANING %%
        %%%%%%%%%%%%%%
        if strcmp(opt.size_output,'minimum')||strcmp(opt.size_output,'quality_control')            
            clear files_clean_tmp files_out_tmp opt_tmp
            name_job_clean       = ['clean_corsica_intermediate_',subject,'_',run];
            switch opt.size_output
                case 'minimum'
                    files_clean_tmp.space      = pipeline.(name_job_sica).files_out.space;
                    files_clean_tmp.time       = pipeline.(name_job_sica).files_out.time;
                    files_clean_tmp.figure     = pipeline.(name_job_sica).files_out.figure;
                    files_clean_tmp.compsel    = files_sel;
                    files_clean_tmp.mask       = files_in.(subject).mask_brain;
                case 'quality_control'
                    files_clean_tmp.space      = pipeline.(name_job_sica).files_out.space;
                    files_clean_tmp.time       = pipeline.(name_job_sica).files_out.time;
                    files_clean_tmp.compsel    = files_sel;
            end
            pipeline = psom_add_clean(pipeline,name_job_clean,files_clean_tmp);
        end % size_output
        
    end % run
end % subject


%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end