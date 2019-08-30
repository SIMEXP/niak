# Connectome pipeline

## Overview

This pipeline creates connectomes as well as functional connectivity maps and graph measures from preprocessed fMRI data. The command to run the pipeline in a Matlab/Octave session is:
```matlab
 niak_pipeline_connectome(files_in,opt)
```
where `files_in` is a structure describing how the dataset is organized, and `opt` is a structure describing the options of the pipeline.

## Input files

The inputs of the pipelines are:

  * **Fully preprocessed fMRI datasets**. This is typically the output of `niak_pipeline_fmri_preprocessing`, but the preprocessing can be done with any package.
  * **A mask of brain regions/networks**. This can be for example the AAL template (see notes below), or the result of a boostrap analysis of stable clusters (BASC). Any mask can be used here.
  * **A list of coordinates of interest** (or numerical value corresponding to regions of the mask), along with string labels. This list is specified through a `.csv` file (which can be generated with a text editor or an excel-like program).

If the fMRI datasets have been preprocessed using NIAK, setting up the input files is very easy. Just grab the results of the preprocessing with the following command:
```matlab
 % The minimum number of volumes for an fMRI dataset to be included.
 % This option is useful when scrubbing is used, and the resulting time series may be too short.
 opt_g.min_nb_vol = 100;

 % Specify to the grabber to prepare the files for the connectome pipeline
 opt_g.type_files = 'glm_connectome';
 files_in.fmri = niak_grab_fmri_preprocess('/home/pbellec/demo_niak_preproc/',opt_g).fmri;
```

More options for the grabber are available. See `help niak_grab_fmri_preprocess` or the template of the region growing pipeline for more info. The mask is specified as follows:
```matlab
 files_in.network = '/home/pbellec/niak/template/roi_aal.mnc.gz';
```
Finally the (optional) list of seeds is specified by:
```matlab
 files_in.seeds = '/home/pbellec/database/list_seeds.csv';
```
If NIAK was not used to prepocess the data, all inputs have to be manually specified in the script. The first field ''fmri'' directly lists all of the preprocessed fMRI datasets, organized by subject, session and runs. Example:
```matlab
 files_in.subject1.session1.rest = '/home/pbellec/demo_niak_preproc/fmri/fmri_subject1_session1_rest.nii.gz';
 files_in.subject2.session1.rest = '/home/pbellec/demo_niak_preproc/fmri/fmri_subject2_session1_rest.nii.gz';
```
*NOTE*: you can customize the names for the subjects, sessions and runs.

*WARNING*: Octave and Matlab impose some restrictions on the labels used for subject, session and run. In order to avoid any issue, please do not use long labels (say less than 8 characters for subject, and ideally 4 characters or less for session/run). Also avoid to use any special character, including `.` `+` `-` or `_`. None of these restrictions apply on the naming convention of the files, just to the labels that are used to build the structure files_in in Matlab/Octave.

## List of seeds

The .csv FILES_IN.SEEDS can take two forms. Example 1, (world) coordinates in stereotaxic space:
```
         ,   x ,  y ,  z
 ROI1    ,  12 ,  7 , 33
 ROI2    ,  45 , -3 , 27
```
With that method, the region will load the parcellation, extract the number of the parcels corresponding to the coordinates, and associate them to labels ROI1 and ROI2. WARNING: the labels for the ROI must be acceptable as field names for matlab, i.e. no special characters (+ - / * space) and relatively short.

Example 2, string and numeric labels:
```
        , index
 ROI1   , 3010
 ROI2   , 3020
```
In this case, the index refers to the number associated with one parcel. The labels will be attached. With both methods, the first row does not really matter. It is still important that the row is present, and that the intersection of first column and first row is left empty. If two rows are associated with the same parcel, the pipeline will throw an error. This can occur in particular with method 1.

## Workflow 

