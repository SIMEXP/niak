function [pipeline,opt] = niak_pipeline_fmri_preprocess(files_in,opt)
% Run a pipeline to preprocess fMRI and T1 MRI for a group of subjects.
% The flowchart of the pipeline is flexible (steps can be skipped using 
% flags), and the analysis can be further customized by changing the 
% parameters of any step.
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
%   <SUBJECT>.FMRI.<SESSION>.<RUN>
%       (string) a list of fMRI datasets, acquired in the same 
%       session (small displacements). 
%       The field names <SUBJECT>, <SESSION> and <RUN> can be any arbitrary 
%       strings.
%       All data in FILES_IN.<SUBJECT> should be from the same subject.
%       Note that <SUBJECT>.<SESSION> can also be a cell of strings, in 
%       which case RUN1, RUN2 etc will be used as tags for each run.
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
%       will be used to resample the fMRI datasets. 
%
%   GRANULARITY
%       (string, default 'cleanup') the level of granularity of the pipeline.
%       Available options:
%           'max' : break down all operations as separate jobs, if possible
%           'cleanup' : group together clean-up jobs for each subject
%           'subject' : bundle all jobs associated with a specific subject
%
%   FLAG_RAND
%      (boolean, default false) if the flag is false, the pipeline is 
%      deterministic. Otherwise, the random number generator is initialized
%      based on the clock for each job.
%
%   FLAG_TEST
%       (boolean, default false) If FLAG_TEST is true, the pipeline will 
%       just produce a pipeline structure, and will not actually process 
%       the data. Otherwise, PSOM_RUN_PIPELINE will be used to process the 
%       data.
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function
%       prints some infos during the processing.
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
%   PVE
%       (structure) option for the estimation of partial volume effects of 
%       tissue types (grey matter, white matter, cerbrospinal fluid) on the 
%       anatomical scan.
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
%   REGION_GROWING 
%       (structure) options of NIAK_PIPELINE_REGION_GROWING.
%     
%       THRE_SIZE 
%           (integer,default 1000 mm3) threshold on the region size (maximum). 
%     
%       THRE_NB_ROIS 
%           (integer, default 0) the minimum number of homogeneous
%           regions (if no threshold are fixed on size and similarity,
%           THRE_NB_ROIS will be the actual number of homogeneous regions).
%
%       CORRECTION_AVERAGE
%           (structure, default CORRECTION.TYPE = 'mean') the temporal 
%           normalization to apply on the individual time series before 
%           averaging in each ROI. See OPT in NIAK_NORMALIZE_TSERIES.
%     
%       IND_ROIS
%           (vector of integer, default all) list of ROIs index that will 
%           be included in the analysis. By default, the brick is processing 
%           all the ROIs found in FILES_IN.MASK
%
%       FLAG_SKIP
%           (boolean, default true) if FLAG_SKIP==1, the brick does not do
%           anything. 
%
%   TUNE
%       (structure) can be used to set different parameters for one or 
%       multiple subjects. OPT.TUNE can have multiple entries with the following 
%       fields:
%       
%       SUBJECT
%          (string) the name of a subject OR a pattern that will be used to
%          match a group of subjects (see OPT.TUNE.TYPE below)
%
%       TYPE
%          (string, default 'exact') it TYPE is 'exact', the options will 
%          apply only to an exact match in subject ID . 
%          If TYPE equals 'regexpr', then any ID that matches with 
%          a call to REGEXP will be included.
%
%       PARAM
%          (structure) same as OPT (without the TUNE field). Any field 
%          present in PARAM will override the fields of OPT of the subject
%          or group of subjects that fit with LABEL.
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
%           See NIAK_BRICK_PVE and OPT.PVE
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
%      13.  Region growing.
%           See NIAK_PIPELINE_REGION_GROWING and OPT.REGION_GROWING
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
%       4.  Group quality control for the change in variance following 
%           motion correction.
%       5.  Group quality control for the variance explained by slow time
%           drifts.
%       6.  Group quality control for the variance explained by the regression
%           of motion parameters (F-test).
%       7.  Group quality control for the variance explained by the regression
%           of the average signal in the white matter (F-test).
%       8.  Group quality control for the variance explained by the regression
%           of the global signal estimate (using PCA, F-test).
%       9.  Group quality control for the variance explained by custom confound
%           covariates (F-test).
%       10. Group quality control for the explained explained by the selection of 
%           physiological noise components in an ICA (CORSICA).
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
%   http://www.nitrc.org/plugins/mwiki/index.php/niak:FmriPreprocessing
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
% Maintainer : pierre.bellec@criugm.qc.ca
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

