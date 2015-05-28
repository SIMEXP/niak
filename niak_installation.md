# NIAK docker

The recommended way to install NIAK is to use a [docker](https://www.docker.com/) container, which bundles the NIAK library with all of its dependencies. Docker acts as a lightweight virtual machine, and ensures full replicability of results, regardless of potential upgrades to the production OS. It can be deployed on Linux, Windows or Mac OSX. 

To run niak with docker on your work station, you will need super user or sudo priviledge.

The first step is to install docker, there is suppost for many different system on the [docker installation site](https://docs.docker.com/installation/).

We have seen that federa (20) and centos (7) are turning SELinux on there docker installation. It might lead to some problem when you will expose data to be analyse to the docker/niak image. You can run the following command to disable SELinux on docker. 

```bash
sudo sed "s/\(\(OPTIONS=.*\)--selinux-enabled\(.*\)\)/\2\3/" -i /etc/sysconfig/docker
```


See instructions to run the container [here](https://registry.hub.docker.com/u/simexp/niak/).

# Pipeline manager

NIAK is using a pipeline system called [PSOM](http://psom.simexp-lab.org), a free open-source software (MIT license). With PSOM, it is possible to run computations in parallel on a laptop or a supercomputer, restart efficiently analysis or access detailed logs. In all pipelines, the options of psom are set using the field `opt.psom`. The most important parameter is the maximal number of processes that PSOM can run in parallel. More details about PSOM capabilities and configuration can be found in the dedicated [tutorial](http://psom.simexp-lab.org/psom_configuration.html).
```matlab
% Use up to four processes
opt.psom.max_queued = 4; 
```

# Manual installation

The following instructions describe how to install NIAK without using docker. 

**Matlab/Octave.** NIAK requires a recent version of [Matlab](http://www.mathworks.com/) (proprietary software) or [GNU Octave](http://www.gnu.org/software/octave/index.html) (free open-source software, GNU license). In addition to Matlab/Octave, NIAK depends on the "image processing" and "statistics" toolbox. This comes by default with Matlab. In Octave, it needs to be downloaded from [Octave forge](http://octave.sourceforge.net/index.html).
```matlab
% For a local install, remove the -global flag.
pkg install -auto -global -forge control general signal image io statistics
```

For Octave users, we suggest editing the `~/.octaverc` to change some of octave's default behaviour. 
```matlab
% Verbose in real time
more off
% Use the same .mat files as Matlab
default_save_options('-7');
% Set plot engine to gnuplot, to work around an issue with fltk
graphics_toolkit gnuplot
```

**NIAK library**. Download the [latest NIAK release on NITRC](http://www.nitrc.org/frs/download.php/7470/niak-boss-0.13.0.zip), a free open-source software (MIT license). Once the library has been decompressed, all you need to do is to start a Matlab or Octave session and add the NIAK path (with all his subfolders) to your search path. At this stage all pipelines (except the preprocessing pipeline) will work for nifti files. Any manipulation of MINC files will require the installation of the MINC tools (see below). The NIAK archive bundles the [brain connectivity toolbox](https://sites.google.com/site/bctnet/) and [PSOM](http://psom.simexp-lab.org/), which do not need to be installed separately. 
```matlab
 path_niak = '/home/toto/niak/'; 
 P = genpath(path_niak); 
 addpath(P); 
``` 

**MINC tools.** To read MINC files or run the fMRI preprocessing pipeline, it is necessary to install the [minc toolkit](http://www.bic.mni.mcgill.ca/ServicesSoftware/ServicesSoftwareMincToolKit) version 1.9.2 (free open-source software, with a custom MIT-like license). 

**Test the installation** Follow the [test tutorial](http://niak.simexp-lab.org/niak_tutorial_test.html) to make sure that your installation is working properly. 