The main steps of the `connectome` pipeline are the following:

  * Generate the average fMRI time series for each network in the mask.
  * Generate a connectome for each subject. Multiple measures are available (covariance, correlation, Fisher transform of the correlation, concentration, partial correlation). If multiple runs are available for one subject, the connectomes are averaged across runs.
  * Binarize the connectome, either by applying a fixed threshold on positive or absolute connectivity measures, or by retaining a fixed percentage of the largest connections.
  * Report the values of point-to-point connectivity measures for a selected number of networks specified in FILES_IN.CSV
  * Generate full brain, voxel-level functional connectivity maps for each subject (i.e. correlation or Fisher transform of the correlation, starting from a selected number of networks specified in FILES_IN.CSV. An average of all subjects is also generated for each seed.
  * Generate a battery of graph properties, based on the binarized version of the connectome. These measures are generated using the [brain connectivity toolbox](https://sites.google.com/site/bctnet/Home/functions ).

## Pipeline options

The first option `opt.folder_out` is used to specify the folder where the results of the pipeline will be saved. The pipeline manager will create but also delete many files and subfolders in that location. It is thus highly recommended to use a new folder dedicated to the analysis, and to prevent any manual modification of that folder at all times. Example:
```matlab
 opt.folder_out = '/database/data_demo/region_growing/';
```
The following option sets the type of connectome (see `help niak_brick_connectome` for more info):
```matlab
  opt.connectome.type = 'Z';
 % 'S': covariance;
 % 'R': correlation;
 % 'Z': Fisher transform of the correlation;
 % 'U': concentration;
 % 'P': partial correlation
```
The following option sets how the connectome is binarized (See "help niak_brick_connectome" for more info):
```matlab
  opt.connectome.thresh.type = 'sparsity_pos';
  % The type of treshold used to binarize the connectome. See "help niak_brick_connectome" for more info.
  % 'sparsity': keep a proportion of the largest connection (in absolute value);
  % 'sparsity_pos': keep a proportion of the largest connection (positive only)
  % 'cut_off': a cut-off on connectivity (in absolute value)
  % 'cut_off_pos': a cut-off on connectivity (only positive)
```
The following option sets the threshold used to binarize the connectome (See `help niak_brick_connectome` for more info):
```matlab
  opt.connectome.thresh.param = 0.2;&nbsp;
  % The parameter of the thresholding. The actual definition depends of THRESH.TYPE:
  % 'sparsity': (scalar, default 0.2) percentage of connections
  % 'sparsity_pos': (scalar, default 0.2) percentage of connections
  % 'cut_off': (scalar, default 0.25) the cut-off
  % 'cut_off_pos': (scalar, default 0.25) the cut-off
```
## Pipeline management

The pipeline execution is powered by a generic manager called PSOM (Bellec et al. 2012, see reference below). See the [PSOM website](http://psom.simexp-lab.org) for guidelines to set the configuration. Parameters for PSOM are specified through `opt.psom`.

## Outputs

The individual connectomes (averaged across runs) are saved in the files `connectomes/connectome_rois_(SUBJECT).mat` with the following variables:

  * `conn`: the vectorized individual connectome. See ''niak_build_srup'' for instructions on how to get back the square form (the method depends on the type of the connectome).
  * `G`: same as `conn` but binarized.
  * `ind_roi`: a vector with the indices of the parcels. This defines the order of rows/columns in the connectome.
  * `type`: same as `opt.connectome.type`. Describes the type of the connectome.
  * `thresh`: same as `opt.connectome.thresh`. Describes the method for binarization.

The individual graph properties are saved in the files `graph_prop/graph_prop_rois_(SUBJECT).mat` with the following variables:

  * `(MEASURE)_(PARCEL).type` the type of measure. The labels for `PARCEL` are defined by `files_in.seeds`.
  * `(MEASURE).(PARCEL).param`: the option of the measure. Typically the numerical ID of the parcel used in the calculation. The labels for `PARCEL` are defined by `files_in.seeds`.
  * `(MEASURE).(PARCEL).val`: the value estimated for the measure.

The functional connectivity maps are saved in the folder `rmaps`:

* `rmaps/rmap_(SUBJECT)_(PARCEL).(EXT)`: the voxelwise connectivity map using `PARCEL` as a seed (labels are defined in `files_in.seeds`).
  * `rmaps/mask_(PARCEL).(EXT)`: a binary volume of the seed associated with the label `PARCEL`.
  * `rmaps/average_rmap_(PARCEL).(EXT)`: the connectivity map using `PARCEL` as seed, averaged across all subjects.

## Publication guidelines

Here is a short description of the connectome pipeline that can be adapted in a publication. You are encouraged to include the script that was used to generate the connectomes as supplementary material of the article.

 The individual connectomes were generated using the Neuroimaging Analysis Kit (NIAK) release 0.7 (Bellec et al. 2011, NIAK website). For each run, the correlation matrix [REPLACE HERE BY COVARIANCE, CONCENTRATION OR PARTIAL CORRELATION, DEPENDING ON OPT.CONNECTOME.TYPE] was generated base on the time series averaged on the [DESCRIBE THE EMPLOYED PARCELLATION HERE] parcellation. For each subject, the connectomes were averaged across all runs [SUPPRESS THIS IF THERE IS ONLY ONE RUN]. The individual connectomes were binarized by application by retaining positive connections larger than XX [THIS SENTENCE APPLIES ONLY IF OPT.CONNECTOME.THRESH.TYPE IS 'cut_off_pos'. XX IS OPT.CONNECTOME.TRESH.PARAM]. The individual connectomes were binarized by application by retaining connections larger than XX in absolute value[THIS SENTENCE APPLIES ONLY IF OPT.CONNECTOME.THRESH.TYPE IS 'cut_off'. XX IS OPT.CONNECTOME.TRESH.PARAM]. The individual connectomes were binarized by application by retaining the XX larger connections [THIS SENTENCE APPLIES ONLY IF OPT.CONNECTOME.THRESH.TYPE IS 'sparsity_pos'. XX IS OPT.CONNECTOME.TRESH.PARAM]. The individual connectomes were binarized by application by retaining the XX larger connections in absolute value [THIS SENTENCE APPLIES ONLY IF OPT.CONNECTOME.THRESH.TYPE IS 'sparsity'. XX IS OPT.CONNECTOME.TRESH.PARAM]. The following regions were selected based on the literature [THIS SENTENCE APPLIES ONLY IF A SUBSET OF REGIONS IS EXTRACTED FROM THE PARCELLATION]. The following graph metrics were generated for each subject based on binarized connections: clustering coefficient for each parcel, average clustering, local efficiency for each parcel, average efficiency, modularity coefficient, as defined in (Rubinov and Sporns, 2010) and implemented in the brain connectivity toolbox (https://sites.google.com/site/bctnet/Home/functions). In addition, degree centrality was generated as the number of edge associated with each parcel, corrected to have a zero mean and unit variance across all parcels, as described in (Buckner et al., 2009). Finally, the average voxelwise functional connectivity maps were generated for each selected region, i.e. Pearson's correlation corrected by the Fisher transform and averaged across all runs for each subject.

## References

Regarding the NIAK package:

 P. Bellec, F. M. Carbonell, V. Perlbarg, C. Lepage, O. Lyttelton, V. Fonov, A. Janke, J. Tohka, A. Evans, A neuroimaging analysis kit for Matlab and Octave. Proceedings of the 17th International Conference on Functional Mapping of the Human Brain, 2011.

Regarding the pipeline system for Octave and Matlab (PSOM):

 P. Bellec, S. Lavoie-Courchesne, P. Dickinson, J. Lerch, A. Zijdenbos, A. C. Evans. The pipeline system for Octave and Matlab (PSOM): a lightweight scripting framework and execution engine for scientific workflows. Front. Neuroinform. (2012) 6:7. Full text open-access: http://dx.doi.org/10.3389/fninf.2012.00007

Regarding the graph properties:

 Rubinov, M., Sporns, O., Sep. 2010. Complex network measures of brain connectivity: Uses and interpretations. NeuroImage 52 (3), 1059-1069. URL http://dx.doi.org/10.1016/j.neuroimage.2009.10.003

Regarding the degree centrality:

 Buckner et al. Cortical Hubs Revealed by Intrinsic Functional Connectivity: Mapping, Assessment of Stability, and Relation to Alzheimer’s Disease. The Journal of Neuroscience, February 11, 2009.
