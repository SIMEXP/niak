function [pipeline,opt] = niak_pipeline_fmri_preprocess_ind(files_in,opt)
% Run a pipeline to preprocess individual fMRI datasets. 
% The flowchart of the pipeline is flexible (steps can be skipped using 
% flags), and the analysis can be further customized by changing the 
% parameters of any step.
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
%   FMRI.<SESSION>.<RUN>
%       (string) a file name of an fMRI dataset. All datasets in <SESSIONS>
%       are acquired in the same session (small displacements). 
%       The field names <SESSION> and <RUN> can be any arbitrary string.
%       Note that FILES_IN.<SESSION> can also be a cell of strings, in which 
%       case the names of the runs will be default strings 'run1', 'run2', etc
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
%   REGRESS_CONFOUNDS (optional)
%       Take a .mat file with the variable 'covar'(TxK). the preprossesing
%       will regress the confounds specified in the file.
%
% OPT   
%   (structure) with the following fields : 
%
%   SUBJECT
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
%       (string, default '<~niak>/template/roi_aal_3mm.mnc.gz') a volume that
%       will be used to resample the fMRI datasets. 
%
%   TEMPLATE_T1
%       (string, default 'mni_icbm152_nlin_sym_09a') the template that 
%       will be used as a target for the coregistration of the T1 image. 
%       Available choices: 
%         'mni_icbm152_nlin_asym_09a' : an adult symmetric template 
%             (18.5 - 43 y.o., 40 iterations of non-linear fit). 
%         'mni_icbm152_nlin_sym_09a' : an adult asymmetric template 
%             (18.5 - 43 y.o., 20 iterations of non-linear fit). 
%
%   TARGET_SPACE
%       (string, default 'stereonl') which space will be used to resample
%       the functional datasets. Available options:
%          'stereolin' : stereotaxic space using a linear transformation. 
%          'stereonl' : stereotaxic space using a non-linear transformation.
%
%   RAND_SEED
%       (scalar, default []) The specified value is used to seed the random
%       number generator with PSOM_SET_RAND_SEED for each job. If left empty,
%       the generator is not initialized by the bricks. As PSOM features an 
%       initialization based on the clock, the results will be slightly 
%       different due to random variations in bootstrap sampling if the 
%       pipeline is executed twice.
%
%   FOLDER_OUT
%       (string) where to write the default outputs.
%
%   FOLDER_LOGS
%       (string, default FOLDER_OUT/logs/) where to write the logs of the
%       pipeline.
%
%   FOLDER_FMRI
%       (string, default FOLDER_OUT/fmri/) where to write the preprocessed 
%       fMRI volumes.
%
%   FOLDER_ANAT
%       (string, default FOLDER_OUT/anat/) where to write the 
%       preprocessed anatomical volumes as well as the results related to 
%       T1-T2 coregistration.
%
%   FOLDER_QC
%       (string, default FOLDER_OUT/quality_control/) where to write the 
%       results of the quality control.
%
%   FOLDER_INTERMEDIATE
%       (string, default FOLDER_OUT/intermediate/) where to write the 
%       intermediate results.
%
%   FLAG_TEST
%       (boolean, default false) If FLAG_TEST is true, the pipeline will 
%       just produce a pipeline structure, and will not actually process 
%       the data. Otherwise, PSOM_RUN_PIPELINE will be used to process the 
%       data.
%
%   FLAG_VERBOSE
%       (boolean, default 0) if the flag is 1, then the function
%       prints some infos during the processing.
%
%   PSOM
%       (structure) the options of the pipeline manager. See the OPT 
%       argument of PSOM_RUN_PIPELINE. Default values can be used here.
%       Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
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
%       anatomical scan. Additional option:
%
%       FLAG_SKIP
%           (boolean, default false) if the flag is true, do not extract 
%           PVE maps.
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
%       SUPPRESS_VOL 
%           (integer, default 0) the number of volumes that are suppressed 
%           at the begining of the time series. This is a good stage to get 
%           rid of "dummy scans" necessary to reach signal stabilization 
%           (that takes about 10 seconds, usually 3 to 5 volumes depending 
%           on the TR). Note that most brain imaging centers now 
%           automatically discard dummy scans.
%
%       FLAG_SKIP
%           (boolean,  default 0) If FLAG_SKIP == 1, the brick is not doing 
%           anything, just copying the input to the output. Some 
%           simplifications will still be made in the header, see the
%           FLAG_REGULAR and FLAG_HISTORY flags.
%
%   MOTION 
%       (structure) options of NIAK_PIPELINE_MOTION 
%
%       SESSION_REF
%           (string, default first session) name of the session of reference. 
%           By default, it is the first field found in FILES_IN. Use the
%           session corresponding to the acqusition of the T1 scan.
%
%   QC_MOTION_CORRECTION_IND
%       (structure) options of NIAK_BRICK_QC_MOTION_CORRECTION_IND 
%       (Individual brain mask in fMRI data, measures of quality for 
%       motion correction).
%
%   RESAMPLE_VOL 
%       (structure) options of NIAK_BRICK_RESAMPLE_VOL (spatial resampling 
%       in the stereotaxic space).
%
%       INTERPOLATION 
%           (string, default 'trilinear') the spatial interpolation method. 
%           Available options : 'trilinear', 'tricubic', 
%           'nearest_neighbour','sinc'.
%
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
%   REGRESS_CONFOUNDS
%       (structure) Options of NIAK_BRICK_REGRESS_CONFOUNDS.
%       FOLDER_OUT
%           (string, default folder of FMRI) the folder where the default outputs
%           are generated.
%
%       FLAG_SLOW
%           (boolean, default true) turn on/off the correction of slow time drifts
%
%       FLAG_GSC 
%           (boolean, default true) turn on/off global signal correction
%
%       FLAG_SCRUBBING
%           (boolean, default true) turn on/off the "scrubbing" of volumes with 
%           excessive motion.
%
%       FLAG_COMPCOR
%           (boolean, default false) turn on/off COMPCOR 
%
%       FLAG_MOTION_PARAMS 
%           (boolean, default false) turn on/off the removal of the 6 motion 
%           parameters + the square of 6 motion parameters.
%
%       FLAG_WM 
%           (boolean, default true) turn on/off the removal of the average 
%           white matter signal
%
%       FLAG_VENT
%          (boolean, default true) turn on/off the removal of the average 
%          signal in the lateral ventricles.
%
%       PCT_VAR_EXPLAINED 
%           (boolean, default 0.95) the % of variance explained by the selected 
%           PCA components when reducing the dimensionality of motion parameters.
%
%       COMPCOR
%           (structure, default see NIAK_COMPCOR) the OPT argument of NIAK_COMPCOR.
% 
%       FLAG_PCA_MOTION 
%           (boolean, default true) turn on/off the PCA reduction of motion 
%           parameters.
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
%   CIVET (structure)
%       If this field is present, NIAK will not process the T1 image, but
%       will rather grab the (previously generated) results of the CIVET 
%       pipeline, i.e. copy/rename them. The following fields need
%       to be specified :
%               
%       FOLDER 
%          (string) The path of a folder with CIVET results. The field 
%          ANAT will be ignored in this case.
%
%       ID 
%          (string) the ID associated with SUBJECT in the CIVET results. 
%
%       PREFIX 
%          (string) The prefix used for the database.
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
%       1.  Slice timing correction
%           See NIAK_BRICK_SLICE_TIMING and OPT.SLICE_TIMING
%       2.  Motion estimation (within- and between-run for each label).
%           See NIAK_PIPELINE_MOTION and OPT.MOTION
%       3.  Quality control for motion correction.
%           See NIAK_BRICK_QC_MOTION_CORRECTION and
%           OPT.QC_MOTION_CORRECTION
%       4.  Linear and non-linear spatial normalization of the anatomical 
%           image (and many more anatomical stuff such as brain masking and
%           CSF/GM/WM classification)
%           See NIAK_BRICK_T1_PREPROCESS and OPT.T1_PREPROCESS
%           See NIAK_BRICK_PVE and OPT.PVE
%       5.  Coregistration of the anatomical volume with the target volume of 
%           the motion estimation
%           See NIAK_BRICK_ANAT2FUNC and OPT.ANAT2FUNC
%       6.  Concatenation of the T2-to-T1 and T1-to-stereotaxic-nl
%           transformations.
%           See NIAK_BRICK_CONCAT_TRANSF, no option there.
%       7.  Resampling of the functional data in the stereotaxic space.
%           See NIAK_BRICK_RESAMPLE_VOL and OPT.RESAMPLE_VOL
%       8.  Quality control for 7 (includes generation of average image and mask,
%           as well as metrics of coregistration between runs for motion).
%           See NIAK_BRICK_QC_COREGISTER
%       9.  Estimation of a temporal model of slow time drifts.
%           See NIAK_BRICK_TIME_FILTER
%      10.  Regression of confounds (slow time drifts, motion parameters, 
%           WM average, COMPCOR, global signal) preceeded by scrubbing of time frames 
%           with an excessive motion.
%           See NIAK_BRICK_REGRESS_CONFOUNDS and OPT.REGRESS_CONFOUNDS
%      11.  Correction of physiological noise.
%           See NIAK_PIPELINE_CORSICA and OPT.CORSICA
%           Also, see NIAK_BRICK_MASK_CORSICA (no option there)
%      12.  Spatial smoothing.
%           See NIAK_BRICK_SMOOTH_VOL and OPT.SMOOTH_VOL
%
% NOTE 2:
%   The physiological & motion noise correction CORSICA is changing the
%   degrees of freedom of the data. It is usullay negligible for 
%   intra-label analysis, and will have no impact on the between-label 
%   variance estimate (except those should be less noisy). The slice timing 
%   and scrubbing of time series also changes the sampling grid in time. 
%   These effects have to be taken into account in the linear model 
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
% operationnelle, Universite de Montreal, 2010-2012.
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
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_FMRI_PREPROCESS_IND(FILES_IN,OPT).\n Type ''help niak_pipeline_fmri_preprocess_ind'' for more info.')
end