%% Syntax
if ~exist('files_in','var')||~exist('opt','var')
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_FMRI_PREPROCESS(FILES_IN,OPT).\n Type ''help niak_pipeline_fmri_preprocess'' for more info.')
end

%% FILES_IN
files_in = sub_check_format(files_in); % check the format of FILES_IN
[fmri_c,label] = niak_fmri2cell(files_in); % Convert FILES_IN into a cell of string form
[path_f,name_f,ext_f] = niak_fileparts(fmri_c{1}); % Get the extension of outputs

%% OPT
opt = sub_backwards(opt); % Fiddling with OPT for backwards compatibility
template_fmri = [gb_niak_path_template filesep 'roi_aal.mnc.gz'];
list_fields    = { 'flag_rand' , 'granularity' , 'tune'   , 'flag_verbose' , 'template_fmri' , 'size_output'     , 'folder_out' , 'folder_logs' , 'folder_fmri' , 'folder_anat' , 'folder_qc' , 'folder_intermediate' , 'flag_test' , 'psom'   , 'slice_timing' , 'motion_correction' , 'qc_motion_correction_ind' , 't1_preprocess' , 'pve'   , 'anat2func' , 'qc_coregister' , 'corsica' , 'time_filter' , 'resample_vol' , 'smooth_vol' , 'region_growing' };
list_defaults  = { false       , 'cleanup'     , struct() , true           , template_fmri   , 'quality_control' , NaN          , ''            , ''            , ''            , ''          , ''                    , false       , struct() , struct()       , struct()            , struct()                   , struct()        , struct(), struct()    , struct()        , struct()  , struct()      , struct()       , struct()     , struct()         };
opt = psom_struct_defaults(opt,list_fields,list_defaults);
opt.psom.path_logs = [opt.folder_out 'logs' filesep];

if ~isfield(opt.region_growing,'flag_skip') % By default, skip the region growing
    opt.region_growing.flag_skip = true;
end

if ~ismember(opt.size_output,{'quality_control','all'}) % check that the size of outputs is a valid option
    error(sprintf('%s is an unknown option for OPT.SIZE_OUTPUT. Available options are ''quality_control'', ''all''',opt.size_output))
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The pipeline starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = struct();

%% Resample the AAL template 
clear job_in job_out job_opt
[path_t,name_t,ext_t] = niak_fileparts(opt.template_fmri);
job_in.source      = opt.template_fmri;
job_in.target      = opt.template_fmri;
job_out            = [opt.folder_out 'anat' filesep 'template_aal' ext_t];
job_opt            = opt.resample_vol;
job_opt.interpolation    = 'nearest_neighbour';
pipeline = psom_add_job(pipeline,'resample_aal','niak_brick_resample_vol',job_in,job_out,job_opt);

opt.template_fmri = pipeline.resample_aal.files_out;

%% Build individual pipelines
if opt.flag_verbose
    fprintf('Generating pipeline for individual fMRI preprocessing :\n')
end
list_subject = fieldnames(files_in);
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    if opt.flag_verbose
        t1 = clock;
        fprintf('    Adding %s ; ',subject);
    end
    opt_ind = sub_tune(opt,subject); % Tune the pipeline parameters for this subject    
    if ~opt.flag_rand
        opt_ind.rand_seed = double(md5sum(subject,true));
        opt_ind.rand_seed = opt_ind.rand_seed(1:min(length(opt_ind.rand_seed),625));
    end
    pipeline_ind = niak_pipeline_fmri_preprocess_ind(files_in.(subject),opt_ind);

    %% aggregate jobs
    switch opt.granularity
       case 'max'
           pipeline = psom_merge_pipeline(pipeline,pipeline_ind);
       case 'cleanup'
           pipeline = psom_merge_pipeline(pipeline,psom_bundle_cleanup(pipeline_ind,['clean_' subject]));
       case 'subject'
           [pipeline.(['preproc_' subject]),pipeline.(['clean_' subject])] = psom_pipeline2job(pipeline_ind,[opt.psom.path_logs subject]);
       otherwise
           error('%s is not a supported level of granularity for the pipeline',opt.granularity)
    end     
               
    if opt.flag_verbose        
        fprintf('%1.2f sec\n',etime(clock,t1));
    end
