= Neuroimaging Analysis Kit (NIAK) v0.6 =

The NIAK is a library of functions dedicated to process neuroimaging data within Octave or Matlab(r), with an emphasis on functional magnetic resonance images (fMRI). Tools have been implemented in a modular fashion following consistent coding guidelines, such that they would integrate easily into new projects. A generic pipeline system is available to handle complex multi-stage processing and support distributed computing. Please read niak_install.txt for download and installation instructions. The latest version of the user's guide can be found at http://wiki.bic.mni.mcgill.ca/index.php/NeuroImagingAnalysisKit.

----
= What does NIAK exactly do ? =

The current version of NIAK (0.6) features :
* Reader/writer of medical image, supporting MINC1, MINC2, NIFTI and ANALYZE file formats.
* The pipeline system PSOM.
* Tools for T1 & fMRI preprocessing : slice timing correction, multi-session motion correction, coregistration between T1 and fMRI, non-linear spatial normalization to the MNI152 space, segmentation of T1 image, spatial and temporal filtering of fMRI data.
* Tools for individual spatial principal or independent component analysis (PCA/ICA) of fMRI data.
* Pipeline template for fMRI preprocessing, with multiple styles available, optimized for linear modeling or connectivity analysis. An optional correction of physiological noise based on ICA is available.

----
= Documentation =

There is a tutorial for the fMRI preprocessing pipeline :

* [http://wiki.bic.mni.mcgill.ca/index.php/NiakFmriPreprocessing] : How to run an fMRI preprocessing pipeline

Developers interested in integrating tools from the NIAK to their own project or to contribute to the NIAK can consult the [NIAK project webpage|http://code.google.com/p/niak/]. There is also an (outdated) pdf presentation you can [download|http://www.bic.mni.mcgill.ca/users/pbellec/data/niak.pdf].

The most detailed and up-to-date documentation about NIAK functions can be invoked using standard matlab/octave help:

<verbatim>
>> help niak_read_vol
_________________________________________________________________________
  SUMMARY NIAK_READ_VOL

  Read 3D or 3D+t data. Currently supported formats are minc1 and minc2
  (.mnc), nifti (.nii or .img/.hdr) and analyze (.img/.hdr/.mat).
  The data can also be zipped (additional extension .gz, see the COMMENTS
  section below).

  SYNTAX :
  [HDR,VOL] = NIAK_READ_VOL(FILE_NAME)
  ...
</verbatim>

----
=Contributions=

The kit was initially designed and assembled by PierreBellec at the McConnell Brain Imaging Center, Montreal Neurological Institute, McGill University, Canada, 2008.

Many of the functions of the kit are actually simple overlays of software developed over the years my members and collaborators of the BIC. Specifically, the pipeline system is based on a project called [PSOM|http://code.google.com/p/psom/] derived from the [Poor Man's Pipeline|PoorMansPipeline] project. The MINC reader/writer, operations of motion correction and spatial normalization are based of the [MINC tools|MincToolsGuide]. The implementation of linear model analysis is just an overlay of the [fMRIstat|http://www.math.mcgill.ca/keith/fmristat/] package developed by Keith Worsley at the Mathematics & Statistics Department of McGill. The processing of T1 image is based on the [CIVET|http://wiki.bic.mni.mcgill.ca/index.php/CIVET] pipeline. Claude Lepage gave a very precious support to wrap all these tools in the NIAK. Benjamin D'Hont has been the first beta-tester of the project.

Other functions have been based on existing open-source softwares. The NIFTI reader/writer is adapted from a code by Jimmy Shen. Some parts of the fMRI data preprocessing are ports from SPM. The NIAK logo was adapted from an original work by the artist [Mattahan|http://mattahan.deviantart.com/] under a [creative commons license|http://creativecommons.org/licenses/by-nc-sa/3.0/].

----
= License =

NIAK is an opensource project under an MIT license, reproduced hereafter : 

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software. 
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE. 
