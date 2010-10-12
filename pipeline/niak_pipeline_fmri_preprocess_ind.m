function pipeline = niak_pipeline_fmri_preprocess(files_in,opt)
% Run a pipeline to preprocess individual fMRI datasets. 
% The flowchart of the pipeline is flexible using flags, and the various 
% steps of the analysis can be further customized by changing virtually any 
% parameter.
%
% SYNTAX:
% PIPELINE = NIAK_PIPELINE_FMRI_PREPROCESS_IND(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN  
%   (structure) with the following fields : 
%
%   FMRI.<SESSION>   
%       (cell of strings) a list of file names of fMRI datasets, acquired 
%       in the same session (small displacements). The field name <SESSION> 
%       can be any arbitrary string.
%
%   ANAT 
%       (string) Anatomical (T1-weighted) volume.
%
%   COMPONENT_TO_KEEP
%       (string, default none) a text file, whose first line is a
%       a set of string labels, and each column is otherwise a temporal
%       component of interest. The ICA component with higher
%       correlation with each signal of interest will be automatically
%       attributed a selection score of 0, i.e. will *not* be identified as
%       physiological noise.
%
% OPT   
%   (structure) with the following fields : 
%
%   LABEL
%       (string, no default) a label that will be used to name the outputs.
%
%   SIZE_OUTPUT 
%       (string, default 'quality_control') possible values : 
%       'quality_control’, ‘all’.
%       The quantity of intermediate results that are generated. 
%           * With the option ‘quality_control’, only the preprocessed 
%             data and quality controls at the final stage are generated. 
%             All intermediate outputs are cleaned as soon as possible. 
%           * With the option ‘all’, all possible outputs are generated at 
%             each stage of the pipeline, and the intermediate results are
%             kept
%       
%   TEMPLATE_FMRI
%       (string, default '<~niak>/template/roi_aal.mnc.gz') a volume that
%       will be used to resample the fMRI datasets. By default it uses
%       a 2 mm isotropic space with a field of view adjusted on the brain.
%
%   FOLDER_PREPROCESSED
%       (string) where to write the preprocessed fMRI volumes.
%
%   FOLDER_ANAT
%       (string) where to write the preprocessed anatomical volumes as well 
%       as the results related to T1-T2 coregistration.
%
%   FOLDER_QC
%       (string) where to write the results of quality control.
%
%   FOLDER_INTERMEDIATE
%       (string) where to write the intermediate results.
%
%   FLAG_TEST
%       (boolean, default false) If FLAG_TEST is true, the pipeline will 
%       just produce a pipeline structure, and will not actually process 
%       the data. Otherwise, PSOM_RUN_PIPELINE will be used to process the 
%       data.
%
%   PSOM
%       (structure) the options of the pipeline manager. See the OPT 
%       argument of PSOM_RUN_PIPELINE. Default values can be used here.
%       Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%    
%   SLICE_TIMING 
%       (structure) options of NIAK_BRICK_SLICE_TIMING (correction of slice 
%       timing effects). Note that there are more flexible ways to specify 
%       the slice timing but the following should work for most users, see 
%       the help for details:
%
%       TYPE_ACQUISITION
%           (string, default 'manual') the type of acquisition used by the 
%           scanner. Possible choices are 'manual', 'sequential ascending',
%           'sequential descending', 'interleaved ascending',
%           'interleaved descending'. 
%       
%       TYPE_SCANNER
%           (string, default '') the type of MR scanner. The only value
%           that will change something to the processing here is 'Siemens', 
%           which has different conventions for interleaved acquisitions.
%
%       DELAY_IN_TR
%           (integer, default 0) the delay between the last slice of the 
%           first volume and the first slice of the following volume.
%
%       FLAG_SKIP
%           (boolean,  default 0) If FLAG_SKIP == 1, the brick is not doing 
%           anything, just copying the input to the output. Some 
%           simplifications will still be made in the header, see the
%           FLAG_REGULAR and FLAG_HISTORY flags.
%
%   MOTION_CORRECTION 
%       (structure) options of NIAK_PIPELINE_MOTION_CORRECTION. 
%
%       SUPPRESS_VOL 
%           (integer, default 0) the number of volumes that are suppressed 
%           at the begining of the time series. This is a good stage to get 
%           rid of "dummy scans" necessary to reach signal stabilization 
%           (that takes about 10 seconds, usually 3 to 5 volumes depending 
%           on the TR). Note that most brain imaging centers now 
%           automatically discard dummy scans.
%
%       FLAG_SKIP
%           (boolean, default 0) if FLAG_SKIP == 1, the flag does not do 
%           anything, just copying the inputs to the outputs (note that it 
%           is still possible to suppress volumes). The motion oarameters 
%           are still estimated and the quality control is still performed.
%  
%   QC_MOTION
%       (structure) options of NIAK_BRICK_QC_MOTION (Individual brain mask 
%       in fMRI data, measures of quality for motion correction).
%
%   T1_PREPROCESS
%       (structure) Options of NIAK_BRICK_T1_PREPROCESS, the brick of 
%       spatial normalization (non-linear transformation of T1 image in the 
%       stereotaxic space, brain masking and non-uniformity correction). 
%
%       NU_CORRECT.ARG
%           (string, default '-distance 200') any argument that will be 
%           passed to the NU_CORRECT command for non-uniformity 
%           corrections. The '-distance' option sets the N3 spline distance 
%           in mm (suggested values: 200 for 1.5T scan; 50 for 3T scan).
%
%   ANAT2FUNC 
%       (structure) options of NIAK_BRICK_ANAT2FUNC (coregistration 
%       between T1 and T2).
%
%       INIT
%       (string, default 'identity') how to set the initial guess of the 
%       transformation. 
%           'center': translation to align the centers of mass. 
%           'identity' : identity transformation.
%       The 'center' option usually does more harm than good. Use it only 
%       if you have very big misrealignement between the two images 
%       (say, > 2 cm).
%
%   QC_COREGISTER
%       (structure) options of NIAK_BRICK_QC_COREGISTER (measures of 
%       registration of the T1 volume in stereotaxic space as well as the 
%       coregistration between the anatomical and functional volumes.
%
%   CORSICA
%       (structure) options of NIAK_PIPELINE_CORSICA (correction of the
%       physiological noise based on automatic component selection in an
%       independent component analysis).
%               
%       SICA.NB_COMP
%           (integer, default min(60,foor(0.95*T)))
%           Number of components to compute (for default : T is the number 
%           of time samples).
%
%       COMPONENT_SUPP.THRESHOLD 
%           (scalar, default 0.15) a threshold to apply on the score for 
%           suppression (scores above the thresholds are selected, values
%           from 0 to 1).
%
%   TIME_FILTER 
%       (structure) options of NIAK_BRICK_TIME_FILTER (temporal filtering).
%
%   RESAMPLE_VOL 
%       (structure) options of NIAK_BRICK_RESAMPLE_VOL (spatial resampling 
%       in the stereotaxic space).
%
%       INTERPOLATION 
%           (string, default 'tricubic') the spatial interpolation method. 
%           Available options : 'trilinear', 'tricubic', 
%           'nearest_neighbour','sinc'.
%
%       FLAG_SKIP
%           (boolean, default false) if FLAG_SKIP==1, the brick does not do
%           anything, just copy the input on the output. 
%
%   SMOOTH_VOL 
%       (structure) options of NIAK_BRICK_SMOOTH_VOL (spatial smoothing).
%
%       FWHM  
%           (vector of size [1 3], default 6) the full width at half 
%           maximum of the Gaussian kernel, in each dimension. If fwhm has 
%           length 1, an isotropic kernel is implemented.
%
%       FLAG_SKIP
%           (boolean, default false) if FLAG_SKIP==1, the brick does not do
%           anything, just copy the input on the output. 
%
% _________________________________________________________________________
% OUTPUTS : 
%
%	PIPELINE 
%       (structure) describe all jobs that need to be performed in the
%       pipeline.
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
% The steps of the pipeline are the following :
%  
%       1.  Slice timing correction
%       2.  Motion correction (within- and between-run for each subject).
%       3.  Quality control for motion correction.
%       4.  Linear and non-linear spatial normalization of the anatomical 
%           image (and many more anatomical stuff such as brain masking and
%           CSF/GM/WM classification)
%       5.  Coregistration of the anatomical volume with the mean 
%           functional volume.
%       6.  Concatenation of the T2-to-T1 and T1-to-stereotaxic-nl
%           transformations.
%       7.  Quality control for 4 and 5.
%       8.  Correction of slow time drifts.
%       9.  Correction of physiological noise.
%      10.  Resampling of the functional data in the stereotaxic space.
%      11.  Spatial smoothing.
%
% NOTE 2:
%   The physiological & motion noise correction CORSICA is changing the
%   degrees of freedom of the data. It is usullay negligible for 
%   intra-subject analysis, and will have no impact on the between-subject 
%   variance estimate (except those should be less noisy). However, the 
%   purist may consider to take that into account in the linear model 
%   analysis. This will be taken care of in the (yet to come) 
%   NIAK_PIPELINE_FMRISTAT
%
% NOTE 3:
%   The exact list of outputs generated by the pipeline depend on the 
%   OPT.SIZE_OUTPUTS field. See the internet documentation for details :
%   http://wiki.bic.mni.mcgill.ca/index.php/NiakFmriPreprocessing 
%
% NOTE 4:
%   The PSOM pipeline manager is used to process the pipeline if
%   OPT.FLAG_TEST is false. PSOM has a number of interesting features to 
%   deal with job failures or pipeline updates. You can read the following
%   tutorial for a review of its capabilities : 
%   http://code.google.com/p/psom/wiki/HowToUsePsom
%   http://code.google.com/p/psom/wiki/PsomConfiguration
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% geriatrie de Montreal, 2010.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline, niak, preprocessing, fMRI, psom

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
            if (num_s == 1)&&(num_c==1)
                [path_f,name_f,ext_f] = fileparts(data_session{1});
                if isempty(path_f)
                    path_f = '.';
                end
                
                if strcmp(ext_f,gb_niak_zip_ext)
                    [tmp,name_f,ext_f] = fileparts(name_f);
                    ext_f = cat(2,ext_f,gb_niak_zip_ext);
                end
            end
            
        end
                   
        if ~isfield(data_subject,'anat')
            error('I could not find the field FILES_IN.%s.ANAT!',upper(subject));
        end
        
        data_anat = getfield(data_subject,'anat');
        if ~ischar(data_anat)
             error('FILES_IN.%s.ANAT is not a string!',upper(subject));
        end
        
        if ~isfield(data_subject,'component_to_keep')
            files_in.(subject).component_to_keep = 'gb_niak_omitted';            
        end
        
    end
    
end

%% Options
gb_name_structure = 'opt';
default_psom.path_logs = '';
gb_list_fields = {'method_t1_process','template_fmri','flag_corsica','style','size_output','folder_out','flag_test','psom','bricks'};
gb_list_defaults = {'t1_preprocess',cat(2,gb_niak_path_template,filesep,'roi_aal.mnc.gz'),1,NaN,'quality_control',NaN,false,default_psom,struct([])};
niak_set_defaults

opt.psom(1).path_logs = [opt.folder_out 'logs' filesep];

switch opt.size_output % check that the size of outputs is a valid option
    case {'minimum','quality_control','all'}
        
    otherwise
        error(cat(2,opt.size_output,': is an unknown option for OPT.SIZE_OUTPUT. Available options are ''minimum'', ''quality_control'', ''all'''))
end

%% The options for the bricks
gb_name_structure = 'opt.bricks';
opt_tmp.flag_test = false;

switch style
    
    case 'fmristat'
    
        gb_list_fields = {method_t1_preprocess,'mask_brain','resample_vol','motion_correction','coregister','sica','component_sel','component_supp','smooth_vol'};
        gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp};
    
    case 'standard-native'
        
        gb_list_fields = {method_t1_preprocess,'mask_brain','resample_vol','motion_correction','slice_timing','coregister','time_filter','sica','component_sel','component_supp','smooth_vol'};
        gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp};
        
    case 'standard-stereotaxic'
        
        gb_list_fields = {method_t1_preprocess,'mask_brain','motion_correction','slice_timing','coregister','time_filter','smooth_vol','resample_vol','sica','component_sel','component_supp',};
        gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp};
        
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

