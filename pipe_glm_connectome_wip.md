# GLM connectome pipeline

## Overview
The general liner model for connectome (GLM-connectome) pipeline tests for association between group-level variable (e.g. sex, age, etc) and brain connectivity. This process is repeated independently for every brain connection. It is possible to extract various connectivity metrics at the intra-run and inter-run/intra-subject levels, before entering a random effect group analysis. The GLM estimation can be replicated at multiple resolutions, i.e. number of brain parcels, and an omnibus test of the overall presence of true association across resolutions is available.

## Syntax
The pipeline is invoked by `niak_pipeline_glm_connectome`.
The argument `files_in` is a structure describing how the dataset is organized, and `opt` is a structure describing the options of the pipeline.
```matlab
niak_pipeline_glm_connectome(files_in,opt)
```

## Inputs

The inputs of the pipelines are:

* One or multiple brain parcellations, generally associated with different number of brain parcels (resolutions).
* Fully preprocessed fMRI datasets. This is typically the output of `niak_pipeline_fmri_preprocessing`, but the preprocessing can be done with any package.
* A series of .csv models, which can be specified at different levels: intra-run, inter-run intra-subject, inter-subject.

## Brain parcellations

### General considerations
There are several options here. We recommend using a single brain parcellation for the main analysis of the paper, and then tests how robust these findings are using other parcellations, possibly using different resolutions. Based on a number of experiments, we recommend using 30-40 parcels for the main analysis, and complement these results with at least 100 parcels. We found that the sensitivity of analyses with 30-40 parcels to be good, while also providing a good summary of connectome-wide association studies performed at much higher resolutions.

### The multiresolution Cambridge functional parcellation
A first option is to use an existing multi-resolution brain parcellation, for example the BASC-Cambridge generated on about 200 young healthy subjects. Downloading the template in the current folder is achieved using the following instruction:
```
[status,msg,data_template] = niak_wget('cambridge_template_mnc1');
```
To specify the parcellation into 36 clusters, enter the following command:
```
files_in.networks.sc036 = [data_template.path filesep 'template_cambridge_basc_multiscale_sym_scale036.mnc.gz'];
```
The same instruction can be used to specify one or multiple brain parcellations. Note that the label used for each parcellation (here `sc036`) is arbitrary.

If a BASC pipeline was used to produce multiresolution brain parcellations, it is also possible to use those parcellations using the following command:
```
files_in = niak_grab_stability_rest('path_basc');
```
where `path_basc` is the path to the results of the BASC pipeline. Note that all parcellations generated in the second path (along with stability maps etc) will be grabbed from the results.

## Preprocessed fMRI data

If the fMRI datasets have been preprocessed using NIAK, setting up the input files is straightforward. Just grab the results of the preprocessing with `niak_grab_fmri_preprocess`.
```matlab
% The minimum tolerable number of volumes
opt_g.min_nb_vol = 100;
opt_g.type_files = 'roi';
files_in = ...
   niak_grab_fmri_preprocess('/home/pbellec/demo_niak_preproc/',opt_g);
```

More options for the grabber are available, see `help niak_grab_fmri_preprocess`. , and the areas are the AAL segmentation (see the description below).

If NIAK was not used to prepocess the data, all inputs have to be manually specified in the script. The first field `fmri` lists the preprocessed fMRI datasets, organized by subject, session and runs.
```matlab
files_in.fmri.subject1.session1.rest = ...
   '/path/demo_niak_preproc/fmri/fmri_sub1_sess1_rest.nii.gz';
files_in.fmri.subject2.session1.rest = ...
   '/path/demo_niak_preproc/fmri/fmri_sub2_sess1_rest.nii.gz';
```

Labels for subjects, sessions and runs are arbitrary, however Octave and Matlab impose some restrictions. Please do not use long labels (say less than 8 characters for subject, and ideally 4 characters or less for session/run). Also avoid to use any special character, including '.' '+' '-' or '_'.
>None of these restrictions apply on the naming convention of the raw files, just to the labels that are used to build the structure files_in in Matlab/Octave.

## Analysis mask

The `mask` field is the name of a 3D binary volume serving as a mask for the analysis. It can be a mask of the brain common to all subjects, or a mask of a specific brain area, e.g. the thalami. It is important to make sure that this segmentation is in the same space and resolution as the fMRI datasets. If `niak_grab_fmri_preprocess` is used, the mask is set to the group mask (i.e. voxels that fall in the brain for more than 50% of subjects) generated in the quality control step. Otherwise, use SPM or MINCRESAMPLE to resample the mask at the correct resolution.
```matlab
files_in.mask = '/data/func_mask_group_stereonl.nii.gz';
```
## Brain areas