%% FILES_IN
files_in = sub_check_format(files_in); % Checking that FILES_IN is in the correct format

%% OPT
file_template = [gb_niak_path_template filesep 'roi_aal_3mm.mnc.gz'];
list_fields    = { 'civet'           , 'target_space' , 'rand_seed' , 'subject' , 'template_fmri' ,  'template_t1'              , 'size_output'     , 'folder_out' , 'folder_logs' , 'folder_fmri' , 'folder_anat' , 'folder_qc' , 'folder_intermediate' , 'flag_test' , 'flag_verbose' , 'psom'   , 'slice_timing' , 'motion' , 'qc_motion_correction_ind' , 't1_preprocess' , 'pve'    , 'anat2func' , 'qc_coregister' , 'corsica' , 'time_filter' , 'resample_vol' , 'smooth_vol' , 'region_growing' , 'regress_confounds'};
list_defaults  = { 'gb_niak_omitted' , 'stereonl'     , []          , NaN       , file_template   ,  'mni_icbm152_nlin_sym_09a' , 'quality_control' , NaN          , ''            , ''            , ''            , ''          , ''                    , false       , false          , struct() , struct()       , struct() , struct()                   , struct()        , struct() , struct()    , struct()        , struct()  , struct()      , struct()       , struct()     , struct()         , struct()           };
opt = psom_struct_defaults(opt,list_fields,list_defaults);
subject = opt.subject;

