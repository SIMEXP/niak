
# fMRI preprocessing
This tutorial shows how to run the NIAK fMRI preprocessing pipeline, using a limited set of options. See the [documentation](http://niak.simexp-lab.org/pipe_preprocessing.html) of the pipeline for a more comprehensive list of options. This tutorial can be downloaded as a notebook [here](https://raw.githubusercontent.com/SIMEXP/niak_tutorials/master/fmri_preprocessing/niak_tutorial_fmri_preprocessing.ipynb) and a matlab script [here](https://raw.githubusercontent.com/SIMEXP/niak_tutorials/master/fmri_preprocessing/niak_tutorial_fmri_preprocessing.m). To run this tutorial, we recommand to use [jupyter](http://jupyter.org/) from a niak docker container, as described in the [NIAK installation page](http://niak.simexp-lab.org/niak_installation.html). 

## Preparing files
First download a small fMRI dataset, with a structural scan. Be aware that all raw and derivatives data will be generated in the current folder. Note that you will need to manually remove the `data_test_niak_mnc1` and `fmri_preprocess` folders to restart this tutorial from scratch.


```octave
clear
niak_wget('data_test_niak_mnc1');
```

    --2016-10-15 17:04:06--  http://www.nitrc.org/frs/download.php/7241/data_test_niak_mnc1.zip
    Resolving www.nitrc.org (www.nitrc.org)... 132.239.16.23
    Connecting to www.nitrc.org (www.nitrc.org)|132.239.16.23|:80... connected.
    HTTP request sent, awaiting response... 200 OK
    Length: 2726269 (2.6M) [application/force-download]
    Saving to: `/sandbox/home/git/niak_tutorials/fmri_preprocessing/data_test_niak_mnc1/data_test_niak_mnc1.zip'
    
    100%[======================================>] 2,726,269    918K/s   in 2.9s    
    
    2016-10-15 17:04:10 (918 KB/s) - `/sandbox/home/git/niak_tutorials/fmri_preprocessing/data_test_niak_mnc1/data_test_niak_mnc1.zip' saved [2726269/2726269]
    
    Deleting file '/sandbox/home/git/niak_tutorials/fmri_preprocessing/data_test_niak_mnc1/data_test_niak_mnc1.zip' 
    ans = 0


Now, set up the names of the structural and functional files.


```octave
path_data = [pwd filesep];
% Structural scan
files_in.subject1.anat = ...
    [path_data 'data_test_niak_mnc1/anat_subject1.mnc.gz'];       
% fMRI run 1
files_in.subject1.fmri.session1.motor = ...
    [path_data 'data_test_niak_mnc1/func_motor_subject1.mnc.gz'];
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

# Resampling
The voxel size for resampling in stereotaxic space is specified by the user:


```octave
% The voxel size to use in the stereotaxic space
opt.resample_vol.voxel_size    = 10;
```

# T1 processing
The options for non-uniformity correction of the T1 image is often useful to tweak:


```octave
% Parameter for non-uniformity correction. 
% 200 is a suggested value for 1.5T images, 
% 75 for 3T images. 
opt.t1_preprocess.nu_correct.arg = '-distance 75';
```

# Regression of confounds
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

# Spatial smoothing
The size of the spatial Gaussian blurring kernel: 


```octave
% Full-width at maximum (FWHM) of the Gaussian blurring kernel, in mm.
opt.smooth_vol.fwhm      = 6;
```

# Run the pipeline
This command can take up to 20-30 minutes to complete. It runs the full preprocessing pipeline on one subject/run. The text output normally gets regularly updated while the pipeline progresses. If the output gets interrupted, try simply to re-execute the cell to refresh the outputs. 


```octave
niak_pipeline_fmri_preprocess(files_in,opt);
```

    Generating pipeline for individual fMRI preprocessing :
        Adding subject1 ; 0.23 sec
    Adding group-level quality control of coregistration in anatomical space (linear stereotaxic space) ; 0.02 sec
    Adding group-level quality control of coregistration in anatomical space (non-linear stereotaxic space) ; 0.01 sec
    Adding group-level quality control of coregistration in functional space ; 0.01 sec
    Adding group-level quality control of motion correction (motion parameters) ; 0.01 sec
    Adding group-level quality control of scrubbing time frames with excessive motion ; 0.00 sec
    Adding the report on fMRI preprocessing ; 0.52 sec
    
    Logs will be stored in /sandbox/home/git/niak_tutorials/fmri_preprocessing/fmri_preprocess/logs/
    Generating dependencies ...
       Percentage completed :  0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100- 0.12 sec
    Setting up the to-do list ...
       I found 50 job(s) to do.
    I could not find any log file. This pipeline has not been started (yet?). Press CTRL-C to cancel.
    Deamon started on 15-Oct-2016 17:04:21
    15-Oct-2016 17:04:21 Starting the pipeline manager...
    15-Oct-2016 17:04:21 Starting the garbage collector...
    15-Oct-2016 17:04:21 Starting worker number 1...
    15-Oct-2016 17:04:21 Starting worker number 2...
    
    Pipeline started on 15-Oct-2016 17:04:22
    user: , host: 6e3cbb9f4193, system: unix
    ****************************************
    15-Oct-2016 17:04:23 pipe_params                               submitted  (1 run / 0 fail / 0 done / 49 left)
    15-Oct-2016 17:04:23 resample_aal                              submitted  (2 run / 0 fail / 0 done / 48 left)
    15-Oct-2016 17:04:23 cp_confounds_keys                         submitted  (3 run / 0 fail / 0 done / 47 left)
    15-Oct-2016 17:04:23 cp_template                               submitted  (4 run / 0 fail / 0 done / 46 left)
    15-Oct-2016 17:04:23 pipe_params                               finished   (3 run / 0 fail / 1 done / 46 left)
    15-Oct-2016 17:04:23 cp_confounds_keys                         finished   (2 run / 0 fail / 2 done / 46 left)
    15-Oct-2016 17:04:23 cp_template                               finished   (1 run / 0 fail / 3 done / 46 left)
    15-Oct-2016 17:04:23 resample_fmri_stereo                      submitted  (2 run / 0 fail / 3 done / 45 left)
    15-Oct-2016 17:04:23 t1_preprocess_subject1                    submitted  (3 run / 0 fail / 3 done / 44 left)
    15-Oct-2016 17:04:23 slice_timing_subject1_session1_motor      submitted  (4 run / 0 fail / 3 done / 43 left)
    15-Oct-2016 17:04:24 resample_aal                              finished   (3 run / 0 fail / 4 done / 43 left)
    15-Oct-2016 17:04:24 rep_cp_report_templates                   submitted  (4 run / 0 fail / 4 done / 42 left)
    15-Oct-2016 17:04:25 resample_fmri_stereo                      finished   (3 run / 0 fail / 5 done / 42 left)
    15-Oct-2016 17:04:25 rep_params                                submitted  (4 run / 0 fail / 5 done / 41 left)
    15-Oct-2016 17:04:25 slice_timing_subject1_session1_motor      finished   (3 run / 0 fail / 6 done / 41 left)
    15-Oct-2016 17:04:25 motion_target_subject1_session1_motor     submitted  (4 run / 0 fail / 6 done / 40 left)
    15-Oct-2016 17:04:26 rep_cp_report_templates                   finished   (3 run / 0 fail / 7 done / 40 left)
    15-Oct-2016 17:04:26 rep_template_stereo                       submitted  (4 run / 0 fail / 7 done / 39 left)
    15-Oct-2016 17:04:26 motion_target_subject1_session1_motor     finished   (3 run / 0 fail / 8 done / 39 left)
    15-Oct-2016 17:04:26 motion_Wrun_subject1_session1_motor       submitted  (4 run / 0 fail / 8 done / 38 left)
    15-Oct-2016 17:04:35 rep_template_stereo                       finished   (3 run / 0 fail / 9 done / 38 left)
    15-Oct-2016 17:04:35 rep_t1_outline_registration               submitted  (4 run / 0 fail / 9 done / 37 left)
    15-Oct-2016 17:04:51 motion_Wrun_subject1_session1_motor       finished   (3 run / 0 fail / 10 done / 37 left)
    15-Oct-2016 17:04:51 motion_parameters_subject1_session1_motor submitted  (4 run / 0 fail / 10 done / 36 left)
    .
    15-Oct-2016 17:04:56 motion_parameters_subject1_session1_motor finished   (3 run / 0 fail / 11 done / 36 left)
    15-Oct-2016 17:04:56 rep_t1_outline_registration               finished   (2 run / 0 fail / 12 done / 36 left)
    15-Oct-2016 17:04:56 rep_template_stereo_overlay               submitted  (3 run / 0 fail / 12 done / 35 left)
    15-Oct-2016 17:04:56 rep_init_report                           submitted  (4 run / 0 fail / 12 done / 34 left)
    15-Oct-2016 17:04:56 rep_init_report                           finished   (3 run / 0 fail / 13 done / 34 left)
    15-Oct-2016 17:04:56 rep_motion_native_subject1_session1_motor submitted  (4 run / 0 fail / 13 done / 33 left)
    15-Oct-2016 17:04:57 rep_template_stereo_overlay               finished   (3 run / 0 fail / 14 done / 33 left)
    15-Oct-2016 17:04:57 rep_target_native_subject1_session1_motor submitted  (4 run / 0 fail / 14 done / 32 left)
    15-Oct-2016 17:04:58 rep_motion_native_subject1_session1_motor finished   (3 run / 0 fail / 15 done / 32 left)
    15-Oct-2016 17:04:58 rep_motion_report_subject1_session1_motor submitted  (4 run / 0 fail / 15 done / 31 left)
    15-Oct-2016 17:04:59 rep_target_native_subject1_session1_motor finished   (3 run / 0 fail / 16 done / 31 left)
    15-Oct-2016 17:04:59 rep_motion_report_subject1_session1_motor finished   (2 run / 0 fail / 17 done / 31 left)
    15-Oct-2016 17:04:59 rep_motion_report                         submitted  (3 run / 0 fail / 17 done / 30 left)
    15-Oct-2016 17:04:59 rep_motion_report                         finished   (2 run / 0 fail / 18 done / 30 left)


Once the pipeline has completed, an interactive report is built as part of the output. The following [link](fmri_preprocess/report/index.html) will take you there once the pipeline is completed. Note that because of the very low resolution in the functional images of these data, the T1-BOLD registration fails. 
