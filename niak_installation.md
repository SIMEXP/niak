Currently, NIAK has been tested in Ubuntu as well as CentOS. The package reads and writes MINC files. Both MINC1 and MINC2 are supported. MINC1 files may in addition be compressed (extension .gz). Support for 4D NIFTI files is experimental. 

# Docker installation

The recommended way to install NIAK is to use a docker container, which bundles the NIAK library with all of its dependencies. Docker acts as a lightweight virtual machine, and ensures full replicability of results, regardless of potential upgrades to the production OS. See installation instructions [here](https://registry.hub.docker.com/u/simexp/niak/).

# Configuration of the pipeline manager

NIAK is using a pipeline system called [PSOM](http://psom.simexp-lab.org). In all pipelines, the options of psom are set using the field `opt.psom`. The most important parameter is the maximal number of processes that PSOM can run in parallel. More details about PSOM capabilities and configuration can be found in the dedicated [tutorial](http://psom.simexp-lab.org/psom_configuration.html).
```matlab
% Use up to four processes
opt.psom.max_queued = 4; 
```

# Manual installation

**Matlab/Octave.** To use NIAK, you will need a recent version of [Matlab](http://www.mathworks.com/) or [GNU Octave](http://www.gnu.org/software/octave/index.html). In addition to Matlab/Octave, NIAK depends on the "image processing" and "statistics" toolbox. This comes by default with Matlab. In Octave, you have to download it from [Octave forge](http://octave.sourceforge.net/index.html).
```matlab
% For a local install, remove the -global flag.
pkg install -auto -global -forge control general signal image io statistics
```

For Octave users, we suggest editing the `~/.octaverc` to change octave's default behaviour. 
```matlab
% Verbose in real time
more off
% Use the same .mat files as Matlab
default_save_options('-7');
% Set plot engine to gnuplot, to work around an issue with fltk
graphics_toolkit gnuplot
```

**NIAK library**. Download the [latest NIAK release on NITRC](http://www.nitrc.org/frs/download.php/7470/niak-boss-0.13.0.zip). Once the library has been decompressed, all you need to do is to start a Matlab or Octave session and add the NIAK path (with all his subfolders) to your search path. At this stage all pipelines (except the preprocessing pipeline) will work for nifti files. Any manipulation of MINC files will require the installation of the MINC tools (see below).
```matlab
 path_niak = '/home/toto/niak/'; 
 P = genpath(path_niak); 
 addpath(P); 
``` 

**MINC tools.** To read MINC files or run the fMRI preprocessing pipeline, it is necessary to install the [minc toolkit](http://www.bic.mni.mcgill.ca/ServicesSoftware/ServicesSoftwareMincToolKit) version 1.9.2. 

**Test the installation** Run the [test tutorial](http://niak.simexp-lab.org/niak_tutorial_test.html) to make sure that your installation is working properly. 
