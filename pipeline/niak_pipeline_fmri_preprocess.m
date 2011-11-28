function [pipeline,opt] = niak_pipeline_fmri_preprocess(files_in,opt)
% Run a pipeline to preprocess fMRI and T1 MRI for a group of subjects.
% The flowchart of the pipeline is flexible (steps can be skipped using 
% flags), and the various steps of the analysis can be further customized 
% by changing virtually any parameter.
%
% SYNTAX:
% PIPELINE = NIAK_PIPELINE_FMRI_PREPROCESS(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN  
%   (structure) with the following fields : 
%
% FILES_IN  
%   (structure) with the following fields : 
%
%   <SUBJECT>.FMRI.<SESSION>   
%       (cell of strings) a list of fMRI datasets, acquired in the same 
%       session (small displacements). 
%       The field names <SUBJECT> and <SESSION> can be any arbitrary 
%       strings.
%       All data in FILES_IN.<SUBJECT> should be from the same subject.
%
%   <SUBJECT>.ANAT 
%       (string) anatomical volume, from the same subject as in 
%       FILES_IN.<SUBJECT>.FMRI
%
% OPT   
%   (structure) with the following fields : 
%
%   FOLDER_OUT
%       (string) where to write the default outputs.
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
%   FLAG_TEST
%       (boolean, default false) If FLAG_TEST is true, the pipeline will 
%       just produce a pipeline structure, and will not actually process 
%       the data. Otherwise, PSOM_RUN_PIPELINE will be used to process the 
%       data.
%
%   FLAG_VERBOSE
%           (boolean, default 1) if the flag is 1, then the function
%           prints some infos during the processing.
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
%       SESSION_REF
%           (string, default first session) name of the session of reference. 
%           By default, it is the first field found in FILES_IN. Use the
%           session corresponding to the acqusition of the T1 scan.
%
%       SUPPRESS_VOL 
%           (integer, default 0) the number of volumes that are suppressed 
%           at the begining of the time series. This is a good stage to get 
%           rid of "dummy scans" necessary to reach signal stabilization 
%           (that takes about 10 seconds, usually 3 to 5 volumes depending 
%           on the TR). Note that most brain imaging centers now 
%           automatically discard dummy scans.²
%
%       FLAG_SKIP
%           (boolean, default 0) if FLAG_SKIP == 1, the flag does not do 
%           anything, just copying the inputs to the outputs (note that it 
%           is still possible to suppress volumes). The motion parameters 
%           are still estimated and the quality control is still performed.
%  
%   QC_MOTION_CORRECTION_IND
%       (structure) options of NIAK_BRICK_QC_MOTION_CORRECTION_IND 
%       (Individual brain mask in fMRI data, measures of quality for 
%       motion correction).
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
%       coregistration between the anatomical and functional volumes).
%
%   TIME_FILTER 
%       (structure) options of NIAK_BRICK_TIME_FILTER (temporal filtering).
%
%       HP 
%           (real, default: 0.01) the cut-off frequency for high pass
%           filtering. opt.hp = -Inf means no high-pass filtering.
%
%       LP 
%           (real, default: Inf) the cut-off frequency for low pass 
%           filtering. opt.lp = Inf means no low-pass filtering.
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
%       FLAG_SKIP
%           (boolean, default false) if FLAG_SKIP is true, the brick does 
%           not do anything, just copying the inputs to the outputs (the 
%           ICA decomposition will still be generated and the component 
%           selection will still be generated for quality control purposes)
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
% The steps of the pipeline for each individual subjects are the following:
%       1.  Slice timing correction
%           See NIAK_BRICK_SLICE_TIMING and OPT.SLICE_TIMING
%       2.  Motion correction (within- and between-run for each label).
%           See NIAK_PIPELINE_MOTION_CORRECTION and OPT.MOTION_CORRECTION
%       3.  Quality control for motion correction.
%           See NIAK_BRICK_QC_MOTION_CORRECTION and
%           OPT.QC_MOTION_CORRECTION
%       4.  Linear and non-linear spatial normalization of the anatomical 
%           image (and many more anatomical stuff such as brain masking and
%           CSF/GM/WM classification)
%           See NIAK_BRICK_T1_PREPROCESS and OPT.T1_PREPROCESS
%       5.  Coregistration of the anatomical volume with the mean 
%           functional volume.
%           See NIAK_BRICK_ANAT2FUNC and OPT.ANAT2FUNC
%       6.  Concatenation of the T2-to-T1 and T1-to-stereotaxic-nl
%           transformations.
%           See NIAK_BRICK_CONCAT_TRANSF, no option there.
%       7.  Extraction of mean/std/mask for functional images, in various
%           spaces (Linear and non-linear stereotaxic spaces).
%           Uses the outputs of step 3, and NIAK_BRICK_RESAMPLE_VOL. 
%           Options can be accessed through OPT.RESAMPLE_VOL
%       8.  Quality control for 4 and 5.
%           See NIAK_BRICK_QC_COREGISTER
%       9.  Correction of slow time drifts.
%           See NIAK_BRICK_TIME_FILTER
%      10.  Correction of physiological noise.
%           See NIAK_PIPELINE_CORSICA and OPT.CORSICA
%           Also, see NIAK_BRICK_MASK_CORSICA (no option there)
%      11.  Resampling of the functional data in the stereotaxic space.
%           See NIAK_BRICK_RESAMPLE_VOL and OPT.RESAMPLE_VOL
%      12.  Spatial smoothing.
%           See NIAK_BRICK_SMOOTH_VOL and OPT.SMOOTH_VOL
%
% In addition job the following jobs are performed at the group level:
%       1.  Group quality control for motion correction.
%           See NIAK_BRICK_QC_MOTION_CORRECTION_GROUP and 
%           OPT.QC_MOTION_CORRECTION_GROUP
%       2.  Group quality control for coregistration of T1 images in
%           stereotaxic space
%           See NIAK_BRICK_QC_COREGISTER
%       3.  Group quality control for coregistration of fMRI in stereotaxic
%           space.
%
% NOTE 2:
%   The physiological & motion noise correction CORSICA is changing the
%   degrees of freedom of the data. It is usullay negligible for 
%   intra-label analysis, and will have no impact on the between-label 
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
% geriatrie de Montreal, Departement d'informatique et recherche 
% operationnelle, Universite de Montreal, 2010.
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pipeline, niak, preprocessing, fMRI, psom

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, label to the following conditions:
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
        
        if ~isstruct(files_in.(subject))
            error('FILES_IN.%s should be a structure!',upper(subject));
        end
        
        if ~isfield(files_in.(subject),'fmri')
            error('I could not find the field FILES_IN.%s.FMRI!',upper(subject));
        end
                
        if num_s==1
            list_session = cell([nb_subject 1]);
        end
        list_session{num_s} = fieldnames(files_in.(subject).fmri);
        
        for num_c = 1:length(list_session{num_s})
            session = list_session{num_s}{num_c};            
            if ~iscellstr(files_in.(subject).fmri.(session))
                error('FILES_IN.%s.fmri.%s is not a cell of strings!',upper(subject),upper(session));
            end
            if (num_s == 1)&&(num_c==1)
                [path_f,name_f,ext_f] = niak_fileparts(files_in.(subject).fmri.(session){1});                
            end
            
        end
                   
        if ~isfield(files_in.(subject),'anat')
            error('I could not find the field FILES_IN.%s.ANAT!',upper(subject));
        end
                
        if ~ischar(files_in.(subject).anat)
             error('FILES_IN.%s.ANAT is not a string!',upper(subject));
        end
        
        if ~isfield(files_in.(subject),'component_to_keep')
            files_in.(subject).component_to_keep = 'gb_niak_omitted';            
        end        
    end    