end

%% GROUP QC COREGISTER ANAT STEREOLIN 
if opt.flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality control of coregistration in anatomical space (linear stereotaxic space) ; ');
end
clear job_in job_out job_opt
job_in.vol  = cell([length(list_subject) 1]);
job_in.mask = cell([length(list_subject) 1]);
for num_s = 1:length(list_subject)
    if strcmp(opt.granularity,'subject')
        job_in.vol{num_s}  = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['t1_preprocess_' list_subject{num_s}]).files_out.anat_nuc_stereolin;
        job_in.mask{num_s} = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['t1_preprocess_' list_subject{num_s}]).files_out.mask_stereolin;
    else
        job_in.vol{num_s}  = pipeline.(['t1_preprocess_' list_subject{num_s}]).files_out.anat_nuc_stereolin;
        job_in.mask{num_s} = pipeline.(['t1_preprocess_' list_subject{num_s}]).files_out.mask_stereolin;
    end 
end
job_out.mean_vol        = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mean_average_stereolin' ext_f];
job_out.std_vol         = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mean_std_stereolin' ext_f];
job_out.mask_average    = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mask_average_stereolin' ext_f];
job_out.mask_group      = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mask_group_stereolin' ext_f];
job_out.fig_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_fig_qc_coregister_stereolin.pdf'];
job_out.tab_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_tab_qc_coregister_stereolin.csv'];
job_opt                 = opt.qc_coregister;
job_opt.labels_subject  = list_subject;
pipeline = psom_add_job(pipeline,'qc_coregister_group_anat_stereolin','niak_brick_qc_coregister',job_in,job_out,job_opt);
if opt.flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%% GROUP QC COREGISTER ANAT STEREONL 
if opt.flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality control of coregistration in anatomical space (non-linear stereotaxic space) ; ');
end
clear job_in job_out job_opt
job_in.vol  = cell([length(list_subject) 1]);
job_in.mask = cell([length(list_subject) 1]);
for num_s = 1:length(list_subject)
    if strcmp(opt.granularity,'subject')
        job_in.vol{num_s}  = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['t1_preprocess_' list_subject{num_s}]).files_out.anat_nuc_stereonl;
        job_in.mask{num_s} = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['t1_preprocess_' list_subject{num_s}]).files_out.mask_stereonl;
    else
        job_in.vol{num_s}  = pipeline.(['t1_preprocess_' list_subject{num_s}]).files_out.anat_nuc_stereonl;
        job_in.mask{num_s} = pipeline.(['t1_preprocess_' list_subject{num_s}]).files_out.mask_stereonl;
    end 
end
job_out.mean_vol        = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mean_average_stereonl' ext_f];
job_out.std_vol         = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mean_std_stereonl' ext_f];
job_out.mask_average    = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mask_average_stereonl' ext_f];
job_out.mask_group      = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_mask_group_stereonl' ext_f];
job_out.fig_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_fig_qc_coregister_stereonl.pdf'];
job_out.tab_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'anat_tab_qc_coregister_stereonl.csv'];
job_opt                      = opt.qc_coregister;
job_opt.labels_subject        = list_subject;
pipeline = psom_add_job(pipeline,'qc_coregister_group_anat_stereonl','niak_brick_qc_coregister',job_in,job_out,job_opt);
if opt.flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%% GROUP QC COREGISTER FUNC STEREOLIN 
if opt.flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality control of coregistration in functional space (linear stereotaxic space) ; ');
end
clear job_in job_out job_opt
job_in.vol  = cell([length(list_subject) 1]);
job_in.mask = cell([length(list_subject) 1]);
for num_s = 1:length(list_subject)
    if strcmp(opt.granularity,'subject')
        job_in.vol{num_s}  = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['mask_ind_stereolin_' list_subject{num_s}]).files_out{1};
        job_in.mask{num_s} = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['mask_ind_stereolin_' list_subject{num_s}]).files_out{2};
    else
        job_in.vol{num_s}  = pipeline.(['mask_ind_stereolin_' list_subject{num_s}]).files_out{1};
        job_in.mask{num_s} = pipeline.(['mask_ind_stereolin_' list_subject{num_s}]).files_out{2};
    end 
end