if ~ischar(opt.civet)
    list_fields   = { 'folder' , 'id' , 'prefix' };
    list_defaults = { NaN      , NaN  , NaN      }; 
    opt.civet = psom_struct_defaults(opt.civet,list_fields,list_defaults);
end

if ~ismember(opt.size_output,{'quality_control','all'}) % check that the size of outputs is a valid option
    error(sprintf('%s is an unknown option for OPT.SIZE_OUTPUT. Available options are ''minimum'', ''quality_control'', ''all''',opt.size_output))
end

if isempty(opt.folder_logs)
    opt.folder_logs = [opt.folder_out 'logs'];
end

if isempty(opt.folder_fmri)
    opt.folder_fmri = [opt.folder_out 'fmri'];
end

if isempty(opt.folder_anat)
    opt.folder_anat = [opt.folder_out 'anat' filesep subject filesep];
end

if isempty(opt.folder_qc)
    opt.folder_qc = [opt.folder_out 'quality_control' filesep subject filesep];
end

if isempty(opt.folder_intermediate)
    opt.folder_intermediate = [opt.folder_out 'intermediate' filesep subject filesep];
end

if ~ismember(opt.template_t1,{'mni_icbm152_nlin_sym_09a','mni_icbm152_nlin_asym_09a'})
    error('%s is an unkown T1 template space',opt.template_t1)
end

opt.psom.path_logs = opt.folder_logs;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The pipeline starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialization of the pipeline 
pipeline = struct([]);
tmp.(subject) = files_in.fmri;
[fmri,label] = niak_fmri2cell(tmp);
fmri_s = niak_fmri2struct(fmri,label);
[path_f,name_f,ext_f] = niak_fileparts(fmri{1});

