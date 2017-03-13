
# fMRI preprocessing
This tutorial shows how to run the NIAK fMRI preprocessing pipeline, using a limited set of options. See the [documentation](http://niak.simexp-lab.org/pipe_preprocessing.html) of the pipeline for a more comprehensive list of options. Download the tutorial as a notebook [here](https://raw.githubusercontent.com/SIMEXP/niak_tutorials/master/niak_tutorial_fmri_preprocessing.ipynb) and a matlab script [here](https://raw.githubusercontent.com/SIMEXP/niak_tutorials/master/niak_tutorial_fmri_preprocessing.m). 

## Preparing files
First download a small fMRI dataset, with a structural scan. Be aware that all raw and derivatives data will be generated in the current folder. Note that you will need to manually remove the `data_test_niak_mnc1` and `fmri_preprocess` folders to restart this tutorial from scratch.


```octave
clear
niak_wget('data_test_niak_mnc1');
```

Now, set up the names of the structural and functional files.


```octave
path_data = [pwd filesep];
% Structural scan subject 1
files_in.subject1.anat = ...
    [path_data 'data_test_niak_mnc1/anat_subject1.mnc.gz'];       
% fMRI run 1 subject 1
files_in.subject1.fmri.session1.motor = ...
    [path_data 'data_test_niak_mnc1/func_motor_subject1.mnc.gz'];
% Structural scan subject 2
files_in.subject2.anat = ...
    [path_data 'data_test_niak_mnc1/anat_subject2.mnc.gz'];       
% fMRI run 1 subject 2
files_in.subject2.fmri.session1.motor = ...
    [path_data 'data_test_niak_mnc1/func_motor_subject2.mnc.gz'];
```

We start by specifying where to write the results.


```octave
% Where to store the results
opt.folder_out  = [path_data 'fmri_preprocess/'];
```

## Parallel computing 
Next we specify how many threads to use. A value of `N` means that up to `N` jobs can be executed in parallel. 


```octave
% Use up to 2 threads
opt.psom.max_queued = 2;
```

## Slice timing
We now set the options of the slice timing correction. Note that we specify the type of the scanner (in practice, only 'Siemens' has an impact), because the definition of the scanner impacts the definition of the slice timing.


```octave
opt.slice_timing.type_acquisition = 'interleaved ascending'; 
opt.slice_timing.type_scanner     = 'Bruker';                
opt.slice_timing.delay_in_tr      = 0;
```

other options are available as part of the slice timing step, which are not part of the slice timing per say. It is notably possible to center the functional images (if the header information is not accurate), or to suppress some volumes at the beginning of the time series: 


```octave
% Center the functional volumes on the brain center-of-mass (true/false)
opt.slice_timing.flag_center = false;
% Suppress some volumes at the beginning of the run
opt.slice_timing.suppress_vol = 3;
```

## Resampling
The voxel size for resampling in stereotaxic space is specified by the user:


```octave
% The voxel size to use in the stereotaxic space
opt.resample_vol.voxel_size    = 10;
```

## T1 processing
The options for non-uniformity correction of the T1 image is often useful to tweak:


```octave
% Parameter for non-uniformity correction. 
% 200 is a suggested value for 1.5T images, 
% 75 for 3T images. 
opt.t1_preprocess.nu_correct.arg = '-distance 75';
```

## Regression of confounds
The options for temporal filtering, motion parameter regression, white matter and ventricle signal regression, COMPCOR, global signal correction and scrubbing.


```octave
% Cut-off frequency for high-pass filtering, 
% or removal of low frequencies (in Hz). 
opt.time_filter.hp = 0.01; 
% Cut-off frequency for low-pass filtering, 
% or removal of high frequencies (in Hz). 
opt.time_filter.lp = 0.1;
% Remove slow time drifts (true/false)
opt.regress_confounds.flag_slow = true;
% Remove high frequencies (true/false)
opt.regress_confounds.flag_high = false;
% Apply regression of motion parameters (true/false)
opt.regress_confounds.flag_motion_params = true;
% Reduce the dimensionality of motion parameters with PCA (true/false)
opt.regress_confounds.flag_pca_motion = true;
% How much variance of motion parameters (with squares) to retain
opt.regress_confounds.pct_var_explained = 0.95;
% Apply average white matter signal regression (true/false)         
opt.regress_confounds.flag_wm = true;
% Apply average ventricle signal regression (true/false)         
opt.regress_confounds.flag_vent = true;
% Apply anat COMPCOR (white matter+ventricles, true/false)
% We recommend not using FLAG_WM and FLAG_VENT together with FLAG_COMPCOR
opt.regress_confounds.flag_compcor = false;
% Apply global signal regression (true/false)         
opt.regress_confounds.flag_gsc = true; 
% Apply scrubbing (true/false)
opt.regress_confounds.flag_scrubbing = true;     
% The threshold on frame displacement for scrubbing 
opt.regress_confounds.thre_fd = 0.5;    
```

## Spatial smoothing
The size of the spatial Gaussian blurring kernel: 


```octave
% Full-width at maximum (FWHM) of the Gaussian blurring kernel, in mm.
opt.smooth_vol.fwhm      = 6;
```

## Run the pipeline
This command can take up to 20-30 minutes to complete. It runs the full preprocessing pipeline on one subject/run. 


```octave
niak_pipeline_fmri_preprocess(files_in,opt);
% Check the content of fmri_preprocess/logs/PIPE_history.txt to monitor the progress of the pipeline
```

    Generating pipeline for individual fMRI preprocessing :
        Adding subject1 ; 0.14 sec
        Adding subject2 ; 0.08 sec
    Adding group-level quality control of coregistration in anatomical space (linear stereotaxic space) ; 0.01 sec
    Adding group-level quality control of coregistration in anatomical space (non-linear stereotaxic space) ; 0.01 sec
    Adding group-level quality control of coregistration in functional space ; 0.01 sec
    Adding group-level quality control of motion correction (motion parameters) ; 0.01 sec
    Adding group-level quality control of scrubbing time frames with excessive motion ; 0.00 sec
    Adding the report on fMRI preprocessing ; 0.24 sec
    
    Logs will be stored in /sandbox/home/git/niak_tutorials/fmri_preprocess/logs/
    Generating dependencies ...
       Percentage completed :  0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100- 0.07 sec
    Setting up the to-do list ...
       I found 65 job(s) to do, and 10 job(s) already completed.
    Deamon started on 13-Mar-2017 15:23:15
    13-Mar-2017 15:23:15 Starting the pipeline manager...
    13-Mar-2017 15:23:15 Starting the garbage collector...
    13-Mar-2017 15:23:15 Starting worker number 1...
    13-Mar-2017 15:23:15 Starting worker number 2...
    
    Pipeline started on 13-Mar-2017 15:23:16
    user: , host: 82112340824c, system: unix
    ****************************************
    13-Mar-2017 15:23:17 pipe_params                               submitted  (1 run | 0 fail | 10 done | 64 left)
    13-Mar-2017 15:23:17 t1_preprocess_subject1                    submitted  (2 run | 0 fail | 10 done | 63 left)
    13-Mar-2017 15:23:17 slice_timing_subject1_session1_motor      submitted  (3 run | 0 fail | 10 done | 62 left)
    13-Mar-2017 15:23:17 t1_preprocess_subject2                    submitted  (4 run | 0 fail | 10 done | 61 left)
    13-Mar-2017 15:23:18 pipe_params                               finished   (3 run | 0 fail | 11 done | 61 left)
    13-Mar-2017 15:23:18 slice_timing_subject2_session1_motor      submitted  (4 run | 0 fail | 11 done | 60 left)
    13-Mar-2017 15:23:19 slice_timing_subject1_session1_motor      finished   (3 run | 0 fail | 12 done | 60 left)
    13-Mar-2017 15:23:19 motion_target_subject1_session1_motor     submitted  (4 run | 0 fail | 12 done | 59 left)
    13-Mar-2017 15:23:20 slice_timing_subject2_session1_motor      finished   (3 run | 0 fail | 13 done | 59 left)
    13-Mar-2017 15:23:20 motion_target_subject2_session1_motor     submitted  (4 run | 0 fail | 13 done | 58 left)
    13-Mar-2017 15:23:21 motion_target_subject1_session1_motor     finished   (3 run | 0 fail | 14 done | 58 left)
    13-Mar-2017 15:23:21 motion_Wrun_subject1_session1_motor       submitted  (4 run | 0 fail | 14 done | 57 left)
    13-Mar-2017 15:23:22 motion_target_subject2_session1_motor     finished   (3 run | 0 fail | 15 done | 57 left)
    13-Mar-2017 15:23:22 motion_Wrun_subject2_session1_motor       submitted  (4 run | 0 fail | 15 done | 56 left)
    .
    13-Mar-2017 15:23:48 motion_Wrun_subject1_session1_motor       finished   (3 run | 0 fail | 16 done | 56 left)
    13-Mar-2017 15:23:48 motion_parameters_subject1_session1_motor submitted  (4 run | 0 fail | 16 done | 55 left)
    13-Mar-2017 15:24:11 motion_Wrun_subject2_session1_motor       finished   (3 run | 0 fail | 17 done | 55 left)
    13-Mar-2017 15:24:12 motion_parameters_subject1_session1_motor finished   (2 run | 0 fail | 18 done | 55 left)
    13-Mar-2017 15:24:12 motion_parameters_subject2_session1_motor submitted  (3 run | 0 fail | 18 done | 54 left)
    13-Mar-2017 15:24:12 rep_params                                submitted  (4 run | 0 fail | 18 done | 53 left)
    13-Mar-2017 15:24:12 motion_parameters_subject2_session1_motor finished   (3 run | 0 fail | 19 done | 53 left)
    13-Mar-2017 15:24:12 rep_params                                finished   (2 run | 0 fail | 20 done | 53 left)
    13-Mar-2017 15:24:12 rep_init_report                           submitted  (3 run | 0 fail | 20 done | 52 left)
    13-Mar-2017 15:24:12 rep_motion_native_subject1_session1_motor submitted  (4 run | 0 fail | 20 done | 51 left)
    13-Mar-2017 15:24:13 rep_init_report                           finished   (3 run | 0 fail | 21 done | 51 left)
    13-Mar-2017 15:24:13 rep_target_native_subject1_session1_motor submitted  (4 run | 0 fail | 21 done | 50 left)
    13-Mar-2017 15:24:14 rep_motion_native_subject1_session1_motor finished   (3 run | 0 fail | 22 done | 50 left)
    13-Mar-2017 15:24:14 rep_motion_native_subject2_session1_motor submitted  (4 run | 0 fail | 22 done | 49 left)
    13-Mar-2017 15:24:15 rep_target_native_subject1_session1_motor finished   (3 run | 0 fail | 23 done | 49 left)
    13-Mar-2017 15:24:15 rep_target_native_subject2_session1_motor submitted  (4 run | 0 fail | 23 done | 48 left)
    13-Mar-2017 15:24:17 rep_motion_native_subject2_session1_motor finished   (3 run | 0 fail | 24 done | 48 left)
    13-Mar-2017 15:24:17 rep_motion_report_subject2_session1_motor submitted  (4 run | 0 fail | 24 done | 47 left)
    13-Mar-2017 15:24:17 rep_target_native_subject2_session1_motor finished   (3 run | 0 fail | 25 done | 47 left)
    .
    13-Mar-2017 15:24:18 rep_motion_report_subject2_session1_motor finished   (2 run | 0 fail | 26 done | 47 left)
    ........................
    13-Mar-2017 15:36:46 t1_preprocess_subject1                    finished   (1 run | 0 fail | 27 done | 47 left)
    13-Mar-2017 15:36:46 mask_anat2func_subject1                   submitted  (2 run | 0 fail | 27 done | 46 left)
    13-Mar-2017 15:36:46 rep_t1_subject1                           submitted  (3 run | 0 fail | 27 done | 45 left)
    ....
    13-Mar-2017 15:38:41 mask_anat2func_subject1                   finished   (2 run | 0 fail | 28 done | 45 left)
    13-Mar-2017 15:38:41 anat2func_subject1                        submitted  (3 run | 0 fail | 28 done | 44 left)
    13-Mar-2017 15:38:51 rep_t1_subject1                           finished   (2 run | 0 fail | 29 done | 44 left)
    13-Mar-2017 15:38:51 rep_t1_subject1_overlay                   submitted  (3 run | 0 fail | 29 done | 43 left)
    .........
    13-Mar-2017 15:43:05 anat2func_subject1                        finished   (2 run | 0 fail | 30 done | 43 left)
    13-Mar-2017 15:43:05 concat_transf_nl_subject1                 submitted  (3 run | 0 fail | 30 done | 42 left)
    13-Mar-2017 15:43:06 rep_t1_subject1_overlay                   finished   (2 run | 0 fail | 31 done | 42 left)
    13-Mar-2017 15:43:08 concat_transf_nl_subject1                 finished   (1 run | 0 fail | 32 done | 42 left)
    13-Mar-2017 15:43:08 resample_subject1_session1_motor          submitted  (2 run | 0 fail | 32 done | 41 left)
    ..
    13-Mar-2017 15:44:18 resample_subject1_session1_motor          finished   (1 run | 0 fail | 33 done | 41 left)
    13-Mar-2017 15:44:18 qc_motion_subject1                        submitted  (2 run | 0 fail | 33 done | 40 left)
    13-Mar-2017 15:44:18 time_filter_subject1_session1_motor       submitted  (3 run | 0 fail | 33 done | 39 left)
    13-Mar-2017 15:44:18 rep_motion_stereo_subject1_session1_motor submitted  (4 run | 0 fail | 33 done | 38 left)
    13-Mar-2017 15:44:26 qc_motion_subject1                        finished   (3 run | 0 fail | 34 done | 38 left)
    13-Mar-2017 15:44:26 mask_confounds_subject1                   submitted  (4 run | 0 fail | 34 done | 37 left)
    13-Mar-2017 15:44:26 time_filter_subject1_session1_motor       finished   (3 run | 0 fail | 35 done | 37 left)
    13-Mar-2017 15:44:26 rep_bold_subject1                         submitted  (4 run | 0 fail | 35 done | 36 left)
    .
    13-Mar-2017 15:44:35 mask_confounds_subject1                   finished   (3 run | 0 fail | 36 done | 36 left)
    13-Mar-2017 15:44:35 build_confounds_subject1_session1_motor   submitted  (4 run | 0 fail | 36 done | 35 left)
    13-Mar-2017 15:44:36 rep_bold_subject1                         finished   (3 run | 0 fail | 37 done | 35 left)
    13-Mar-2017 15:44:36 rep_target_stereo_subject1_session1_motor submitted  (4 run | 0 fail | 37 done | 34 left)
    13-Mar-2017 15:44:39 build_confounds_subject1_session1_motor   finished   (3 run | 0 fail | 38 done | 34 left)
    13-Mar-2017 15:44:39 regress_confounds_subject1_session1_motor submitted  (4 run | 0 fail | 38 done | 33 left)
    13-Mar-2017 15:44:40 rep_target_stereo_subject1_session1_motor finished   (3 run | 0 fail | 39 done | 33 left)
    13-Mar-2017 15:44:40 rep_motion_ind_subject1_session1_motor    submitted  (4 run | 0 fail | 39 done | 32 left)
    13-Mar-2017 15:44:41 regress_confounds_subject1_session1_motor finished   (3 run | 0 fail | 40 done | 32 left)
    13-Mar-2017 15:44:41 rep_motion_ind_subject1_session1_motor    finished   (2 run | 0 fail | 41 done | 32 left)
    13-Mar-2017 15:44:41 smooth_subject1_session1_motor            submitted  (3 run | 0 fail | 41 done | 31 left)
    13-Mar-2017 15:44:56 smooth_subject1_session1_motor            finished   (2 run | 0 fail | 42 done | 31 left)
    13-Mar-2017 15:44:56 clean_subject1                            submitted  (3 run | 0 fail | 42 done | 30 left)
    13-Mar-2017 15:44:57 clean_subject1                            finished   (2 run | 0 fail | 43 done | 30 left)
    .............
    13-Mar-2017 15:51:33 t1_preprocess_subject2                    finished   (1 run | 0 fail | 44 done | 30 left)
    13-Mar-2017 15:51:33 mask_anat2func_subject2                   submitted  (2 run | 0 fail | 44 done | 29 left)
    13-Mar-2017 15:51:33 qc_coregister_group_anat_stereolin        submitted  (3 run | 0 fail | 44 done | 28 left)
    13-Mar-2017 15:51:34 qc_group_coregister_anat_stereonl         submitted  (4 run | 0 fail | 44 done | 27 left)
    13-Mar-2017 15:51:35 rep_motion_stereo_subject1_session1_motor finished   (3 run | 0 fail | 45 done | 27 left)
    13-Mar-2017 15:51:35 rep_t1_subject2                           submitted  (4 run | 0 fail | 45 done | 26 left)
    .
    13-Mar-2017 15:52:03 qc_group_coregister_anat_stereonl         finished   (3 run | 0 fail | 46 done | 26 left)
    13-Mar-2017 15:52:03 rep_summary_anat                          submitted  (4 run | 0 fail | 46 done | 25 left)
    .
    13-Mar-2017 15:52:15 rep_summary_anat                          finished   (3 run | 0 fail | 47 done | 25 left)
    13-Mar-2017 15:52:15 rep_t1_subject2                           finished   (2 run | 0 fail | 48 done | 25 left)
    13-Mar-2017 15:52:15 rep_average_t1_stereo                     submitted  (3 run | 0 fail | 48 done | 24 left)
    13-Mar-2017 15:52:15 rep_t1_subject2_overlay                   submitted  (4 run | 0 fail | 48 done | 23 left)
    13-Mar-2017 15:52:27 rep_average_t1_stereo                     finished   (3 run | 0 fail | 49 done | 23 left)
    13-Mar-2017 15:52:27 rep_t1_subject2_overlay                   finished   (2 run | 0 fail | 50 done | 23 left)
    .
    13-Mar-2017 15:52:59 mask_anat2func_subject2                   finished   (1 run | 0 fail | 51 done | 23 left)
    13-Mar-2017 15:52:59 anat2func_subject2                        submitted  (2 run | 0 fail | 51 done | 22 left)
    .
    13-Mar-2017 15:53:27 qc_coregister_group_anat_stereolin        finished   (1 run | 0 fail | 52 done | 22 left)
    .....
    13-Mar-2017 15:56:01 anat2func_subject2                        finished   (0 run | 0 fail | 53 done | 22 left)
    13-Mar-2017 15:56:01 concat_transf_nl_subject2                 submitted  (1 run | 0 fail | 53 done | 21 left)
    13-Mar-2017 15:56:03 concat_transf_nl_subject2                 finished   (0 run | 0 fail | 54 done | 21 left)
    13-Mar-2017 15:56:03 resample_subject2_session1_motor          submitted  (1 run | 0 fail | 54 done | 20 left)
    ..
    13-Mar-2017 15:56:58 resample_subject2_session1_motor          finished   (0 run | 0 fail | 55 done | 20 left)
    13-Mar-2017 15:56:58 qc_motion_subject2                        submitted  (1 run | 0 fail | 55 done | 19 left)
    13-Mar-2017 15:56:58 time_filter_subject2_session1_motor       submitted  (2 run | 0 fail | 55 done | 18 left)
    13-Mar-2017 15:56:58 rep_motion_stereo_subject2_session1_motor submitted  (3 run | 0 fail | 55 done | 17 left)
    13-Mar-2017 15:56:58 rep_target_stereo_subject2_session1_motor submitted  (4 run | 0 fail | 55 done | 16 left)
    13-Mar-2017 15:56:59 rep_target_stereo_subject2_session1_motor finished   (3 run | 0 fail | 56 done | 16 left)
    13-Mar-2017 15:57:00 time_filter_subject2_session1_motor       finished   (2 run | 0 fail | 57 done | 16 left)
    13-Mar-2017 15:57:03 qc_motion_subject2                        finished   (1 run | 0 fail | 58 done | 16 left)
    13-Mar-2017 15:57:03 mask_confounds_subject2                   submitted  (2 run | 0 fail | 58 done | 15 left)
    13-Mar-2017 15:57:03 qc_group_coregister_func                  submitted  (3 run | 0 fail | 58 done | 14 left)
    13-Mar-2017 15:57:03 qc_group_motion_estimation                submitted  (4 run | 0 fail | 58 done | 13 left)
    13-Mar-2017 15:57:05 rep_motion_stereo_subject2_session1_motor finished   (3 run | 0 fail | 59 done | 13 left)
    13-Mar-2017 15:57:05 rep_summary_intra                         submitted  (4 run | 0 fail | 59 done | 12 left)
    13-Mar-2017 15:57:09 qc_group_coregister_func                  finished   (3 run | 0 fail | 60 done | 12 left)
    13-Mar-2017 15:57:09 rep_summary_intra                         finished   (2 run | 0 fail | 61 done | 12 left)
    13-Mar-2017 15:57:09 rep_summary_func                          submitted  (3 run | 0 fail | 61 done | 11 left)
    13-Mar-2017 15:57:09 rep_average_func_stereo                   submitted  (4 run | 0 fail | 61 done | 10 left)
    .
    13-Mar-2017 15:57:11 rep_summary_func                          finished   (3 run | 0 fail | 62 done | 10 left)
    13-Mar-2017 15:57:11 rep_average_func_stereo                   finished   (2 run | 0 fail | 63 done | 10 left)
    13-Mar-2017 15:57:11 rep_mask_func_group_stereo                submitted  (3 run | 0 fail | 63 done | 9 left)
    13-Mar-2017 15:57:11 rep_avg_mask_func_stereo                  submitted  (4 run | 0 fail | 63 done | 8 left)
    13-Mar-2017 15:57:12 mask_confounds_subject2                   finished   (3 run | 0 fail | 64 done | 8 left)
    13-Mar-2017 15:57:12 build_confounds_subject2_session1_motor   submitted  (4 run | 0 fail | 64 done | 7 left)
    13-Mar-2017 15:57:13 rep_avg_mask_func_stereo                  finished   (3 run | 0 fail | 65 done | 7 left)
    13-Mar-2017 15:57:13 rep_bold_subject2                         submitted  (4 run | 0 fail | 65 done | 6 left)
    13-Mar-2017 15:57:14 qc_group_motion_estimation                finished   (3 run | 0 fail | 66 done | 6 left)
    13-Mar-2017 15:57:15 rep_mask_func_group_stereo                finished   (2 run | 0 fail | 67 done | 6 left)
    13-Mar-2017 15:57:17 build_confounds_subject2_session1_motor   finished   (1 run | 0 fail | 68 done | 6 left)
    13-Mar-2017 15:57:17 rep_bold_subject2                         finished   (0 run | 0 fail | 69 done | 6 left)
    13-Mar-2017 15:57:17 regress_confounds_subject2_session1_motor submitted  (1 run | 0 fail | 69 done | 5 left)
    13-Mar-2017 15:57:17 rep_motion_ind_subject2_session1_motor    submitted  (2 run | 0 fail | 69 done | 4 left)
    13-Mar-2017 15:57:17 rep_motion_ind_subject2_session1_motor    finished   (1 run | 0 fail | 70 done | 4 left)
    13-Mar-2017 15:57:18 regress_confounds_subject2_session1_motor finished   (0 run | 0 fail | 71 done | 4 left)
    13-Mar-2017 15:57:18 smooth_subject2_session1_motor            submitted  (1 run | 0 fail | 71 done | 3 left)
    13-Mar-2017 15:57:18 qc_group_scrubbing                        submitted  (2 run | 0 fail | 71 done | 2 left)
    13-Mar-2017 15:57:18 qc_group_scrubbing                        finished   (1 run | 0 fail | 72 done | 2 left)
    13-Mar-2017 15:57:18 rep_summary_scrubbing                     submitted  (2 run | 0 fail | 72 done | 1 left)
    13-Mar-2017 15:57:19 rep_summary_scrubbing                     finished   (1 run | 0 fail | 73 done | 1 left)
    13-Mar-2017 15:57:19 Stopping idle worker 2 (not enough jobs left to do).
    13-Mar-2017 15:57:35 smooth_subject2_session1_motor            finished   (0 run | 0 fail | 74 done | 1 left)
    13-Mar-2017 15:57:35 clean_subject2                            submitted  (1 run | 0 fail | 74 done | 0 left)
    Deamon terminated on 13-Mar-2017 15:57:36
    
    13-Mar-2017 15:57:36 clean_subject2                            finished   (0 run | 0 fail | 75 done | 0 left)
    13-Mar-2017 15:57:36 Stopping idle worker 1 (not enough jobs left to do).
    
    *******************************************
    Pipeline terminated on 13-Mar-2017 15:57:36
    All jobs have been successfully completed.
    


Once the pipeline has completed, an interactive report is built as part of the output. Just open the file [fmri_preprocess/report/index.html](./fmri_preprocess/report/index.html) in your browser. Note that the images of the test data have very low resolution. Check an example report on a large sample with typical resolution [here](https://simexp.github.io/qc_cobre/index.html).  
