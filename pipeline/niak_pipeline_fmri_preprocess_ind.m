function pipeline = niak_pipeline_fmri_preprocess_ind(files_in,opt)
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
%       (string) where to write the preprocessed fMRI volumes.
%
%   FOLDER_ANAT
%       (string, default FOLDER_OUT) where to write the preprocessed 
%       anatomical volumes as well as the results related to T1-T2 
%       coregistration.
%
%   FOLDER_QC
%       (string, default FOLDER_OUT) where to write the results of quality 
%       control.
%
%   FOLDER_INTERMEDIATE
%       (string, default FOLDER_OUT) where to write the intermediate 
%       results.
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
%       1.  Slice timing correction
%       2.  Motion correction (within- and between-run for each label).
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
% geriatrie de Montreal, 2010.
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
if ~exist('files_in','var')|~exist('opt','var')
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
        [path_f,name_f,ext_f] = niak_fileparts(files_in.fmri.session{1});
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
gb_list_fields    = {'label' , 'template_fmri' , 'size_output'     , 'folder_out' , 'folder_anat' , 'folder_qc' , 'folder_intermediate' , 'flag_test' , 'psom'       , 'slice_timing' , 'motion_correction' , 'qc_motion_correction_ind' , 't1_preprocess' , 'anat2func' , 'qc_coregister' , 'corsica' , 'time_filter' , 'resample_vol' , 'smooth_vol' };
gb_list_defaults  = {NaN     , file_template   , 'quality_control' , NaN          , ''            , ''          , ''                    , false       , default_psom , opt_tmp        , opt_tmp             , opt_tmp                    , opt_tmp         , opt_tmp     , opt_tmp         , opt_tmp   , opt_tmp       , opt_tmp        , opt_tmp      };
niak_set_defaults
opt.psom.path_logs = [opt.folder_out 'logs' filesep];

if ~ismember(opt.size_output,{'quality_control','all'}) % check that the size of outputs is a valid option
    error(sprintf('%s is an unknown option for OPT.SIZE_OUTPUT. Available options are ''minimum'', ''quality_control'', ''all''',opt.size_output))
end

if isempty(folder_anat)
    opt.folder_anat = opt.folder_out;
end

if isempty(folder_qc)
    opt.folder_qc = opt.folder_out;
end

if isempty(folder_intermediate)
    opt.folder_intermediate = opt.folder_out;
end