The `areas` field is the name of a volume of integer values, describing some brain areas that are used to save memory space in the region-growing algorithm. Different brain areas are treated independently at this step of the analysis. If the brain mask is small enough, this may not be necessary. Otherwise, you can use for example the AAL segmentation. That is the segmentation used by `niak_grab_fmri_preprocess`. It is important to make sure that this segmentation is in the same space and resolution as the fMRI datasets. If not, use SPM or mincresample to resample the AAL segmentation at the correct resolution.
```matlab
files_in.areas = '/data/roi_aal.nii.gz';
```

# Pipeline options

The first option `opt.folder_out` is used to specify the folder where the results of the pipeline will be saved.
```matlab
opt.folder_out = '/data/region_growing/';
```
The second option is the size of the regions, when they are mature (i.e. they stop growing). The parameter is set in mm3, if the size of voxels is specified in mm in the header (that is pretty much always the case). A threshold of 1000 mm3 will give about 1000 regions on the grey matter.
```matlab
opt.thre_size = 1000;
```

# Publication guidelines

Here is a short description of the fMRI preprocessing pipeline that can be adapted in a publication. You are encouraged to include the script that was used to preprocess the fMRI database as supplementary material of the article.

>To reduce the computational burden of the analysis, the spatial dimension of the individual fMRI dataset was reduced using a region-growing algorithm. The spatial dimension was selected arbitrarily by setting the size where the growing process stopped (a threshold of 1000 mm3 resulted into R=957 regions). The regions were built to maximize the homogeneity of the time series within the region, i.e. the average correlation between the time series associated with any pair of voxels of the region. The region growing was applied on the time series concatenated across all subjects (after correction to zero mean and unit variance), such that the homogeneity was maximized on average for all subjects, and the small homogeneous regions are identical for all subjects. Because of the temporal concatenation of time series, we had to limit the memory demand, and the region-growing was thus applied independently in each of the 116 areas of the AAL template \citep{Tzourio-Mazoyer2002}. See (Bellec et al. 2006) for more details regarding the implementation of the region-growing algorithm. Overall, this process reduced the dataset of each subject into a (T x R) data array, where T is the number of time samples and R is the number of regions.

The AAL template that ships with NIAK 0.7+ is not identical to the original AAL template described by Tzouri-Mazoyer et al., 2002. A description of the differences follows:

>The original AAL template was modified for inclusion in NIAK, as NIAK uses a different stereotaxic space for coregistration than the one used by (Tzourio-Mazoyer et al., 2002). The AAL parcels have been drawn in the Colin27 template space. Colin27 is the average of 27 structural scan of a single subject, linearly registered in the Montreal Neurological Institute (MNI) International Consortium for Brain Mapping (ICBM) 152 stereotaxic space. The MNI-ICBM152 is the average of 152 young adults that were linearly realigned. Only coarse anatomical details can be seen on an average brain after such a linear coregistration. However, the AAL template precisely follows the unique sulcal anatomy of Colin27, which is in particular highly asymmetric. By contrast, we used the MNI-ICBM152-2009c template (http://www.bic.mni.mcgill.ca/ServicesAtlases/ICBM152NLin2009), described in (Fonov et al. 2011). The MNI-ICBM152-2009c is the average of the same structural scans as the MNI-ICBM152, but after a non-linear (rather than linear) coregistration process. The processus of coregistration/template generation was iterated 40 times in order to produce MNI-ICBM152-2009c. In addition, the template was constrained to be symmetrical with respect to the mid-sagital plane, such that homotopic connections can be easily studied. Because of the non-linear coregistration procedure, many details of the sulcal anatomy are visible in the MNI-ICBM152-2009c, which were lost in the linear version. The Colin27 template was thus co-registered non-linearly to the MNI-ICBM152-2009c in order for the parcellation to respect these landmarks. Some morphomathematical operations were in addition applied to ensure that homotopic parcels were symmetric and that each of the AAL parcels remained spatially connex after the non-linear transformation. A nearest-neighbour extrapolation of the parcels was also applied to cover all of the mask of the grey matter, as defined by a liberal threshold on the average grey matter partial volume map released as part of the MNI ICBM152 2009c template. In particular, some novel ventral cerebellar regions were included in the 2009c version of the AAL template, that were missing in the original work. For that reason the anatomical labels inherited from the original AAL atlas should be interpreted with great caution in the cerebellar regions for the updated AAL-2009c template. The result of the extrapolation process was manually edited in some areas.
