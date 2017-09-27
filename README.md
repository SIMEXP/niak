[![Build Status](https://circleci.com/gh/BIDS-Apps/niak.png?circle-token=:circle-token)](https://circleci.com/gh/BIDS-Apps/niak) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
# Niak
The neuroimaging analysis kit (NIAK) is a library of pipelines for the preprocessing and mining of large functional neuroimaging data, using GNU Octave or Matlab(r), and distributed under a MIT license. This includes but is not limited to the preprocessing pipeline implemented in this app. Essential documentation can be found on the [NIAK website](http://niak.simexp-lab.org/). 

# In this Bids-apps

__This app__ implements a pipeline for __preprocessing structural and functional MRI__ datasets. You can find the full description of the NIAK fmri preprocessing pipeline [here](http://niak.simexp-lab.org/pipe_preprocessing.html).

This pipeline first aims at reducing various noise sources that compromise the interpretation of fMRI fluctuations, e.g. physiological and motion artefacts. The second major aim is to align the data acquired at different time points and imaging modalities for a single subject, sometimes separated by years, and also to establish some correspondence between the brains of different subjects, such that an inference on the role of a given brain area can be carried at the level of a group.

## How to report errors and ask questions

If the problems seems to be related to the app itself, you can always create a [new issue on our github page.](https://github.com/BIDS-Apps/niak/issues)  
If is seems to come from NIAK itself, please [report you issues on the NIAK github page](https://github.com/SIMEXP/niak/issues)