%% T1 preprocess
if ischar(opt.civet)
    if opt.flag_verbose
        t1 = clock;
        fprintf('T1 preprocess (');
    end
    clear job_in job_out job_opt
    job_in                          = files_in.anat;
    job_out.transformation_lin      = [opt.folder_anat 'transf_' subject '_nativet1_to_stereolin.xfm'];
    job_out.transformation_nl       = [opt.folder_anat 'transf_' subject '_stereolin_to_stereonl.xfm'];
    job_out.transformation_nl_grid  = [opt.folder_anat 'transf_' subject '_stereolin_to_stereonl_grid.mnc'];
    job_out.anat_nuc                = [opt.folder_anat 'anat_'   subject '_nuc_nativet1' ext_f];
    job_out.anat_nuc_stereolin      = [opt.folder_anat 'anat_'   subject '_nuc_stereolin' ext_f];
    job_out.anat_nuc_stereonl       = [opt.folder_anat 'anat_'   subject '_nuc_stereonl' ext_f];
    job_out.mask_stereolin          = [opt.folder_anat 'anat_'   subject '_mask_stereolin' ext_f];
    job_out.mask_stereonl           = [opt.folder_anat 'anat_'   subject '_mask_stereonl' ext_f];
    job_out.classify                = [opt.folder_anat 'anat_'   subject '_classify_stereolin' ext_f];
    job_opt                         = opt.t1_preprocess;
    job_opt.template_t1             = opt.template_t1;
    job_opt.folder_out              = opt.folder_anat;
    pipeline = psom_add_job(pipeline,['t1_preprocess_' subject],'niak_brick_t1_preprocess',job_in,job_out,job_opt);
    if opt.flag_verbose        
        fprintf('%1.2f sec) - ',etime(clock,t1));
    end
    
    %% PVE
    if opt.flag_verbose
        t1 = clock;
        fprintf('PVE (');
    end
    clear job_in job_out job_opt
    job_in.vol          = pipeline.(['t1_preprocess_' subject]).files_out.anat_nuc_stereolin;
    job_in.mask         = pipeline.(['t1_preprocess_' subject]).files_out.mask_stereolin;
    job_in.segmentation = pipeline.(['t1_preprocess_' subject]).files_out.classify;    
    job_out.pve_wm      = [opt.folder_anat 'anat_' subject '_pve_wm_stereolin'   ext_f];
    job_out.pve_gm      = [opt.folder_anat 'anat_' subject '_pve_gm_stereolin'   ext_f];
    job_out.pve_csf     = [opt.folder_anat 'anat_' subject '_pve_csf_stereolin'  ext_f];
    job_out.pve_disc    = [opt.folder_anat 'anat_' subject '_pve_disc_stereolin' ext_f];
    job_opt             = opt.pve;
    job_opt.rand_seed   = opt.rand_seed;
    if isfield(job_opt,'flag_skip')
        job_opt = rmfield(job_opt,'flag_skip');
    end
    if ~isfield(opt.pve,'flag_skip')||~opt.pve.flag_skip
        pipeline = psom_add_job(pipeline,['pve_',subject],'niak_brick_pve',job_in,job_out,job_opt);
    end
    if opt.flag_verbose        
        fprintf('%1.2f sec) - ',etime(clock,t1));
    end
else
    % CIVET results have been specified. Copy and rename them
    if opt.flag_verbose
        t1 = clock;
        fprintf('CIVET (');
    end
    clear job_in job_out job_opt
    job_in.civet                    = struct;
    job_out.transformation_lin      = [opt.folder_anat 'transf_' subject '_nativet1_to_stereolin.xfm'];
    job_out.transformation_nl       = [opt.folder_anat 'transf_' subject '_stereolin_to_stereonl.xfm'];
    job_out.transformation_nl_grid  = [opt.folder_anat 'transf_' subject '_stereolin_to_stereonl_grid.mnc'];
    job_out.anat_nuc                = [opt.folder_anat 'anat_'   subject '_nuc_nativet1' ext_f];
    job_out.anat_nuc_stereolin     = [opt.folder_anat 'anat_'   subject '_nuc_stereolin' ext_f];
    job_out.anat_nuc_stereonl      = [opt.folder_anat 'anat_'   subject '_nuc_stereonl' ext_f]; 
    job_out.mask_stereolin          = [opt.folder_anat 'anat_'   subject '_mask_stereolin' ext_f];
    job_out.mask_stereonl           = [opt.folder_anat 'anat_'   subject '_mask_stereonl' ext_f];
    job_out.classify                = [opt.folder_anat 'anat_'   subject '_classify_stereolin' ext_f];
    job_out.pve_wm                  = [opt.folder_anat 'anat_' subject '_pve_wm_stereolin'   ext_f];
    job_out.pve_gm                  = [opt.folder_anat 'anat_' subject '_pve_gm_stereolin'   ext_f];
    job_out.pve_csf                 = [opt.folder_anat 'anat_' subject '_pve_csf_stereolin'  ext_f];
    job_out.verify                  = [opt.folder_anat 'anat_' subject '_verify.png'];
    job_opt.civet                   = opt.civet;    
    job_opt.folder_out              = opt.folder_anat;
    pipeline = psom_add_job(pipeline,['t1_preprocess_' subject],'niak_brick_civet',job_in,job_out,job_opt);
    if opt.flag_verbose        
        fprintf('%1.2f sec) - ',etime(clock,t1));
    end
