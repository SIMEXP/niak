function pipeline = niak_pipeline_fmri_preprocess(files_in,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_PIPELINE_FMRI_PREPROCESS
%
% Build a pipeline structure to preprocess an fMRI database. Mutliple 
% preprocessing "styles" are available, depending on the analysis planned 
% afterwards, and the amount of generated outputs can be adjusted.
% Steps of the analysis can be further customized by changing virtually any
% parameter of the bricks used in the pipeline.
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
%       FOLDER_OUT 
%           (string) where to write the results of the pipeline. For the 
%           actual content of folder_out, see the internet 
%           documentation (http://wiki.bic.mni.mcgill.ca/index.php/NiakFmriPreprocessing)
%
%       ENVIRONMENT 
%           (string, default current environment) Available options : 
%           'matlab', 'octave'. The environment where the pipeline will run. 
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
%           SMOOTH_VOL 
%               (structure) options of NIAK_BRICK_SMOOTH_VOL (spatial
%               smoothing).
%
%           The following field is necessary if OPT.FLAG_CORSICA is set to 1
%           (which means that an attempt will be made to correct for
%           physiological noise) :
%
%           CORSICA
%               (structure) options of the NIAK_PIPELINE_CORSICA template
%               (correction of physiological noise). The options FOLDER_OUT
%               and ENVIRONMENT can be ignored (those will be taken care of
%               by the current template), but you can use the BRICKS field
%               to customize the parameters of the bricks used in that
%               pipeline. The field SIZE_OUTPUTS can be used here 
%               independently of the one of the FMRI_PREPROCESS pipeline, i.e.
%               it is possible to keep all the outputs of CORSICA even if you 
%               kept the bare minimum of the rest of the FMRI_PREPROCESS 
%               pipeline. The other interesting options would be :
%               
%               BRICKS.SICA.NB_COMP
%                   (integer, default min(60,foor(0.95*T)))
%                   number of components to compute (for default : T is the 
%                   number of time samples.
%
%               BRICKS.COMPONENT_SUPP.THRESHOLD
%                   (scalar, default 0.15) a threshold to apply on the 
%                   score for suppression (scores above the thresholds are 
%                   selected). If the threshold is -Inf, all components 
%                   will be suppressed. If the threshold is Inf, an 
%                   adaptative method based on the Otsu algorithm will be 
%                   applied to select the threshold automatically.
%
%           The Following additional fields have (or can) be used if the
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
%       pipeline. This structure is meant to be use in the function
%       NIAK_INIT_PIPELINE.
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
%       2.  Motion correction (within- and between-run for each subject).
%       3.  Coregistration of the anatomical volume with the mean 
%           functional volume.
%       4.  Concatenation of the T2-to-T1 and T1-to-stereotaxic-nl
%           transformations.
%       5.  Slice timing correction
%       6.  Correction of slow time drifts.
%       7.  Correction of physiological noise (if OPT.FLAG_CORSICA == 1)
%       8.  Spatial smoothing.
%   
%  * style 'standard-stereotaxic'
%       1.  Linear and non-linear spatial normalization of the anatomical 
%           image (and many more anatomical stuff such as brain masking and
%           CSF/GM/WM classification)
%       2.  Motion correction (within- and between-run for each subject).
%       3.  Coregistration of the anatomical volume with the mean 
%           functional volume.
%       4.  Concatenation of the T2-to-T1 and T1-to-stereotaxic-nl
%           transformations.
%       5.  Slice timing correction
%       6.  Correction of slow time drifts.
%       7.  Correction of physiological noise (if OPT.FLAG_CORSICA == 1)
%       8.  Resampling of the functional data in the stereotaxic space.
%       9.  Spatial smoothing.
%
% NOTE 2:
% The physiological & motion noise correction CORSICA is changing the
% degrees of freedom of the data. It is usullay negligible for intra-subject
% analysis, and will have no impact on the between-subject variance
% estimate (expect those should be less noisy). However, the purist may
% consider to take that into account in the linear model analysis. This
% will be taken care of in the (yet to come) NIAK_PIPELINE_LM_ANALYSIS.
%
% The exact list of outputs generated by the pipeline depend on the
% pipeline style and the OPT.SIZE_OUTPUTS field. See the internet
% documentation at http://wiki.bic.mni.mcgill.ca/index.php/NiakFmriPreprocessing for details.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline, niak, preprocessing, fMRI

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
if ~exist('files_in','var')|~exist('opt','var')
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_FMRI_PREPROCESS(FILES_IN,OPT).\n Type ''help niak_pipeline_fmri_preprocess'' for more info.')
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
        
        data_fmri = data_subject.fmri;
        list_session{num_s} = fieldnames(data_fmri);
        
        for num_c = 1:length(list_session{num_s})
            session = list_session{num_s}{num_c};
            data_session = data_fmri.(session);
            if ~iscellstr(data_session)
                error('FILES_IN.%s.fmri.%s is not a cell of strings!',upper(subject),upper(session));
            end
        end
        
        if ~isfield(data_subject,'anat')
            error('I could not find the field FILES_IN.%s.ANAT!',upper(subject));
        end
        
        data_anat = getfield(data_subject,'anat');
        if ~ischar(data_anat)
             error('FILES_IN.%s.ANAT is not a string!',upper(subject));
        end
        
    end
    
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'flag_corsica','style','size_output','folder_out','environment','bricks'};
gb_list_defaults = {1,NaN,'quality_control',NaN,'octave',struct([])};
niak_set_defaults

switch opt.size_output % check that the size of outputs is a valid option
    case {'minimum','quality_control','all'}
        
    otherwise
        error(cat(2,opt.size_output,': is an unknown option for OPT.SIZE_OUTPUT. Available options are ''minimum'', ''quality_control'', ''all'''))
end

%% The options for the bricks
gb_name_structure = 'opt.bricks';
opt_tmp.flag_test = 1;
opt_tmp_pipeline = struct([]);

switch style
    
    case 'fmristat'
    
        gb_list_fields = {'motion_correction','coregister','civet','corsica','smooth_vol'};
        gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,opt_tmp_pipeline,opt_tmp};
    
    case 'standard-native'
        
        gb_list_fields = {'motion_correction','slice_timing','coregister','time_filter','civet','corsica','smooth_vol'};
        gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp_pipeline,opt_tmp};
        
    case 'standard-stereotaxic'
        
        gb_list_fields = {'motion_correction','slice_timing','coregister','time_filter','civet','smooth_vol','resample_vol','corsica'};
        gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp_pipeline};
        