job_out.mean_vol        = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mean_average_stereolin' ext_f];
job_out.std_vol         = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mean_std_stereolin' ext_f];
job_out.mask_average    = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mask_average_stereolin' ext_f];
job_out.mask_group      = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mask_group_stereolin' ext_f];
job_out.fig_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_fig_qc_coregister_stereolin.pdf'];
job_out.tab_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_tab_qc_coregister_stereolin.csv'];
job_opt                      = opt.qc_coregister;
job_opt.labels_subject        = list_subject;
pipeline = psom_add_job(pipeline,'qc_coregister_group_func_stereolin','niak_brick_qc_coregister',job_in,job_out,job_opt);
if opt.flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%% GROUP QC COREGISTER FUNC STEREONL 
if opt.flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality control of coregistration in functional space (non-linear stereotaxic space) ; ');
end
clear job_in job_out job_opt
job_in.vol  = cell([length(list_subject) 1]);
job_in.mask = cell([length(list_subject) 1]);
for num_s = 1:length(list_subject)
    if strcmp(opt.granularity,'subject')
        job_in.vol{num_s}  = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['mask_ind_stereonl_' list_subject{num_s}]).files_out{1};
        job_in.mask{num_s} = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['mask_ind_stereonl_' list_subject{num_s}]).files_out{2};
    else
        job_in.vol{num_s}  = pipeline.(['mask_ind_stereonl_' list_subject{num_s}]).files_out{1};
        job_in.mask{num_s} = pipeline.(['mask_ind_stereonl_' list_subject{num_s}]).files_out{2};
    end 
end
job_out.mean_vol        = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mean_average_stereonl' ext_f];
job_out.std_vol         = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mean_std_stereonl' ext_f];
job_out.mask_average    = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mask_average_stereonl' ext_f];
job_out.mask_group      = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_mask_group_stereonl' ext_f];
job_out.fig_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_fig_qc_coregister_stereonl.pdf'];
job_out.tab_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_coregistration' filesep 'func_tab_qc_coregister_stereonl.csv'];
job_opt                      = opt.qc_coregister;
job_opt.labels_subject        = list_subject;
pipeline = psom_add_job(pipeline,'qc_coregister_group_func_stereonl','niak_brick_qc_coregister',job_in,job_out,job_opt);
if opt.flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%% GROUP QC MOTION CORRECTION : PART 1, MOTION PARAMETERS
if opt.flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality control of motion correction (motion parameters) ; ');
end
clear job_in job_out job_opt
for num_s = 1:length(list_subject)
    if strcmp(opt.granularity,'subject')
        job_in.(list_subject{num_s}).tab_coregister_ind    = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['qc_motion_' list_subject{num_s}]).files_out.tab_coregister;
        job_in.(list_subject{num_s}).motion_parameters_ind = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['qc_motion_' list_subject{num_s}]).files_in.motion_parameters;
    else
        job_in.(list_subject{num_s}).tab_coregister_ind    = pipeline.(['qc_motion_' list_subject{num_s}]).files_out.tab_coregister;
        job_in.(list_subject{num_s}).motion_parameters_ind = pipeline.(['qc_motion_' list_subject{num_s}]).files_in.motion_parameters;
    end 
end

job_out.fig_coregister_group  = [opt.folder_out filesep 'quality_control' filesep 'group_motion' filesep 'qc_coregister_between_runs_group.pdf'];
job_out.tab_coregister_group  = [opt.folder_out filesep 'quality_control' filesep 'group_motion' filesep 'qc_coregister_between_runs_group.csv'];
job_out.fig_motion_group      = [opt.folder_out filesep 'quality_control' filesep 'group_motion' filesep 'qc_motion_group.pdf'];
job_out.tab_motion_group      = [opt.folder_out filesep 'quality_control' filesep 'group_motion' filesep 'qc_motion_group.csv'];
job_opt.flag_test                   = true;
pipeline = psom_add_job(pipeline,'qc_param_motion_group','niak_brick_qc_motion_correction_group',job_in,job_out,job_opt);
if opt.flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%% GROUP QC MOTION CORRECTION : PART 2, VARIANCE MAPS
if opt.flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality control of motion correction (ratio of variance maps) ; ');
end
clear job_in job_out job_opt
job_in.vol  = cell([length(fmri_c) 1]);
job_in.mask = pipeline.qc_coregister_group_func_stereonl.files_out.mask_group;
num_e = 0;
for num_s = 1:length(list_subject)
    if strcmp(opt.granularity,'subject')
        tmp = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['resample_qc_var_motion_' list_subject{num_s}]).files_out;
    else
        tmp  = pipeline.(['resample_qc_var_motion_' list_subject{num_s}]).files_out;
    end 
    job_in.vol((num_e+1):(num_e+length(tmp))) = tmp;
    num_e = num_e+length(tmp);