end

%% Slice-timing correction
if opt.flag_verbose
    t1 = clock;
    fprintf('slice timing (');
end
for num_e = 1:length(fmri)
    clear job_in job_out job_opt
    job_in             = fmri{num_e};        
    job_opt            = opt.slice_timing;
    job_opt.folder_out = [opt.folder_intermediate 'slice_timing' filesep];
    job_out            = [job_opt.folder_out filesep 'fmri_' label(num_e).name '_a' ext_f];        
    if any(strfind(label(num_e).run,'_'))
        error('The labels of runs should not contain any underscore. I cannot process the run "%s"',label(num_e).run)
    end
    pipeline = psom_add_job(pipeline,['slice_timing_' label(num_e).name],'niak_brick_slice_timing',job_in,job_out,job_opt);    
    if strcmp(opt.size_output,'quality_control') % Clean-up
        pipeline = psom_add_clean(pipeline,['clean_slice_timing_' label(num_e).name],job_out);        
    end
end 
if opt.flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%% Motion correction
if opt.flag_verbose
    t1 = clock;
    fprintf('motion correction (');
end
clear job_opt job_in job_out
job_in = cell(length(fmri),1);
for num_e = 1:length(fmri)
    job_in{num_e} = pipeline.(['slice_timing_' label(num_e).name]).files_out;
end
job_in = niak_fmri2struct(job_in,label);
job_in = job_in.(subject);
job_opt             = opt.motion;
job_opt.subject     = subject;
job_opt.flag_test   = true;
job_opt.folder_out  = [opt.folder_intermediate 'motion_correction',filesep];
[pipeline_mc,job_opt,files_motion] = niak_pipeline_motion(job_in,job_opt);
session_ref = job_opt.session_ref;
list_run_tmp = fieldnames(fmri_s.(subject).(session_ref));
run_ref = list_run_tmp{job_opt.run_ref};
pipeline = psom_merge_pipeline(pipeline,pipeline_mc);

%% T1-T2 coregistration
if opt.flag_verbose
    t1 = clock;
    fprintf('T1-T2 coregistration (');
end
clear job_in job_out job_opt
job_in.func                   = pipeline.(['motion_target_' subject '_' session_ref '_' run_ref]).files_out;
job_in.anat                   = pipeline.(['t1_preprocess_' subject]).files_out.anat_nuc_stereolin;
job_in.mask_anat              = pipeline.(['t1_preprocess_' subject]).files_out.mask_stereolin;
job_in.transformation_init    = pipeline.(['t1_preprocess_' subject]).files_out.transformation_lin;
job_out.transformation        = [opt.folder_anat 'transf_' subject '_nativefunc_to_stereolin.xfm'];
job_out.anat_hires            = [opt.folder_anat 'anat_' subject '_nativefunc_hires' ext_f];
job_out.anat_lowres           = [opt.folder_anat 'anat_' subject '_nativefunc_lowres' ext_f];
job_opt                           = opt.anat2func;
job_opt.flag_invert_transf_init   = true;
job_opt.flag_invert_transf_output = true;
pipeline = psom_add_job(pipeline,['anat2func_',subject],'niak_brick_anat2func',job_in,job_out,job_opt);

%% Concatenate T2-to-T1_stereo_lin and T1_stereo_lin-to-stereotaxic-nl spatial transformation
clear job_in job_out job_opt
job_in{1}         = pipeline.(['anat2func_' subject]).files_out.transformation;
job_in{2}         = pipeline.(['t1_preprocess_',subject]).files_out.transformation_nl;
job_out           = [opt.folder_anat 'transf_' subject '_nativefunc_to_stereonl.xfm'];
job_opt.flag_test = 0;
pipeline = psom_add_job(pipeline,['concat_transf_nl_' subject],'niak_brick_concat_transf',job_in,job_out,job_opt,false);    
if opt.flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%% Spatial resampling of functional datasets in stereotaxic space
if opt.flag_verbose
    t1 = clock;
    fprintf('resampling (');
