= Neuroimaging Analysis Kit (NIAK) v0.6.4.3 =

NIAK is a library of modules and pipelines for fMRI processing with Octave or Matlab(r) that can run in parallel either locally or in a supercomputing environment. Linux OS and MINC file format are supported. Developers interested in using NIAK as a development library or to contribute to the project can consult the [http://code.google.com/p/niak/ NIAK google code] webpage. The wiki http://www.nitrc.org/plugins/mwiki/index.php/niak:MainPage is a detailed user guide with the following resources : 

*[[http://www.nitrc.org/plugins/mwiki/index.php/niak:Installation|Installation]] instructions. 
*[http://www.nitrc.org/frs/downloadlink.php/2726 Overview of NIAK] in pdf. 
*List of [[http://www.nitrc.org/plugins/mwiki/index.php/niak:NiakContributions|contributions]] to NIAK development and testing. 
*Tutorial of the [[http://www.nitrc.org/plugins/mwiki/index.php/niak:FmriPreprocessing|fMRI preprocessing]] pipeline;

Note that the most detailed and up-to-date documentation about NIAK functions can be invoked using standard matlab/octave (type "help ''function_name''").

=Contributions=

The kit was originally designed by [http://simexp-lab.org/brainwiki/doku.php?id=pierrebellec Pierre Bellec]&nbsp;who is still the main person responsible for its maintenance and development at the UNF, CRIUGM, DIRO, Université de Montréal, 2010-2011. The project started in the lab of [http://www.bic.mni.mcgill.ca/~alan/ Alan C. Evans], Canada, 2008-10. The following people have directly helped to develop NIAK, either through code or ideas&nbsp;: 

*[http://felixmiguelc.googlepages.com Felix Carbonell] 
*[http://www.imed.jussieu.fr/fr/outils/affiche_personne.php?pers_id=95 Vincent Perlbarg] 
*[http://www.bic.mni.mcgill.ca/users/claude/ Claude Lepage] 
*[http://www.dementia.unsw.edu.au/dcrcweb.nsf/page/Janke Andrew Janke] 
*[http://www.bic.mni.mcgill.ca/~vfonov/ Vladimir Fonov] 
*[http://www.cs.tut.fi/~jupeto/ Jussi Tohka] 
*[http://www.bic.mni.mcgill.ca/~oliver/ Oliver Lytelton]

=== Institutions  ===

The following institutions are involved in the development and diffusion of NIAK&nbsp;: 

*[http://www.bic.mni.mcgill.ca/ McConnell Brain Imaging Center (BIC)], [http://www.mni.mcgill.ca/ Montreal Neurological Institute], [http://www.mcgill.ca/ Mcgill University], Montréal, Canada. Most of the tools provided in NIAK have been developed at this institution over the past 15 years. 
*[http://www.unf-montreal.ca/siteweb/Home_fr.html Unité de neuroimagerie foncitonnelle], [http://www.criugm.qc.ca/ Centre de recherche de l'institut de gériatrie de Montréal (CRIUGM)], [http://www.umontreal.ca/ Université de Montréal], Montréal, Canada. This institution supports the lab of Pierre Bellec, and thereof the core of NIAK maintenance and development. 
*[http://www.iro.umontreal.ca/ Département d'informatique et de recherche opérationnelle (DIRO)], [http://www.umontreal.ca/ Université de Montréal], Montréal, Canada. This institution supports the lab of Pierre Bellec, and thereof the core of NIAK maintenance and development. 
*[http://www.imed.jussieu.fr/ Laboratoire d'Imagerie Fonctionnelle (LIF)], [http://www.inserm.fr/ Inserm], [http://www.upmc.fr/ Université Pierre et Marie Curie (UPMC)], Paris, France. This institution has contributed a number of tools to NIAK through the inputs of Vincent Perlbarg. 
*[http://sp.cs.tut.fi/index.en.shtml Department of Signal Processing, Tampere University of Technology]. This institution has contributed a number of tools to NIAK through the inputs of Jussi Tohka. 
*[http://www.anu.edu.au/index.php Australia National University]. This institution has contributed a number of tools to NIAK through the inputs of Andrew Janke. 
*[http://www.nitrc.org/ The Neuroimaging Informatics Tools and Resources Clearinghouse (NITRC)] generously provides hosting of the NIAK user website. 
*[http://code.google.com/ Google code] generously provides hosting of the NIAK developer's website.

=== Opensource software  ===

Many of the functions of the kit are based on software developed over the years by members and collaborators of the BIC and most notably fMRIstat developed by the late [http://www.math.mcgill.ca/keith/ Keith Worsley] and NIAKified by Felix Carbonnell, the [http://en.wikibooks.org/wiki/MINC MINC] tools and the [http://www.bic.mni.mcgill.ca/users/yaddab/Yasser-HBM2006-Poster.pdf CIVET] pipeline. Other codes came from opensource projects (the detailed licenses are in the respective codes): 

*The pipeline system is a project called [http://code.google.com/p/psom/ PSOM] developed by Pierre Bellec (MIT license). 
*The NIFTI reader/writer is adapted from a [http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=8797&objectType=file code] by [http://www.rotman-baycrest.on.ca/~jimmy/ Jimmy Shen] (BSD license). 
*The [http://www.mathworks.com/matlabcentral/fileexchange/956 conversion] between rotation/translation and matrix representations of rigid-body motion by Giampiero Campa (BSD license). 
*The 'sinc' scheme for slice timing correction is a port from [http://www.fil.ion.ucl.ac.uk/spm/ SPM] (GPL license). 
*The NIAK logo was adapted from an original work by the artist [http://mattahan.deviantart.com/ Mattahan] (creative commons license). 
*The spatial independent component analysis was extracted from [http://sccn.ucsd.edu/fmrlab/ fMRlab] (GPL license). 
*The windowed Fourier transfrom is from the [http://www-stat.stanford.edu/~wavelab/ WaveLab] toolbox (license&nbsp;: non-standard). 
*The mutli-dimensional scaling algorithm and implementation was generously contributed by [http://pgrc-16.ipk-gatersleben.de/~stricker/ Marc Strickert] as part of the NIAK project (MIT license).

Finally, a lot of people have been involved in beta-testing the project and gave very precious feedback over the past two years. A non-exhaustive list includes Benjamin D'hont, Pr Christophe Grova's lab, Pr Jean Gotman's lab, Pr Alain Dhager's lab, Pr Pedro Rosa-Neto's lab and Sébastien Lavoie-Courchesne.

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
