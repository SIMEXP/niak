In order to validate that a computational environment behaves the way it should, NIAK offers a series of tests. To run all NIAK tests, fir create a folder to put all the test results:
````matlab
psom_mkdir('test_niak')
cd test_niak
````
Then simply type:
````matlab
niak_test_all
````
This command will download the test dataset, as well as a series of results generated on a trusted system. All the pipelines available in NIAK will run. The tests will compare all the results generated locally with those previous results, and produce a series of reports in .csv format. 
> * report_test_regression_connectome_demoniak.csv
> * report_test_regression_region_growing_demoniak.csv
> * report_test_regression_connectome_demoniak.csv

Those are spreadsheets formatted as comma-separated values. Each row is about one file of the associated pipeline, and includes the following information: 

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
   * **scalar**: the max correlation between the time series of voxels inside the brain masks, for two 4D volumes (.nii/.mnc). 
   * **NaN**: not 4D .mnc/.nii files (the test does not apply, ignore value).
 * **`min_corr`** (scalar in [0,1] or NaN) 
   * **scalar**: the min correlation between the time series of voxels inside the brain masks, for two 4D volumes (.nii/.mnc). 
   * **NaN**: not 4D .mnc/.nii files (the test does not apply, ignore value).
 * **`mean_corr`** (scalar in [0,1] or NaN) 
   * **scalar**: the mean correlation between the time series of voxels inside the brain masks, for two 4D volumes (.nii/.mnc). 
   * **NaN**: not 4D .mnc/.nii files (the test does not apply, ignore value).

Two files are identical if they exist in both source and target and 

* **.nii/.mnc** files: the headers are identical and the max absolute difference is less than a tolerance value (10^-4). 
* **.csv** files: the labels of rows and columns are identical and the max absolute difference is less than a tolerance value (10^-4, see `opt.eps` in `niak_brick_cmp_files`). 
* **.mat** files: the content is identical up to a tolerance value (10^-4, see `opt.eps` in `niak_brick_cmp_files`).

The tests fail if any two pairs of file are not identical in the reference results and the generated results. Note that tests can fail if slightly different versions of Matlab/Octave/minc tools are used when generating results as compared to the reference results. When NIAK is executed through docker, perfect replications are expected.