end

%% This block is for backward compatibility
if isfield(opt,'bricks')
    opt = psom_merge_pipeline(opt,opt.bricks);
    opt = rmfield(opt,'bricks');
    if isfield(opt,'flag_corsica');
        opt.corsica.flag_skip = ~opt.flag_corsica;
        opt = rmfield(opt,'flag_corsica');
    end
    if isfield(opt,'sica');
        opt.corsica.sica = opt.sica;
        opt = rmfield(opt,'sica');
    end
    if isfield(opt,'component_sel');
        opt.corsica.component_sel = opt.component_sel;
        opt = rmfield(opt,'component_sel');
    end
    if isfield(opt,'component_supp');
        opt.corsica.component_supp = opt.component_supp;
        opt = rmfield(opt,'component_supp');
        if isfield(opt.corsica.component_supp,'threshold')
          opt.corsica.threshold = opt.corsica.component_supp.threshold;
        end
    end
end

%% Options
default_psom.path_logs = '';
opt_tmp.flag_test = false;
file_template = [gb_niak_path_template filesep 'roi_aal.mnc.gz'];
gb_name_structure = 'opt';
gb_list_fields    = {'flag_verbose' , 'template_fmri' , 'size_output'     , 'folder_out' , 'folder_logs' , 'folder_fmri' , 'folder_anat' , 'folder_qc' , 'folder_intermediate' , 'flag_test' , 'psom'       , 'slice_timing' , 'motion_correction' , 'qc_motion_correction_ind' , 't1_preprocess' , 'anat2func' , 'qc_coregister' , 'corsica' , 'time_filter' , 'resample_vol' , 'smooth_vol' , 'region_growing' };
gb_list_defaults  = {true           , ''   , 'quality_control' , NaN          , ''            , ''            , ''            , ''          , ''                    , false       , default_psom , opt_tmp        , opt_tmp             , opt_tmp                    , opt_tmp         , opt_tmp     , opt_tmp         , opt_tmp   , opt_tmp       , opt_tmp        , opt_tmp      , opt_tmp          };
niak_set_defaults
opt.psom(1).path_logs = [opt.folder_out 'logs' filesep];

