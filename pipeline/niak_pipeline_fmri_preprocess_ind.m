function [pipeline,opt] = niak_pipeline_fmri_preprocess_ind(files_in,opt)
% Run a pipeline to preprocess individual fMRI datasets. 
% The flowchart of the pipeline is flexible (steps can be skipped using 
% flags), and the various steps of the analysis can be further customized 
% by changing virtually any parameter.
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
%           (boolean, default 0) if the flag is 1, then the function
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
%       coregistration between the anatomical and functional volumes.
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
% Maintainer : pbellec@bic.mni.mcgill.ca
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
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_FMRI_PREPROCESS_IND(FILES_IN,OPT).\n Type ''help niak_pipeline_fmri_preprocess_ind'' for more info.')
end

%% Checking that FILES_IN is in the correct format
if ~isstruct(files_in)
    error('FILES_IN should be a struture!')
end
list_session = fieldnames(files_in.fmri);
nb_session   = length(list_session); 
for num_c = 1:nb_session
    session = list_session{num_c};
    if ~iscellstr(files_in.fmri.(session))
        error(sprintf('FILES_IN.FMRI.%s is not a cell of strings!',session));
    end
    if num_c==1
        [path_f,name_f,ext_f] = niak_fileparts(files_in.fmri.(session){1});
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

%% Options
default_psom.path_logs = '';
opt_tmp.flag_test = false;
file_template = [gb_niak_path_template filesep 'roi_aal.mnc.gz'];
gb_name_structure = 'opt';
gb_list_fields    = {'label' , 'template_fmri' , 'size_output'     , 'folder_out' , 'folder_logs' , 'folder_fmri' , 'folder_anat' , 'folder_qc' , 'folder_intermediate' , 'flag_test' , 'flag_verbose' , 'psom'       , 'slice_timing' , 'motion_correction' , 'qc_motion_correction_ind' , 't1_preprocess' , 'anat2func' , 'qc_coregister' , 'corsica' , 'time_filter' , 'resample_vol' , 'smooth_vol' , 'region_growing' };
gb_list_defaults  = {NaN     , file_template   , 'quality_control' , NaN          , ''            , ''            , ''            , ''          , ''                    , false       , false          , default_psom , opt_tmp        , opt_tmp             , opt_tmp                    , opt_tmp         , opt_tmp     , opt_tmp         , opt_tmp   , opt_tmp       , opt_tmp        , opt_tmp      , opt_tmp};
niak_set_defaults

if ~ismember(opt.size_output,{'quality_control','all'}) % check that the size of outputs is a valid option
    error(sprintf('%s is an unknown option for OPT.SIZE_OUTPUT. Available options are ''minimum'', ''quality_control'', ''all''',opt.size_output))
end

if isempty(folder_logs)
    opt.folder_logs = [opt.folder_out 'logs'];
end

if isempty(folder_fmri)
    opt.folder_fmri = [opt.folder_out 'fmri'];
end

if isempty(folder_anat)
    opt.folder_anat = [opt.folder_out 'anat' filesep label filesep];
end

if isempty(folder_qc)
    opt.folder_qc = [opt.folder_out 'quality_control' filesep label filesep];
end

if isempty(folder_intermediate)
    opt.folder_intermediate = [opt.folder_out 'intermediate' filesep label filesep];
end

opt.psom.path_logs = opt.folder_logs;

