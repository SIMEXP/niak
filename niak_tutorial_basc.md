
This tutorial shows how to run the BASC pipeline. This tutorial only shows a limited subset of available options. See the [documentation](http://niak.simexp-lab.org/pipe_basc.html) of the pipeline for a more comprehensive list of options. The script of the tutorial can be downloaded [here](https://raw.githubusercontent.com/SIMEXP/niak_tutorials/master/basc/niak_tutorial_basc.m). 

# Prepare input files

## fMRI

First download a small pre-processed fMRI dataset, with a structural scan.


```octave
clear
path_data = [pwd filesep];
[status,msg,data_fmri] = niak_wget('cobre_lightweight20_nii');
```

When starting from fMRI data preprocessed with NIAK, it is possible to use niak_grab_fmri_preprocess on the output folder to collect the file names, as described in the [pipeline documentation](http://niak.simexp-lab.org/pipe_basc.html). In this case, we explicitely a few files:


```octave
file_pheno = [data_fmri.path filesep 'phenotypic_data.tsv.gz'];
tab = niak_read_csv_cell(file_pheno);
list_subject = tab(2:end,1);
files_in = struct;
for ss = 1:5
    files_in.data.(list_subject{ss}).sess1.rest = [data_fmri.path filesep 'fmri_' list_subject{ss} '.nii.gz'];
end
```

## Analysis mask

The pipeline also needs to have one mask of brain areas. The first step of BASC is to use a region growing algorithm to reduce the spatial dimension of fMRI data to about 1000 small regions (called atoms). This stage is very memory hungry, because it runs on a concatenation of all time series from all subjects. To save memory, the region growing is run on each area independently. Typically, the pipeline uses the AAL parcellation for that purpose (or, more precisely, a tweaked version of the AAL adapted to the MNI ICBM non-linear template, see the [doc](http://niak.simexp-lab.org/pipe_region_growing.html#publication-guidelines)). The NIAK preprocessing pipeline generates this mask, which is automatically grabbed by `niak_grab_fmri_preprocess`. But here we are using low resolution data which do not come with a mask, so we are going to grab the AAL template from NIAK and resample it at the right resolution.  


```octave
%% Prepare the analysis mask
% load global niak variables
niak_gb_vars
% the AAL template in niak
in.source = [GB_NIAK.path_niak filesep 'template' filesep 'roi_aal_3mm.mnc.gz'];
% Use fMRI data from the first subject as target
in.target = files_in.data.(list_subject{1}).sess1.rest;
% Where to write the resampled mask 
out = [path_data 'roi_aal_cobre.nii.gz'];
% resample the data
niak_brick_resample_vol(in,out);
```

    Copying or converting file /sandbox/home/git/niak_tutorials/basc/cobre_lightweight20/fmri_40061.nii.gz to /tmp/niak_tmp_509482616_roi_aal_cobre/target.mnc
    
     Reading source volume information /usr/local/niak//template/roi_aal_3mm.mnc.gz ...
    
     Reading target volume information /tmp/niak_tmp_509482616_roi_aal_cobre/target.mnc ...
    
     Resampling source on target ...
    Transforming slices:..........................Done
    Cleaning temporary files
    Done!
    Copying or converting file /tmp/niak_tmp_509482616_roi_aal_cobre/resample.mnc to /sandbox/home/git/niak_tutorials/basc/roi_aal_cobre.nii.gz
    Deleting folder '/tmp/niak_tmp_509482616_roi_aal_cobre/' 
    ans =
    
      scalar structure containing the fields:
    
        source = /usr/local/niak//template/roi_aal_3mm.mnc.gz
        target = /sandbox/home/git/niak_tutorials/basc/cobre_lightweight20/fmri_40061.nii.gz
        transformation = 
        transformation_stereo = gb_niak_omitted
    


Now we just need to tell the pipeline where to find the mask: 


```octave
% Specify the mask of brain areas for the pipeline
files_in.areas = out;
```

# Set the options of the pipeline
Now we set up where to store the results:


```octave
% Where to store the results
opt.folder_out = [path_data 'basc'];
```

This next parameter sets the size at which the region growing process stops (in mm$^3$). This does indirectly set the number of parcels covering the gray matter. A threshold of 1000 mm$^3$ will give about 1000 regions on the grey matter. Here we are going to reduce the dimension even more to speed up the pipeline.


```octave
% the size of the regions, when they stop growing. 
opt.region_growing.thre_size = 2000; 
```

The following parameter sets the values that will be explored regarding the number of clusters. A more exhaustive search, up to 500 clusters, could for example use an irregular grid like `[10:10:100 120:20:200 240:40:500]`. Also note that for each number of clusters, a number of solutions around those values, with different numbers being used at the individual and group levels, as well as the final consensus group partitions.  


```octave
% Search for stable clusters in the range 10 to 30
opt.grid_scales = [10:10:30]'; 
```

The following parameter is used to generate stability maps, and consensus partitions. Although stability is assessed over a wide range of parameters, those maps are only generated for select numbers in order to save disk space. For each set of results, three (integer) parameters actually need to be provided: the number of clusters at the individual level, at the group level and at the final consensus level. Each row will define a new set of results. We could for example use `opt.scales_maps = [10 10 10; 20 20 20];` to generate maps using the same number of clusters (5 and 10) at all three levels. For now we will leave that empty, which means we will not be generating any map. A first run of the pipeline is going to give us insights in the stable cluster solution, and provide data-driven suggestions about what number(s) of clusters to use. 


```octave
% Scale parameters to generate stability maps and consensus clusters
opt.scales_maps = [];
```

The following parameters control the number of bootstrap samples used to assess the stability of the clustering both at the individual level, and the group level. Note that with 100 samples, the confidence interval on the stability measures is $\pm 0.1$, while with 500 samples it reaches $\pm 0.05$. Here we will use only a few (20 samples) to speed-up the pipeline. 


```octave
% Number of bootstrap samples at the individual level.
opt.stability_tseries.nb_samps = 20;
% Number of bootstrap samples at the group level. 
opt.stability_group.nb_samps = 20; 
```

The final set of flags tell the pipeline which level of the pipeline to run. BASC can be used at the individual level, for each subject independently, or at the group level, to find a parcellation that is the consensus of those generated across all subjects and bootstrap replications of individual fMRI time series. In addition, BASC can generate so-called "mixed parcellation", which individual parcellations generated using the group parcellation as an initialization. It is possible to turn on/off the generation of consensus parcellations and stability map for each level of the pipeline (individual, group or mixed): 


```octave
% Generate maps/time series at the individual level
opt.flag_ind = false;   
% Generate maps/time series at the mixed level (group-level networks mixed with individual stability matrices).
opt.flag_mixed = false; 
% Generate maps/time series at the group level
opt.flag_group = true;  
```

# Running the pipeline

Now it is time to run the pipeline. As explained above, we will not at this stage generate any map or parcellation, but we will use the outputs to select the scales that we will explore in more details. The instruction to run the pipeline is: 


```octave
niak_pipeline_stability_rest(files_in,opt);
```

    
    Logs will be stored in /sandbox/home/git/niak_tutorials/basc/basc/logs/
    Generating dependencies ...
       Percentage completed :  0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100- 0.15 sec
    Setting up the to-do list ...
       I found 145 job(s) to do.
    I could not find any log file. This pipeline has not been started (yet?). Press CTRL-C to cancel.
    Deamon started on 12-Mar-2017 05:44:46
    12-Mar-2017 05:44:46 Starting the pipeline manager...
    12-Mar-2017 05:44:46 Starting the garbage collector...
    12-Mar-2017 05:44:46 Starting worker number 1...
    12-Mar-2017 05:44:46 Starting worker number 2...
    12-Mar-2017 05:44:46 Starting worker number 3...
    12-Mar-2017 05:44:46 Starting worker number 4...
    
    Pipeline started on 12-Mar-2017 05:44:47
    user: , host: 2080f78652f8, system: unix
    ****************************************
    12-Mar-2017 05:44:48 mask_areas                     submitted  (1 run | 0 fail | 0 done | 144 left)
    12-Mar-2017 05:44:48 mask_areas                     finished   (0 run | 0 fail | 1 done | 144 left)
    12-Mar-2017 05:44:48 tseries_40061_sess1_rest       submitted  (1 run | 0 fail | 1 done | 143 left)
    12-Mar-2017 05:44:48 tseries_40117_sess1_rest       submitted  (2 run | 0 fail | 1 done | 142 left)
    12-Mar-2017 05:44:48 tseries_40145_sess1_rest       submitted  (3 run | 0 fail | 1 done | 141 left)
    12-Mar-2017 05:44:48 tseries_40113_sess1_rest       submitted  (4 run | 0 fail | 1 done | 140 left)
    12-Mar-2017 05:44:48 tseries_40029_sess1_rest       submitted  (5 run | 0 fail | 1 done | 139 left)
    12-Mar-2017 05:44:48 neighbourhood_areas            submitted  (6 run | 0 fail | 1 done | 138 left)
    12-Mar-2017 05:44:51 neighbourhood_areas            finished   (5 run | 0 fail | 2 done | 138 left)
    12-Mar-2017 05:44:51 tseries_40145_sess1_rest       finished   (4 run | 0 fail | 3 done | 138 left)
    12-Mar-2017 05:44:51 tseries_40113_sess1_rest       finished   (3 run | 0 fail | 4 done | 138 left)
    12-Mar-2017 05:44:51 tseries_40029_sess1_rest       finished   (2 run | 0 fail | 5 done | 138 left)
    12-Mar-2017 05:44:52 tseries_40117_sess1_rest       finished   (1 run | 0 fail | 6 done | 138 left)
    12-Mar-2017 05:44:52 tseries_40061_sess1_rest       finished   (0 run | 0 fail | 7 done | 138 left)
    12-Mar-2017 05:44:52 region_growing_area_2001       submitted  (1 run | 0 fail | 7 done | 137 left)
    12-Mar-2017 05:44:52 region_growing_area_2002       submitted  (2 run | 0 fail | 7 done | 136 left)
    12-Mar-2017 05:44:52 region_growing_area_2101       submitted  (3 run | 0 fail | 7 done | 135 left)
    12-Mar-2017 05:44:52 region_growing_area_2102       submitted  (4 run | 0 fail | 7 done | 134 left)
    12-Mar-2017 05:44:52 region_growing_area_2111       submitted  (5 run | 0 fail | 7 done | 133 left)
    12-Mar-2017 05:44:52 region_growing_area_2112       submitted  (6 run | 0 fail | 7 done | 132 left)
    12-Mar-2017 05:44:52 region_growing_area_2201       submitted  (7 run | 0 fail | 7 done | 131 left)
    12-Mar-2017 05:44:52 region_growing_area_2202       submitted  (8 run | 0 fail | 7 done | 130 left)
    12-Mar-2017 05:44:53 region_growing_area_2001       finished   (7 run | 0 fail | 8 done | 130 left)
    12-Mar-2017 05:44:53 region_growing_area_2102       finished   (6 run | 0 fail | 9 done | 130 left)
    12-Mar-2017 05:44:53 region_growing_area_2211       submitted  (7 run | 0 fail | 9 done | 129 left)
    12-Mar-2017 05:44:53 region_growing_area_2212       submitted  (8 run | 0 fail | 9 done | 128 left)
    12-Mar-2017 05:44:54 region_growing_area_2002       finished   (7 run | 0 fail | 10 done | 128 left)
    12-Mar-2017 05:44:54 region_growing_area_2101       finished   (6 run | 0 fail | 11 done | 128 left)
    12-Mar-2017 05:44:54 region_growing_area_2111       finished   (5 run | 0 fail | 12 done | 128 left)
    12-Mar-2017 05:44:54 region_growing_area_2301       submitted  (6 run | 0 fail | 12 done | 127 left)
    12-Mar-2017 05:44:54 region_growing_area_2302       submitted  (7 run | 0 fail | 12 done | 126 left)
    12-Mar-2017 05:44:54 region_growing_area_2311       submitted  (8 run | 0 fail | 12 done | 125 left)
    12-Mar-2017 05:44:54 region_growing_area_2112       finished   (7 run | 0 fail | 13 done | 125 left)
    12-Mar-2017 05:44:54 region_growing_area_2201       finished   (6 run | 0 fail | 14 done | 125 left)
    12-Mar-2017 05:44:54 region_growing_area_2202       finished   (5 run | 0 fail | 15 done | 125 left)
    12-Mar-2017 05:44:54 region_growing_area_2211       finished   (4 run | 0 fail | 16 done | 125 left)
    12-Mar-2017 05:44:54 region_growing_area_2312       submitted  (5 run | 0 fail | 16 done | 124 left)
    12-Mar-2017 05:44:54 region_growing_area_2321       submitted  (6 run | 0 fail | 16 done | 123 left)
    12-Mar-2017 05:44:55 region_growing_area_2301       finished   (5 run | 0 fail | 17 done | 123 left)
    12-Mar-2017 05:44:55 region_growing_area_2322       submitted  (6 run | 0 fail | 17 done | 122 left)
    12-Mar-2017 05:44:55 region_growing_area_2331       submitted  (7 run | 0 fail | 17 done | 121 left)
    12-Mar-2017 05:44:55 region_growing_area_2332       submitted  (8 run | 0 fail | 17 done | 120 left)
    12-Mar-2017 05:44:56 region_growing_area_2212       finished   (7 run | 0 fail | 18 done | 120 left)
    12-Mar-2017 05:44:56 region_growing_area_2302       finished   (6 run | 0 fail | 19 done | 120 left)
    12-Mar-2017 05:44:56 region_growing_area_2311       finished   (5 run | 0 fail | 20 done | 120 left)
    12-Mar-2017 05:44:56 region_growing_area_2312       finished   (4 run | 0 fail | 21 done | 120 left)
    12-Mar-2017 05:44:56 region_growing_area_2401       submitted  (5 run | 0 fail | 21 done | 119 left)
    12-Mar-2017 05:44:56 region_growing_area_2402       submitted  (6 run | 0 fail | 21 done | 118 left)
    12-Mar-2017 05:44:56 region_growing_area_2501       submitted  (7 run | 0 fail | 21 done | 117 left)
    12-Mar-2017 05:44:56 region_growing_area_2502       submitted  (8 run | 0 fail | 21 done | 116 left)
    12-Mar-2017 05:44:56 region_growing_area_2321       finished   (7 run | 0 fail | 22 done | 116 left)
    12-Mar-2017 05:44:56 region_growing_area_2322       finished   (6 run | 0 fail | 23 done | 116 left)
    12-Mar-2017 05:44:56 region_growing_area_2332       finished   (5 run | 0 fail | 24 done | 116 left)
    12-Mar-2017 05:44:56 region_growing_area_2601       submitted  (6 run | 0 fail | 24 done | 115 left)
    12-Mar-2017 05:44:56 region_growing_area_2602       submitted  (7 run | 0 fail | 24 done | 114 left)
    12-Mar-2017 05:44:57 region_growing_area_2331       finished   (6 run | 0 fail | 25 done | 114 left)
    12-Mar-2017 05:44:57 region_growing_area_2402       finished   (5 run | 0 fail | 26 done | 114 left)
    12-Mar-2017 05:44:57 region_growing_area_2501       finished   (4 run | 0 fail | 27 done | 114 left)
    12-Mar-2017 05:44:57 region_growing_area_2502       finished   (3 run | 0 fail | 28 done | 114 left)
    12-Mar-2017 05:44:57 region_growing_area_2611       submitted  (4 run | 0 fail | 28 done | 113 left)
    12-Mar-2017 05:44:57 region_growing_area_2612       submitted  (5 run | 0 fail | 28 done | 112 left)
    12-Mar-2017 05:44:57 region_growing_area_2701       submitted  (6 run | 0 fail | 28 done | 111 left)
    12-Mar-2017 05:44:57 region_growing_area_2702       submitted  (7 run | 0 fail | 28 done | 110 left)
    12-Mar-2017 05:44:57 region_growing_area_3001       submitted  (8 run | 0 fail | 28 done | 109 left)
    12-Mar-2017 05:44:57 region_growing_area_2401       finished   (7 run | 0 fail | 29 done | 109 left)
    12-Mar-2017 05:44:57 region_growing_area_2601       finished   (6 run | 0 fail | 30 done | 109 left)
    12-Mar-2017 05:44:57 region_growing_area_2602       finished   (5 run | 0 fail | 31 done | 109 left)
    12-Mar-2017 05:44:57 region_growing_area_2611       finished   (4 run | 0 fail | 32 done | 109 left)
    12-Mar-2017 05:44:57 region_growing_area_2612       finished   (3 run | 0 fail | 33 done | 109 left)
    12-Mar-2017 05:44:57 region_growing_area_3002       submitted  (4 run | 0 fail | 33 done | 108 left)
    12-Mar-2017 05:44:57 region_growing_area_4001       submitted  (5 run | 0 fail | 33 done | 107 left)
    12-Mar-2017 05:44:57 region_growing_area_4002       submitted  (6 run | 0 fail | 33 done | 106 left)
    12-Mar-2017 05:44:57 region_growing_area_4011       submitted  (7 run | 0 fail | 33 done | 105 left)
    12-Mar-2017 05:44:57 region_growing_area_4012       submitted  (8 run | 0 fail | 33 done | 104 left)
    12-Mar-2017 05:44:58 region_growing_area_2701       finished   (7 run | 0 fail | 34 done | 104 left)
    12-Mar-2017 05:44:58 region_growing_area_2702       finished   (6 run | 0 fail | 35 done | 104 left)
    12-Mar-2017 05:44:58 region_growing_area_3001       finished   (5 run | 0 fail | 36 done | 104 left)
    12-Mar-2017 05:44:58 region_growing_area_4021       submitted  (6 run | 0 fail | 36 done | 103 left)
    12-Mar-2017 05:44:58 region_growing_area_4022       submitted  (7 run | 0 fail | 36 done | 102 left)
    12-Mar-2017 05:44:58 region_growing_area_4101       submitted  (8 run | 0 fail | 36 done | 101 left)
    12-Mar-2017 05:44:59 region_growing_area_3002       finished   (7 run | 0 fail | 37 done | 101 left)
    12-Mar-2017 05:44:59 region_growing_area_4102       submitted  (8 run | 0 fail | 37 done | 100 left)
    12-Mar-2017 05:44:59 region_growing_area_4012       finished   (7 run | 0 fail | 38 done | 100 left)
    12-Mar-2017 05:44:59 region_growing_area_4002       finished   (6 run | 0 fail | 39 done | 100 left)
    12-Mar-2017 05:44:59 region_growing_area_4011       finished   (5 run | 0 fail | 40 done | 100 left)
    12-Mar-2017 05:44:59 region_growing_area_4001       finished   (4 run | 0 fail | 41 done | 100 left)
    12-Mar-2017 05:44:59 region_growing_area_4111       submitted  (5 run | 0 fail | 41 done | 99 left)
    12-Mar-2017 05:44:59 region_growing_area_4112       submitted  (6 run | 0 fail | 41 done | 98 left)
    12-Mar-2017 05:44:59 region_growing_area_4201       submitted  (7 run | 0 fail | 41 done | 97 left)
    12-Mar-2017 05:44:59 region_growing_area_4202       submitted  (8 run | 0 fail | 41 done | 96 left)
    12-Mar-2017 05:45:00 region_growing_area_4021       finished   (7 run | 0 fail | 42 done | 96 left)
    12-Mar-2017 05:45:00 region_growing_area_4022       finished   (6 run | 0 fail | 43 done | 96 left)
    12-Mar-2017 05:45:00 region_growing_area_4101       finished   (5 run | 0 fail | 44 done | 96 left)
    12-Mar-2017 05:45:00 region_growing_area_4102       finished   (4 run | 0 fail | 45 done | 96 left)
    12-Mar-2017 05:45:00 region_growing_area_5001       submitted  (5 run | 0 fail | 45 done | 95 left)
    12-Mar-2017 05:45:00 region_growing_area_5002       submitted  (6 run | 0 fail | 45 done | 94 left)
    12-Mar-2017 05:45:00 region_growing_area_5011       submitted  (7 run | 0 fail | 45 done | 93 left)
    12-Mar-2017 05:45:00 region_growing_area_4201       finished   (6 run | 0 fail | 46 done | 93 left)
    12-Mar-2017 05:45:00 region_growing_area_5012       submitted  (7 run | 0 fail | 46 done | 92 left)
    12-Mar-2017 05:45:01 region_growing_area_4112       finished   (6 run | 0 fail | 47 done | 92 left)
    12-Mar-2017 05:45:01 region_growing_area_4202       finished   (5 run | 0 fail | 48 done | 92 left)
    12-Mar-2017 05:45:01 region_growing_area_5021       submitted  (6 run | 0 fail | 48 done | 91 left)
    12-Mar-2017 05:45:01 region_growing_area_5022       submitted  (7 run | 0 fail | 48 done | 90 left)
    12-Mar-2017 05:45:01 region_growing_area_4111       finished   (6 run | 0 fail | 49 done | 90 left)
    12-Mar-2017 05:45:01 region_growing_area_5101       submitted  (7 run | 0 fail | 49 done | 89 left)
    12-Mar-2017 05:45:01 region_growing_area_5002       finished   (6 run | 0 fail | 50 done | 89 left)
    12-Mar-2017 05:45:01 region_growing_area_5102       submitted  (7 run | 0 fail | 50 done | 88 left)
    12-Mar-2017 05:45:01 region_growing_area_5201       submitted  (8 run | 0 fail | 50 done | 87 left)
    12-Mar-2017 05:45:02 region_growing_area_5001       finished   (7 run | 0 fail | 51 done | 87 left)
    12-Mar-2017 05:45:02 region_growing_area_5011       finished   (6 run | 0 fail | 52 done | 87 left)
    12-Mar-2017 05:45:02 region_growing_area_5012       finished   (5 run | 0 fail | 53 done | 87 left)
    12-Mar-2017 05:45:02 region_growing_area_5202       submitted  (6 run | 0 fail | 53 done | 86 left)
    12-Mar-2017 05:45:02 region_growing_area_5301       submitted  (7 run | 0 fail | 53 done | 85 left)
    12-Mar-2017 05:45:02 region_growing_area_5302       submitted  (8 run | 0 fail | 53 done | 84 left)
    12-Mar-2017 05:45:03 region_growing_area_5021       finished   (7 run | 0 fail | 54 done | 84 left)
    12-Mar-2017 05:45:03 region_growing_area_5022       finished   (6 run | 0 fail | 55 done | 84 left)
    12-Mar-2017 05:45:03 region_growing_area_5401       submitted  (7 run | 0 fail | 55 done | 83 left)
    12-Mar-2017 05:45:03 region_growing_area_5101       finished   (6 run | 0 fail | 56 done | 83 left)
    12-Mar-2017 05:45:03 region_growing_area_5102       finished   (5 run | 0 fail | 57 done | 83 left)
    12-Mar-2017 05:45:03 region_growing_area_5402       submitted  (6 run | 0 fail | 57 done | 82 left)
    12-Mar-2017 05:45:03 region_growing_area_6001       submitted  (7 run | 0 fail | 57 done | 81 left)
    12-Mar-2017 05:45:03 region_growing_area_6002       submitted  (8 run | 0 fail | 57 done | 80 left)
    12-Mar-2017 05:45:04 region_growing_area_5201       finished   (7 run | 0 fail | 58 done | 80 left)
    12-Mar-2017 05:45:04 region_growing_area_5301       finished   (6 run | 0 fail | 59 done | 80 left)
    12-Mar-2017 05:45:04 region_growing_area_5302       finished   (5 run | 0 fail | 60 done | 80 left)
    12-Mar-2017 05:45:04 region_growing_area_6101       submitted  (6 run | 0 fail | 60 done | 79 left)
    12-Mar-2017 05:45:04 region_growing_area_6102       submitted  (7 run | 0 fail | 60 done | 78 left)
    12-Mar-2017 05:45:04 region_growing_area_6201       submitted  (8 run | 0 fail | 60 done | 77 left)
    12-Mar-2017 05:45:04 region_growing_area_5202       finished   (7 run | 0 fail | 61 done | 77 left)
    12-Mar-2017 05:45:04 region_growing_area_5401       finished   (6 run | 0 fail | 62 done | 77 left)
    12-Mar-2017 05:45:04 region_growing_area_6202       submitted  (7 run | 0 fail | 62 done | 76 left)
    12-Mar-2017 05:45:04 region_growing_area_6211       submitted  (8 run | 0 fail | 62 done | 75 left)
    12-Mar-2017 05:45:05 region_growing_area_5402       finished   (7 run | 0 fail | 63 done | 75 left)
    12-Mar-2017 05:45:05 region_growing_area_6001       finished   (6 run | 0 fail | 64 done | 75 left)
    12-Mar-2017 05:45:05 region_growing_area_6002       finished   (5 run | 0 fail | 65 done | 75 left)
    12-Mar-2017 05:45:05 region_growing_area_6212       submitted  (6 run | 0 fail | 65 done | 74 left)
    12-Mar-2017 05:45:05 region_growing_area_6221       submitted  (7 run | 0 fail | 65 done | 73 left)
    12-Mar-2017 05:45:05 region_growing_area_6222       submitted  (8 run | 0 fail | 65 done | 72 left)
    12-Mar-2017 05:45:06 region_growing_area_6102       finished   (7 run | 0 fail | 66 done | 72 left)
    12-Mar-2017 05:45:06 region_growing_area_6201       finished   (6 run | 0 fail | 67 done | 72 left)
    12-Mar-2017 05:45:06 region_growing_area_6301       submitted  (7 run | 0 fail | 67 done | 71 left)
    12-Mar-2017 05:45:06 region_growing_area_6302       submitted  (8 run | 0 fail | 67 done | 70 left)
    12-Mar-2017 05:45:06 region_growing_area_6101       finished   (7 run | 0 fail | 68 done | 70 left)
    12-Mar-2017 05:45:06 region_growing_area_6202       finished   (6 run | 0 fail | 69 done | 70 left)
    12-Mar-2017 05:45:06 region_growing_area_6211       finished   (5 run | 0 fail | 70 done | 70 left)
    12-Mar-2017 05:45:06 region_growing_area_6221       finished   (4 run | 0 fail | 71 done | 70 left)
    12-Mar-2017 05:45:06 region_growing_area_6401       submitted  (5 run | 0 fail | 71 done | 69 left)
    12-Mar-2017 05:45:06 region_growing_area_6402       submitted  (6 run | 0 fail | 71 done | 68 left)
    12-Mar-2017 05:45:06 region_growing_area_7001       submitted  (7 run | 0 fail | 71 done | 67 left)
    12-Mar-2017 05:45:06 region_growing_area_7002       submitted  (8 run | 0 fail | 71 done | 66 left)
    12-Mar-2017 05:45:07 region_growing_area_6212       finished   (7 run | 0 fail | 72 done | 66 left)
    12-Mar-2017 05:45:07 region_growing_area_6222       finished   (6 run | 0 fail | 73 done | 66 left)
    12-Mar-2017 05:45:07 region_growing_area_7011       submitted  (7 run | 0 fail | 73 done | 65 left)
    12-Mar-2017 05:45:07 region_growing_area_7012       submitted  (8 run | 0 fail | 73 done | 64 left)
    12-Mar-2017 05:45:08 region_growing_area_6301       finished   (7 run | 0 fail | 74 done | 64 left)
    12-Mar-2017 05:45:08 region_growing_area_6302       finished   (6 run | 0 fail | 75 done | 64 left)
    12-Mar-2017 05:45:08 region_growing_area_7021       submitted  (7 run | 0 fail | 75 done | 63 left)
    12-Mar-2017 05:45:08 region_growing_area_6401       finished   (6 run | 0 fail | 76 done | 63 left)
    12-Mar-2017 05:45:08 region_growing_area_6402       finished   (5 run | 0 fail | 77 done | 63 left)
    12-Mar-2017 05:45:08 region_growing_area_7022       submitted  (6 run | 0 fail | 77 done | 62 left)
    12-Mar-2017 05:45:08 region_growing_area_7101       submitted  (7 run | 0 fail | 77 done | 61 left)
    12-Mar-2017 05:45:08 region_growing_area_7102       submitted  (8 run | 0 fail | 77 done | 60 left)
    12-Mar-2017 05:45:08 region_growing_area_7002       finished   (7 run | 0 fail | 78 done | 60 left)
    12-Mar-2017 05:45:09 region_growing_area_7001       finished   (6 run | 0 fail | 79 done | 60 left)
    12-Mar-2017 05:45:09 region_growing_area_7011       finished   (5 run | 0 fail | 80 done | 60 left)
    12-Mar-2017 05:45:09 region_growing_area_8101       submitted  (6 run | 0 fail | 80 done | 59 left)
    12-Mar-2017 05:45:09 region_growing_area_8102       submitted  (7 run | 0 fail | 80 done | 58 left)
    12-Mar-2017 05:45:09 region_growing_area_8111       submitted  (8 run | 0 fail | 80 done | 57 left)
    12-Mar-2017 05:45:09 region_growing_area_7012       finished   (7 run | 0 fail | 81 done | 57 left)
    12-Mar-2017 05:45:09 region_growing_area_7021       finished   (6 run | 0 fail | 82 done | 57 left)
    12-Mar-2017 05:45:09 region_growing_area_7102       finished   (5 run | 0 fail | 83 done | 57 left)
    12-Mar-2017 05:45:09 region_growing_area_8112       submitted  (6 run | 0 fail | 83 done | 56 left)
    12-Mar-2017 05:45:09 region_growing_area_8121       submitted  (7 run | 0 fail | 83 done | 55 left)
    12-Mar-2017 05:45:09 region_growing_area_8122       submitted  (8 run | 0 fail | 83 done | 54 left)
    12-Mar-2017 05:45:09 region_growing_area_7022       finished   (7 run | 0 fail | 84 done | 54 left)
    12-Mar-2017 05:45:10 region_growing_area_7101       finished   (6 run | 0 fail | 85 done | 54 left)
    12-Mar-2017 05:45:10 region_growing_area_8102       finished   (5 run | 0 fail | 86 done | 54 left)
    12-Mar-2017 05:45:10 region_growing_area_8201       submitted  (6 run | 0 fail | 86 done | 53 left)
    12-Mar-2017 05:45:10 region_growing_area_8202       submitted  (7 run | 0 fail | 86 done | 52 left)
    12-Mar-2017 05:45:10 region_growing_area_8211       submitted  (8 run | 0 fail | 86 done | 51 left)
    12-Mar-2017 05:45:10 region_growing_area_8101       finished   (7 run | 0 fail | 87 done | 51 left)
    12-Mar-2017 05:45:11 region_growing_area_8111       finished   (6 run | 0 fail | 88 done | 51 left)
    12-Mar-2017 05:45:11 region_growing_area_8212       submitted  (7 run | 0 fail | 88 done | 50 left)
    12-Mar-2017 05:45:11 region_growing_area_8112       finished   (6 run | 0 fail | 89 done | 50 left)
    12-Mar-2017 05:45:11 region_growing_area_8121       finished   (5 run | 0 fail | 90 done | 50 left)
    12-Mar-2017 05:45:11 region_growing_area_8122       finished   (4 run | 0 fail | 91 done | 50 left)
    12-Mar-2017 05:45:11 region_growing_area_8301       submitted  (5 run | 0 fail | 91 done | 49 left)
    12-Mar-2017 05:45:11 region_growing_area_8302       submitted  (6 run | 0 fail | 91 done | 48 left)
    12-Mar-2017 05:45:11 region_growing_area_9001       submitted  (7 run | 0 fail | 91 done | 47 left)
    12-Mar-2017 05:45:11 region_growing_area_9002       submitted  (8 run | 0 fail | 91 done | 46 left)
    12-Mar-2017 05:45:12 region_growing_area_8201       finished   (7 run | 0 fail | 92 done | 46 left)
    12-Mar-2017 05:45:12 region_growing_area_8202       finished   (6 run | 0 fail | 93 done | 46 left)
    12-Mar-2017 05:45:12 region_growing_area_8211       finished   (5 run | 0 fail | 94 done | 46 left)
    12-Mar-2017 05:45:12 region_growing_area_8212       finished   (4 run | 0 fail | 95 done | 46 left)
    12-Mar-2017 05:45:12 region_growing_area_9011       submitted  (5 run | 0 fail | 95 done | 45 left)
    12-Mar-2017 05:45:12 region_growing_area_9012       submitted  (6 run | 0 fail | 95 done | 44 left)
    12-Mar-2017 05:45:12 region_growing_area_9021       submitted  (7 run | 0 fail | 95 done | 43 left)
    12-Mar-2017 05:45:12 region_growing_area_9022       submitted  (8 run | 0 fail | 95 done | 42 left)
    12-Mar-2017 05:45:13 region_growing_area_8301       finished   (7 run | 0 fail | 96 done | 42 left)
    12-Mar-2017 05:45:13 region_growing_area_9001       finished   (6 run | 0 fail | 97 done | 42 left)
    12-Mar-2017 05:45:13 region_growing_area_9002       finished   (5 run | 0 fail | 98 done | 42 left)
    12-Mar-2017 05:45:13 region_growing_area_9031       submitted  (6 run | 0 fail | 98 done | 41 left)
    12-Mar-2017 05:45:13 region_growing_area_9032       submitted  (7 run | 0 fail | 98 done | 40 left)
    12-Mar-2017 05:45:13 region_growing_area_9041       submitted  (8 run | 0 fail | 98 done | 39 left)
    12-Mar-2017 05:45:14 region_growing_area_8302       finished   (7 run | 0 fail | 99 done | 39 left)
    12-Mar-2017 05:45:14 region_growing_area_9042       submitted  (8 run | 0 fail | 99 done | 38 left)
    12-Mar-2017 05:45:14 region_growing_area_9011       finished   (7 run | 0 fail | 100 done | 38 left)
    12-Mar-2017 05:45:14 region_growing_area_9021       finished   (6 run | 0 fail | 101 done | 38 left)
    12-Mar-2017 05:45:14 region_growing_area_9022       finished   (5 run | 0 fail | 102 done | 38 left)
    12-Mar-2017 05:45:14 region_growing_area_9051       submitted  (6 run | 0 fail | 102 done | 37 left)
    12-Mar-2017 05:45:14 region_growing_area_9052       submitted  (7 run | 0 fail | 102 done | 36 left)
    12-Mar-2017 05:45:14 region_growing_area_9061       submitted  (8 run | 0 fail | 102 done | 35 left)
    12-Mar-2017 05:45:15 region_growing_area_9012       finished   (7 run | 0 fail | 103 done | 35 left)
    12-Mar-2017 05:45:15 region_growing_area_9031       finished   (6 run | 0 fail | 104 done | 35 left)
    12-Mar-2017 05:45:15 region_growing_area_9032       finished   (5 run | 0 fail | 105 done | 35 left)
    12-Mar-2017 05:45:15 region_growing_area_9041       finished   (4 run | 0 fail | 106 done | 35 left)
    12-Mar-2017 05:45:15 region_growing_area_9062       submitted  (5 run | 0 fail | 106 done | 34 left)
    12-Mar-2017 05:45:15 region_growing_area_9071       submitted  (6 run | 0 fail | 106 done | 33 left)
    12-Mar-2017 05:45:15 region_growing_area_9072       submitted  (7 run | 0 fail | 106 done | 32 left)
    12-Mar-2017 05:45:15 region_growing_area_9081       submitted  (8 run | 0 fail | 106 done | 31 left)
    12-Mar-2017 05:45:16 region_growing_area_9042       finished   (7 run | 0 fail | 107 done | 31 left)
    12-Mar-2017 05:45:16 region_growing_area_9051       finished   (6 run | 0 fail | 108 done | 31 left)
    12-Mar-2017 05:45:16 region_growing_area_9052       finished   (5 run | 0 fail | 109 done | 31 left)
    12-Mar-2017 05:45:16 region_growing_area_9061       finished   (4 run | 0 fail | 110 done | 31 left)
    12-Mar-2017 05:45:16 region_growing_area_9082       submitted  (5 run | 0 fail | 110 done | 30 left)
    12-Mar-2017 05:45:16 region_growing_area_9100       submitted  (6 run | 0 fail | 110 done | 29 left)
    12-Mar-2017 05:45:16 region_growing_area_9110       submitted  (7 run | 0 fail | 110 done | 28 left)
    12-Mar-2017 05:45:16 region_growing_area_9120       submitted  (8 run | 0 fail | 110 done | 27 left)
    12-Mar-2017 05:45:16 region_growing_area_9071       finished   (7 run | 0 fail | 111 done | 27 left)
    12-Mar-2017 05:45:16 region_growing_area_9072       finished   (6 run | 0 fail | 112 done | 27 left)
    12-Mar-2017 05:45:16 region_growing_area_9130       submitted  (7 run | 0 fail | 112 done | 26 left)
    12-Mar-2017 05:45:16 region_growing_area_9140       submitted  (8 run | 0 fail | 112 done | 25 left)
    12-Mar-2017 05:45:17 region_growing_area_9062       finished   (7 run | 0 fail | 113 done | 25 left)
    12-Mar-2017 05:45:17 region_growing_area_9081       finished   (6 run | 0 fail | 114 done | 25 left)
    12-Mar-2017 05:45:17 region_growing_area_9100       finished   (5 run | 0 fail | 115 done | 25 left)
    12-Mar-2017 05:45:17 region_growing_area_9150       submitted  (6 run | 0 fail | 115 done | 24 left)
    12-Mar-2017 05:45:17 region_growing_area_9160       submitted  (7 run | 0 fail | 115 done | 23 left)
    12-Mar-2017 05:45:17 region_growing_area_9170       submitted  (8 run | 0 fail | 115 done | 22 left)
    12-Mar-2017 05:45:17 region_growing_area_9082       finished   (7 run | 0 fail | 116 done | 22 left)
    12-Mar-2017 05:45:18 region_growing_area_9110       finished   (6 run | 0 fail | 117 done | 22 left)
    12-Mar-2017 05:45:18 region_growing_area_9120       finished   (5 run | 0 fail | 118 done | 22 left)
    12-Mar-2017 05:45:18 region_growing_area_9130       finished   (4 run | 0 fail | 119 done | 22 left)
    12-Mar-2017 05:45:18 region_growing_area_9140       finished   (3 run | 0 fail | 120 done | 22 left)
    12-Mar-2017 05:45:19 region_growing_area_9150       finished   (2 run | 0 fail | 121 done | 22 left)
    12-Mar-2017 05:45:19 region_growing_area_9160       finished   (1 run | 0 fail | 122 done | 22 left)
    12-Mar-2017 05:45:19 region_growing_area_9170       finished   (0 run | 0 fail | 123 done | 22 left)
    12-Mar-2017 05:45:19 merge_part                     submitted  (1 run | 0 fail | 123 done | 21 left)
    12-Mar-2017 05:45:19 merge_part                     finished   (0 run | 0 fail | 124 done | 21 left)
    12-Mar-2017 05:45:19 tseries_atoms_40061_sess1_rest submitted  (1 run | 0 fail | 124 done | 20 left)
    12-Mar-2017 05:45:19 tseries_atoms_40117_sess1_rest submitted  (2 run | 0 fail | 124 done | 19 left)
    12-Mar-2017 05:45:19 tseries_atoms_40145_sess1_rest submitted  (3 run | 0 fail | 124 done | 18 left)
    12-Mar-2017 05:45:19 tseries_atoms_40113_sess1_rest submitted  (4 run | 0 fail | 124 done | 17 left)
    12-Mar-2017 05:45:19 tseries_atoms_40029_sess1_rest submitted  (5 run | 0 fail | 124 done | 16 left)
    12-Mar-2017 05:45:21 tseries_atoms_40117_sess1_rest finished   (4 run | 0 fail | 125 done | 16 left)
    12-Mar-2017 05:45:21 tseries_atoms_40145_sess1_rest finished   (3 run | 0 fail | 126 done | 16 left)
    12-Mar-2017 05:45:21 tseries_atoms_40029_sess1_rest finished   (2 run | 0 fail | 127 done | 16 left)
    12-Mar-2017 05:45:21 stability_ind_40117            submitted  (3 run | 0 fail | 127 done | 15 left)
    12-Mar-2017 05:45:21 stability_ind_40145            submitted  (4 run | 0 fail | 127 done | 14 left)
    12-Mar-2017 05:45:21 stability_ind_40029            submitted  (5 run | 0 fail | 127 done | 13 left)
    12-Mar-2017 05:45:21 tseries_atoms_40113_sess1_rest finished   (4 run | 0 fail | 128 done | 13 left)
    12-Mar-2017 05:45:21 stability_ind_40113            submitted  (5 run | 0 fail | 128 done | 12 left)
    .
    12-Mar-2017 05:45:23 tseries_atoms_40061_sess1_rest finished   (4 run | 0 fail | 129 done | 12 left)
    12-Mar-2017 05:45:23 stability_ind_40061            submitted  (5 run | 0 fail | 129 done | 11 left)
    ..
    12-Mar-2017 05:46:25 stability_ind_40113            finished   (4 run | 0 fail | 130 done | 11 left)
    12-Mar-2017 05:46:25 msteps_ind_40113               submitted  (5 run | 0 fail | 130 done | 10 left)
    12-Mar-2017 05:46:26 stability_ind_40145            finished   (4 run | 0 fail | 131 done | 10 left)
    12-Mar-2017 05:46:26 stability_ind_40029            finished   (3 run | 0 fail | 132 done | 10 left)
    12-Mar-2017 05:46:26 msteps_ind_40145               submitted  (4 run | 0 fail | 132 done | 9 left)
    12-Mar-2017 05:46:26 msteps_ind_40029               submitted  (5 run | 0 fail | 132 done | 8 left)
    12-Mar-2017 05:46:26 stability_ind_40117            finished   (4 run | 0 fail | 133 done | 8 left)
    12-Mar-2017 05:46:26 msteps_ind_40117               submitted  (5 run | 0 fail | 133 done | 7 left)
    12-Mar-2017 05:46:27 msteps_ind_40145               finished   (4 run | 0 fail | 134 done | 7 left)
    12-Mar-2017 05:46:27 msteps_ind_40113               finished   (3 run | 0 fail | 135 done | 7 left)
    12-Mar-2017 05:46:27 msteps_ind_40029               finished   (2 run | 0 fail | 136 done | 7 left)
    12-Mar-2017 05:46:51 stability_ind_40061            finished   (1 run | 0 fail | 137 done | 7 left)
    12-Mar-2017 05:46:51 stability_group_sci10          submitted  (2 run | 0 fail | 137 done | 6 left)
    12-Mar-2017 05:46:51 stability_group_sci20          submitted  (3 run | 0 fail | 137 done | 5 left)
    12-Mar-2017 05:46:51 stability_group_sci30          submitted  (4 run | 0 fail | 137 done | 4 left)
    12-Mar-2017 05:46:51 summary_stability_avg_ind      submitted  (5 run | 0 fail | 137 done | 3 left)
    12-Mar-2017 05:46:51 msteps_ind_40061               submitted  (6 run | 0 fail | 137 done | 2 left)
    12-Mar-2017 05:46:53 msteps_ind_40061               finished   (5 run | 0 fail | 138 done | 2 left)
    12-Mar-2017 05:46:53 msteps_ind_40117               finished   (4 run | 0 fail | 139 done | 2 left)
    12-Mar-2017 05:46:53 Stopping idle worker 1 (not enough jobs left to do).
    ...
    12-Mar-2017 05:48:07 stability_group_sci10          finished   (3 run | 0 fail | 140 done | 2 left)
    12-Mar-2017 05:48:09 summary_stability_avg_ind      finished   (2 run | 0 fail | 141 done | 2 left)
    12-Mar-2017 05:48:09 Stopping idle worker 2 (not enough jobs left to do).
    12-Mar-2017 05:48:11 stability_group_sci20          finished   (1 run | 0 fail | 142 done | 2 left)
    12-Mar-2017 05:48:11 stability_group_sci30          finished   (0 run | 0 fail | 143 done | 2 left)
    12-Mar-2017 05:48:11 summary_stability_group        submitted  (1 run | 0 fail | 143 done | 1 left)
    12-Mar-2017 05:48:11 msteps_group                   submitted  (2 run | 0 fail | 143 done | 0 left)
    12-Mar-2017 05:48:14 summary_stability_group        finished   (1 run | 0 fail | 144 done | 0 left)
    12-Mar-2017 05:48:14 Stopping idle worker 3 (not enough jobs left to do).
    Deamon terminated on 12-Mar-2017 05:48:18
    
    12-Mar-2017 05:48:18 msteps_group                   finished   (0 run | 0 fail | 145 done | 0 left)
    12-Mar-2017 05:48:18 Stopping idle worker 4 (not enough jobs left to do).
    
    *******************************************
    Pipeline terminated on 12-Mar-2017 05:48:18
    All jobs have been successfully completed.
    


Now that the pipeline has successfully completed, we can check a .csv file generated as part of the outpus. This .csv file list the number of clusters identified as "representative" of all stable solutions across the grid of clustering parameters we selected, using a method called MSTEPS. 


```octave
file_msteps = [opt.folder_out filesep 'stability_group' filesep 'msteps_group_table.csv'];
[tab,lx,ly] = niak_read_csv(file_msteps);
tab
```

    tab =
    
       10    7    6
       20   16   15
       30   30   38
    


So each line is a number of clusters at the individual/group/consensus levels. Here MSTEPS has selected three scales as appropriate to summarize all tested numbers of clusters. Note that, even though we selected only 10, 20 and 30 in our grid, that grid is strictly used only at the individual level. At the group and consensus levels, other parameters are explored, in the neighbourhood of the number of individual clusters. We can now set these parameters in the pipeline to generate stability maps and parcellations:


```octave
opt.scales_maps = tab;
```

We can finally restart the pipeline. It will pick up where it left, and only deal with the generation of the maps. 


```octave
niak_pipeline_stability_rest(files_in,opt);
```

    
    Logs will be stored in /sandbox/home/git/niak_tutorials/basc/basc/logs/
    Generating dependencies ...
       Percentage completed :  0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100- 0.23 sec
    Setting up the to-do list ...
       I found 6 job(s) to do, and 145 job(s) already completed.
    Deamon started on 12-Mar-2017 05:55:41
    12-Mar-2017 05:55:41 Starting the pipeline manager...
    12-Mar-2017 05:55:41 Starting the garbage collector...
    12-Mar-2017 05:55:41 Starting worker number 1...
    12-Mar-2017 05:55:41 Starting worker number 2...
    12-Mar-2017 05:55:41 Starting worker number 3...
    12-Mar-2017 05:55:41 Starting worker number 4...
    
    Pipeline started on 12-Mar-2017 05:55:43
    user: , host: 2080f78652f8, system: unix
    ****************************************
    12-Mar-2017 05:55:44 stability_maps_group_sci10_scg7_scf6     submitted  (1 run | 0 fail | 145 done | 5 left)
    12-Mar-2017 05:55:44 figure_stability_group_sci10_scg7_scf6   submitted  (2 run | 0 fail | 145 done | 4 left)
    12-Mar-2017 05:55:44 stability_maps_group_sci20_scg16_scf15   submitted  (3 run | 0 fail | 145 done | 3 left)
    12-Mar-2017 05:55:44 figure_stability_group_sci20_scg16_scf15 submitted  (4 run | 0 fail | 145 done | 2 left)
    12-Mar-2017 05:55:44 stability_maps_group_sci30_scg30_scf38   submitted  (5 run | 0 fail | 145 done | 1 left)
    12-Mar-2017 05:55:44 figure_stability_group_sci30_scg30_scf38 submitted  (6 run | 0 fail | 145 done | 0 left)
    12-Mar-2017 05:55:46 stability_maps_group_sci30_scg30_scf38   finished   (5 run | 0 fail | 146 done | 0 left)
    12-Mar-2017 05:55:46 Stopping idle worker 4 (not enough jobs left to do).
    12-Mar-2017 05:55:48 figure_stability_group_sci10_scg7_scf6   finished   (4 run | 0 fail | 147 done | 0 left)
    12-Mar-2017 05:55:49 stability_maps_group_sci10_scg7_scf6     finished   (3 run | 0 fail | 148 done | 0 left)
    12-Mar-2017 05:55:49 Stopping idle worker 1 (not enough jobs left to do).
    12-Mar-2017 05:55:49 figure_stability_group_sci20_scg16_scf15 finished   (2 run | 0 fail | 149 done | 0 left)
    12-Mar-2017 05:55:49 Stopping idle worker 3 (not enough jobs left to do).
    12-Mar-2017 05:55:50 figure_stability_group_sci30_scg30_scf38 finished   (1 run | 0 fail | 150 done | 0 left)
    Deamon terminated on 12-Mar-2017 05:55:51
    
    12-Mar-2017 05:55:51 stability_maps_group_sci20_scg16_scf15   finished   (0 run | 0 fail | 151 done | 0 left)
    12-Mar-2017 05:55:51 Stopping idle worker 2 (not enough jobs left to do).
    
    *******************************************
    Pipeline terminated on 12-Mar-2017 05:55:51
    All jobs have been successfully completed.
    


That's all for now! Check other tutorials to learn how to explore the results of the pipeline. 