end
job_out.mean_vol        = [opt.folder_out filesep 'quality_control' filesep 'group_motion' filesep 'func_ratio_var_mc_stereonl_mean' ext_f];
job_out.std_vol         = [opt.folder_out filesep 'quality_control' filesep 'group_motion' filesep 'func_ratio_var_mc_stereonl_std'  ext_f];
job_out.fig_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_motion' filesep 'func_ratio_var_mc_stereonl_fit.pdf'];
job_out.tab_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_motion' filesep 'func_ratio_var_mc_stereonl_fit.csv'];
job_opt                 = opt.qc_coregister;
job_opt.labels_subject  = {label.name};
pipeline = psom_add_job(pipeline,'qc_var_motion_group_stereonl','niak_brick_qc_coregister',job_in,job_out,job_opt);
if opt.flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%% GROUP QC CONFOUNDS : regression of slow time drifts, white matter average, motion parameters, global signal and (optional) custom parameters
if opt.flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality control of confound regression (slow time drifts, motion parameters, etc; F-test) ; ');
end
list_maps = { 'qc_wm' , 'qc_slow_drift' , 'qc_motion' , 'qc_gse' , 'qc_custom_param' };
for num_m = 1:length(list_maps)
    clear job_in job_out job_opt
    job_in.vol  = cell([length(fmri_c) 1]);
    job_in.mask = pipeline.qc_coregister_group_func_stereonl.files_out.mask_group;
    num_e = 0;
    if strcmp(list_maps{num_m},'qc_custom_param')&&~isfield(pipeline,['resample_' list_maps{num_m} '_' list_subject{1}])
        continue
    end
    for num_s = 1:length(list_subject)
        if strcmp(opt.granularity,'subject')
            tmp = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['resample_' list_maps{num_m} '_' list_subject{num_s}]).files_out;
        else
            tmp  = pipeline.(['resample_' list_maps{num_m} '_' list_subject{num_s}]).files_out;
        end 
        job_in.vol((num_e+1):(num_e+length(tmp))) = tmp;
        num_e = num_e+length(tmp);
    end
    job_out.mean_vol        = [opt.folder_out filesep 'quality_control' filesep 'group_confounds' filesep 'func_' list_maps{num_m} '_stereonl_mean' ext_f];
    job_out.std_vol         = [opt.folder_out filesep 'quality_control' filesep 'group_confounds' filesep 'func_' list_maps{num_m} '_stereonl_std'  ext_f];
    job_out.fig_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_confounds' filesep 'func_' list_maps{num_m} '_stereonl_fit.pdf'];
    job_out.tab_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_confounds' filesep 'func_' list_maps{num_m} '_stereonl_fit.csv'];
    job_opt                 = opt.qc_coregister;
    job_opt.labels_subject  = {label.name};
    pipeline = psom_add_job(pipeline,[list_maps{num_m} '_group_stereonl'],'niak_brick_qc_coregister',job_in,job_out,job_opt);
end
if opt.flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%% GROUP QC CORSICA
if opt.flag_verbose
    t1 = clock;
    fprintf('Adding group-level quality control of CORSICA (ratio of variance maps) ; ');
end
clear job_in job_out job_opt
job_in.vol  = cell([length(fmri_c) 1]);
job_in.mask = pipeline.qc_coregister_group_func_stereonl.files_out.mask_group;
num_e = 0;
for num_s = 1:length(list_subject)
    if strcmp(opt.granularity,'subject')
        tmp = pipeline.(['preproc_' list_subject{num_s}]).opt.pipeline.(['resample_qc_corsica_var_' list_subject{num_s}]).files_out;
    else
        tmp  = pipeline.(['resample_qc_corsica_var_' list_subject{num_s}]).files_out;
    end 
    job_in.vol((num_e+1):(num_e+length(tmp))) = tmp;
    num_e = num_e+length(tmp);
