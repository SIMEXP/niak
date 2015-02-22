# [fMRI/T1 preprocessing](pipe_preprocessing.html) 
Before any statistical or pattern recognition model is applied on fMRI data, a number of preprocessing steps need to be applied. These steps aim at reducing noise and align the brains of different subjects. The NIAK preprocessing pipeline for fMRI (and T1) data is versatile and includes most of the preprocessing tools currently available for connectivity analysis in fMRI.
> [<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/fig_flowchart_fmri_preprocess.jpg" width="200px" />](pipe_preprocessing.html)

# [Region growing](pipe_region_growing.html)
The region growing algorithm is extracting functionally homogeneous brain regions that are connected in space and have a controlled size. The pipeline can be applied to individual fMRI datasets, or multiple datasets (or subjects) can be combined by concatenation. 
> [<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/fig_region_growing.jpg" width="350px" />](pipe_region_growing.html)

# [BASC-FIR](pipe_basc_fir.html)

# [GLM-connectome](pipe_glm_connectome.html)