%% Initialization of the pipeline 
pipeline = struct([]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% slice-timing correction %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('slice timing (');
end
for num_sess = 1:nb_session
    session = list_session{num_sess};
    nb_run = length(files_in.fmri.(session));
    for num_r = 1:nb_run
        run      = ['run',num2str(num_r)];
        name_job = ['slice_timing_',label,'_',session,'_',run];
        clear files_in_tmp files_out_tmp opt_tmp        
        files_in_tmp                = files_in.fmri.(session){num_r};        
        opt_tmp                     = opt.slice_timing;
        opt_tmp.folder_out          = [opt.folder_intermediate 'slice_timing' filesep];
        files_out_tmp               = [opt_tmp.folder_out filesep 'fmri_' label '_' session '_' run '_a' ext_f];        
        files_a.(session){num_r}    = files_out_tmp;
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_slice_timing',files_in_tmp,files_out_tmp,opt_tmp);    
        if strcmp(size_output,'quality_control') % Clean-up
            pipeline = psom_add_clean(pipeline,['clean_' name_job],files_out_tmp);        
        end
    end % run
end % session
if flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%%%%
%% Motion correction %%
%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('motion correction (');
end
clear opt_tmp files_in_tmp files_out_tmp
files_in_tmp        = files_a;
opt_tmp             = opt.motion_correction;
opt_tmp.label       = opt.label;
opt_tmp.flag_test   = true;
opt_tmp.folder_out  = [opt.folder_intermediate 'motion_correction',filesep];
[pipeline_mc,opt_tmp,files_motion] = niak_pipeline_motion_correction(files_in_tmp,opt_tmp);
pipeline = psom_merge_pipeline(pipeline,pipeline_mc);
if strcmp(size_output,'quality_control')
    files_tmp = psom_files2cell(files_motion.motion_corrected);
    for num_e = 1:length(files_tmp)
        pipeline = psom_add_clean(pipeline,['clean_motion_correction_' label '_file' num2str(num_e)],files_tmp{num_e}); 
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% QC motion correction %%
%%%%%%%%%%%%%%%%%%%%%%%%%%
clear files_in_tmp files_out_tmp opt_tmp
name_job_qc_motion                   = ['qc_motion_' label];
files_in_tmp.vol                     = psom_files2cell(files_motion.motion_corrected);
files_in_tmp.motion_parameters       = psom_files2cell(files_motion.motion_parameters);
files_out_tmp.fig_motion_parameters  = [opt.folder_qc 'motion_correction' filesep 'fig_motion_within_run.pdf'];
files_out_tmp.mask_average           = [opt.folder_qc 'motion_correction' filesep 'func_' label '_mask_average_nativefunc' ext_f];
files_out_tmp.mask_group             = [opt.folder_anat 'func_' label '_mask_nativefunc' ext_f];
files_out_tmp.mean_vol               = [opt.folder_anat 'func_' label '_mean_nativefunc' ext_f];
files_out_tmp.std_vol                = [opt.folder_anat 'func_' label '_std_nativefunc' ext_f];
files_out_tmp.fig_coregister         = [opt.folder_qc 'motion_correction' filesep 'fig_coregister_motion.pdf'];
files_out_tmp.tab_coregister         = [opt.folder_qc 'motion_correction' filesep 'tab_coregister_motion.csv'];
opt_tmp                              = opt.qc_motion_correction_ind;
[tmp1,opt_tmp.labels_vol]            = niak_fileparts(files_in_tmp.vol);
pipeline = psom_add_job(pipeline,name_job_qc_motion,'niak_brick_qc_motion_correction_ind',files_in_tmp,files_out_tmp,opt_tmp);  
if flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%
%% T1 preprocess %%
%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('T1 preprocess (');
end
clear files_in_tmp files_out_tmp opt_tmp
name_job_t1                           = ['t1_preprocess_',label];
files_in_tmp                          = files_in.anat;
files_out_tmp.transformation_lin      = [opt.folder_anat 'transf_' label '_nativet1_to_stereolin.xfm'];
files_out_tmp.transformation_nl       = [opt.folder_anat 'transf_' label '_stereolin_to_stereonl.xfm'];
files_out_tmp.transformation_nl_grid  = [opt.folder_anat 'transf_' label '_stereolin_to_stereonl_grid.mnc'];
files_out_tmp.anat_nuc                = [opt.folder_anat 'anat_' label '_nuc_nativet1' ext_f];
files_out_tmp.anat_nuc_stereolin      = [opt.folder_anat 'anat_' label '_nuc_stereolin' ext_f];
files_out_tmp.anat_nuc_stereonl       = [opt.folder_anat 'anat_' label '_nuc_stereonl' ext_f];
files_out_tmp.mask_stereolin          = [opt.folder_anat 'anat_' label '_mask_stereolin' ext_f];
files_out_tmp.mask_stereonl           = [opt.folder_anat 'anat_' label '_mask_stereonl' ext_f];
files_out_tmp.classify                = [opt.folder_anat 'anat_' label '_classify_stereolin' ext_f];
opt_tmp                               = opt.t1_preprocess;
opt_tmp.folder_out                    = opt.folder_anat;
pipeline = psom_add_job(pipeline,name_job_t1,'niak_brick_t1_preprocess',files_in_tmp,files_out_tmp,opt_tmp);
if flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% T1-T2 coregistration %%
%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('T1-T2 coregistration (');
end

clear opt_tmp files_in_tmp files_out_tmp
name_job_qc_motion                  = ['qc_motion_' label];
name_job_t1                         = ['t1_preprocess_' label];
files_in_tmp.func                   = pipeline.(name_job_qc_motion).files_out.mean_vol;
files_in_tmp.mask_func              = pipeline.(name_job_qc_motion).files_out.mask_group;
files_in_tmp.anat                   = pipeline.(name_job_t1).files_out.anat_nuc_stereolin;
files_in_tmp.mask_anat              = pipeline.(name_job_t1).files_out.mask_stereolin;
files_in_tmp.transformation_init    = pipeline.(name_job_t1).files_out.transformation_lin;
files_out_tmp.transformation        = [opt.folder_anat 'transf_' label '_nativefunc_to_stereolin.xfm'];
files_out_tmp.anat_hires            = [opt.folder_anat 'anat_' label '_nativefunc_hires' ext_f];
files_out_tmp.anat_lowres           = [opt.folder_anat 'anat_' label '_nativefunc_lowres' ext_f];
opt_tmp                             = opt.anat2func;
opt_tmp.flag_invert_transf_init     = true;
opt_tmp.flag_invert_transf_output   = true;
pipeline = psom_add_job(pipeline,['anat2func_',label],'niak_brick_anat2func',files_in_tmp,files_out_tmp,opt_tmp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Concatenate T2-to-T1_stereo_lin and T1_stereo_lin-to-stereotaxic-nl spatial transformation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear opt_tmp files_in_tmp files_out_tmp
name_job_concat_transf  = ['concat_transf_nl_' label];
name_job_anat2func      = ['anat2func_' label];
name_job_anat           = ['t1_preprocess_',label];
files_in_tmp{1}         = pipeline.(name_job_anat2func).files_out.transformation;
files_in_tmp{2}         = pipeline.(name_job_anat).files_out.transformation_nl;
files_out_tmp           = [opt.folder_anat 'transf_' label '_nativefunc_to_stereonl.xfm'];
opt_tmp.flag_test       = 0;
pipeline = psom_add_job(pipeline,name_job_concat_transf,'niak_brick_concat_transf',files_in_tmp,files_out_tmp,opt_tmp,false);    
if flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate functional brain masks/mean/std volumes in the stereotaxic (non-linear) space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('Brain masks & average (');
end
clear opt_tmp files_in_tmp files_out_tmp
name_job                          = ['mask_ind_stereonl_',label];
name_job_concat                   = cat(2,'concat_transf_nl_',label);
name_job_qc_motion                = cat(2,'qc_motion_',label);
files_in_tmp(1).transformation    = pipeline.(name_job_concat).files_out;
files_in_tmp(1).source            = pipeline.(name_job_qc_motion).files_out.mean_vol;
files_in_tmp(1).target            = opt.template_fmri;
files_in_tmp(2).transformation    = pipeline.(name_job_concat).files_out;
files_in_tmp(2).source            = pipeline.(name_job_qc_motion).files_out.mask_group;
files_in_tmp(2).target            = opt.template_fmri;
files_out_tmp{1}                  = [opt.folder_anat 'func_' label '_mean_stereonl' ext_f];
files_out_tmp{2}                  = [opt.folder_anat 'func_' label '_mask_stereonl' ext_f];
opt_tmp(1)                        = opt.resample_vol;
opt_tmp(2)                        = opt.resample_vol;
opt_tmp(1).interpolation          = 'tricubic';
opt_tmp(2).interpolation          = 'nearest_neighbour';
pipeline(1).(name_job).command    = 'niak_brick_resample_vol(files_in(1),files_out{1},opt(1)),niak_brick_resample_vol(files_in(2),files_out{2},opt(2))';
pipeline(1).(name_job).files_in   = files_in_tmp;
pipeline(1).(name_job).files_out  = files_out_tmp;
pipeline(1).(name_job).opt        = opt_tmp;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate functional brain masks/mean/std volumes in the stereotaxic linear space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
name_job                          = ['mask_ind_stereolin_' label];
name_job_anat2func                = ['anat2func_' label];
files_in_tmp(1).transformation    = pipeline.(name_job_anat2func).files_out.transformation;
files_in_tmp(2).transformation    = pipeline.(name_job_anat2func).files_out.transformation;
files_out_tmp{1}                  = [opt.folder_anat 'func_' label '_mean_stereolin' ext_f];
files_out_tmp{2}                  = [opt.folder_anat 'func_' label '_mask_stereolin' ext_f];
pipeline(1).(name_job).command    = 'niak_brick_resample_vol(files_in(1),files_out{1},opt(1)),niak_brick_resample_vol(files_in(2),files_out{2},opt(2))';
pipeline(1).(name_job).files_in   = files_in_tmp;
pipeline(1).(name_job).files_out  = files_out_tmp;
pipeline(1).(name_job).opt        = opt_tmp;
if flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%%%%%
%% temporal filtering %%
%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('time filter (');
end
for num_s = 1:nb_session
    session = list_session{num_s};
    nb_run = length(files_in.fmri.(session));
    for num_r = 1:nb_run
        run = ['run' num2str(num_r)];
        clear opt_tmp files_in_tmp files_out_tmp
        name_job                     = ['time_filter_',label,'_',session,'_',run];        
        files_in_tmp                 = files_motion.motion_corrected.(session){num_r};
        files_out_tmp.filtered_data  = '';                                    
        opt_tmp                      = opt.time_filter;
        opt_tmp.folder_out           = [opt.folder_intermediate 'time_filter' filesep];
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_time_filter',files_in_tmp,files_out_tmp,opt_tmp);    
        files_tf.(session){num_r}    = pipeline.(name_job).files_out.filtered_data;               
        if strcmp(size_output,'quality_control')
          pipeline = psom_add_clean(pipeline,['clean_' name_job],files_tf.(session){num_r});
        end    
    end
end

if flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%
%% CORSICA MASKS %%
%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('corsica (');
end
name_job_mask_corsica = ['mask_corsica_' label];
clear files_in_tmp files_out_tmp opt_tmp 
files_in_tmp.mask_vent_stereo   = [gb_niak_path_niak 'template' filesep 'roi_ventricle.mnc.gz'];
files_in_tmp.mask_stem_stereo   = [gb_niak_path_niak 'template' filesep 'roi_stem.mnc.gz'];
files_in_tmp.functional_space   = pipeline.(name_job_qc_motion).files_out.mask_group;
files_in_tmp.transformation_lin = pipeline.(name_job_anat2func).files_out.transformation;
files_in_tmp.transformation_nl  = pipeline.(name_job_concat_transf).files_out;
files_in_tmp.segmentation       = pipeline.(name_job_t1).files_out.classify;
files_out_tmp.mask_vent_ind     = [opt.folder_qc 'corsica' filesep label '_mask_vent_nativefunc' ext_f];
files_out_tmp.mask_stem_ind     = [opt.folder_qc 'corsica' filesep label '_mask_stem_nativefunc' ext_f];
opt_tmp.flag_test = false;
pipeline = psom_add_job(pipeline,name_job_mask_corsica,'niak_brick_mask_corsica',files_in_tmp,files_out_tmp,opt_tmp);

%%%%%%%%%%%%%
%% CORSICA %%
%%%%%%%%%%%%%
clear files_in_tmp files_out_tmp opt_tmp 
files_in_tmp.(label).fmri               = psom_files2cell(files_tf);
files_in_tmp.(label).component_to_keep  = files_in.component_to_keep;
files_in_tmp.(label).mask_brain         = pipeline.(name_job_qc_motion).files_out.mask_group;
files_in_tmp.(label).mask_selection{1}  = pipeline.(name_job_mask_corsica).files_out.mask_vent_ind;
files_in_tmp.(label).mask_selection{2}  = pipeline.(name_job_mask_corsica).files_out.mask_stem_ind;
opt_tmp                                 = opt.corsica;
if isfield(opt.corsica,'size_output')
  opt_tmp.size_output                   = opt.corsica.size_output;
else
  opt_tmp.size_output                   = opt.size_output;
end
opt_tmp.folder_out                      = [opt.folder_intermediate 'corsica' filesep];
opt_tmp.folder_sica                     = [opt.folder_out 'quality_control' filesep label filesep 'corsica' filesep];
opt_tmp.flag_test                       = true;
opt_tmp.labels_mask                     = {'ventricles','stem'};
[pipeline_corsica,opt_tmp,files_co] = niak_pipeline_corsica(files_in_tmp,opt_tmp);
files_co    = files_co.suppress_vol.(label);
pipeline = psom_merge_pipeline(pipeline,pipeline_corsica);
if strcmp(size_output,'quality_control')
    files_tmp = psom_files2cell(files_co);
    for num_e = 1:length(files_tmp)
        pipeline = psom_add_clean(pipeline,['clean_corsica_' label '_file' num2str(num_e)],files_tmp{num_e}); 
    end  
end

if flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Spatial resampling in stereotaxic space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('resampling (');
end
files_re = cell([length(files_co) 1]);
for num_r = 1:length(files_co);
    run = ['run',num2str(num_r)];
    clear files_in_tmp files_out_tmp opt_tmp     
    name_job_resample = ['resample_' label '_' run];    
    files_in_tmp.source = files_co{num_r};            
    files_in_tmp.target = opt.template_fmri;
    files_in_tmp.transformation = pipeline.(name_job_concat_transf).files_out;
    files_out_tmp = '';            
    opt_tmp = opt.resample_vol;
    opt_tmp.folder_out = [opt.folder_intermediate 'resample' filesep];
    pipeline = psom_add_job(pipeline,name_job_resample,'niak_brick_resample_vol',files_in_tmp,files_out_tmp,opt_tmp);
    files_re{num_r} = pipeline.(name_job_resample).files_out;
    if strcmp(size_output,'quality_control')
        pipeline = psom_add_clean(pipeline,['clean_' name_job_resample],files_re{num_r});
    end
end

if flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% spatial smoothing (stereotaxic space) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    t1 = clock;
    fprintf('smoothing (');
end
files_sm = cell([length(files_re) 1]);
num_r = 0;
for num_s = 1:nb_session
    session = list_session{num_s};
    nb_run = length(files_in.fmri.(session));
    for num_run = 1:nb_run
        num_r = num_r+1;
        run = ['run',num2str(num_run)];
        clear files_in_tmp files_out_tmp opt_tmp     
        name_job = ['smooth_' label '_' session '_' run];    
        files_in_tmp = files_re{num_r};               
        files_out_tmp = [opt.folder_fmri filesep 'fmri_' label '_' session '_' run ext_f];            
        opt_tmp = opt.smooth_vol;    
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_smooth_vol',files_in_tmp,files_out_tmp,opt_tmp);
        files_sm{num_r} = pipeline.(name_job).files_out;
    end
end

if flag_verbose        
    fprintf('%1.2f sec) - ',etime(clock,t1));
end

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end