if ~ismember(opt.size_output,{'quality_control','all'}) % check that the size of outputs is a valid option
    error(sprintf('%s is an unknown option for OPT.SIZE_OUTPUT. Available options are ''minimum'', ''quality_control'', ''all''',opt.size_output))
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Resample the AAL template %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
name_job = 'resamp_aal';
clear files_in_tmp files_out_tmp opt_tmp

%force the AAL template

files_in_tmp.source      = template_fmri;
files_in_tmp.target      = template_fmri;
[path_f,name_f,ext_f,flag_zip,ext_short] = niak_fileparts(files_in.(list_subject{1}).fmri.(list_session{1}{1}){1});
files_out_tmp            = [opt.folder_out 'region_growing' filesep 'template_aal' ext_f];
opt_tmp                  = opt.resample_vol;
opt_tmp.interpolation    = 'nearest_neighbour';
pipeline = psom_add_job(struct(),name_job,'niak_brick_resample_aal',files_in_tmp,files_out_tmp,opt_tmp,false);

opt.template_fmri = pipeline.resamp_aal.files_out;
template_fmri = opt.template_fmri;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Build individual pipelines %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    fprintf('Generating pipeline for individual fMRI preprocessing :\n')
end
for num_s = 1:nb_subject
    subject = list_subject{num_s};
    if flag_verbose
        t1 = clock;
        fprintf('    %s ; ',subject);
    end    
    opt_ind = rmfield(opt,'flag_verbose');
    opt_ind.label = subject;
    
    %opt_ind.template_fmri = file_template; %[opt.folder_out filesep 'region_growing' filesep ''];
    opt_ind.flag_test = true;
    
%     if num_s == 1
%         pipeline = niak_pipeline_fmri_preprocess_ind(files_in.(subject),opt_ind);
%     else
        pipeline = psom_merge_pipeline(pipeline,niak_pipeline_fmri_preprocess_ind(files_in.(subject),opt_ind));
%     end
    if flag_verbose        
        fprintf('%1.2f sec\n',etime(clock,t1));
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GROUP QC COREGISTER ANAT STEREOLIN %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality of coregistration in anatomical space (linear stereotaxic space) ; ');
end
clear files_in_tmp files_out_tmp opt_tmp
files_in_tmp.vol  = cell([nb_subject 1]);
files_in_tmp.mask = cell([nb_subject 1]);
for num_s = 1:nb_subject
    files_in_tmp.vol{num_s}  = pipeline.(['t1_preprocess_' list_subject{num_s}]).files_out.anat_nuc_stereolin;
    files_in_tmp.mask{num_s} = pipeline.(['t1_preprocess_' list_subject{num_s}]).files_out.mask_stereolin;
