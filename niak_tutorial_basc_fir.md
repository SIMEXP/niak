This tutorial shows how to run the BASC FIR pipeline. This tutorial only shows a limited subset of available options. See the [documentation](http://niak.simexp-lab.org/pipe_basc_fir.html) of the pipeline for a more comprehensive list of options. The script of the tutorial can be downloaded [here](https://raw.githubusercontent.com/SIMEXP/niak_tutorials/master/region_growing/niak_tutorial_basc_fir.m). A good starting point to write a new script is the following [template file](https://github.com/SIMEXP/niak/blob/master/template/niak_template_basc_fir.m).

First download a small pre-processed fMRI dataset, with a structural scan.

```matlab
clear
niak_wget('target_test_niak_mnc1');
```

Now, set up some parameters to filter out the data to be grabbed and the specify the location of the files to grab.

```matlab
opt_g.min_nb_vol = 20; % the demo dataset is very short, so we have to lower considerably the minimum acceptable number of volumes per run
opt_g.type_files = 'fir'; % Specify to the grabber to prepare the files for the stability FIR pipeline
opt_g.filter.run = {'motor'}; % Just grab the "motor" runs
path_demo = [path_data 'target_test_niak_mnc1-0.13.0/demoniak_preproc/']
files_in = niak_grab_fmri_preprocess(path_demo,opt_g);
```

Specify where to write the results.
```matlab
% Where to store the results
opt.folder_out = [path_data 'stability_fir/'];
```

Now, set up the timing of events and condition name.
```matlab
files_in.timing = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
opt.name_condition = 'motor';
opt.name_baseline  = 'rest';
```

Set the scales of analysis
```matlab
opt.grid_scales = [5 10]'; % Search for stable clusters in the range 10 to 500
opt.scales_maps = [  5  5  5  ; ...   % The scales that will be used to generate the maps of brain clusters and stability.
                    10 10 10  ];
```
Set stability fir parameters
```matlab
opt.stability_fir.nb_samps = 10;     % Number of bootstrap samples at the individual level. 100: the CI on indidividual stability is +/-0.1
opt.stability_fir.std_noise = 0;     % The standard deviation of the judo noise. The value 0 will not use judo noise.
opt.stability_group.nb_samps = 10;   % Number of bootstrap samples at the group level. 500: the CI on group stability is +/-0.05
opt.stability_group.min_subject = 2; % Lower the min number of subject ... there are only two subjects in the demo_niak.
```
Set the FIR estimation parameters
```matlab
opt.fir.nb_min_baseline = 1; % There is not much data in the demo_niak, so do not set a minimum on the number of points used to estimate the baseline
opt.fir.type_norm     = 'fir_shape'; % The type of normalization of the FIR. Only "fir_shape" is available (starts at zero, unit sum-of-squares)
opt.fir.time_window   = 20;          % The size (in sec) of the time window to evaluate the response
opt.fir.time_sampling = 1;           % The time between two samples for the estimated response. Do not go below 1/2 TR unless there is a very large number of trials.
opt.fir.max_interpolation = 15;      % Allow interpolations of up to 15 seconds to cover for scrubbing. That's because the small demo dataset has hardly any usable time window
```

The number of samples to estimate the false-discovery rate
```matlab
opt.nb_samps_fdr = 100;
```
Generate the pipeline
```matlab
[pipeline,opt_pipe] = niak_pipeline_stability_fir(files_in,opt);
```