%% Initialization of the pipeline 
pipeline = struct([]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% slice-timing correction %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for num_sess = 1:nb_session
    session = list_session{num_sess};
    nb_run = length(files_session);
    for num_r = 1:nb_run
        run      = ['run',num2str(num_r)];
        name_job = ['slice_timing_',label,'_',session,'_',run];
        clear files_in_tmp files_out_tmp opt_tmp        
        files_in_tmp                = files_in.fmri.(session){num_r};        
        opt_tmp                     = opt.slice_timing;
        opt_tmp.folder_out          = [opt.folder_intermediate,filesep,label,filesep,'slice_timing',filesep];
        files_out_tmp               = [opt_tmp.folder_out filesep 'fmri_' label '_' session '_' run '_a' ext_f];        
        files_a.(session){num_r}    = files_out_tmp;
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_slice_timing',files_in_tmp,files_out_tmp,opt_tmp);        
    end % run
end % session

%%%%%%%%%%%%%%%%%%%%%%%
%% Motion correction %%
%%%%%%%%%%%%%%%%%%%%%%%
clear opt_tmp files_in_tmp files_out_tmp
files_in_tmp        = files_a;
opt_tmp             = opt.motion_correction;
opt_tmp.label       = opt.label;
opt_tmp.flag_test   = true;
opt_tmp.folder_out  = [opt.folder_intermediate,filesep,label,filesep,'motion_correction',filesep];
[pipeline_mc,opt_tmp,files_mc,files_mp] = niak_pipeline_motion_correction(files_in_tmp,opt_tmp);
pipeline = psom_merge_pipeline(pipeline,pipeline_mc);

%% Clean-up
if strcmp(size_output,'quality_control')    
    clear opt_tmp files_in_tmp files_out_tmp
    name_job = ['clean_slice_timing_',label];
    files_in_tmp = files_mc;    
    files_out_tmp = {};
    opt_tmp.clean = files_a;
    pipeline = psom_add_job(pipeline,name_job,'niak_brick_clean',files_in_tmp,files_out_tmp,opt_tmp);        
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% QC motion correction %%
%%%%%%%%%%%%%%%%%%%%%%%%%%
clear files_in_tmp files_out_tmp opt_tmp
name_job                             = ['qc_motion_' label];
files_in_tmp.vol                     = psom_files2cell(files_mc);
files_in_tmp.motion_parameters       = psom_files2cell(files_mp);
files_out_tmp.fig_motion_parameters  = [opt.folder_qc label filesep 'motion_correction' filesep 'fig_motion_within_run.pdf'];
files_out_tmp.mask_average           = [opt.folder_qc label filesep 'motion_correction' filesep 'mask_average' ext_f];
files_out_tmp.mask_group             = [opt.folder_anat 'func_' label '_mask_nativefunc' ext_f];
files_out_tmp.mean_vol               = [opt.folder_anat 'func_' label '_mean_nativefunc' ext_f];
files_out_tmp.std_vol                = [opt.folder_anat 'func_' label '_std_nativefunc' ext_f];
files_out_tmp.fig_coregister         = [opt.folder_qc label filesep 'motion_correction' filesep 'fig_coregister_motion.pdf'];
files_out_tmp.tab_coregister         = [opt.folder_qc label filesep 'motion_correction' filesep 'tab_coregister_motion.csv'];
opt_tmp                              = opt.qc_motion_correction_ind;
[tmp1,opt_tmp.labels_vol]            = niak_fileparts(files_in_tmp.vol);
pipeline = psom_add_job(pipeline,name_job,'niak_brick_qc_motion_correction_ind',files_in_tmp,files_out_tmp,opt_tmp);  

%%%%%%%%%%%%%%%%%%%
%% T1 preprocess %%
%%%%%%%%%%%%%%%%%%%
clear files_in_tmp files_out_tmp opt_tmp
name_job                              = ['t1_preprocess_',label];
files_in_tmp                          = files_in.anat;
files_out_tmp.transformation_lin      = [opt_tmp.folder_anat,filesep,'transf_',label,'_nativet1_to_stereolin.xfm'];
files_out_tmp.transformation_nl       = [opt_tmp.folder_anat,filesep,'transf_',label,'_stereolin_to_stereonl.xfm'];
files_out_tmp.transformation_nl_grid  = [opt_tmp.folder_anat,filesep,'transf_',label,'_stereolin_to_stereonl_grid.mnc'];
files_out_tmp.anat_nuc                = [opt_tmp.folder_anat,filesep,'anat_',label,'_nuc_nativet1',ext_f];
files_out_tmp.anat_nuc_stereolin      = [opt_tmp.folder_anat,filesep,'anat_',label,'_nuc_stereolin',ext_f];
files_out_tmp.anat_nuc_stereonl       = [opt_tmp.folder_anat,filesep,'anat_',label,'_nuc_stereonl',ext_f];
files_out_tmp.mask_stereolin          = [opt_tmp.folder_anat,filesep,'anat_',label,'_mask_stereolin',ext_f];
files_out_tmp.mask_stereonl           = [opt_tmp.folder_anat,filesep,'anat_',label,'_mask_stereonl',ext_f];
files_out_tmp.classify                = [opt_tmp.folder_anat,filesep,'anat_',label,'_classify_stereolin',ext_f];
opt_tmp                               = opt.t1_preprocess;
opt_tmp.folder_out                    = opt.folder_anat;
pipeline = psom_add_job(pipeline,name_job,'niak_brick_t1_preprocess',files_in_tmp,files_out_tmp,opt_tmp);

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% T1-T2 coregistration %%
%%%%%%%%%%%%%%%%%%%%%%%%%%
clear opt_tmp files_in_tmp files_out_tmp
name_job_qc_motion                  = ['qc_motion_' label];
name_job_t1                         = ['t1_preprocess_' label];
files_in_tmp.func                   = pipeline.(name_job_qc_motion).files_out.mean_vol;
files_in_tmp.mask_func              = pipeline.(name_job_qc_motion).files_out.mask_group;
files_in_tmp.anat                   = pipeline.(name_job_t1).files_out.anat_nuc_stereolin;
files_in_tmp.mask_anat              = pipeline.(name_job_t1).files_out.mask_stereolin;
files_in_tmp.transformation_init    = pipeline.(name_job_t1).files_out.transformation_lin;
files_out_tmp.transformation        = [opt.folder_anat 'transf_',label,'_nativefunc_to_stereolin.xfm'];
files_out_tmp.anat_hires            = [opt.folder_anat 'anat_',label,'_nativefunc_hires.mnc'];
files_out_tmp.anat_lowres           = [opt.folder_anat 'anat_',label,'_nativefunc_lowres.mnc'];
opt_tmp                             = opt.anat2func;
opt_tmp.flag_invert_transf_init     = true;
opt_tmp.flag_invert_transf_output   = true;
pipeline = psom_add_job(pipeline,['anat2func_',label],'niak_brick_anat2func',files_in_tmp,files_out_tmp,opt_tmp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Concatenate T2-to-T1_stereo_lin and T1_stereo_lin-to-stereotaxic-nl spatial transformation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear opt_tmp files_in_tmp files_out_tmp
name_job            = ['concat_transf_nl_' label];
name_job_anat2func  = ['anat2func_' label];
name_job_anat       = ['t1_preprocess_',label];
files_in_tmp{1}     = pipeline.(name_job_anat2func).files_out.transformation;
files_in_tmp{2}     = pipeline.(name_job_anat).files_out.transformation_nl;
files_out_tmp       = [opt.folder_anat 'transf_',label,'_nativefunc_to_stereonl.xfm'];
opt_tmp.flag_test   = 0;
pipeline = psom_add_job(pipeline,name_job,'niak_brick_concat_transf',files_in_tmp,files_out_tmp,opt_tmp,false);    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate masks & mean volumes in the stereotaxic (non-linear) space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
opt_tmp(1).interpolation          = 'tricubic';
opt_tmp(2).interpolation          = 'nearest_neighbour';
pipeline(1).(name_job).command    = 'niak_brick_resample_vol(files_in(1),files_out{1},opt(1)),niak_brick_resample_vol(files_in(2),files_out{2},opt(2))';
pipeline(1).(name_job).files_in   = files_in_tmp;
pipeline(1).(name_job).files_out  = files_out_tmp;
pipeline(1).(name_job).opt        = opt_tmp;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate masks & mean volumes in the stereotaxic linear space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
name_job                        = ['mask_ind_stereolin_' label];
name_job_anat2func              = ['anat2func_' label];
files_in_tmp(1).transformation  = pipeline.(name_job_anat2func).files_out.transformation;
files_in_tmp(2).transformation  = pipeline.(name_job_anat2func).files_out.transformation;
pipeline(1).(name_job).command    = 'niak_brick_resample_vol(files_in(1),files_out{1},opt(1)),niak_brick_resample_vol(files_in(2),files_out{2},opt(2))';
pipeline(1).(name_job).files_in   = files_in_tmp;
pipeline(1).(name_job).files_out  = files_out_tmp;
pipeline(1).(name_job).opt        = opt_tmp;

%%%%%%%%%%%%%%%%%%%%%%%%
%% temporal filtering %%
%%%%%%%%%%%%%%%%%%%%%%%%
for num_s = 1:nb_session
    session = list_session{num_s};
    for num_r = 1:nb_run
        run = ['run' num2str(num_r)];
        clear opt_tmp files_in_tmp files_out_tmp
        name_job                     = ['time_filter_',label,'_',session,'_',run];        
        files_in_tmp                 = list_mc.(session){num_r};
        files_out_tmp.filtered_data  = '';                                    
        opt_tmp                      = opt.time_filter;
        opt_tmp.folder_out           = [opt.folder_intermediate filesep label filesep 'time_filter' filesep];
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_concat_transf',files_in_tmp,files_out_tmp,opt_tmp,false);    
        files_tf.(session){num_r}    = pipeline.(name_job).files_out;               
    end
end

%% Clean-up
if strcmp(size_output,'quality_control')
    clear opt_tmp files_in_tmp files_out_tmp
    files_in_tmp  = files_tf;
    files_out_tmp = {};
    opt_tmp.clean = files_mc;
    pipeline = psom_add_job(pipeline,['clean_motion_correction_' label],'niak_brick_clean',files_in_tmp,files_out_tmp,opt_tmp,false);        
end
        
%%%%%%%%%%%%%
%% CORSICA %%
%%%%%%%%%%%%%
name_job_transf = ['concat_transf_nl_' label];
clear files_in_tmp files_out_tmp opt_tmp 
files_in_tmp.(label).fmri               = psom_files2cell(files_tf);
files_in_tmp.(label).component_to_keep  = files_in.component_to_keep;
files_in_tmp.(label).transformation     = pipeline.(name_job_transf).files_out;
opt_tmp                                 = opt.corsica;
opt_tmp.size_output                     = opt.size_output;
opt_tmp.folder_out                      = [opt.folder_intermediate label filesep 'corsica' filesep];
opt_tmp.folder_sica                     = [opt.folder_qc label filesep 'corsica' filesep];
opt_tmp.flag_test                       = true;
[pipeline_corsica,opt_tmp,files_co] = niak_pipeline_corsica(files_in_tmp,opt_tmp);
pipeline = psom_merge_pipeline(pipeline,pipeline_corsica);

%% Clean up
if strcmp(size_output,'quality_control')
    clear files_in_tmp files_out_tmp opt_tmp 
    files_in_tmp = files_co;
    files_out_tmp = {};
    opt_tmp.clean = files_tf;
    pipeline = psom_add_job(pipeline,['clean_time_filter_' label],'niak_brick_clean',files_in_tmp,files_out_tmp,opt_tmp,false);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Spatial resampling in stereotaxic space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
files_re = cell([length(files_co) 1]);
for num_r = 1:length(files_co);
    run = ['run',num2str(num_r)];
    clear files_in_tmp files_out_tmp opt_tmp     
    name_job = ['resample_' label '_' run];
    name_job_transf = ['concat_transf_nl_' label];      
    files_in_tmp.source = files_co{num_r};            
    files_in_tmp.target = opt.template_fmri;
    files_in_tmp.transformation = pipeline.(name_job_transf).files_out;
    files_out_tmp = '';            
    opt_tmp = opt.resample_vol;
    opt_tmp.folder_out = [opt.folder_intermediate label filesep 'resample' filesep];
    pipeline = psom_add_job(pipeline,name_job,'niak_brick_resample_vol',files_in_tmp,files_out_tmp,opt_tmp);
    files_re{num_r} = pipeline.(name_job).files_out;
end

%% Clean up
if strcmp(size_output,'quality_control')
    clear files_in_tmp files_out_tmp opt_tmp 
    files_in_tmp = files_re;
    files_out_tmp = {};
    opt_tmp.clean = files_co;
    pipeline = psom_add_job(pipeline,['clean_corsica_' label],'niak_brick_clean',files_in_tmp,files_out_tmp,opt_tmp,false);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% spatial smoothing (stereotaxic space) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
files_sm = cell([length(files_re) 1]);
for num_r = 1:length(files_re);
    run = ['run',num2str(num_r)];
    clear files_in_tmp files_out_tmp opt_tmp     
    name_job = ['smooth_',label,'_',run];    
    files_in_tmp = files_re{num_r};            
    files_out_tmp = '';            
    opt_tmp = opt.smooth_vol;
    opt_tmp.folder_out = [opt.folder_out label filesep 'resample' filesep];
    pipeline = psom_add_job(pipeline,name_job,'niak_brick_resample_vol',files_in_tmp,files_out_tmp,opt_tmp);
    files_sm{num_r} = pipeline.(name_job).files_out;
end

%% Clean up
if strcmp(size_output,'quality_control')
    clear files_in_tmp files_out_tmp opt_tmp 
    files_in_tmp = files_sm;
    files_out_tmp = {};
    opt_tmp.clean = files_re;
    pipeline = psom_add_job(pipeline,['clean_resample_' label],'niak_brick_clean',files_in_tmp,files_out_tmp,opt_tmp,false);
end

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end