end
files_out_tmp.mean_vol        = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mean_average_stereolin' ext_f];
files_out_tmp.std_vol         = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mean_std_stereolin' ext_f];
files_out_tmp.mask_average    = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mask_average_stereolin' ext_f];
files_out_tmp.mask_group      = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mask_group_stereolin' ext_f];
files_out_tmp.fig_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_fig_qc_coregister_stereolin.pdf'];
files_out_tmp.tab_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_tab_qc_coregister_stereolin.csv'];
opt_tmp                       = opt.qc_coregister;
opt_tmp.labels_subject        = list_subject;
pipeline = psom_add_job(pipeline,'qc_coregister_group_anat_stereolin','niak_brick_qc_coregister',files_in_tmp,files_out_tmp,opt_tmp);
if flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GROUP QC COREGISTER ANAT STEREONL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality of coregistration in anatomical space (non-linear stereotaxic space) ; ');
end
clear files_in_tmp files_out_tmp opt_tmp
files_in_tmp.vol  = cell([nb_subject 1]);
files_in_tmp.mask = cell([nb_subject 1]);
for num_s = 1:nb_subject
    files_in_tmp.vol{num_s}  = pipeline.(['t1_preprocess_' list_subject{num_s}]).files_out.anat_nuc_stereonl;
    files_in_tmp.mask{num_s} = pipeline.(['t1_preprocess_' list_subject{num_s}]).files_out.mask_stereonl;
end
files_out_tmp.mean_vol        = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mean_average_stereonl' ext_f];
files_out_tmp.std_vol         = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mean_std_stereonl' ext_f];
files_out_tmp.mask_average    = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mask_average_stereonl' ext_f];
files_out_tmp.mask_group      = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mask_group_stereonl' ext_f];
files_out_tmp.fig_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_fig_qc_coregister_stereonl.pdf'];
files_out_tmp.tab_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_tab_qc_coregister_stereonl.csv'];
opt_tmp                       = opt.qc_coregister;
opt_tmp.labels_subject        = list_subject;
pipeline = psom_add_job(pipeline,'qc_coregister_group_anat_stereonl','niak_brick_qc_coregister',files_in_tmp,files_out_tmp,opt_tmp);
if flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GROUP QC COREGISTER FUNC STEREOLIN %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality of coregistration in functional space (linear stereotaxic space) ; ');
end
clear files_in_tmp files_out_tmp opt_tmp
files_in_tmp.vol  = cell([nb_subject 1]);
files_in_tmp.mask = cell([nb_subject 1]);
for num_s = 1:nb_subject
    files_in_tmp.vol{num_s}  = pipeline.(['mask_ind_stereolin_' list_subject{num_s}]).files_out{1};
    files_in_tmp.mask{num_s} = pipeline.(['mask_ind_stereolin_' list_subject{num_s}]).files_out{2};
end
files_out_tmp.mean_vol        = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mean_average_stereolin' ext_f];
files_out_tmp.std_vol         = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mean_std_stereolin' ext_f];
files_out_tmp.mask_average    = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mask_average_stereolin' ext_f];
files_out_tmp.mask_group      = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mask_group_stereolin' ext_f];
files_out_tmp.fig_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_fig_qc_coregister_stereolin.pdf'];
files_out_tmp.tab_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_tab_qc_coregister_stereolin.csv'];
opt_tmp                       = opt.qc_coregister;
opt_tmp.labels_subject        = list_subject;
pipeline = psom_add_job(pipeline,'qc_coregister_group_func_stereolin','niak_brick_qc_coregister',files_in_tmp,files_out_tmp,opt_tmp);
if flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GROUP QC COREGISTER FUNC STEREONL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality of coregistration in functional space (non-linear stereotaxic space) ; ');
end
clear files_in_tmp files_out_tmp opt_tmp
files_in_tmp.vol  = cell([nb_subject 1]);
files_in_tmp.mask = cell([nb_subject 1]);
for num_s = 1:nb_subject
    files_in_tmp.vol{num_s}  = pipeline.(['mask_ind_stereonl_' list_subject{num_s}]).files_out{1};
    files_in_tmp.mask{num_s} = pipeline.(['mask_ind_stereonl_' list_subject{num_s}]).files_out{2};