end
niak_set_defaults

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = struct([]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CIVET (spatial normalization) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'anat';

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    data_anat = getfield(files_in,subject,'anat');
    name_stage = cat(2,name_process,'_',subject);
        
    %% Inputs and options
    clear files_in_tmp files_out_tmp opt_tmp
    opt_tmp = opt.bricks.civet;
    opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

    if isfield(opt_tmp,'civet')
        opt_tmp.civet.id = subject;
        files_in_tmp.anat = '';
    else
        files_in_tmp.anat = data_anat;
    end

    %% Outputs
    files_out_tmp.transformation_lin = cat(2,opt_tmp.folder_out,filesep,'transf_',subject,'_nativet1_to_stereolin.xfm');
    files_out_tmp.transformation_nl = cat(2,opt_tmp.folder_out,filesep,'transf_',subject,'_nativet1_to_stereonl.xfm');
    files_out_tmp.transformation_nl_grid = cat(2,opt_tmp.folder_out,filesep,'transf_',subject,'_nativet1_to_stereonl_grid.mnc');
    files_out_tmp.anat_nuc = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_nativet1.mnc');
    files_out_tmp.anat_nuc_stereo_lin = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_stereolin.mnc');
    files_out_tmp.anat_nuc_stereo_nl = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_stereonl.mnc');
    files_out_tmp.mask = cat(2,opt_tmp.folder_out,filesep,'mask_anat_',subject,'_nativet1.mnc');
    files_out_tmp.mask_stereo = cat(2,opt_tmp.folder_out,filesep,'mask_anat_',subject,'_stereolin.mnc');
    files_out_tmp.classify = cat(2,opt_tmp.folder_out,filesep,'classify_anat_',subject,'_stereolin.mnc');
    files_out_tmp.pve_wm = cat(2,opt_tmp.folder_out,filesep,'pve_wm_anat_',subject,'_stereolin.mnc');
    files_out_tmp.pve_gm = cat(2,opt_tmp.folder_out,filesep,'pve_gm_anat_',subject,'_stereolin.mnc');
    files_out_tmp.pve_csf = cat(2,opt_tmp.folder_out,filesep,'pve_csf_anat_',subject,'_stereolin.mnc');
    files_out_tmp.verify = cat(2,opt_tmp.folder_out,filesep,'verify_anat_',subject,'.png');

    %% set the default values
    opt_tmp.flag_test = 1;
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_civet(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline
    pipeline(1).(name_stage).label = 'Processing of the anatomical data (transformation to stereotaxic space)';
    pipeline(1).(name_stage).command = 'niak_brick_civet(files_in,files_out,opt)';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;
    pipeline(1).(name_stage).environment = opt.environment;

end % subject

%%%%%%%%%%%%%%%%%%%%%%%
%% Motion correction %%
%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'motion_correction';
opt_tmp = opt.bricks.motion_correction;

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    clear opt_tmp files_in_tmp files_out_tmp
    name_stage = cat(2,'motion_correction_',subject);
    data_subject = files_in.(subject);    
    
    %% Bulding inputs 
    files_in_tmp.sessions = files_in.(subject).fmri;

    %% Building outputs
    switch size_output
        
        case {'minimum','quality_control'}
            
            files_out_tmp.motion_corrected_data = '';
            files_out_tmp.motion_parameters = '';
            files_out_tmp.fig_motion = '';
            files_out_tmp.mean_volume = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mean_nativefunc.mnc');
            files_out_tmp.std_volume = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_std_nativefunc.mnc');
            files_out_tmp.mask_volume = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mask_nativefunc.mnc');
            
        case 'all'
            
            files_out_tmp.motion_corrected_data = '';
            files_out_tmp.transf_within_session = '';
            files_out_tmp.transf_between_session = '';
            files_out_tmp.fig_motion = '';
            files_out_tmp.motion_parameters = '';
            files_out_tmp.mean_volume = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mean_nativefunc.mnc');
            files_out_tmp.std_volume = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_std_nativefunc.mnc');
            files_out_tmp.mask_volume = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mask_nativefunc.mnc');
            
    end
    
    %% Setting up default options
    opt_tmp = getfield(opt,'bricks',name_process);
    opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);
    
    %% Setting up defaults of the motion correction
    opt_tmp.flag_test = 1;    
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_motion_correction(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;
    
    %% Adding the stage to the pipeline
    pipeline(1).(name_stage).label = 'Correction of within- and between-sessions motion correction';
    pipeline(1).(name_stage).command = 'niak_brick_motion_correction(files_in,files_out,opt)';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;
    environment = opt.environment;    
        
end


%%%%%%%%%%%%%%%%%%%%%%%%%%
%% T1 T2 coregistration %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'coregister';

for num_s = 1:nb_subject

    subject = list_subject{num_s};

    clear opt_tmp files_in_tmp files_out_tmp

    %% Names of input/output stages
    name_stage = cat(2,name_process,'_',subject);
    name_stage_motion = cat(2,'motion_correction_',subject);
    name_stage_anat = cat(2,'anat_',subject);

    %% Building inputs for NIAK_BRICK_TIME_FILTER
    files_in_tmp.functional = getfield(pipeline,name_stage_motion,'files_out','mean_volume');
    files_in_tmp.anat = getfield(pipeline,name_stage_anat,'files_out','anat_nuc_stereo_lin');
    files_in_tmp.csf = getfield(pipeline,name_stage_anat,'files_out','pve_csf');
    files_in_tmp.transformation = getfield(pipeline,name_stage_anat,'files_out','transformation_lin');
    files_in_tmp.mask = getfield(pipeline,name_stage_anat,'files_out','mask_stereo');
    
    %% Building outputs for NIAK_BRICK_TIME_FILTER
    files_out_tmp.transformation = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'transf_',subject,'_nativefunc_to_stereolin.xfm');
    files_out_tmp.anat_hires = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'anat_',subject,'_nativefunc_hires.mnc');
    files_out_tmp.anat_lowres = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'anat_',subject,'_nativefunc_lowres.mnc');
    
    %% Setting up options
    opt_tmp = getfield(opt.bricks,name_process);
    opt_tmp.folder_out = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep);

    %% Setting up defaults of the motion correction
    opt_tmp.flag_test = 1;
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_coregister(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline    
    pipeline(1).(name_stage).label = 'T1-T2 coregistration';
    pipeline(1).(name_stage).command = 'niak_brick_coregister(files_in,files_out,opt)';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;
    pipeline(1).(name_stage).environment = opt.environment;

end % subject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Concatenate T2-to-T1_stereo_lin and T1_stereo_lin-to-stereotaxic-nl spatial transformation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'concat_transf_nl';

for num_s = 1:nb_subject

    subject = list_subject{num_s};

    clear opt_tmp files_in_tmp files_out_tmp

    %% Names of input/output stages
    name_stage = cat(2,name_process,'_',subject);
    name_stage_coregister = cat(2,'coregister_',subject);
    name_stage_anat = cat(2,'anat_',subject);

    %% Building inputs for NIAK_BRICK_CONCAT_TRANSF
    files_in_tmp{1} = getfield(pipeline,name_stage_coregister,'files_out','transformation');
    files_in_tmp{2} = getfield(pipeline,name_stage_anat,'files_out','transformation_nl');

    %% Building outputs for NIAK_BRICK_CONCAT_TRANSF
    files_out_tmp = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'transf_',subject,'_nativefunc_to_stereonl.xfm');

    %% Setting up options
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline    
    pipeline(1).(name_stage).label = 'concat spatial transformations (non-linear)';
    pipeline(1).(name_stage).command = 'niak_brick_concat_transf(files_in,files_out,opt)';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;
    pipeline(1).(name_stage).environment = opt.environment;

