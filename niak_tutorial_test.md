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
> report_test_regression_connectome_demoniak.csv
> report_test_regression_region_growing_demoniak.csv
> report_test_regression_connectome_demoniak.csv

Those are spreadsheets formatted as comma-separated values. Each row is about one file of the associated pipeline, and includes the following information: 

*'source' (boolean) indicates if the file exist in the source (generated results). 
*'target' (boolean) the file exist in the target (reference results). 
*'identical' (boolean or NaN) the files are identical (see the note below). NaN for unsupported file types, or files that exist only on source or target 
*'same_labels' (boolean or NaN) the .csv files have the same labels. NaN indicates any other file type. 
*'same_variables' (boolean or NaN) the .mat files have the same variables. NaN for any other file type. 
*'same_header_info' (boolean or NaN) the .nii/.mnc files have the same info&nbsp;% in the header. NaN for any other file type. 
*'same_dim' (boolean or NaN) the volumes have the same dimensions (.nii/.mnc) or the spreadsheets have the same dimension (.csv). NaN for any other file type. 
*'dice_mask_brain' (scalar in [0,1] or NaN) the dice coefficient between the brain mask of the two volumes (.nii/.mnc). NaN for any other file type. 
*'max_diff' (positive scalar or NaN) the max absolute difference between the two volumes (.nii/.mnc) or spreadsheets (.csv). NaN for any other file type. 
*'min_diff' (positive scalar or NaN) the min absolute difference between the two volumes (.nii/.mnc) or spreadsheets (.csv). NaN for any other file type. 
*'mean_diff' (positive scalar or NaN) the mean absolute difference between the two volumes (.nii/.mnc) or spreadsheets (.csv). NaN for any other file type. 
*'max_corr' (scalar in [0,1] or NaN) the max correlation between the time series of voxels inside the brain mask between two 4D volumes (.nii/.mnc). NaN for any other file type. 
*'min_corr' (scalar in [0,1] or NaN) the min correlation between the time series of voxels inside the brain mask between two 4D volumes (.nii/.mnc). NaN for any other file type. 
*'mean_corr' (scalar in [0,1] or NaN) the mean correlation between the time series of voxels inside the brain mask between two 4D volumes (.nii/.mnc). NaN for any other file type.

Two files are identical if they exist in both source and target and 

*for .nii/.mnc: the headers are identical and the max absolute difference is less than a tolerance value (10^-4). 
*for .csv files: the labels of rows and columns are identical and the max absolute difference is less than a tolerance value (10^-4). 
*for .mat files: the content is identical up to a tolerance value (10^-4).

The tests fail if any two pairs of file are not identical in the reference results and the generated results. Note that tests can fail if slightly different versions of Matlab/Octave/minc tools are used when generating results as compared to the reference results. When NIAK is executed through docker, perfect replications are expected.