end
files_out_tmp.mean_vol        = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mean_average_stereonl' ext_f];
files_out_tmp.std_vol         = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mean_std_stereonl' ext_f];
files_out_tmp.mask_average    = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mask_average_stereonl' ext_f];
files_out_tmp.mask_group      = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mask_group_stereonl' ext_f];
files_out_tmp.fig_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_fig_qc_coregister_stereonl.pdf'];
files_out_tmp.tab_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_tab_qc_coregister_stereonl.csv'];
opt_tmp                       = opt.qc_coregister;
opt_tmp.labels_subject        = list_subject;
pipeline = psom_add_job(pipeline,'qc_coregister_group_func_stereonl','niak_brick_qc_coregister',files_in_tmp,files_out_tmp,opt_tmp);
if flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GROUP QC MOTION_CORRECTION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality of motion correction ; ');
end
clear files_in_tmp files_out_tmp opt_tmp
for num_s = 1:nb_subject
    subject = list_subject{num_s};
    files_in_tmp.(subject).tab_coregister_ind    = pipeline.(['qc_motion_' subject]).files_out.tab_coregister;
    files_in_tmp.(subject).motion_parameters_ind = pipeline.(['qc_motion_' subject]).files_in.motion_parameters;
end
files_out_tmp.fig_coregister_group  = [opt.folder_out filesep 'quality_control' filesep 'group_motion' filesep 'qc_coregister_between_runs_group.pdf'];
files_out_tmp.tab_coregister_group  = [opt.folder_out filesep 'quality_control' filesep 'group_motion' filesep 'qc_coregister_between_runs_group.csv'];
files_out_tmp.fig_motion_group      = [opt.folder_out filesep 'quality_control' filesep 'group_motion' filesep 'qc_motion_group.pdf'];
files_out_tmp.tab_motion_group      = [opt.folder_out filesep 'quality_control' filesep 'group_motion' filesep 'qc_motion_group.csv'];
opt_tmp.flag_test                   = true;
pipeline = psom_add_job(pipeline,'qc_motion_group','niak_brick_qc_motion_correction_group',files_in_tmp,files_out_tmp,opt_tmp);
if flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%
%% Region Growing %%
%%%%%%%%%%%%%%%%%%%%

if ~opt.region_growing.flag_skip
    if flag_verbose
        t1 = clock;
        fprintf('Generating pipeline for the region growing ');
    end
    clear files_in_tmp files_out_tmp opt_tmp
    k=0;
    for num_s = 1:nb_subject
        subject = list_subject{num_s};

        for num_session = 1:size(list_session{num_s})
            session = list_session{num_s}{num_session};

            for num_r = 1:size(files_in.(subject).fmri.(session),2)
                k=k+1;
                run_name = ['run' num2str(num_r)];
                files_in_tmp.fmri{k}        = pipeline.(['smooth_' subject '_' session '_' run_name]).files_out;
            end
        end
    end
    
    files_in_tmp.areas_in       = pipeline.resamp_aal.files_in.source;
    files_in_tmp.areas          = pipeline.resamp_aal.files_out;
    files_in_tmp.mask           = pipeline.qc_coregister_group_func_stereonl.files_out.mask_group;

    opt_tmp                     = opt.region_growing;
    opt_tmp.folder_out          = [opt.folder_out filesep 'region_growing' filesep];
    opt_tmp.flag_test           = true;

    [pipeline_rg] = niak_pipeline_region_growing(files_in_tmp,opt_tmp);
    [pipeline] = psom_merge_pipeline(pipeline,pipeline_rg);

    if flag_verbose        
        fprintf('%1.2f sec\n',etime(clock,t1));
    end
end
%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end