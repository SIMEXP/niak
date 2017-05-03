# NIAK with docker

The recommended way to install NIAK is to use a [docker](https://www.docker.com/) container, which bundles the NIAK library with all of its dependencies. Docker acts as a lightweight virtual machine, and ensures full repeatability of results, regardless of potential upgrades to the production OS. It can be deployed on Linux, Windows or Mac OSX. Using NIAK through docker also makes it very easy to update the software. To run niak with docker on your work station, you will need super user or sudo privilege. Start by installing docker, following the official [docker installation site](https://docs.docker.com/installation/). **Disclaimer**: Be aware that any user that can execute a "docker run"  command on a machine have access to the complete file system as a super user. Alternatively, you can use [singularity](http://singularity.lbl.gov/) which will be able to play the same docker image, while keeping tight control on user rights. Both set of instructions (docker and singularity) are provided below.

 > [<img src="https://raw.githubusercontent.com/SIMEXP/niak/gh-pages/docker_logo.png" width="350px" />](https://www.docker.com/)

### Linux
The first step is to create a docker group and add the user that will use docker to that list.

```bash
# If the group already exists, the command will return an error, just ignore it
sudo groupadd docker
# Then add user USERNAME to the docker group
sudo usermod -a -G docker USERNAME
```

For the docker group to become effective, you will need to either restart the system or type:
``` bash
sudo chgrp docker /run/docker.sock
sudo chmod 660 /run/docker.sock
```
All the members of the docker group will have access to the docker service.

The following command will start NIAK with your home directory accessible (the rest of the file system is not accessible):
```bash
xhost +local:
docker run -i -t --privileged --rm \
       --name niak \
       -v $HOME:$HOME -v /etc/group:/etc/group \
       -v /etc/passwd:/etc/passwd -v /etc/shadow:/etc/shadow  \
       -v /tmp:/tmp \
       -e DISPLAY=unix$DISPLAY \
       --user $UID \
       simexp/niak-boss:latest \
       /bin/bash -ic "cd $HOME; octave --force-gui; /bin/bash"
```
You can also add the following to you $HOME/.bashrc file so you can simply type `docker_run_niak` to run niak.

```bash
alias docker_run_niak="xhost +local: && docker stop niak && docker rm niak && \
docker run -i -t --privileged --rm \
       --name niak \
       -v $HOME:$HOME -v /etc/group:/etc/group \
       -v /etc/passwd:/etc/passwd -v /etc/shadow:/etc/shadow  \
       -v /tmp:/tmp \
       -e DISPLAY=unix$DISPLAY \
       --user $UID \
       simexp/niak-boss:latest \
       /bin/bash -ic \"cd $HOME; octave --force-gui; /bin/bash\""

```

Replace `simexp/niak-boss:0.19.1` in the command above by `simexp/niak-boss` to always get the latest niak release. Note that the first execution will be longer, since the `simexp/niak-boss(:0.19.1)` mirror has to be downloaded from the internet. All subsequent call to the line should be much faster. Close the GUI and type "exit" in the terminal to stop your session. if somehow the process did not exit properly and docker complains that niak is already running when you restart it, type:
```bash
docker stop niak
docker rm niak
```

The procedure as been tested on Debian 8.0, Ubuntu `>=` 14.10, centOS 7, fedora `>=` 20, OpenSuse `>=` 13.1 and we expect it to run smoothly on many other Linux distributions.

### Mac OSX

On more recent OSX distribution (>= 10.10.3, or better > 10.11), Docker usage is straight forward. Downoload the stable channel from the [docker mac install page](https://docs.docker.com/docker-for-mac/install/#download-docker-for-mac). For older distributions, the task is not always as smooth, but is [explained in detail here](https://docs.docker.com/toolbox/toolbox_install_mac/).


One docker is running, you to start a bash terminal and type

```bash
bash
docker run -it --privileged --rm \
       simexp/niak-boss:latest \
       /bin/bash -ic "cd $HOME; octave; /bin/bash"
```

in that terminal and an octave session with NIAK included starts. (Note that Macs often have tcsh terminal by default, the first line with `bash` forces your terminal to be in bash mode.)

Note that one could access the octave gui by installing xquart on its mac, we do not officially support this feature but you can have a look [here](https://fredrikaverpil.github.io/2016/07/31/docker-for-mac-and-gui-applications/) for a procedure. We recommend the use of Jupyter notebooks (see below) for a full featured user interface experience of NIAK.

### Windows

If you have a Windows 10 Pro, the [docker installation](https://docs.docker.com/docker-for-windows/install/) is straight forward.
We recommend using a Jupyter notebook to run NIAK on windows (see bellow), but you can also run the following command in your favorite terminal to get an `octave` session with NIAK included.

For older distributions, the task is not always as smooth, but is [explained in detail here](https://docs.docker.com/toolbox/toolbox_install_windows/).

```bash
docker run -it --privileged --rm \
       simexp/niak-boss:latest \
       /bin/bash -ic "cd $HOME; octave; /bin/bash"
```


# NIAK in a Jupyter notebook

After a successful docker installation, niak can be controlled throught a Jupyter notebook. It is available with niak-boss  >= 0.18.0 image. You can run:

#### Linux & OSX variant
```bash
docker run -it --rm  -v $PWD:/sandbox/home --user $UID \
       -p 8080:8080 simexp/niak-boss:latest niak_jupyter
```
#### Windows variant
```bash
docker run -it --rm  -v $PWD:"/sandbox/home"  -p 8080:8080 \
 simexp/niak-boss:latest niak_jupyter
```

the output should looks like the following:
```
Welcome to NIAK in your browser, powered by jupyter!
NIAK is now available on your machine
Open your favorite browser at the following address: http://localhost:8080
If that does not work, then try http://172.17.0.2:8080
Then click New --> Octave

The PASSWORD is: NIAK

For a tutorials on how to run Niak, go to http://niak.simexp-lab.org/niak_tutorials.html
For the notebook logs, look in /tmp/niak_jypiter_Ln3BTm.log
```

You can now start your favorite browser and go to the [following address: http://localhost:8080](http://localhost:8080), then click New --> Octave. You now have access to all niak features! Note that the NIAK outputs will be in the directory where you called the `docker run` command (that is $PWD).

# NIAK in Singularity
Follow the [HPC Installation section](http://niak.simexp-lab.org/niak_HPC_installation.html)

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

**NIAK library**. Download the [latest NIAK release on Github](https://github.com/SIMEXP/niak/releases/download/v0.16/niak-with-dependencies.zip), a free open-source software (MIT license). Once the library has been decompressed, all you need to do is to start a Matlab or Octave session and add the NIAK path (with all his subfolders) to your search path. At this stage all pipelines (except the preprocessing pipeline) will work for nifti files. Any manipulation of MINC files will require the installation of the MINC tools (see below). The NIAK archive bundles the [brain connectivity toolbox](https://sites.google.com/site/bctnet/) and [PSOM](http://psom.simexp-lab.org/), which do not need to be installed separately.
```matlab
 path_niak = '/home/toto/niak/';
 P = genpath(path_niak);
 addpath(P);
```

**MINC tools.** To read MINC files or run the fMRI preprocessing pipeline, it is necessary to install the [minc toolkit](http://www.bic.mni.mcgill.ca/ServicesSoftware/ServicesSoftwareMincToolKit) version 1.9.2 (free open-source software, with a custom MIT-like license).

**Test the installation** Follow the [test tutorial](http://niak.simexp-lab.org/niak_tutorial_test.html) to make sure that your installation is working properly.

# Pipeline manager

NIAK is using a pipeline system called [PSOM](http://psom.simexp-lab.org), a free open-source software (MIT license). With PSOM, it is possible to run computations in parallel on a laptop or a supercomputer, restart efficiently analysis or access detailed logs. In all pipelines, the options of psom are set using the field `opt.psom`. The most important parameter is the maximal number of processes that PSOM can run in parallel. More details about PSOM capabilities and configuration can be found in the dedicated [tutorial](http://psom.simexp-lab.org/psom_configuration.html).
```matlab
% Use up to four processes
opt.psom.max_queued = 4;
```