end
for num_e = 1:length(fmri);
    clear job_in job_out job_opt     
    job_in.source = pipeline.(['slice_timing_' label(num_e).name]).files_out;
    job_in.target = opt.template_fmri;
    job_in.transformation = files_motion.final.(label(num_e).subject).(label(num_e).session).(label(num_e).run);
    switch opt.target_space
        case 'stereolin'
            job_in.transformation_stereo = pipeline.(['anat2func_' subject]).files_out.transformation; 
        case 'stereonl'
            job_in.transformation_stereo = pipeline.(['concat_transf_nl_' subject]).files_out; 
        otherwise
            error('%s is an unknown target space (see OPT.TARGET_SPACE)',opt.target_space)
    end
    job_out = '';            
    job_opt = opt.resample_vol;
    job_opt.folder_out = [opt.folder_intermediate 'resample' filesep];
    pipeline = psom_add_job(pipeline,['resample_' label(num_e).name],'niak_brick_resample_vol',job_in,job_out,job_opt);
    if strcmp(opt.size_output,'quality_control')
        pipeline = psom_add_clean(pipeline,['clean_resample_' label(num_e).name],pipeline.(['resample_' label(num_e).name]).files_out);
    end
end
if opt.flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%% QC motion correction 
clear job_in job_out job_opt
job_in.vol = cell(length(fmri),1);
for num_e = 1:length(fmri)
    job_in.vol{num_e} = pipeline.(['resample_' label(num_e).name]).files_out;
end
job_in.motion_parameters       = psom_files2cell(files_motion.within_run);
job_out.fig_motion_parameters  = [opt.folder_qc 'motion_correction' filesep 'fig_motion_within_run.pdf'];
job_out.mask_average           = [opt.folder_qc 'motion_correction' filesep 'func_' subject '_mask_average_' opt.target_space ext_f];
job_out.mask_group             = [opt.folder_anat 'func_' subject '_mask_' opt.target_space ext_f];
job_out.mean_vol               = [opt.folder_anat 'func_' subject '_mean_' opt.target_space ext_f];
job_out.std_vol                = [opt.folder_anat 'func_' subject '_std_' opt.target_space ext_f];
job_out.fig_coregister         = [opt.folder_qc 'motion_correction' filesep 'fig_coregister_motion.pdf'];
job_out.tab_coregister         = [opt.folder_qc 'motion_correction' filesep 'tab_coregister_motion.csv'];
job_opt                        = opt.qc_motion_correction_ind;
[tmp1,job_opt.labels_vol]      = niak_fileparts(job_in.vol);
pipeline = psom_add_job(pipeline,['qc_motion_' subject],'niak_brick_qc_motion_correction_ind',job_in,job_out,job_opt);  
if opt.flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%% CORSICA masks
if opt.flag_verbose
    t1 = clock;
    fprintf('corsica (');
