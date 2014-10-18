# Outputs 

These outputs of the fMRI/T1 preprocessing pipeline are generated in the `opt.folder_out` folder. These typically represent a 250% increase in size compared to the raw datasets if `opt.size_output` is equal to `'quality_control'` (and much more if `opt.size_output` is equal to `'all'`). The exact outputs are listed below. The files that are generated only if ''opt.size_output'' equals 'all' are indicated with a *. In the following `subject`, `session` and `run` are the IDs used in the `files_in` argument of the pipeline, and `ext` is the extension of the images (same as inputs, either `.mnc` or `.mnc.gz`). 

# fMRI images

The final preprocessed fMRI datasets are located in the folder ''fmri'': 

 * **fmri/fmri_subject_session_run.ext**: fMRI datasets after the full preprocessing pipeline was applied.
 * **fmri/fmri_subject_session_run._extra.mat**: the .mat companion of the fMRI dataset. It contains four variables: 
  * **mask_suppressed** (vector, same length as the number of time frames in the raw data) binary vector indicating if a time frame from the raw dataset was removed (1) or retained (0).  
  * **time_frames** (vector, same length as the preprocessed time series) vector indicating the time associated with each time frame. This is accurate only if the dataset has been corrected for slice timing.  
  * **confounds** (matrix, length of the preprocessed time series x number of confounds) each column is a counfound that has been regressed out from the preprocessed data 
  * **labels_confounds** (cell of strings) the kth entry is the (string) label of the kth confound.

# anatomical images

The final results regarding the T1 image as well as all coregistration processes using the T1 image (thus including fMRI to T1 and fMRI to stereotaxic) are located in the folder ''anat'': 

 * **anat/subject/anat_subject_classify_stereolin.ext**: a 3 tissue-type classification (cerebrospinal fluid / gray matter / white matter, in this order) in the stereotaxic (linear) MNI152 space. 
 * **anat/subject/anat_subject_mask_stereolin.ext**: a mask of the brain for the T1 scan in stereotaxic linear space. 
 * **anat/subject/anat_subject_mask_stereonl.ext**: a mask of the brain for the T1 scan in stereotaxic non-linear space. 
 * **anat/subject/anat_subject_nativefunc_hires.ext**: the T1 scan resampled in native functional space at high spatial resolution. 
 * **anat/subject/anat_subject_nativefunc_lowres.ext**: the T1 scan resampled in native functional space at native functional resolution. 
 * **anat/subject/anat_subject_nuc_nativet1.ext**: the T1 scan in native space after non-uniformity correction. 
 * **anat/subject/anat_subject_nuc_stereolin.ext**: the T1 scan in stereotaxic linear space after non-uniformity correction. 
 * **anat/subject/anat_subject_nuc_stereonl.ext**: the T1 scan in stereotaxic non-linear space after non-uniformity correction. 
 * **anat/subject/func_subject_mask_nativefunc.ext**: a mask of the brain based on fMRI in native functional space. 
 * **anat/subject/func_subject_mask_stereolin.ext**: a mask of the brain based on fMRI in stereotaxic linear space. 
 * **anat/subject/func_subject_mask_stereonl.ext**: a mask of the brain based on fMRI in stereotaxic non-linear space. 
 * **anat/subject/func_subject_mean_nativefunc.ext**: a mean fMRI volume in native functional space. 
 * **anat/subject/func_subject_mean_stereolin.ext**: a mean fMRI volume in stereotaxic linear space. 
 * **anat/subject/func_subject_mean_stereonl.ext**: a mean fMRI volume in stereotaxic non-linear space. 
 * **anat/subject/func_subject_std_nativefunc.ext**: an average image (across all runs) of the standard deviation of the fMRI time series in native functional space. 
 * **anat/subject/transf_subject_nativefunc_to_stereolin.xfm**: a linear transformation from native functional space to stereotaxic space. 
 * **anat/subject/transf_subject_nativefunc_to_stereonl.xfm**: a non-linear transformation from native functional space to stereotaxic space. 
 * **anat/subject/transf_subject_nativefunc_to_stereonl.mnc**: the grid images associated to the preceeding non-linear transformation. 
 * **anat/subject/transf_subject_nativet1_to_stereolin.xfm**: a linear transformation from native structural (T1) space to stereotaxic space. 
 * **anat/subject/transf_subject_stereolin_to_stereonl.xfm**: a non-linear transformation from stereotaxic space to itself, based on the T1 scan after linear transformation into stereotaxic space. 
 * **anat/subject/transf_subject_stereolin_to_stereonl.mnc**: the grid images associated to the preceeding non-linear transformation.

