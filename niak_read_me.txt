NIAK is a library of modules and pipelines for fMRI processing with Octave or Matlab(r) that can run in parallel either locally or in a supercomputing environment. 
Details about the project can be found at https://code.google.com/p/niak

= Active contributors = 

Pierre Bellec (1,2,4), Christian Danserau (1,2), Felix Carbonell (3,4)

1: Centre de recherche de l'institut de gériatrie de Montréal
2: Département d'informatique et de recherche opérationnelle, Université de Montréal, Canada
3: Biospective Inc., Canada (biospective.com)
4: Former affiliation: Montreal Neurological Institute, McGill University, Canada

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

= Other licenses and contributions = 

*The NIAK project was initiated by Pierre Bellec during his post-doctoral work in the laboratory of Alan C. Evans (ACElab), Montreal Neurological Institute, McGill University, Canada. The initial design for NIAK was inspired by the CIVET pipeline developed in the ACElab. 
*Many of the functions of the NIAK depend on software developed over the years by members and collaborators of the BIC, the minc toolkit (http://www.bic.mni.mcgill.ca/ServicesSoftware/ServicesSoftwareMincToolKit). The minc-toolkit is not part of NIAK and needs to be installed separately.
*Several functions are adapted from fMRIstat developed by the late Pr [http://www.math.mcgill.ca/keith/ Keith Worsley].
*The pipeline system is a project called [http://code.google.com/p/psom/ PSOM] developed by Pierre Bellec (MIT license). PSOM is not part of the NIAK code base, but is bundled as part of the NIAK archive. 
*The connectome pipeline is based on the brain connectivity toolbox (https://sites.google.com/site/bctnet/). The BCT is not part of NIAK and needs to be installed separately.
*The partial-volume estimation was generously contributed by Jussi Tohka, Tampere University of Technology, Finland (MIT license).
*The processing of T1 scan is based on ideas and code generously shared by Claude Lepage and Oliver Lyttelton, from the ACElab, as well as Vladimir Fonov and Andrew Janke, from the laboratory of Louis Collins at the MNI, McGill University. (MINC license, which is an MIT-like license, see niak_bestlinreg.pl and niak_best1stepnlreg.pl)
*The CORSICA method for correcting structured noise in fMRI was generously contributed by Vincent Perlbarg from the LIF Inserm U678 laboratory in Paris, directed by Dr Habib Benali (MIT license).
*The mutli-dimensional scaling algorithm and implementation was generously contributed by [http://pgrc-16.ipk-gatersleben.de/~stricker/ Marc Strickert] as part of the NIAK project (MIT license).
*The NIFTI reader/writer is adapted from a [http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=8797&objectType=file code] by [http://www.rotman-baycrest.on.ca/~jimmy/ Jimmy Shen] (BSD license). 
*The [http://www.mathworks.com/matlabcentral/fileexchange/956 conversion] between rotation/translation and matrix representations of rigid-body motion by Giampiero Campa (BSD license). 
*The 'sinc' scheme for slice timing correction is a port from [http://www.fil.ion.ucl.ac.uk/spm/ SPM] (GPL license). 
*The NIAK logo was adapted from an original work by the artist [mattahan.deviantart.com/ Mattahan] (creative commons license). 
*The spatial independent component analysis was extracted from [http://sccn.ucsd.edu/fmrlab/ fMRlab] (GPL license). 
*The windowed Fourier transfrom is from the [http://www-stat.stanford.edu/~wavelab/ WaveLab] toolbox (license&nbsp;: non-standard). 