end
clear job_in job_out job_opt 
job_in.mask_vent_stereo   = [gb_niak_path_niak 'template' filesep 'roi_ventricle.mnc.gz'];
switch opt.template_t1
    case 'mni_icbm152_nlin_sym_09a'
        job_in.mask_wm_stereo     = [gb_niak_path_niak 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_sym_09a_mask_pure_wm_2mm.mnc.gz'];
    case 'mni_icbm152_nlin_asym_09a'
        job_in.mask_wm_stereo     = [gb_niak_path_niak 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_asym_09a_mask_pure_wm_2mm.mnc.gz'];
end
job_in.mask_stem_stereo   = [gb_niak_path_niak 'template' filesep 'roi_stem.mnc.gz'];
job_in.mask_brain         = pipeline.(['qc_motion_' subject]).files_out.mask_group;
job_in.aal                = [gb_niak_path_niak 'template' filesep 'roi_aal.mnc.gz'];
job_in.functional_space   = pipeline.(['qc_motion_' subject]).files_out.mask_group;
job_in.transformation_nl  = pipeline.(['t1_preprocess_',subject]).files_out.transformation_nl;
job_in.segmentation       = pipeline.(['t1_preprocess_' subject]).files_out.classify;
job_out.mask_vent_ind     = [opt.folder_qc 'corsica' filesep subject '_mask_vent_func' opt.target_space ext_f];
job_out.mask_stem_ind     = [opt.folder_qc 'corsica' filesep subject '_mask_stem_func' opt.target_space ext_f];
job_out.white_matter_ind  = [opt.folder_qc 'corsica' filesep subject '_mask_wm_func' opt.target_space ext_f];
job_opt.target_space = opt.target_space;
job_opt.flag_test = false;
pipeline = psom_add_job(pipeline,['mask_corsica_' subject],'niak_brick_mask_corsica',job_in,job_out,job_opt);

%% temporal filtering 
if opt.flag_verbose
    t1 = clock;
    fprintf('time filter (');
end
for num_e = 1:length(fmri)
    clear job_opt job_in job_out
    job_in = pipeline.(['resample_' label(num_e).name]).files_out;
    job_out.dc_high  = '';
    job_out.dc_low   = '';                                    
    job_opt            = opt.time_filter;
    job_opt.folder_out = [opt.folder_intermediate 'time_filter' filesep];
    pipeline = psom_add_job(pipeline,['time_filter_' label(num_e).name],'niak_brick_time_filter',job_in,job_out,job_opt);    
    if strcmp(opt.size_output,'quality_control')
      pipeline = psom_add_clean(pipeline,['clean_time_filter_' label(num_e).name],pipeline.(['time_filter_' label(num_e).name]).files_out.filtered_data);
    end    
end
if opt.flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%% Regress Confounds 
if opt.flag_verbose
    t1 = clock;
    fprintf('regress confounds (');
end
for num_e = 1:length(fmri)
    clear job_opt job_in job_out
    job_in.fmri         = pipeline.(['resample_' label(num_e).name]).files_out;
    job_in.dc_low       = pipeline.(['time_filter_' label(num_e).name]).files_out.dc_low;
    job_in.dc_high      = pipeline.(['time_filter_' label(num_e).name]).files_out.dc_high;
    job_in.mask_vent    = pipeline.(['mask_corsica_' subject]).files_out.mask_vent_ind;
    job_in.mask_wm      = pipeline.(['mask_corsica_' subject]).files_out.white_matter_ind;
    job_in.mask_brain   = pipeline.(['qc_motion_' subject]).files_out.mask_group;
    job_in.motion_param = pipeline.(['motion_parameters_' label(num_e).name]).files_out;
    job_in.custom_param = files_in.custom_confounds;

    job_opt = opt.regress_confounds;
    job_opt.folder_out     = [opt.folder_intermediate 'regress_confounds' filesep];
    job_out.filtered_data  = [job_opt.folder_out filesep 'fmri_' label(num_e).name '_cor' ext_f]; 
    job_out.confounds      = [job_opt.folder_out filesep 'confounds_gs_' label(num_e).name '_cor.mat']; 
    job_out.scrubbing      = [job_opt.folder_out filesep 'scrubbing_' label(num_e).name '.mat'];
    job_out.compcor_mask   = [job_opt.folder_out filesep 'compcor_mask_' label(num_e).name ext_f]; 
    job_out.qc_wm          = [opt.folder_qc filesep 'regress_confounds' filesep label(num_e).name '_qc_wm_func' opt.target_space ext_f]; 
    job_out.qc_vent        = [opt.folder_qc filesep 'regress_confounds' filesep label(num_e).name '_qc_vent_func' opt.target_space ext_f]; 
    job_out.qc_slow_drift  = [opt.folder_qc filesep 'regress_confounds' filesep label(num_e).name '_qc_slow_drift_func' opt.target_space ext_f]; 
    job_out.qc_high        = [opt.folder_qc filesep 'regress_confounds' filesep label(num_e).name '_qc_high_func' opt.target_space ext_f];  
    job_out.qc_motion      = [opt.folder_qc filesep 'regress_confounds' filesep label(num_e).name '_qc_motion_func' opt.target_space ext_f]; 
    job_out.qc_compcor     = [opt.folder_qc filesep 'regress_confounds' filesep label(num_e).name '_qc_compcor_func' opt.target_space ext_f]; 
    job_out.qc_gse         = [opt.folder_qc filesep 'regress_confounds' filesep label(num_e).name '_qc_gse_func' opt.target_space ext_f]; 
    if ~strcmp(job_in.custom_param,'gb_niak_omitted')
        job_out.qc_custom_param = [opt.folder_qc filesep 'regress_confounds' filesep label(num_e).name '_qc_gse_func' opt.target_space ext_f]; 
    end
    pipeline = psom_add_job(pipeline,['confounds_' label(num_e).name],'niak_brick_regress_confounds',job_in,job_out,job_opt);    
    if strcmp(opt.size_output,'quality_control')
        pipeline = psom_add_clean(pipeline,['clean_confounds_' label(num_e).name],pipeline.(['confounds_' label(num_e).name]).files_out.filtered_data);
    end    
end
if opt.flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%% CORSICA
clear job_in job_out job_opt 
job_in.(subject).fmri = cell(length(fmri),1);
for num_e = 1:length(fmri)
    job_in.(subject).fmri{num_e} = pipeline.(['confounds_' label(num_e).name]).files_out.filtered_data;
end
job_in.(subject).component_to_keep  = files_in.component_to_keep;
job_in.(subject).mask_brain         = pipeline.(['qc_motion_' subject]).files_out.mask_group;
job_in.(subject).mask_selection{1}  = pipeline.(['mask_corsica_' subject]).files_out.mask_vent_ind;
job_in.(subject).mask_selection{2}  = pipeline.(['mask_corsica_' subject]).files_out.mask_stem_ind;
job_opt = opt.corsica;
job_opt.rand_seed = opt.rand_seed;
if isfield(opt.corsica,'size_output')
  job_opt.size_output = opt.corsica.size_output;
else
  job_opt.size_output = opt.size_output;
end
job_opt.folder_out  = [opt.folder_intermediate 'corsica' filesep];
job_opt.folder_sica = [opt.folder_qc 'corsica' filesep];
job_opt.flag_test   = true;
job_opt.labels_mask = {'ventricles','stem'};
[pipeline_corsica,job_opt,files_co] = niak_pipeline_corsica(job_in,job_opt);
files_co = files_co.suppress_vol.(subject);
pipeline = psom_merge_pipeline(pipeline,pipeline_corsica);
if strcmp(opt.size_output,'quality_control')
    pipeline = psom_add_clean(pipeline,['clean_corsica_' subject],files_co); 
end

if opt.flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%% CORSICA QC: variance explained 
for num_e = 1:size(files_co,1)
    clear job_in job_out job_opt
    name_job = ['qc_corsica_var_' label(num_e).name];
    job_in{1} = files_co{num_e};
    job_in{2} = pipeline.(['confounds_' label(num_e).name]).files_out.filtered_data;
    job_out     = [opt.folder_qc 'corsica' filesep name_job '_func' opt.target_space ext_f];
    job_opt.operation = [ 'var1 = std(vol_in{1},[],4).^2; ' ...
                          'var2 = std(vol_in{2},[],4).^2; ' ...
                          'mask = (var1>0) & (var2>0); ' ...
                          'vol = ones(size(var1)); ' ...
                          'vol(mask)=var1(mask)./var2(mask);' ]; 
    pipeline = psom_add_job(pipeline,name_job,'niak_brick_math_vol',job_in,job_out,job_opt);
end

%% Spatial smoothing (stereotaxic space) 
if opt.flag_verbose
    t1 = clock;
    fprintf('smoothing (');
end
for num_e = 1:length(fmri)
    clear job_in job_out job_opt     
    job_in = files_co{num_e};
    job_out = [opt.folder_fmri filesep 'fmri_' label(num_e).name ext_f];            
    job_opt = opt.smooth_vol;    
    pipeline = psom_add_job(pipeline,['smooth_' label(num_e).name],'niak_brick_smooth_vol',job_in,job_out,job_opt);
end
if opt.flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end


%%%%%%%%%%%%%%%%%%
%% SUBFUNCTIONS %%
%%%%%%%%%%%%%%%%%%

function files_in = sub_check_format(files_in)
%% Check that FILES_IN is in a proper format

if ~isstruct(files_in)
    error('FILES_IN should be a struture!')
end
list_session = fieldnames(files_in.fmri);
nb_session   = length(list_session); 
for num_c = 1:nb_session
    session = list_session{num_c};
    if ~iscellstr(files_in.fmri.(session))&&~isstruct(files_in.fmri.(session))
        error('files_in.fmri.%s should be a cell of strings or a structure!',session);
    end
end

if ~isfield(files_in,'anat')
    error('I could not find the field FILES_IN.ANAT!');
end

if ~ischar(files_in.anat)
    error('FILES_IN.ANAT is not a string!');
end

if ~isfield(files_in,'component_to_keep')
    files_in.component_to_keep = 'gb_niak_omitted';
end

if ~isfield(files_in,'custom_confounds')
    files_in.custom_confounds = 'gb_niak_omitted';
end
