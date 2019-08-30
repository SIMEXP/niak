# Tutorials

## Notebooks
Before running the following tutorials, NIAK needs to be properly installed. All the codes are to be executed in the matlab/octave environment. It is generally advised to create a new folder and run the script in this folder, as some datasets may be downloaded, and various images may be generated.

[<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/tutorial_fmri_preprocess.png" width="250px" />](https://nbviewer.jupyter.org/github/SIMEXP/niak_tutorials/blob/master/niak_tutorial_fmri_preprocessing.ipynb)
[<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/tutorial_rmap.png" width="250px" />](https://nbviewer.jupyter.org/github/SIMEXP/niak_tutorials/blob/master/niak_tutorial_rmap_connectome.ipynb)
[<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/tutorial_basc_principles.png" width="250px" />](https://nbviewer.jupyter.org/github/simexp/niak_tutorials/blob/master/niak_tutorial_basc_principles.ipynb)
[<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/tutorial_basc.png" width="250px" />](https://nbviewer.jupyter.org/github/simexp/niak_tutorials/blob/master/niak_tutorial_basc.ipynb)

## How to test NIAK

In order to validate that a computational environment behaves the way it should, NIAK offers a series
 of tests. To run all NIAK tests, fir create a folder to put all the test results:
````matlab
psom_mkdir('test_niak')
cd test_niak
````
Then simply type:
````matlab
niak_test_all
````
This command will download the test dataset, as well as a series of results generated on a trusted sy
stem. All the pipelines available in NIAK will run. The tests will compare all the results generated
locally with those previous results, and produce a series of reports in .csv format.
> * report_test_regression_connectome_demoniak.csv
> * report_test_regression_region_growing_demoniak.csv
> * report_test_regression_connectome_demoniak.csv

Those are spreadsheets formatted as comma-separated values. Each row is about one file of the associa
ted pipeline, and includes the following information:

 * **`source`** (boolean)
   * **1**: the file exists in the source (generated results).
   * **0**: the file is absent in the source (generated results).
 * **`target`** (boolean)
   * **1**: the file exists in the target (reference results).
   * **0**: the file is absent in the target (reference results).
 * **`identical`** (boolean or NaN)
   * **1**: the files are identical (the actual test depends on file type, see the note below).
   * **0**: the files are different (the actual test depends on file type, see the note below).
   * **NaN**: unsupported file type, or the file exists only on source or target.
 * **`same_labels`** (boolean or NaN)
   * **1**: the .csv files have the same labels for rows and columns.
   * **0**: the .csv files have different labels for rows or columns.
   * **NaN**: not .csv files (the test does not apply, ignore value).
 * **`same_variables`** (boolean or NaN)
   * **1**: the .mat files contain the same variables.
   * **0**: the .mat files contain different variables.
   * **NaN**: not .mat files (the test does not apply, ignore value).
 * **`same_header_info`** (boolean or NaN)
   * **1**: the .nii/.mnc files have the same headers.
   * **0**: the .nii/.mnc files have different headers.
   * **NaN**: not .mnc/.nii files (the test does not apply, ignore value).
 * **`same_dim`** (boolean or NaN)
   * **1**: the data inside .nii/.mnc or .csv files have the same dimensions.
   * **0**: the data inside .nii/.mnc or .csv files have different dimensions.
   * **NaN**: not .mnc/.nii/.csv files (the test does not apply, ignore value).  
 * **`dice_mask_brain`** (scalar in [0,1] or NaN)
   * **scalar**: the dice coefficient for brain masks generated for two volumes (.nii/.mnc).
   * **NaN**: not .mnc/.nii files (the test does not apply, ignore value).
 * **`max_diff`** (positive scalar or NaN)
   * **scalar**: the max absolute difference between two volumes (.nii/.mnc) or spreadsheets (.csv).
   * **NaN**: not .mnc/.nii/.csv files (the test does not apply, ignore value).
 * **`min_diff`** (positive scalar or NaN)
   * **scalar**: the min absolute difference between two volumes (.nii/.mnc) or spreadsheets (.csv).
   * **NaN**: not .mnc/.nii/.csv files (the test does not apply, ignore value).
 * **`mean_diff`** (positive scalar or NaN)
   * **scalar**: the mean absolute difference between two volumes (.nii/.mnc) or spreadsheets (.csv).
   * **NaN**: not .mnc/.nii/.csv files (the test does not apply, ignore value).
 * **`max_corr`** (scalar in [0,1] or NaN)
   * **scalar**: the max correlation between the time series of voxels inside the brain masks, for tw
o 4D volumes (.nii/.mnc).
   * **NaN**: not 4D .mnc/.nii files (the test does not apply, ignore value).
 * **`min_corr`** (scalar in [0,1] or NaN)
   * **scalar**: the min correlation between the time series of voxels inside the brain masks, for tw
o 4D volumes (.nii/.mnc).
   * **NaN**: not 4D .mnc/.nii files (the test does not apply, ignore value).
 * **`mean_corr`** (scalar in [0,1] or NaN)
   * **scalar**: the mean correlation between the time series of voxels inside the brain masks, for t
wo 4D volumes (.nii/.mnc).
   * **NaN**: not 4D .mnc/.nii files (the test does not apply, ignore value).

Two files are identical if they exist in both source and target and

* **.nii/.mnc** files: the headers are identical and the max absolute difference is less than a toler
ance value (10^-4).
* **.csv** files: the labels of rows and columns are identical and the max absolute difference is les
s than a tolerance value (10^-4, see `opt.eps` in `niak_brick_cmp_files`).
* **.mat** files: the content is identical up to a tolerance value (10^-4, see `opt.eps` in `niak_bri
ck_cmp_files`).

The tests fail if any two pairs of file are not identical in the reference results and the generated
results. Note that tests can fail if slightly different versions of Matlab/Octave/minc tools are used
 when generating results as compared to the reference results. When NIAK is executed through docker,
perfect replications are expected.

## Read and write volumes in NIAK

This tutorial shows how to read and write volumes using the NIAK tools, as well as perform some basic
 operations. It does not generate figures. The script can be downloaded [here](https://raw.githubuser
content.com/SIMEXP/niak_tutorials/master/read_write_vol/niak_tutorial_read_write_vol.m).


First download the single subject, preprocessed cambridge dataset.
```matlab
clear
if ~psom_exist('single_subject_cambridge_preprocessed_nii')
    system('wget http://www.nitrc.org/frs/download.php/6784/single_subject_cambridge_preprocessed_nii
.zip')
    system('unzip single_subject_cambridge_preprocessed_nii.zip')
    psom_clean('single_subject_cambridge_preprocessed_nii.zip')
end
```

To read the data, use `niak_read_vol`.
```matlab
[hdr,vol] = niak_read_vol('single_subject_cambridge_preprocessed_nii/fmri_sub00156_session1_rest.nii.
gz');
```

The `hdr` output is a structure with a full description of the volume. In particular, `hdr.info` cont
ains some basic info found in both nifti and minc.
```matlab
hdr.info
```
For example, the voxel size is found in
```matlab
hdr.info.voxel_size
```

All the detailed information are contained in `hdr.details`. This field will vary based on the format
 of the original volume. Here, for nifti, each field corresponds to a nifti field.
```matlab
hdr.details
```

The `vol` output is the data itself, in either a 3D or a 4D array. Any normalization (min/max) has be
en applied. It is in voxel space however, and no spatial transformation has been applied.
```matlab
size(vol)
```

To write volumes, the name of the volume is going into the header.
```matlab
hdr.file_name = 'mean_vol.nii.gz';
```

The number of time frames can vary, and is automatically updated. Let's comupte the average volume
```matlab
vol_mean = mean(vol,4);
```

To write the volume, call `niak_write_vol`.
```matlab
niak_write_vol(hdr,vol_mean);
```
