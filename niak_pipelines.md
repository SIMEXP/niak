# [fMRI/T1 preprocessing](pipe_preprocessing.html) 
Before any statistical or pattern recognition model is applied on fMRI data, a number of preprocessing steps need to be applied. These steps aim at reducing noise and align the brains of different subjects. The NIAK preprocessing pipeline for fMRI (and T1) data is versatile and includes most of the preprocessing tools currently available for connectivity analysis in fMRI.
> [<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/fig_stereonl.png" width="250px" />](pipe_preprocessing.html)

# [Region growing](pipe_region_growing.html)		
The region growing algorithm is extracting functionally homogeneous brain regions that are connected in space and have a controlled size. The pipeline can be applied to individual fMRI datasets, or multiple datasets (or subjects) can be combined by concatenation. 		
> [<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/fig_region_growing.jpg" width="250px" />](pipe_region_growing.html)

# [BASC](pipe_basc.html)
The bootstrap analysis of stable clusters (BASC) is a pipeline that builds brain parcellations (clusters) based on the similarity of individual fMRI time series. The BASC implements some boostrap replications of the cluster analysis as well as a consensus clustering approach to capture stable clusters at the individual and group levels. The pipeline also includes some automated method (called MSTEPS) to identify critical numbers of clusters, that summarize accurately a whole hierarchy of decomposition into brain networks.  
> [<img src="https://raw.githubusercontent.com/SIMEXP/niak/gh-pages/fig_basc.png" width="250px" />](pipe_basc.html) 

# [BASC-FIR](pipe_basc_fir.html)
This is a variant of the BASC pipeline that builds brain parcellations (clusters) based on the similarity of individual estimated finite-impulse response FIR, in block or slow event-related tasks.
> [<img src="https://raw.githubusercontent.com/SIMEXP/niak/gh-pages/fig_basc_fir.png" width="250px" />](pipe_basc_fir.html)

# [GLM-connectome](pipe_glm_connectome.html)
The general liner model for connectome (GLM-connectome) pipeline tests for association between group-level variable and brain connectivity systematically at each brain connection. It is possible to extract various connectivity metrics at the intra-run and inter-run/intra-subject levels, before entering a random effect group analysis. The GLM estimation can be replicated at multiple resolutions, i.e. number of brain parcels, and an omnibus test of the overall presence of true association across resolutions is available. 
> [<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/logo_glm_connectome.png" width="250px" />](pipe_glm_connectome.html)