switch method_t1_preprocess
    
    case 't1_preprocess'
        
        for num_s = 1:nb_subject
            
            subject = list_subject{num_s};
            data_anat = getfield(files_in,subject,'anat');
            name_stage = cat(2,name_process,'_',subject);
            
            %% Inputs and options
            clear files_in_tmp files_out_tmp opt_tmp
            opt_tmp = opt.bricks.t1_preprocess;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);
                        
            %% Outputs
            files_out_tmp.transformation_lin = cat(2,opt_tmp.folder_out,filesep,'transf_',subject,'_nativet1_to_stereolin.xfm');
            files_out_tmp.transformation_nl = cat(2,opt_tmp.folder_out,filesep,'transf_',subject,'_stereolin_to_stereonl.xfm');
            files_out_tmp.transformation_nl_grid = cat(2,opt_tmp.folder_out,filesep,'transf_',subject,'_stereolin_to_stereonl_grid',ext_f);
            files_out_tmp.anat_nuc = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_nativet1',ext_f);
            files_out_tmp.anat_nuc_stereo_lin = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_stereolin',ext_f);
            files_out_tmp.anat_nuc_stereo_nl = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_stereonl',ext_f);
            files_out_tmp.mask_stereolin = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_mask_stereolin',ext_f);
            files_out_tmp.mask_stereonl = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_mask_stereonl',ext_f);
            files_out_tmp.classify = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_classify_stereolin',ext_f);
            files_out_tmp.pve_wm = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_pve_wm_stereolin',ext_f);
            files_out_tmp.pve_gm = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_pve_gm_stereolin',ext_f);
            files_out_tmp.pve_csf = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_pve_csf_stereolin',ext_f);
            files_out_tmp.verify = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_verify.png');
            
            %% set the default values
            pipeline = psom_add_job(pipeline,[name_process subject],'niak_brick_t1_preprocess',files_in_tmp,files_out_tmp,opt.bricks.t1_preprocess);
            
        end % subject
        
    case 'civet'
        
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
            files_out_tmp.transformation_nl = cat(2,opt_tmp.folder_out,filesep,'transf_',subject,'_stereolin_to_stereonl.xfm');
            files_out_tmp.transformation_nl_grid = cat(2,opt_tmp.folder_out,filesep,'transf_',subject,'_stereolin_to_stereonl_grid.mnc');
            files_out_tmp.anat_nuc = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_nativet1.mnc');
            files_out_tmp.anat_nuc_stereo_lin = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_stereolin.mnc');
            files_out_tmp.anat_nuc_stereo_nl = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_stereonl.mnc');
            files_out_tmp.mask = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_mask_nativet1.mnc');
            files_out_tmp.mask_stereo = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_mask_stereolin.mnc');
            files_out_tmp.classify = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_classify_stereolin.mnc');
            files_out_tmp.pve_wm = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_pve_wm_stereolin.mnc');
            files_out_tmp.pve_gm = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_pve_gm_stereolin.mnc');
            files_out_tmp.pve_csf = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_pve_csf_stereolin.mnc');
            files_out_tmp.verify = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_verify.png');
            
            %% set the default values
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_civet(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;
            
            %% Adding the stage to the pipeline
            pipeline(1).(name_stage).command = 'niak_brick_civet(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;
            
        end % subject
        
    otherwise
        error([method_t1_preprocess ' is an unknown method to preprocess the T1 image']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% slice-timing correction %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(style,'standard-native')||strcmp(style,'standard-stereotaxic')
    
    name_process = 'slice_timing';    

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
                name_stage = cat(2,'slice_timing_',subject,'_',session,'_',run);

                %% Bulding inputs for NIAK_BRICK_SLICE_TIMING
                files_in_tmp = files_session{num_r};
                files_out_tmp = '';

                %% Setting up options
                opt_tmp = opt.bricks.slice_timing;
                opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

                %% Setting up defaults of the motion correction
                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_slice_timing(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;

                %% Keeping track of the file names
                files_a.(subject).(session){num_r} = files_out_tmp;
                
                %% Adding the stage to the pipeline
                pipeline(1).(name_stage).command = 'niak_brick_slice_timing(files_in,files_out,opt)';
                pipeline(1).(name_stage).files_in = files_in_tmp;
                pipeline(1).(name_stage).files_out = files_out_tmp;
                pipeline(1).(name_stage).opt = opt_tmp;

            end % run
        end % session
    end % subject
end % style of pipeline

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
    switch style
        case 'fmristat'
            files_in_tmp.sessions = files_in.(subject).fmri;
        otherwise
            files_in_tmp.sessions = files_a.(subject);
    end    

    %% Building outputs
    switch size_output
        
        case {'minimum','quality_control'}
            
            files_out_tmp.motion_corrected_data = '';
            files_out_tmp.motion_parameters = '';
            files_out_tmp.fig_motion = ''; 
            
        case 'all'
            
            files_out_tmp.motion_corrected_data = '';
            files_out_tmp.transf_within_session = '';
            files_out_tmp.transf_between_session = '';
            files_out_tmp.fig_motion = '';
            files_out_tmp.motion_parameters = '';
            
    end

    %% Setting up default options
    opt_tmp = getfield(opt,'bricks',name_process);
    opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

    %% Setting up defaults of the motion correction
    opt_tmp.flag_test = 1;
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_motion_correction(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline
    pipeline(1).(name_stage).command = 'niak_brick_motion_correction(files_in,files_out,opt)';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;

    %% If the amount of outputs is 'minimum' or 'quality_control',
    %% clean the motion-corrected data when the slice-timing corrected
    %% images have been successfully generated.

    if (strcmp(size_output,'minimum')||strcmp(size_output,'quality_control'))&&~strcmp(style,'fmristat')
        
        clear files_in_tmp
        files_in_tmp = pipeline(1).(name_stage).files_out.motion_corrected_data;
        clear opt_tmp
        opt_tmp.clean = pipeline(1).(name_stage).files_in.sessions;
        files_out_tmp = {};
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        name_stage_new = cat(2,'clean_slice_timing_',subject,'_run',num2str(num_r));
        pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
        pipeline(1).(name_stage_new).files_in = files_in_tmp;
        pipeline(1).(name_stage_new).files_out = files_out_tmp;
        pipeline(1).(name_stage_new).opt = opt_tmp;

    end
        
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate masks in the native space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'mask_ind_native';

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    clear opt_tmp files_in_tmp files_out_tmp

    %% Names of input/output stages
    name_stage = cat(2,name_process,'_',subject);
    name_stage_motion = cat(2,'motion_correction_',subject);
    
    %% Building inputs for NIAK_BRICK_RESAMPLE_VOL
    files_in_tmp = niak_files2cell(pipeline.(name_stage_motion).files_out.motion_corrected_data);    
    
    %% Building outputs for NIAK_BRICK_RESAMPLE_VOL
    files_out_tmp.mean_average = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mean_nativefunc.mnc');
    files_out_tmp.std_average = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_std_nativefunc.mnc');
    files_out_tmp.mask = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mask_nativefunc.mnc');
    files_out_tmp.mask_average = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mask_average_nativefunc.mnc');
    files_out_tmp.tab_fit = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_tab_fit.dat');
    
    %% Setting up options
    opt_tmp = opt.bricks.mask_brain;
    opt_tmp.flag_test = true;
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_mask_brain(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

     %% Adding the stage to the pipeline        
    pipeline(1).(name_stage).command = 'niak_brick_mask_brain(files_in,files_out,opt)';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;   
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% T1 T2 coregistration %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

for num_s = 1:nb_subject

    subject = list_subject{num_s};

    clear opt_tmp files_in_tmp files_out_tmp

    %% Names of input/output stages    
    name_job_mask = cat(2,'mask_ind_native_',subject);
    name_job_anat = cat(2,'anat_',subject);

    %% Building inputs for NIAK_BRICK_COREGISTER
    files_in_tmp.func                   = getfield(pipeline,name_job_mask,'files_out','mean_average');
    files_in_tmp.mask_func              = getfield(pipeline,name_job_mask,'files_out','mask');
    files_in_tmp.anat                   = getfield(pipeline,name_job_anat,'files_out','anat_nuc_stereo_lin');    
    files_in_tmp.mask_anat              = getfield(pipeline,name_job_anat,'files_out','mask_stereo');
    files_in_tmp.transformation_init    = getfield(pipeline,name_job_anat,'files_out','transformation_lin');    
    
    %% Building outputs for NIAK_BRICK_COREGISTER
    files_out_tmp.transformation = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'transf_',subject,'_nativefunc_to_stereolin.xfm');
    files_out_tmp.anat_hires     = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'anat_',subject,'_nativefunc_hires.mnc');
    files_out_tmp.anat_lowres    = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'anat_',subject,'_nativefunc_lowres.mnc');
    
    %% Setting up options
    opt_tmp             = opt.bricks.anat2func;
    opt_tmp.folder_out  = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep);

    %% Add job
    pipeline = psom_add_job(pipeline,['anat2func_',subject],'niak_brick_anat2func',files_in_tmp,files_out_tmp,opt_tmp);

end 

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
    pipeline(1).(name_stage).command = 'niak_brick_concat_transf(files_in,files_out,opt)';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;    

end % subject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate masks in the stereotaxic (non-linear) space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%MMMM%%%%%%%%

name_process = 'mask_ind_stereonl';
files_mean_nl = cell([nb_subject 1]);

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    clear opt_tmp files_in_tmp files_out_tmp

    %% Names of input/output stages
    name_stage = cat(2,name_process,'_',subject);
    name_stage_concat = cat(2,'concat_transf_nl_',subject);
    name_stage_mask = cat(2,'mask_ind_native_',subject);
    
    %% Building inputs for NIAK_BRICK_RESAMPLE_VOL
    files_in_tmp(1).transformation = pipeline.(name_stage_concat).files_out;
    files_in_tmp(1).source = pipeline.(name_stage_mask).files_out.mean_average;
    files_in_tmp(1).target = opt.template_fmri;

    files_in_tmp(2).transformation = pipeline.(name_stage_concat).files_out;
    files_in_tmp(2).source = pipeline.(name_stage_mask).files_out.mask;
    files_in_tmp(2).target = opt.template_fmri;

    %% Building outputs for NIAK_BRICK_RESAMPLE_VOL
    files_out_tmp{1} = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mean_stereonl.mnc');
    files_out_tmp{2} = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mask_stereonl.mnc');
    files_mean_nl{num_s} = files_out_tmp{1};
    
    %% Setting up options
    opt_tmp(1) = opt.bricks.resample_vol;
    opt_tmp(2) = opt.bricks.resample_vol;
    opt_tmp(1).interpolation = 'tricubic';
    opt_tmp(2).interpolation = 'nearest_neighbour';

    %% Adding the stage to the pipeline
    pipeline(1).(name_stage).command = 'niak_brick_resample_vol(files_in(1),files_out{1},opt(1)),niak_brick_resample_vol(files_in(2),files_out{2},opt(2))';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;   
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate masks in the stereotaxic (linear) space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'mask_ind_stereolin';
files_mean_lin = cell([nb_subject 1]);

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    clear opt_tmp files_in_tmp files_out_tmp

    %% Names of input/output stages
    name_stage = cat(2,name_process,'_',subject);
    name_stage_coregister = cat(2,'coregister_',subject);
    name_stage_mask = cat(2,'mask_ind_native_',subject);
    
    %% Building inputs for NIAK_BRICK_RESAMPLE_VOL
    files_in_tmp(1).transformation = pipeline.(name_stage_coregister).files_out.transformation;
    files_in_tmp(1).source = pipeline.(name_stage_mask).files_out.mean_average;
    files_in_tmp(1).target = opt.template_fmri;
    
    files_in_tmp(2).transformation = pipeline.(name_stage_coregister).files_out.transformation;
    files_in_tmp(2).source = pipeline.(name_stage_mask).files_out.mask;
    files_in_tmp(2).target = opt.template_fmri;

    %% Building outputs for NIAK_BRICK_RESAMPLE_VOL
    files_out_tmp{1} = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mean_stereolin.mnc');
    files_out_tmp{2} = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mask_stereolin.mnc');
    files_mean_lin{num_s} = files_out_tmp{1};
    
    %% Setting up options
    opt_tmp(1) = opt.bricks.resample_vol;
    opt_tmp(2) = opt.bricks.resample_vol;
    opt_tmp(1).interpolation = 'tricubic';
    opt_tmp(2).interpolation = 'nearest_neighbour';
    
     %% Adding the stage to the pipeline        
    pipeline(1).(name_stage).command = 'niak_brick_resample_vol(files_in(1),files_out{1},opt(1)),niak_brick_resample_vol(files_in(2),files_out{2},opt(2))';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;   
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Group mask (stereolin) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_job = 'mask_group_stereolin';

clear opt_tmp files_in_tmp files_out_tmp

%% FILES IN
files_in_tmp = files_mean_lin;

%% FILES OUT
[path_f,name_f,ext_f] = fileparts(files_in_tmp{1});

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end

files_out_tmp.mean_average = [opt.folder_out filesep 'group' filesep 'func_mean_average_stereolin' ext_f];
files_out_tmp.mask_average = [opt.folder_out filesep 'group' filesep 'func_mask_average_stereolin' ext_f];
files_out_tmp.mask = [opt.folder_out filesep 'group' filesep 'func_mask_group_stereolin' ext_f];
files_out_tmp.tab_fit = [opt.folder_out filesep 'group' filesep 'func_mask_tab_fit_stereolin.dat'];

%% OPT
opt_tmp = opt.bricks.mask_brain;
opt_tmp.flag_test = 1;
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_mask_brain(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

pipeline.(name_job).command = 'niak_brick_mask_brain(files_in,files_out,opt);';
pipeline.(name_job).files_in = files_in_tmp;
pipeline.(name_job).files_out = files_out_tmp;
pipeline.(name_job).opt = opt_tmp;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Group mask (stereonl) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_job = 'mask_group_stereonl';

clear opt_tmp files_in_tmp files_out_tmp

%% FILES IN
files_in_tmp = files_mean_nl;

%% FILES OUT
[path_f,name_f,ext_f] = fileparts(files_in_tmp{1});

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end

files_out_tmp.mean_average = [opt.folder_out filesep 'group' filesep 'func_mean_average_stereonl' ext_f];
files_out_tmp.mask_average = [opt.folder_out filesep 'group' filesep 'func_mask_average_stereonl' ext_f];
files_out_tmp.mask = [opt.folder_out filesep 'group' filesep 'func_mask_group_stereonl' ext_f];
files_out_tmp.tab_fit = [opt.folder_out filesep 'group' filesep 'func_mask_tab_fit_stereonl.dat'];

%% OPT
opt_tmp = opt.bricks.mask_brain;
opt_tmp.flag_test = 1;
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_mask_brain(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

pipeline.(name_job).command = 'niak_brick_mask_brain(files_in,files_out,opt);';
pipeline.(name_job).files_in = files_in_tmp;
pipeline.(name_job).files_out = files_out_tmp;
pipeline.(name_job).opt = opt_tmp;

%%%%%%%%%%%%%%%%%%%%%%%%
%% temporal filtering %%
%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(style,'standard-native')|strcmp(style,'standard-stereotaxic')
    
    name_process = 'time_filter';

    for num_s = 1:nb_subject

        subject = list_subject{num_s};
        name_stage_motion = cat(2,'motion_correction_',subject);
        files_motion = pipeline.(name_stage_motion).files_out.motion_corrected_data;
        list_session = fieldnames(files_motion);
        nb_session = length(list_session);
        nb_run_tot = 0;
        
        for num_sess = 1:nb_session

            session = list_session{num_sess};

            list_files = files_motion.(session);
            nb_run = length(list_files);

            for num_r = 1:nb_run

                nb_run_tot = nb_run_tot + 1;
                
                clear opt_tmp files_in_tmp files_out_tmp

                run = cat(2,'run',num2str(nb_run_tot));
                name_stage = cat(2,name_process,'_',subject,'_',run);
                

                %% Building inputs for NIAK_BRICK_TIME_FILTER
                files_in_tmp = list_files{num_r};

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
                pipeline(1).(name_stage).command = 'niak_brick_time_filter(files_in,files_out,opt)';
                pipeline(1).(name_stage).files_in = files_in_tmp;
                pipeline(1).(name_stage).files_out = files_out_tmp;
                pipeline(1).(name_stage).opt = opt_tmp;

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
                    pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                    pipeline(1).(name_stage_new).files_in = files_in_tmp;
                    pipeline(1).(name_stage_new).files_out = files_out_tmp;
                    pipeline(1).(name_stage_new).opt = opt_tmp;
                end

            end % run
        end % session
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
                list_stage_in = job_pipeline(find(niak_find_str_cell(job_pipeline,[name_stage_in '_'])));
                nb_run = length(list_stage_in);
                
        end
           
        name_stage_transf = cat(2,'concat_transf_nl_',subject);

        %% Building inputs for NIAK_PIPELINE_CORSICA
        clear opt_tmp files_in_tmp files_out_tmp
        
        switch opt.style
            
            case 'fmristat'
                                
                files_in_tmp.(subject).fmri = niak_files2cell(pipeline.(name_stage_in).files_out.motion_corrected_data);

            case {'standard-native','standard-stereotaxic'}
                
                for num_r = 1:nb_run
                    files_in_tmp.(subject).fmri{num_r} = deal(pipeline.(list_stage_in{num_r}).files_out.filtered_data);
                end % run
                
        end

        files_in_tmp.(subject).component_to_keep = files_in.(subject).component_to_keep;
        files_in_tmp.(subject).transformation = pipeline.(name_stage_transf).files_out;

        %% Setting up options
        gb_name_structure = 'opt_tmp';
        gb_list_fields = {'flag_test','size_output','folder_out'};
        gb_list_defaults = {true,opt.size_output,cat(2,opt.folder_out,filesep,'sica',filesep)};
        niak_set_defaults;
        opt_tmp.bricks.sica = opt.bricks.sica;
        opt_tmp.bricks.component_sel = opt.bricks.component_sel;
        opt_tmp.bricks.component_supp = opt.bricks.component_supp;
        
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
                
                pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in = files_in_tmp;
                pipeline(1).(name_stage_new).files_out = files_out_tmp;
                pipeline(1).(name_stage_new).opt = opt_tmp;                               
            end % run
        end % Cleaning ('minimum' or 'quality_control')

    end % subject

end % if flag_corsica

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% spatial smoothing (native space) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'smooth_vol';

if strcmp(style,'fmristat')|strcmp(style,'standard-native')

    for num_s = 1:nb_subject

        subject = list_subject{num_s};
        job_pipeline = fieldnames(pipeline);
        stage_motion = cat(2,'motion_correction_',subject);
        files_motion = niak_files2cell(pipeline.(stage_motion).files_out.motion_corrected_data);        
        nb_run = length(files_motion);

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
                        files_in_tmp = files_motion{num_r};
                        
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
            pipeline(1).(name_stage).command = 'niak_brick_smooth_vol(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;            

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
                    
                else

                    switch style
                        case 'fmristat'
                            name_stage_new = cat(2,'clean_motion_correction_',subject,'_run',num2str(num_r));
                        case {'standard-native'}
                            name_stage_new = cat(2,'clean_time_filter_',subject,'_run',num2str(num_r));
                    end                    
                    
                end

                pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in = files_in_tmp;
                pipeline(1).(name_stage_new).files_out = files_out_tmp;
                pipeline(1).(name_stage_new).opt = opt_tmp;                

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
            files_in_tmp.target = opt.template_fmri;
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
            pipeline(1).(name_stage).command        =   'niak_brick_resample_vol(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in       =   files_in_tmp;
            pipeline(1).(name_stage).files_out      =   files_out_tmp;
            pipeline(1).(name_stage).opt            =   opt_tmp;            
            
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
                else
                    name_stage_new = cat(2,'clean_time_filter_',subject,'_run',num2str(num_r));                    
                end
                                
                pipeline(1).(name_stage_new).command     =  'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in    =  files_in_tmp;
                pipeline(1).(name_stage_new).files_out   =  files_out_tmp;
                pipeline(1).(name_stage_new).opt         =  opt_tmp;                

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
            pipeline(1).(name_stage).command = 'niak_brick_smooth_vol(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;            

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

                pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in = files_in_tmp;
                pipeline(1).(name_stage_new).files_out = files_out_tmp;
                pipeline(1).(name_stage_new).opt = opt_tmp;                

            end

        end % run
    end % subject
end % Styles 'fmristat' or 'standard_native'

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end