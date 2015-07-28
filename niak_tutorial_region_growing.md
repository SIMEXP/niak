This tutorial shows how to run the region growing pipeline. This tutorial only shows a limited subset of available options. See the [documentation](http://niak.simexp-lab.org/pipe_region_growing.html) of the pipeline for a more comprehensive list of options. The script of the tutorial can be downloaded [here](https://raw.githubusercontent.com/SIMEXP/niak_tutorials/master/region_growing/niak_tutorial_region_growing.m). A good starting point to write a new script is the following [template file](https://github.com/SIMEXP/niak/blob/master/template/niak_template_stability_rest.m).

First download a small pre-processed fMRI dataset, with a structural scan. 

```matlab
clear
niak_wget('target_test_niak_mnc1');
```

Now, set up some parameters to filter out the data to be grabbed and the specify the location of the files to grab.

```matlab
% The minimum number of volumes for an fMRI dataset to be included.
opt_g.min_nb_vol = 20;  
% The minimum xcorr score for an fMRI dataset to be included.
opt_g.min_xcorr_func = 0; 
% The minimum xcorr score for a structural dataset to be included.
opt_g.min_xcorr_anat = 0; 
% Specify to the grabber to prepare the files for the pipeline.
opt_g.type_files = 'roi'; 
% Location of your data to grab.
files_in = niak_grab_fmri_preprocess([path_data 'target_test_niak_mnc1-' gb_niak_target_test '/demoniak_preproc/'],opt_g); 
```

Specify where to write the results.
```matlab
% Where to store the results
opt.folder_out = [path_data 'region_growing/']; 
```

Now, set up some parameters for the region-growing algorithm
```matlab
% Only generate the ROI parcelation
opt.flag_roi = true; 
% The critical size for regions  
opt.region_growing.thre_size = 1000; 
```

Run the pipeline
```matlab
opt.flag_test = false;
[pipeline_rg,opt] = niak_pipeline_stability_rest(files_in,opt);
```
