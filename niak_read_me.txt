#summary Summary of the NIAK project

This is NIAK v0.3

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


Please vist the page http://code.google.com/p/niak/wiki/NiakSummary for the most recent version of this summary. 

==What is the NIAK ?==

From the perspective of a researcher using neuroimaging to advance brain science, the neuroimaging analysis kit (NIAK) is simply "yet another package" dedicated to process fMRI data. The researchers interested in developing new ways of analyzing neuroimaging data may want to use the kit as a library because its elements are modular and provide all the necessary ingredients to develop new pipelines. People are more than welcome to integrate this code into new projects and distribute the resulting software, provided that the copyright and licensing information is retained. Note that the project is opened to any contribution of new functions that will be added to future releases. 

The core functions are implemented in .m code, compatible with both Matlab and octave (click [http://code.google.com/p/niak/wiki/WhyMatlabOctave here] to see why). Most parts of the kit will run on any platform with Matlab/Octave available, but some functionalities depend on third-party software that will only run on unix/linux architectures, see a more detailed discussion [Distribution here].

==What do the NIAK exactly do ?==
At release 1.0, the NIAK will include the necessary components for fMRI data pre-processing and linear modelling and will deal with a variety of file [http://code.google.com/p/niak/wiki/FileFormats formats]. The Milestones of the project can be found [http://code.google.com/p/niak/wiki/Milestones here].
 
The kit is now at its very early stage of development and does not yet include a lot of functionalities. Available features (release 0.3) are :
  * reader/writer for MINC1, MINC2, NIFTI and ANALYZE files
  * the pipeline system 
  * All the necessary bricks for fMRI data preprocessing (slice timing, spatial smoothing, temporal filtering).
  * A pipeline template for fMRI preprocessing

==Who has contributed to the NIAK ?==
The kit was initially designed and assembled by Pierre [http://wiki.bic.mni.mcgill.ca/index.php/PierreBellec Bellec] at the !McConnell Brain Imaging Center, Montreal Neurological Institute, !McGill University, Canada, 2008. 

Many of the functions of the kit are actually simple overlays of software developed over the years my members and collaborators of the !McConnell Brain Imaging Center, Montreal Neurological Institute, !McGill University, Montreal, Canada. Specifically, the pipeline system is an overlay of the [http://wiki.bic.mni.mcgill.ca/index.php/PoorMansPipeline Poor Man's Pipeline]. The MINC reader/writer, operations of motion correction and spatial normalization are overlays of the [http://wiki.bic.mni.mcgill.ca/index.php/MincToolsGuide MINC tools]. The implementation of linear model analysis is just an overlay of the [http://www.math.mcgill.ca/keith/fmristat/ fMRIstat] package developed by Keith Worsley at the Mathematics & Statistics Department, !McGill University, Montreal, Canada. Claude Lepage gave a precious support to warp those tools in the NIAK.

Other functions have been based on existing open-source softwares. The NIFTI reader/writer is adapted from a [http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=8797&objectType=fileoriginal code] by Jimmy Shen. Some parts of the fMRI data preprocessing are port from [http://www.fil.ion.ucl.ac.uk/spm/software/spm5 SPM].

==How to use the NIAK ?==
Latest release can be found in the Download section of this website, see the [Install installation] instructions. There is currently no manual per say, other than this wiki, and the help of matlab functions, but it is [Documentation planned] to have one at some point. Important functionalities of the NIAK have demonstration scripts on a small, publicly available dataset, see the related wiki page for [http://code.google.com/p/niak/wiki/Demonstration details]. 

==What's inside the NIAK ?==
For those who would want to contribute, to recycle the NIAK code or simply out of curiosity, this wiki contains detailed information on the implementation of the NIAK project. There are four main components: 

1. [http://code.google.com/p/niak/wiki/Commands Commands]. The so-called commands are functions designed to work within the Matlab/Octave workspace, without accessing files on the disk.

2. [http://code.google.com/p/niak/wiki/Bricks Bricks]. Those functions are the elements of a pipeline. They take files as inputs (with a couple of options) and create files as outputs.

3. [http://code.google.com/p/niak/wiki/Pipeline Pipeline]. This is a single function. It takes a data structure as input which is used to describe the application of bricks to a large collection of datasets. The pipeline will sort out the dependencies between bricks, run the jobs and write out log files. The jobs can run on a single machine or on a PC cluster. 

4. [http://code.google.com/p/niak/wiki/Demonstration Demonstration]. This collection of scripts illustrates how the main functionalities of NIAK can be applied on a small example dataset.

Some [http://code.google.com/p/niak/wiki/StyleGuidelines guidelines] to write MATLAB code have been developed to make code easier to understand and make future developments consistent with existing code.
