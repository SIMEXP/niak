This tutorial shows how to run the SCORES pipeline. This tutorial only shows a limited subset of available options. See the [documentation](http://niak.simexp-lab.org/pipe_scores.html) of the pipeline for a more comprehensive list of options. The script of the tutorial can be downloaded [here](https://raw.githubusercontent.com/SIMEXP/niak_tutorials/master/scores/niak_tutorial_scores.m). A good starting point to write a new script is the following [template file](https://github.com/SIMEXP/niak/blob/master/template/niak_template_scores.m).

First download a small pre-processed fMRI dataset, with a structural scan.

```matlab
clear all
niak_gb_vars
path_data = [pwd filesep];
niak_wget('target_test_niak_mnc1'); % download demo data set
path_demo = [path_data 'target_test_niak_mnc1-' gb_niak_target_test ];
```

Then get the cambridge templates
```matlab
template.path = [path_demo '/demoniak_preproc/anat/template_cambridge_basc_multiscale_mnc_sym' ];
template.type =  'cambridge_template_mnc';
niak_wget(template);
```

Select a specific scale and template, in this case it is the scale 7
```matlab
scale = 7 ; % select a scale
template_data = [path_data 'template_cambridge_basc_multiscale_mnc_asym'];
template_name = sprintf('template_cambridge_basc_multiscale_sym_scale%03d.mnc.gz',scale);
system([' cp -r ' template.path filesep template_name ' ' path_demo '/demoniak_preproc/anat/']);
```

Grab the results from the NIAK fMRI preprocessing pipeline
```matlab
opt_g.min_nb_vol = 10; % the demo dataset is very short, so we have to lower considerably the minimum acceptable number of volumes per run
opt_g.type_files = 'scores'; % Specify to the grabber to prepare the files for the stability FIR pipeline
files_in = niak_grab_fmri_preprocess([ path_demo '/demoniak_preproc/' ],opt_g);
```

Set pipeline options 
```matlab
opt.folder_out = [path_data 'demo_scores/']; % Where to store the results
opt.flag_vol = true;
```

Generate the pipeline
```matlab
[pipeline, opt_scores] = niak_pipeline_scores(files_in,opt);
```
