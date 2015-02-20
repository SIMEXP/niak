# [fMRI/T1 preprocessing](pipe_preprocessing.html) 
Before any statistical or pattern recognition model is applied on fMRI data, a number of preprocessing steps need to be applied. These steps first aim at reducing various artefacts that compromise the interpretation of fMRI fluctuations, e.g. physiological and motion artefacts. The second major aim is to align the data acquired at different points in time for a single subject, sometimes separated by years, and also to establish some correspondance between the brains of different subjects, such that an inference on the role of a given brain area can be carried at the level of a group. The NIAK preprocessing pipeline for fMRI (and T1) data is versatile and includes most of the preprocessing tools currently available for connectivity analysis in fMRI.
>![The fMRI preprocessing workflow](https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/fig_flowchart_fmri_preprocess.jpg)

# [Region growing](pipe_region_growing.html)
The functional MRI data have a fairly good spatial resolution, with 10s of thousands of voxels covering the gray matter at a typical 3 mm isotropic resolution. This dimensionaility is too high for fast analysis of whole-brain connectome, which examines the connectivity between every possible pairs of brain regions. In NIAK, a region growing algorithm is generally applied to reduce the computational burden of subsequent analysis, by extracting functionally homogeneous brain regions that are connected in space and have a controlled size. Other methods to stop the region growing are available, such as a maximum number of regions in the brain or the level of homogeneity within region. The regions are built to maximize the correlation between time series averaged across all pairs of voxels within each region as well as across all subjects. The pipeline can be applied to individual fMRI datasets, or multiple datasets (or subjects) can be combined by concatenation. 
>![Brain parcellations](https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/fig_region_growing.jpg)

# [BASC-FIR](pipe_basc_fir.html)

# [GLM-connectome](pipe_glm_connectome.html)
