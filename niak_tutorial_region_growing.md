This tutorial shows how to run the fMRI preprocessing pipeline. This tutorial only shows a limited subset of available options. See the [documentation](http://niak.simexp-lab.org/pipe_preprocessing.html) of the pipeline for a more comprehensive list of options. The script of the tutorial can be downloaded [here](https://raw.githubusercontent.com/SIMEXP/niak_tutorials/master/fmri_preprocessing/niak_tutorial_fmri_preprocessing.m). A good starting point to write a new script is the following [template file](https://github.com/SIMEXP/niak/blob/master/template/niak_template_fmri_preprocess.m).

First download a small fMRI dataset, with a structural scan. 

```matlab
clear
niak_wget('data_test_niak_mnc1');
```

Now, set up the names of the structural and functional files

```matlab
path_data = [pwd filesep];
% Structural scan
files_in.subject1.anat                = [path_data 'data_test_niak_mnc1/anat_subject1.mnc.gz'];       
% fMRI run 1
files_in.subject1.fmri.session1.motor = [path_data 'data_test_niak_mnc1/func_motor_subject1.mnc.gz']; 
```

We start by specifying where to write the results.
```matlab
% Where to store the results
opt.folder_out  = [path_data 'fmri_preprocess/'];    
```

Next we specify how many threads to use. A value of N means that, if there are enough jobs that can be executed simultaneously, for example because there are many subjects, up to N jobs can be executed in parallel. 
```
% Use up to four threads
opt.psom.max_queued = 4;       
```

We now set the options of the slice timing correction. Note that we specify the type of the scanner (in practice, only `'Siemens'` has an impact), because the definition of the scanner impacts the definition of the slice timing. 
```matlab
opt.slice_timing.type_acquisition = 'interleaved ascending'; 
opt.slice_timing.type_scanner     = 'Bruker';                
opt.slice_timing.delay_in_tr      = 0;                       
```

The voxel size for resampling in stereotaxic space, as well as the options for non-uniformity correction and temporal filtering.
```matlab
% The voxel size to use in the stereotaxic space
opt.resample_vol.voxel_size    = 10;
% Parameter for non-uniformity correction. 200 is a suggested value for 1.5T images, 75 for 3T images. 
opt.t1_preprocess.nu_correct.arg = '-distance 75'; 
% Cut-off frequency for high-pass filtering, or removal of low frequencies (in Hz). 
opt.time_filter.hp = 0.01; 
% Cut-off frequency for low-pass filtering, or removal of high frequencies (in Hz). 
opt.time_filter.lp = Inf;  
```

The option for global signal correction, scrubbing and spatial smoothing.
```matlab
% Apply global signal regression          
opt.regress_confounds.flag_gsc = true; 
opt.regress_confounds.flag_scrubbing = true;     
% The threshold on frame displacement for scrubbing 
opt.regress_confounds.thre_fd = 0.5;             
% Full-width at maximum (FWHM) of the Gaussian blurring kernel, in mm.
opt.smooth_vol.fwhm      = 6;  
```

Finally, we run the pipeline.
```matlab
niak_pipeline_fmri_preprocess(files_in,opt);
```