end % subject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% slice-timing correction %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(style,'standard-native')|strcmp(style,'standard-stereotaxic')
    
    name_process = 'slice_timing';    

    for num_s = 1:nb_subject

        subject = list_subject{num_s};        
        name_stage_in = cat(2,'motion_correction_',subject);
        files_run = niak_files2cell(getfield(pipeline,name_stage_in,'files_out','motion_corrected_data'));
        nb_run = length(files_run);
        
        for num_r = 1:nb_run

            run = cat(2,'run',num2str(num_r));            
            name_stage = cat(2,'slice_timing_',subject,'_',run);

            %% Bulding inputs for NIAK_BRICK_SLICE_TIMING
            files_in_tmp = files_run{num_r};
            files_out_tmp = '';
            
            %% Setting up options
            opt_tmp = opt.bricks.slice_timing;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

            %% Setting up defaults of the motion correction
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_slice_timing(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;
                        
            %% Adding the stage to the pipeline
            pipeline(1).(name_stage).label = 'Correction of slice-timing';
            pipeline(1).(name_stage).command = 'niak_brick_slice_timing(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;
            pipeline(1).(name_stage).environment = opt.environment;
            
            %% If the amount of outputs is 'minimum' or 'quality_control',
            %% clean the motion-corrected data when the slice-timing corrected
            %% images have been successfully generated.
            
            if strcmp(size_output,'minimum')|strcmp(size_output,'quality_control')
                clear files_in_tmp
                files_in_tmp = {pipeline(1).(name_stage).files_out};
                clear opt_tmp
                opt_tmp.clean = {pipeline(1).(name_stage).files_in};
                files_out_tmp = {};
                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;
                
                %% Adding the stage to the pipeline
                name_stage_new = cat(2,'clean_motion_',subject,'_run',num2str(num_r));                
                pipeline(1).(name_stage_new).label = 'Cleaning motion-corrected data';
                pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in = files_in_tmp;
                pipeline(1).(name_stage_new).files_out = files_out_tmp;
                pipeline(1).(name_stage_new).opt = opt_tmp;
                pipeline(1).(name_stage_new).environment = opt.environment;
                
            end
            
        end % run
    end % subject
end % style of pipeline

%%%%%%%%%%%%%%%%%%%%%%%%
%% temporal filtering %%
%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(style,'standard-native')|strcmp(style,'standard-stereotaxic')
    
    name_process = 'time_filter';    

    for num_s = 1:nb_subject

        subject = list_subject{num_s};               
        job_pipeline = fieldnames(pipeline);
        files_raw = niak_files2cell(getfield(files_in,subject,'fmri'));
        nb_run = length(files_raw);
        
        for num_r = 1:nb_run

            clear opt_tmp files_in_tmp files_out_tmp
            
            run = cat(2,'run',num2str(num_r));            
            name_stage = cat(2,name_process,'_',subject,'_',run);
            name_stage_in = cat(2,'slice_timing_',subject,'_',run);

            %% Building inputs for NIAK_BRICK_TIME_FILTER
            files_in_tmp = getfield(pipeline,name_stage_in,'files_out');
            
            %% Building outputs for NIAK_BRICK_TIME_FILTER
            switch size_output
                
                case 'minimum'
                
                    files_out_tmp.filtered_data = '';
                    
                case 'quality_control'
                    
                    files_out_tmp.filtered_data = '';
                    files_out_tmp.var_high = '';
                    files_out_tmp.var_low = '';
                    
                case 'all'
                    
                    files_out_tmp.filtered_data = '';
                    files_out_tmp.var_high = '';
                    files_out_tmp.var_low = '';
                    files_out_tmp.beta_high = '';
                    files_out_tmp.beta_low = '';
                    files_out_tmp.dc_high = '';
                    files_out_tmp.dc_low = '';
                    
            end
            
            %% Setting up options
            opt_tmp = opt.bricks.time_filter;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

            %% Setting up defaults of the motion correction
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_time_filter(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;
                        
            %% Adding the stage to the pipeline            
            pipeline(1).(name_stage).label = 'temporal filtering';
            pipeline(1).(name_stage).command = 'niak_brick_time_filter(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;
            pipeline(1).(name_stage).environment = opt.environment;
            
            %% If the amount of outputs is 'minimum' or 'quality_control',
            %% clean the slice-timing-corrected data when temporally
            %% filtered images have been successfully generated.
            
            if strcmp(size_output,'minimum')|strcmp(size_output,'quality_control')
                clear files_in_tmp
                files_in_tmp = pipeline(1).(name_stage).files_out.filtered_data;
                clear opt_tmp
                opt_tmp.clean = pipeline(1).(name_stage).files_in;
                files_out_tmp = {};
                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;
                
                %% Adding the stage to the pipeline
                name_stage_new = cat(2,'clean_slice_timing_',subject,'_run',num2str(num_r));                
                pipeline(1).(name_stage_new).label = 'Cleaning slice-timing-corrected data';
                pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in = files_in_tmp;
                pipeline(1).(name_stage_new).files_out = files_out_tmp;
                pipeline(1).(name_stage_new).opt = opt_tmp;
                pipeline(1).(name_stage_new).environment = opt.environment;                
            end
            
        end % run
    end % subject
end % style of pipeline

%%%%%%%%%%%%%
%% CORSICA %%
%%%%%%%%%%%%%

name_process = 'corsica';

if flag_corsica % If the user requested a correction of physiological noise

    for num_s = 1:nb_subject
        
        subject = list_subject{num_s};
        switch opt.style
            case 'fmristat'
                
                name_stage_in = cat(2,'motion_correction_',subject);
                nb_run = length(pipeline.(name_stage_in).files_out.motion_corrected_data);
                
            case {'standard-native','standard-stereotaxic'}
                
                name_stage_in = cat(2,'time_filter_',subject);
                job_pipeline = fieldnames(pipeline);
                list_stage_in = job_pipeline(find(niak_find_str_cell(job_pipeline,name_stage_in)));
                nb_run = length(list_stage_in);
                
        end
           
        name_stage_transf = cat(2,'concat_transf_nl_',subject);

        %% Building inputs for NIAK_PIPELINE_CORSICA
        clear opt_tmp files_in_tmp files_out_tmp
        
        switch opt.style
            
            case 'fmristat'
                
                files_in_tmp.(subject).fmri = pipeline.(name_stage_in).files_out.motion_corrected_data;
                
            case {'standard-native','standard-stereotaxic'}
                
                for num_r = 1:nb_run
                    files_in_tmp.(subject).fmri{num_r} = deal(pipeline.(list_stage_in{num_r}).files_out.filtered_data);
                end % run
                
        end

        files_in_tmp.(subject).transformation = pipeline.(name_stage_transf).files_out;

        %% Setting up options
        gb_name_structure = 'opt.bricks.corsica';
        gb_list_fields = {'size_output','folder_out','environment','bricks'};
        gb_list_defaults = {opt.size_output,cat(2,opt.folder_out,filesep,'sica',filesep),opt.environment,struct([])};
        niak_set_defaults;
        opt_tmp = opt.bricks.corsica;
        
        %% Adding the stages to the pipeline
        pipeline_corsica = niak_pipeline_corsica(files_in_tmp,opt_tmp);
        pipeline = niak_merge_structs(pipeline,pipeline_corsica);
        
        %% If the amount of outputs is 'minimum' or 'quality_control',
        %% clean the temporally filtered data when phyisiological-noise 
        %% corrected images have been successfully generated.
        
        if strcmp(size_output,'minimum')|strcmp(size_output,'quality_control')

            for num_r = 1:nb_run
                run = cat(2,'run',num2str(num_r));
                name_stage = cat(2,'component_supp_',subject,'_',run);
                clear files_in_tmp
                files_in_tmp = pipeline(1).(name_stage).files_out;
                clear opt_tmp
                opt_tmp.clean = pipeline(1).(name_stage).files_in.fmri;
                files_out_tmp = {};

                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;

                %% Adding the stage to the pipeline
                switch style
                    case 'fmristat'
                        name_stage_new = cat(2,'clean_motion_correction_',subject,'_run',num2str(num_r));
                    case {'standard-native'}
                        name_stage_new = cat(2,'clean_time_filter_',subject,'_run',num2str(num_r));
                end

                switch style
                    case 'fmristat'
                        pipeline(1).(name_stage_new).label = 'Cleaning motion-corrected data';
                    case {'standard-native'}
                        pipeline(1).(name_stage_new).label = 'Cleaning temporally filtered data';
                end

                pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in = files_in_tmp;
                pipeline(1).(name_stage_new).files_out = files_out_tmp;
                pipeline(1).(name_stage_new).opt = opt_tmp;
                pipeline(1).(name_stage_new).environment = opt.environment;                
            end % run
        end % Cleaning ('minimum' or 'quality_control')

    end % subject

end % if flag_corsica

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% spatial smoothing (native space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'smooth_vol';

if strcmp(style,'fmristat')|strcmp(style,'standard-native')

    for num_s = 1:nb_subject

        subject = list_subject{num_s};
        job_pipeline = fieldnames(pipeline);
        files_raw = niak_files2cell(getfield(files_in,subject,'fmri'));
        nb_run = length(files_raw);

        for num_r = 1:nb_run

            clear opt_tmp files_in_tmp files_out_tmp

            run = cat(2,'run',num2str(num_r));
            name_stage = cat(2,name_process,'_',subject,'_',run);

            %% Building inputs for NIAK_BRICK_SMOOTH_VOL

            if flag_corsica
                
                %% CORSICA has been applied, we use the
                %% physiologically-corrected data
                name_stage_in = cat(2,'component_supp_',subject,'_',run);
                files_in_tmp = pipeline.(name_stage_in).files_out;
                
            else
                %% NO CORSICA !
                
                switch style
                    
                    case 'fmristat'                     
                        
                        %% For fMRIstat
                        files_in_tmp = files_raw{num_r};
                        
                    case {'standard-native'}
                        
                        name_stage_in = cat(2,'time_filter_',subject,'_',run);
                        files_in_tmp = pipeline.(name_stage_in).files_out.filtered_data;
                        
                end
            end

            %% Building outputs for NIAK_BRICK_SMOOTH_VOL
            files_out_tmp = '';

            %% Setting up options
            opt_tmp = opt.bricks.smooth_vol;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

            %% Setting up defaults of the motion correction
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_smooth_vol(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;

            %% Adding the stage to the pipeline
            pipeline(1).(name_stage).label = 'spatial smoothing';
            pipeline(1).(name_stage).command = 'niak_brick_smooth_vol(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;
            pipeline(1).(name_stage).environment = opt.environment;

            %% If the amount of outputs is 'minimum' or 'quality_control',
            %% clean the inputs when the outpus have been successfully
            %% generated

            if strcmp(size_output,'minimum')|strcmp(size_output,'quality_control')
                
                clear files_in_tmp
                files_in_tmp = pipeline(1).(name_stage).files_out;
                clear opt_tmp
                opt_tmp.clean = pipeline(1).(name_stage).files_in;
                files_out_tmp = {};

                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;

                %% Adding the stage to the pipeline
                if flag_corsica
                    
                    name_stage_new = cat(2,'clean_corsica_',subject,'_run',num2str(num_r));                    
                    pipeline(1).(name_stage_new).label = 'Cleaning physiological-noise corrected data';
                    
                else

                    switch style
                        case 'fmristat'
                            name_stage_new = cat(2,'clean_motion_correction_',subject,'_run',num2str(num_r));
                        case {'standard-native'}
                            name_stage_new = cat(2,'clean_time_filter_',subject,'_run',num2str(num_r));
                    end

                    switch style
                        case 'fmristat'
                            pipeline(1).(name_stage_new).label = 'Cleaning motion-corrected data';
                        case {'standard-native'}
                            pipeline(1).(name_stage_new).label = 'Cleaning temporelly filtered data';
                    end
                    
                end

                pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in = files_in_tmp;
                pipeline(1).(name_stage_new).files_out = files_out_tmp;
                pipeline(1).(name_stage_new).opt = opt_tmp;
                pipeline(1).(name_stage_new).environment = opt.environment;

            end

        end % run
    end % subject
end % Styles 'fmristat' or 'standard_native'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Spatial resampling in stereotaxic space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(style,'standard-stereotaxic')

    name_process = 'resample_vol';

    for num_s = 1:nb_subject

        subject = list_subject{num_s};               
        job_pipeline = fieldnames(pipeline);
        files_raw = niak_files2cell(getfield(files_in,subject,'fmri'));
        nb_run = length(files_raw);
        name_stage_transf = cat(2,'concat_transf_nl_',subject);
        
        for num_r = 1:nb_run

            clear opt_tmp files_in_tmp files_out_tmp
            
            run = cat(2,'run',num2str(num_r));            
            name_stage = cat(2,name_process,'_',subject,'_',run);
            if flag_corsica
                name_stage_in = cat(2,'component_supp_',subject,'_',run);
            else
                name_stage_in = cat(2,'time_filter_',subject,'_',run);
            end

            %% Building inputs 
            if flag_corsica
                files_in_tmp.source = pipeline.(name_stage_in).files_out;
            else
                files_in_tmp.source = pipeline.(name_stage_in).files_out.filtered_data;
            end
            files_in_tmp.target = cat(2,gb_niak_path_template,filesep,'roi_aal.mnc');
            files_in_tmp.transformation = getfield(pipeline,name_stage_transf,'files_out');

            %% Building outputs 
            files_out_tmp = '';            
            
            %% Setting up options
            opt_tmp = opt.bricks.resample_vol;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

            %% Setting up defaults 
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_resample_vol(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;
                        
            %% Adding the stage to the pipeline            
            pipeline(1).(name_stage).label          =   'resampling in stereotaxic space';
            pipeline(1).(name_stage).command        =   'niak_brick_resample_vol(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in       =   files_in_tmp;
            pipeline(1).(name_stage).files_out      =   files_out_tmp;
            pipeline(1).(name_stage).opt            =   opt_tmp;
            pipeline(1).(name_stage).environment    =   opt.environment;
            
            %% If the amount of outputs is 'minimum' 
            %% clean the slice-timing-corrected data when temporally
            %% filtered images have been successfully generated.
            %% In 'quality_control mode' we keep these images as there are
            %% the only one left in native space.
            
            if strcmp(opt.size_output,'minimum')|strcmp(opt.size_output,'quality_control')
                
                clear files_in_tmp
                files_in_tmp = pipeline(1).(name_stage).files_out;
                clear opt_tmp
                opt_tmp.clean = pipeline(1).(name_stage).files_in.source;
                files_out_tmp = {};
                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;
                
                %% Adding the stage to the pipeline
                
                if flag_corsica
                    name_stage_new = cat(2,'clean_corsica_',subject,'_run',num2str(num_r));
                    pipeline(1).(name_stage_new).label = 'Cleaning physiological-noise corrected data in native space';
                else
                    name_stage_new = cat(2,'clean_time_filter_',subject,'_run',num2str(num_r));
                    pipeline(1).(name_stage_new).label       =  'Cleaning time filtered data in native space';
                end
                                
                pipeline(1).(name_stage_new).command     =  'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in    =  files_in_tmp;
                pipeline(1).(name_stage_new).files_out   =  files_out_tmp;
                pipeline(1).(name_stage_new).opt         =  opt_tmp;
                pipeline(1).(name_stage_new).environment =  opt.environment;

            end
            
        end % run
    end % subject
end % style of pipeline

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% spatial smoothing (stereotaxic space) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'smooth_vol';

if strcmp(style,'standard-stereotaxic')

    for num_s = 1:nb_subject

        subject = list_subject{num_s};
        job_pipeline = fieldnames(pipeline);
        files_raw = niak_files2cell(getfield(files_in,subject,'fmri'));
        nb_run = length(files_raw);      

        for num_r = 1:nb_run

            clear opt_tmp files_in_tmp files_out_tmp

            run = cat(2,'run',num2str(num_r));
            name_stage = cat(2,name_process,'_',subject,'_',run);

            %% Building inputs for NIAK_BRICK_SMOOTH_VOL
            name_stage_in = cat(2,'resample_vol_',subject,'_',run);
            files_in_tmp = pipeline.(name_stage_in).files_out;


            %% Building outputs for NIAK_BRICK_SMOOTH_VOL
            files_out_tmp = '';

            %% Setting up options
            opt_tmp = opt.bricks.smooth_vol;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

            %% Setting up defaults of the motion correction
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_smooth_vol(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;

            %% Adding the stage to the pipeline
            pipeline(1).(name_stage).label = 'spatial smoothing';
            pipeline(1).(name_stage).command = 'niak_brick_smooth_vol(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;
            pipeline(1).(name_stage).environment = opt.environment;

            %% If the amount of outputs is 'minimum' or 'quality_control',
            %% clean the inputs when the outpus have been successfully
            %% generated

            if strcmp(size_output,'minimum')|strcmp(size_output,'quality_control')
                
                clear files_in_tmp
                files_in_tmp = pipeline(1).(name_stage).files_out;
                clear opt_tmp
                opt_tmp.clean = pipeline(1).(name_stage).files_in;
                files_out_tmp = {};

                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;

                %% Adding the stage to the pipeline
                name_stage_new = cat(2,'clean_resample_vol_',subject,'_run',num2str(num_r));
                pipeline(1).(name_stage_new).label = 'Cleaning resampled data';

                pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in = files_in_tmp;
                pipeline(1).(name_stage_new).files_out = files_out_tmp;
                pipeline(1).(name_stage_new).opt = opt_tmp;
                pipeline(1).(name_stage_new).environment = opt.environment;

            end

        end % run
    end % subject
end % Styles 'fmristat' or 'standard_native'