# Quality control

All images related to quality control are located in the folder ''quality_control''. Some individual QC results are are generated for CORSICA and every subjects: 

 * **quality_control/subject/corsica/fmri_subject_session_run_a_mc_f_sica_space_qc_corsica.pdf**: a pdf file with "montage" style representation of all spatial components of the ICA, along with the associated time course, its power spectrum as well as a time-frequency plot. The score of selection for CORSICA of each component is indicated (two scores are actually indicated, one per mask). Components that were selected as noise have their score followed by a *. Note that the component are ranked by their maximal selection score in CORSICA. 
 * **quality_control/subject/corsica/subject_mask_vent_nativefunc.ext**: the mask of the ventricle that was used to select physiological noise, in native functional space. 
 * **quality_control/subject/corsica/subject_mask_vent_nativefunc.ext**: the mask of the brain stem that was used to select physiological noise, in native functional space.

Other QC results are generated for the motion correction of every subjects: 

 * **quality_control/motion_correction/tab_coregister_motion.csv**: a "comma-separated values" table representing two quality control measures for the motion correction of each run. First, the relative overlap of the brain mask for each individual run with a "consensus" mask derived by averaging and thresholding the masks of all runs (this is the mask found in the folder ''anat''). Second, the spatial correlation of the average functional volume of each run with the average functional volume of all runs combined together. This reflects the quality of the within-session and between-session motion estimations. Note that if the field of view was constant, all these values should be closed to one. Values of spatial correlation below 0.9 are an indication that the individual run image should checked in detail. 
 * **quality_control/motion_correction/fig_coregister_motion.pdf**: a pdf file with a bar representation of the preceeding table. 
 * **quality_control/motion_correction/func_subject_mask_average_nativefunc.ext**: the average of the brain masks across all runs. This is usefull to check if the field of view was homogeneous across all runs and sessions. 
 * **quality_control/motion_correction/fig_motion_within_run.pdf**: a pdf file with a plot of the within-run motion parameters (3 rotations and 3 rotations). An abrupt change in motion parameters over 2 mm or 2 degrees may suggest to exclude the run from the final analysis, or at least to check the influence of the inclusion of these runs.

Some summary of QC are generated for the motion correction at the group level: 

 * **quality_control/group_motion/qc_motion_group.csv**: a table with the maximal motion between two successive scans for each subject, in rotation and translation. 
 * **quality_control/group_motion/qc_motion_group.pdf**: a pdf with a figure representation of the preceeding table. 
 * **quality_control/group_motion/qc_coregister_between_runs.csv**: a table with the minimal relative overlap between masks and the minimal cross-correlation of average volumes across runs for each subject. 
 * **quality_control/group_motion/qc_coregister_between_runs.pdf**: a pdf with a figure representation of the preceding table.