end
job_out.mean_vol        = [opt.folder_out filesep 'quality_control' filesep 'group_corsica' filesep 'func_ratio_var_corsica_stereonl_mean' ext_f];
job_out.std_vol         = [opt.folder_out filesep 'quality_control' filesep 'group_corsica' filesep 'func_ratio_var_corsica_stereonl_std'  ext_f];
job_out.fig_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_corsica' filesep 'func_ratio_var_corsica_stereonl_fit.pdf'];
job_out.tab_coregister  = [opt.folder_out filesep 'quality_control' filesep 'group_corsica' filesep 'func_ratio_var_corsica_stereonl_fit.csv'];
job_opt                 = opt.qc_coregister;
job_opt.labels_subject  = {label.name};
pipeline = psom_add_job(pipeline,'qc_corsica_var_group_stereonl','niak_brick_qc_coregister',job_in,job_out,job_opt);
if opt.flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%% Region Growing 
if ~opt.region_growing.flag_skip
    if opt.flag_verbose
        t1 = clock;
        fprintf('Generating pipeline for the region growing ; ');
    end
    clear job_in job_out job_opt
    job_opt            = rmfield(opt.region_growing,'flag_skip');
    job_opt.folder_out = [opt.folder_out filesep 'region_growing' filesep];
    job_opt.flag_test  = true;
    for num_e = 1:length(fmri_c)
        if strcmp(opt.granularity,'subject')
            job_in.fmri.(label(num_e).subject).(label(num_e).session).(label(num_e).run) = pipeline.(['preproc_' label(num_e).subject]).opt.pipeline.(['smooth_' label(num_e).name]).files_out;
        else
            job_in.fmri.(label(num_e).subject).(label(num_e).session).(label(num_e).run) = pipeline.(['smooth_' label(num_e).name]).files_out;
        end
    end
    job_in.areas = pipeline.resample_aal.files_out;
    job_in.mask  = pipeline.qc_coregister_group_func_stereonl.files_out.mask_group;
    if strcmp(opt.granularity,'subject')
        [pipeline.region_growing,pipeline.clean_region_growing] = psom_pipeline2job(niak_pipeline_region_growing(job_in,job_opt),[opt.psom.path_logs 'region_growing']);
    else
        pipeline = psom_merge_pipeline(pipeline,niak_pipeline_region_growing(job_in,job_opt));
    end

    if opt.flag_verbose        
        fprintf('%1.2f sec\n',etime(clock,t1));
    end
end

%% Run the pipeline 
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end

%%%%%%%%%%%%%%%%%%
%% SUBFUNCTIONS %%
%%%%%%%%%%%%%%%%%%

function files_in = sub_check_format(files_in)
%% Checking that FILES_IN is in the correct format

if ~isstruct(files_in)

    error('FILES_IN should be a structure!')   

else   

    list_subject = fieldnames(files_in);
    for num_s = 1:length(list_subject)

        subject = list_subject{num_s};        
        
        if ~isstruct(files_in.(subject))
            error('FILES_IN.%s should be a structure!',upper(subject));
        end
        
        if ~isfield(files_in.(subject),'fmri')
            error('I could not find the field FILES_IN.%s.FMRI!',upper(subject));
        end
                
        list_session = fieldnames(files_in.(subject).fmri);
        
        for num_c = 1:length(list_session)
            session = list_session{num_c};
            if ~iscellstr(files_in.(subject).fmri.(session))&&~isstruct(files_in.(subject).fmri.(session))
                error('FILES_IN.%s.fmri.%s should be a struture or a cell of strings!',upper(subject),upper(session));
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

function opt = sub_backwards(opt)
%% Fiddling with OPT for backwards compatibility

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

function opt_ind = sub_tune(opt,subject)
%% Tune the pre-processing parameters for a subject (or group of subjects)
opt_ind = opt;
if isfield(opt.tune,'subject')
    for num_e = 1:length(opt.tune)
        if ~isfield(opt.tune(num_e),'type')||isempty(opt.tune(num_e).type)
            opt.tune(num_e).type = 'exact';
        end
        switch opt.tune(num_e).type
            case 'exact'
                if strcmp(opt.tune(num_e).subject,subject)
                    opt_ind = psom_merge_pipeline(opt_ind,opt.tune(num_e).param);
                end
            case 'regexp'
                if any(regexp(subject,opt.tune(num_e).subject))
                    opt_ind = psom_merge_pipeline(opt_ind,opt.tune(num_e).param);
                end  
        end
    end
end
opt_ind = rmfield(opt_ind,{'tune','flag_verbose','granularity','flag_rand'});    
opt_ind.subject = subject;    
opt_ind.flag_test = true;
