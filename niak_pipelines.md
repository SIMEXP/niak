Each NIAK pipeline comes with:
 * <img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/icon_doc.png" caption="documentation" width="32px" /> an on-line documentation, 
 * <img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/icon_slides.png" caption="slideshow" width="32px" /> a slideshow,
 * <img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/icon_video.png" caption="video" width="32px" /> a video companion to the slideshow.
Access by clicking on the icons next to each pipeline description.

# [fMRI/T1 preprocessing](pipe_preprocessing.html) 
Before any statistical or pattern recognition model is applied on fMRI data, a number of preprocessing steps need to be applied. These steps aim at reducing noise and align the brains of different subjects. The NIAK preprocessing pipeline for fMRI (and T1) data is versatile and includes most of the preprocessing tools currently available for connectivity analysis in fMRI.
> [<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/icon_doc.png" caption="documentation" width="64px" />](pipe_preprocessing.html)
> [<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/icon_slides.png" caption="slideshow" width="64px" />](http://files.figshare.com/2006567/mic_preprocessing_2015.pdf)
> [<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/icon_video.png" caption="video" width="64px" />]()

# [BASC](pipe_basc.html)
The bootstrap analysis of stable clusters (BASC) is a pipeline that builds brain parcellations (clusters) based on the similarity of individual fMRI time series. The BASC implements some boostrap replications of the cluster analysis as well as a consensus clustering approach to capture stable clusters at the individual and group levels. The pipeline also includes some automated method (called MSTEPS) to identify critical numbers of clusters, that summarize accurately a whole hierarchy of decomposition into brain networks.  
> [<img src="https://raw.githubusercontent.com/SIMEXP/niak_manual/master/website/basc_logo_large.jpg" width="150px" />](pipe_basc.html)

# [BASC-FIR](pipe_basc_fir.html)
The bootstrap analysis of stable clusters (BASC) on finite-impulse response (FIR) is a pipeline that builds brain parcellations (clusters) based on the similarity of individual estimated FIR, in block or slow event-related tasks. The BASC implements some boostrap replications of the cluster analysis as well as a consensus clustering approach to capture stable clusters at the individual and group levels. The pipeline also includes some automated method (called MSTEPS) to identify critical numbers of clusters, that summarize accurately a whole hierarchy of decomposition into brain networks.  
> [<img src="https://raw.githubusercontent.com/SIMEXP/niak/gh-pages/user_guide_fig/basc_fir/Screenshot%20at%202014-10-19%2015.03.19.png" width="300px" />](pipe_basc_fir.html)

# [GLM-connectome](pipe_glm_connectome.html)