Some summary of QC are generated for the T1 and T1-to-fMRI coregistration operations at the group level: 

 * **quality_control/group_coregistration/anat_mask_average_stereolin.ext**: average of all structural brain masks is stereotaxic linear space. This is useful to spot the homogneity of the field of views across subjects. 
 * **quality_control/group_coregistration/anat_mask_average_stereolin.ext**: same as previous, but in non-linear stereotaxic space. 
 * **quality_control/group_coregistration/anat_mask_group_stereolin.ext**: A group mask derived by thresholding the average structural mask in stereotaxic linear space. 
 * **quality_control/group_coregistration/anat_mask_group_stereonl.ext**: A group mask derived by thresholding the average structural mask in stereotaxic linear space. 
 * **quality_control/group_coregistration/anat_mean_average_stereolin.ext**: average of all structural brain scans is stereotaxic linear space. This is useful to assess the overall quality of the linear coregistration. 
 * **quality_control/group_coregistration/anat_mean_average_stereonl.ext**: average of all structural brain scans is non-stereotaxic linear space. This is useful to assess the overall quality of the non-linear coregistration. It may be useful to compare this volume with the template used by niak as a target (located in ''folder_niak/template/mni-models_icbm152-nl-2009-1.0/mni_icbm152_t1_tal_nlin_sym_09a.mnc.gz''). 
 * **quality_control/group_coregistration/anat_mean_std_stereolin.ext**: standard-deviation across all brain structural scans is stereotaxic linear space. 
 * **quality_control/group_coregistration/anat_mean_std_stereolin.ext**: standard-deviation across all brain structural scans is non-linear stereotaxic linear space. This is useful to spot the areas of the brain where there is substantial amounts of variability left. 
 * **anat_tab_qc_coregister_stereolin.csv**: a table representing the relative overlap of individual brain structural masks with the group mask, as well as the spatial correlation of each individual structural scan with the group average within the group mask. This is useful to spot subjects where the linear coregistration process performed poorly. It is suggested to check the brain scans of the individuals with lowest scores on either scales. 
 * **anat_tab_qc_coregister_stereonl.csv**: same as previous, but in non-linear stereotaxic space. 
 * **anat_tab_qc_coregister_stereolin.pdf**: a pdf with a figure representation of the associated csv file. 
 * **anat_tab_qc_coregister_stereonl.pdf**: a pdf with a figure representation of the associated csv file. 
*All the preceeding file have an equivalent starting with "func" which contains the same QC as described above, but for the average functional volume after slice timing and motion correction, rather than the structural scan. The quality of coregistration in stereotaxic space is an indirect way to assess the quality of the T1-to-fMRI coregistration step.

# Intermediate results

All the intermediate result of a given subject can be found in a folder ''intermediate/subject/''. The exact list is as follows, where a (*) indicates that results can be found only if ''opt.size_output'' equals 'all': 

 * **intermediate/subject/slice_timing/fmri_subject_session_run_a.ext (*)**: the slice-timing corrected functional images. 
 * **intermediate/subject/motion_corrected/fmri_subject_session_run_a_mc.ext (*)**: the functional images corrected for slice timing and motion. 
 * **intermediate/subject/motion_corrected/motion_within_run_subject_fmri_subject_session_run_a.mat**: The within-run motion parameters (in matlab/octave format). 
 * **intermediate/subject/motion_corrected/motion_within_session_subject_fmri_subject_session_run_a.mat**: The between-run but within-session motion parameters (in matlab/octave format). 
 * **intermediate/subject/motion_corrected/motion_between_session_subject_fmri_subject_session.mat**: The between-session motion parameters (in matlab/octave format). 
 * **intermediate/subject/motion_corrected/motion_parameters_subject_fmri_subject_session.mat**: The final motion parameters, combining within-run, between-run and between-session (in matlab/octave format). 
 * **intermediate/subject/motion_corrected/motion_target_subject_fmri_subject_session_run_a.ext**: The target for coregistration (usually the median voume of a run). 
 * **intermediate/subject/corsica/fmri_subject_session_run_a_mc_p.ext (*)**: the functional images corrected for slice timing, motion and structured noise. 
 * **intermediate/subject/corsica/?**: The space and time components of the ICA. 
 * **intermediate/subject/time_filter/fmri_subject_session_run_a_mc_p_f.ext (*)**: the functional images corrected for slice timing, motion, structured noise and high/low frequencies fluctuations. 
 * **intermediate/subject/resample/fmri_subject_session_run_a_mc_p_f_res.ext (*)**: the functional images corrected for slice timing, motion, structured noise , high/low frequencies fluctuations and finally resampled in stereotaxic space.
