function pipeline = niak_pipeline_fmristat_ind(files_in,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_PIPELINE_FMRI_PREPROCESS
%
% Run a pipeline to preprocess an fMRI database. Mutliple preprocessing 
% "styles" are available, depending on the analysis planned afterwards, and 
% the amount of generated outputs can be adjusted. Steps of the analysis 
% can be further customized by changing virtually any parameter of the 
% bricks used in the pipeline.
%
% SYNTAX:
% PIPELINE = NIAK_PIPELINE_FMRI_PREPROCESS(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN  
%       (structure) with the following fields : 
%
%       <SUBJECT>.FMRI.<SESSION>   
%           (cell of strings) a list of fMRI datasets, acquired in the same 
%           session (small displacements). 
%           The field names <SUBJECT> and <SESSION> can be any arbitrary 
%           strings.
%           All data in FILES_IN.<SUBJECT> should be from the same subject.
%           See NIAK_READ_VOL for supported data formats.
%
%       <SUBJECT>.ANAT 
%           (string) anatomical volume, from the same subject as in 
%           FILES_IN.<SUBJECT>.FMRI
%
%       <SUBJECT>.COMPONENT_TO_KEEP
%           (string, default none) a text file, whose first line is a
%           a set of string labels, and each column is otherwise a temporal
%           component of interest. The ICA component with higher
%           correlation with each signal of interest will be automatically
%           attributed a selection score of 0.
%
%  * OPT   
%       (structure) with the following fields : 
%
%       STYLE 
%           (string) possible values : ‘fmristat’, ‘standard-native’,
%           ‘standard-stereotaxic’.
%           Select the "style" of preprocessing, i.e. the exact series of 
%           processing steps that will be applied to the data. See the
%           NOTES at the end of this documentation.
%
%       SIZE_OUTPUT 
%           (string, default 'quality_control') possible values : 
%           ‘minimum’, 'quality_control’, ‘all’.
%           The quantity of intermediate results that are generated. For a 
%           detailed list of outputs in each mode, see the internet
%           documentation (http://wiki.bic.mni.mcgill.ca/index.php/NiakFmriPreprocessing)
%           * With the option ‘minimum’, only the preprocessed 
%              data at the final stage are generated. All intermediate 
%              outputs are cleaned as soon as possible. 
%           * With the option ‘quality_control’ some outputs are generated 
%              at each step of the analysis for purposes of quality control. 
%           * With the option ‘all’, all possible outputs are generated at 
%              each stage of the pipeline. 
%
%       FLAG_CORSICA
%           (boolean, default 1) if FLAG_CORSICA == 1, the CORSICA method
%           will be applied to correct for physiological & motion noise.
%           That means that a spatial independent component analysis will
%           be applied on each functional run, and the physiological noise
%           components will be identified using spatial priors and
%           suppressed of the linear mixture.
%       
%       TEMPLATE_FMRI
%           (string, default '<~niak>/template/roi_aal.mnc') a volume that
%           will be used to resample the fMRI datasets. By default it uses
%           a 2 mm isotropic space with a field of view adjusted on the
%           brain.
%
%       FOLDER_OUT 
%           (string) where to write the results of the pipeline. For the 
%           actual content of folder_out, see the internet 
%           documentation (http://wiki.bic.mni.mcgill.ca/index.php/NiakFmriPreprocessing)
%
%       FLAG_TEST
%           (boolean, default false) If FLAG_TEST is true, the pipeline
%           will just produce a pipeline structure, and will not actually
%           process the data. Otherwise, PSOM_RUN_PIPELINE will be used to
%           process the data.
%
%       PSOM
%           (structure) the options of the pipeline manager. See the OPT
%           argument of PSOM_RUN_PIPELINE. Default values can be used here.
%           Note that the field PSOM.PATH_LOGS will be set up by the
%           pipeline.
%
%       BRICKS 
%           (structure) The fields of OPT.BRICKS depend on the style of 
%           pre-processing. 
%           Note that the options will be common to all runs, all sessions 
%           and all subjects. Subjects with different options need to be 
%           processed in different pipelines. 
%
%           The following fields are common to all styles. Each field
%           correspond to one brick, which is indicated. Please refer to the
%           help of the brick for detail. Unless specified, the fields can be
%           simply omitted, in which case the default options are used.
%       
%           MOTION_CORRECTION 
%               (structure) options of NIAK_BRICK_MOTION_CORRECTION 
%       
%           CIVET 
%               (structure) Options of NIAK_BRICK_CIVET, the brick of 
%               spatial normalization (non-linear transformation of T1 image 
%               in the stereotaxic space). If OPT.CIVET.CIVET is used to 
%               specify the use of previously generated data, there is no need 
%               to fill the subfields OPT.CIVET.CIVET.ID. The subject ids will 
%               be assumed to match the field names <SUBJECT> in FILES_IN. 
%               It would still necessay to specify OPT.CIVET.CIVET.PREFIX and 
%               OPT.CIVET.CIVET.FOLDER though. 
%
%           COREGISTER 
%               (structure) options of NIAK_BRICK_COREGISTER 
%               (coregistration between T1 and T2).
%
%           MASK_BRAIN
%               (structure) options of NIAK_BRICK_MASK_BRAIN (Individual
%               brain mask in fMRI data, and generation of mean/std volumes
%               of fMRI time series).
%
%           SMOOTH_VOL 
%               (structure) options of NIAK_BRICK_SMOOTH_VOL (spatial
%               smoothing).
%
%           The three following fields are necessary if OPT.FLAG_CORSICA is 
%           set to 1 (which means that an attempt will be made to correct 
%           for physiological noise using the CORSICA method) :
%               
%           SICA
%               (structure) options of NIAK_BRICK_SICA (spatial independent
%               component analysis).
%
%               NB_COMP
%                   (integer, default min(60,foor(0.95*T)))
%                   number of components to compute (for default : T is the 
%                   number of time samples.
%
%           COMPONENT_SEL 
%               (structure) options of NIAK_BRICK_COMPONENT_SEL
%               (selection of ICA components based on spatial priors).
%
%           COMPONENT_SUPP
%               (structure) options of NIAK_BRICK_COMPONENT_SUPP
%               (reconstruction of 4D data after suppression of some ICA 
%               components from the linear mixture).
%
%               THRESHOLD 
%                   (scalar, default 0.15) a threshold to apply on the 
%                   score for suppression (scores above the thresholds are 
%                   selected). If the threshold is -Inf, all components 
%                   will be suppressed. If the threshold is Inf, no
%                   component will be suppressed (the algorithm is 
%                   basically copying the file, except that the data is 
%                   masked inside the brain).
%
%           The Following additional fields can be used if the
%           preprocessing style is 'standard-native' or 'standard-stereotaxic':
%
%           SLICE_TIMING 
%               (structure) options of NIAK_BRICK_SLICE_TIMING
%               (correction of slice timing effects). The following fields
%               need to be specified :
%
%               SLICE_ORDER 
%                   (vector of integer) SLICE_ORDER(i) = k means that the 
%                   kth slice was acquired in ith position. The order of 
%                   the slices is assumed to be the same in all volumes.
%                   ex : slice_order = [1 3 5 2 4 6] for 6 slices acquired 
%                   in 'interleaved' mode, starting by odd slices (slice 5 
%                   was acquired in 3rd position).
% 
%               TIMING		
%                   (vector 2*1) 
%                   TIMING(1) : time between two slices
%                   TIMING(2) : time between last slice and next volume
%
%           TIME_FILTER 
%               (structure) options of NIAK_BRICK_TIME_FILTER (temporal 
%               filtering).
%
%           The Following additional field can be used if the 
%           preprocessing style is 'standard-stereotaxic':
%
%           RESAMPLE_VOL 
%               (structure) options of NIAK_BRICK_RESAMPLE_VOL
%               (spatial resampling in the stereotaxic space).
%
% _________________________________________________________________________
% OUTPUTS : 
%
%  * PIPELINE 
%       (structure) describe all jobs that need to be performed in the
%       pipeline.
%
% _________________________________________________________________________
% COMMENTS
%
% NOTE 1:
% The steps of the pipeline are the following :
%  
%  * style 'fmristat' :
%       1.  Linear and non-linear spatial normalization of the anatomical 
%           image (and many more anatomical stuff such as brain masking and
%           CSF/GM/WM classification)
%       2.  Motion correction (within- and between-run for each subject).
%       3.  Coregistration of the anatomical volume with the mean 
%           functional volume.
%       4.  Concatenation of the T2-to-T1 and T1-to-stereotaxic-nl
%           transformations.
%       5.  Correction of physiological noise (if OPT.FLAG_CORSICA == 1)
%       6.  Spatial smoothing.
%
%  * style 'standard-native'
%       1.  Linear and non-linear spatial normalization of the anatomical 
%           image (and many more anatomical stuff such as brain masking and
%           CSF/GM/WM classification)
%       2.  Slice timing correction
%       3.  Motion correction (within- and between-run for each subject).
%       4.  Coregistration of the anatomical volume with the mean 
%           functional volume.
%       5.  Concatenation of the T2-to-T1 and T1-to-stereotaxic-nl
%           transformations.
%       6.  Correction of slow time drifts.
%       7.  Correction of physiological noise (if OPT.FLAG_CORSICA == 1)
%       8.  Spatial smoothing.
%   
%  * style 'standard-stereotaxic'
%       1.  Linear and non-linear spatial normalization of the anatomical 
%           image (and many more anatomical stuff such as brain masking and
%           CSF/GM/WM classification)
%       2.  Slice timing correction
%       2.  Motion correction (within- and between-run for each subject).
%       3.  Coregistration of the anatomical volume with the mean 
%           functional volume.
%       4.  Concatenation of the T2-to-T1 and T1-to-stereotaxic-nl
%           transformations.
%       5.  Correction of slow time drifts.
%       6.  Correction of physiological noise (if OPT.FLAG_CORSICA == 1)
%       7.  Resampling of the functional data in the stereotaxic space.
%       8.  Spatial smoothing.
%
% NOTE 2:
% The physiological & motion noise correction CORSICA is changing the
% degrees of freedom of the data. It is usullay negligible for intra-subject
% analysis, and will have no impact on the between-subject variance
% estimate (except those should be less noisy). However, the purist may
% consider to take that into account in the linear model analysis. This
% will be taken care of in the (yet to come) NIAK_PIPELINE_FMRISTAT
%
% The exact list of outputs generated by the pipeline depend on the
% pipeline style and the OPT.SIZE_OUTPUTS field. See the internet
% documentation at http://wiki.bic.mni.mcgill.ca/index.php/NiakFmriPreprocessing 
% for details.
%
% NOTE 3:
% The PSOM pipeline manager is used to process the pipeline if
% OPT.FLAG_TEST is false. PSOM has a number of interesting features to deal
% with job failures or pipeline updates. You can read the following
% tutorial for a review of its capabilities : 
% http://code.google.com/p/psom/wiki/HowToUsePsom
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline, niak, preprocessing, fMRI, psom, preprocessing

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
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_FMRISTAT_IND(FILES_IN,OPT).\n Type ''help niak_pipeline_fmristat_ind'' for more info.')
end

%% Checking that FILES_IN is in the correct format
if ~isstruct(files_in)

    error('FILES_IN should be a struture!')
    
else
   
    list_subject = fieldnames(files_in);
    nb_subject = length(list_subject);
    
    for num_s = 1:nb_subject
        
        subject = list_subject{num_s};
        data_subject = files_in.(subject);
        
        if ~isstruct(data_subject)
            error('FILES_IN.%s should be a structure!',upper(subject));
        end
        
        if ~isfield(data_subject,'fmri')
            error('I could not find the field FILES_IN.%s.FMRI!',upper(subject));
        end
        
        flag_mask(num_s) = isfield(data_subject,'mask');
        flag_events(num_s) = isfield(data_subject,'events');
        flag_slicing(num_s) = isfield(data_subject,'slicing');
                      
        data_fmri = data_subject.fmri;
        list_session{num_s} = fieldnames(data_fmri);
        
        for num_c = 1:length(list_session{num_s})
            session = list_session{num_s}{num_c};
            data_session = data_fmri.(session);
            if ~iscellstr(data_session)
                error('FILES_IN.%s.fmri.%s is not a cell of strings!',upper(subject),upper(session));
            end
         
            if ~iscellstr(data_session)
                error('FILES_IN.%s.fmri.%s is not a cell of strings!',upper(subject),upper(session));
            end
                       
         end
                
    end
    
end

%% Options
gb_name_structure = 'opt';
default_psom.path_logs = '';
gb_list_fields         = {'spatial_normalization' , 'contrasts' , 'which_stats' , 'exclude' , 'mask_thresh' , 'folder_out' , 'flag_test' , 'psom'       , 'bricks' };
gb_list_defaults       = {'none'                  , NaN         , []            , []        , []            , NaN          , false       , default_psom , struct() };
niak_set_defaults

opt.psom(1).path_logs = [opt.folder_out 'logs' filesep];

if ~ismember(opt.spatial_normalization,{'additive_glb_av','scaling_glb_av','all_glb_av','none'})
    error(cat(2,opt.spatial_normalization,': is an unknown option for OPT.SPATIAL_NORMALIZATION. Available options are ''additive_glb_av'', ''scaling_glb_av'', ''all_glb_av'',''none'''))
end
flag_spatial_av = ~strcmp(opt.spatial_normalization,'none');

if ~isstruct(opt.contrasts)
     error('OPT.CONTRASTS should be a struture!')
end

%% The options for the bricks
gb_name_structure = 'opt.bricks';
opt_tmp.flag_test = false;

gb_list_fields = {'spatial_av','fmri_design','fmri_lm'};
gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp};
    
niak_set_defaults

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = struct();

%%%%%%%%%%%%%%%%%%%%%
%% Spatial average %%
%%%%%%%%%%%%%%%%%%%%%

name_process = 'spatial_av';

if flag_spatial_av % If the user requested a correction for spatial_av
    
    for num_s = 1:nb_subject
        
        subject = list_subject{num_s};
        list_session = fieldnames(files_in.(subject).fmri);
        nb_session = length(list_session);
        
        for num_sess = 1:nb_session
            
            session = list_session{num_sess};
            files_session = files_in.(subject).fmri.(session);
            nb_run = length(files_session);
            
            for num_r = 1:nb_run
                
                run = cat(2,'run',num2str(num_r));
                name_stage = cat(2,'spatial_av_',subject,'_',session,'_',run);
                
                %% Bulding inputs for NIAK_BRICK_SPATIAL_AV
                files_in_tmp.fmri = files_session{num_r};
                if flag_mask(num_s)
                    files_in_tmp.mask = files_in.(subject).mask;
                else
                    files_in_tmp.mask = [];
                end
                files_out_tmp = '';
                
                %% Setting up options
                opt_tmp = opt.bricks.spatial_av;
                opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

                %% Setting up defaults of the spatial_av
                opt_tmp.exclude = opt.exclude;
                opt_tmp.mask_thresh = opt.mask_thresh;
                
                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_spatial_av(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;
                
                %% Keeping track of the file names
                files_sav.(subject).(session){num_r} = files_out_tmp;

                %% Adding the stage to the pipeline
                pipeline(1).(name_stage).command = 'niak_brick_spatial_av(files_in,files_out,opt)';
                pipeline(1).(name_stage).files_in = files_in_tmp;
                pipeline(1).(name_stage).files_out = files_out_tmp;
                pipeline(1).(name_stage).opt = opt_tmp;

            end % run
        end % session
    end % subject
    
end % if flag_spatial_av


%%%%%%%%%%%%%
%% fmri design %%
%%%%%%%%%%%%%

name_process = 'fmri_design';

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    clear opt_tmp files_in_tmp files_out_tmp
    list_session = fieldnames(files_in.(subject).fmri);
    nb_session = length(list_session);
    
    for num_sess = 1:nb_session
        
        session = list_session{num_sess};
        files_session = files_in.(subject).fmri.(session);
        files_session_slicing = files_in.(subject).slicing.(session);
        files_session_events = files_in.(subject).events.(session);
        nb_run = length(files_session);
        
        for num_r = 1:nb_run
            
            run = cat(2,'run',num2str(num_r));
            name_stage = cat(2,'fmri_design_',subject,'_',session,'_',run);
            
            %% Bulding inputs for NIAK_BRICK_FMRI_DESIGN
            files_in_tmp.fmri = files_session{num_r};
            if flag_slicing(num_s)
                files_in_tmp.slicing = files_session_slicing{num_r};
            end
            if flag_events(num_s)
                files_in_tmp.events = files_session_events{num_r};
            end
            files_out_tmp = '';
            
            %% Setting up options
            opt_tmp = opt.bricks.fmri_design;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);
            
            %% Setting up defaults of the fmri_design
            opt_tmp.exclude = opt.exclude;
            if flag_spatial_av
                spatial_av_tmp = importdata(files_sav.(subject).(session){num_r});
                opt_tmp.spatial_av = spatial_av_tmp;
                if (~isfield(opt_tmp,'nb_trends_spatial'))&&any(strcmp(opt.spatial_normalization,{'additive_glb_av','all_glb_av'}))
                    opt_tmp.nb_trends_spatial = 1;
                end
            end
                       
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_fmri_design(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;
            
            %% Keeping track of the file names
            files_des.(subject).(session){num_r} = files_out_tmp;
            
            %% Adding the stage to the pipeline
            pipeline(1).(name_stage).command = 'niak_brick_fmri_design(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;
        end % run
    end % session
end % subject
   
%%%%%%%%%%%%
%% fmrilm %%
%%%%%%%%%%%%
name_process = 'fmri_lm';    

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    clear opt_tmp files_in_tmp files_out_tmp
    list_session = fieldnames(files_in.(subject).fmri);
    nb_session = length(list_session);
    
    for num_sess = 1:nb_session
        
        session = list_session{num_sess};
        files_session = files_in.(subject).fmri.(session);
        nb_run = length(files_session);
        
        for num_r = 1:nb_run
            
            run = cat(2,'run',num2str(num_r));
            name_stage = cat(2,'fmri_lm_',subject,'_',session,'_',run);
            
            %% Bulding inputs for NIAK_BRICK_FMRI_LM
            files_in_tmp.fmri = files_session{num_r};
            files_in_tmp.design = files_des.(subject).(session){num_r};
            if flag_mask(num_s)
                files_in_tmp.mask = files_in.(subject).mask;
            else
                files_in_tmp.mask = [];
            end
            files_out_tmp = '';
            
            %% Setting up options
            opt_tmp = opt.bricks.fmri_lm;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);
            if ~isempty(opt.which_stats)
                nf_which = length(opt.which_stats);
                for i=1:nf_which
                    files_out_tmp.(opt.which_stats{i}) = '';
                end
            end
            
            %% Setting up defaults of the fmrilm
            if isfield(opt.contrasts,'name')
                opt_tmp.contrast_names = opt.contrasts.name;
            end
            opt_tmp.contrast = opt.contrasts.weight;
            opt_tmp.exclude = opt.exclude;
            opt_tmp.mask_thresh = opt.mask_thresh;
            if flag_spatial_av
                spatial_av_tmp = importdata(files_sav.(subject).(session){num_r});
                opt_tmp.spatial_av = spatial_av_tmp;
                if (~isfield(opt_tmp,'nb_trends_spatial'))&&any(strcmp(opt.spatial_normalization,{'additive_glb_av','all_glb_av'}))
                    opt_tmp.nb_trends_spatial = 1;
                end
                if (~isfield(opt_tmp,'pcnt'))&&any(strcmp(opt.spatial_normalization,{'scaling_glb_av','all_glb_av'}))
                    opt_tmp.pcnt = 1;
                end
            end
                      
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_fmri_lm(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;
            
            %% Keeping track of the file names
            %files_a.(subject).(session){num_r} = files_out_tmp;
            
            %% Adding the stage to the pipeline
            pipeline(1).(name_stage).command = 'niak_brick_fmri_lm(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;
        
        end % run
    end % session
end % subject


%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end