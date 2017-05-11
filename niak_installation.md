# NIAK with docker

The recommended way to install NIAK is to use a [docker](https://www.docker.com/) container, which bundles the NIAK library with all of its dependencies. Docker acts as a lightweight virtual machine, and improves the repeatability of results across operating systems, including Linux, Windows or Mac OSX. Using NIAK through docker also makes it very easy to update the software. To run niak with docker on your work station, you will need super user or sudo privilege. Start by installing docker, following the official [docker installation site](https://docs.docker.com/installation/). **Disclaimer**: Be aware that any user that can execute a "docker run"  command on a machine have access to the complete file system as a super user. Alternatively, you can use [singularity](http://singularity.lbl.gov/) which will be able to play the same docker image, while keeping tight control on user rights. Instructions for singularity can be found in the section on [installation for high-performance computing](http://niak.simexp-lab.org/niak_HPC_installation.html).

 > [<img src="https://raw.githubusercontent.com/SIMEXP/niak/gh-pages/docker_logo.png" width="350px" />](https://www.docker.com/)

### Linux
The first step is to create a docker group and add the user that will use docker to that list.
```bash
# If the group already exists, the command will return an error, just ignore it
sudo groupadd docker
# Then add user USERNAME to the docker group
sudo usermod -a -G docker USERNAME
```
All the members of the docker group will have access to the docker service. For the docker group to become effective, you will need to either unlog or restart your system.

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
       simexp/niak-cog:latest \
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
       simexp/niak-cog:latest \
       /bin/bash -ic \"cd $HOME; octave --force-gui; /bin/bash\""

```

Replace `simexp/niak-cog:latest` by, for example, `simexp/niak-cog:1.0.1` to use a specific version (here 1.0.1). Note that the first execution will be longer, since the `simexp/niak-cog` image has to be downloaded from the internet. All subsequent call to the line will start niak immediately, and will be much faster. Close the GUI and type "exit" in the terminal to stop your session. if somehow the process did not exit properly and docker complains that niak is already running when you restart it, type:
```bash
docker stop niak
docker rm niak
```

The procedure as been tested on Debian 8.0, Ubuntu `>=` 14.10, centOS 7, fedora `>=` 20, OpenSuse `>=` 13.1 and we expect it to run smoothly on most Linux distributions.

### Mac OSX

On more recent OSX distribution (>= 10.10.3, or better > 10.11), Docker usage is straightforward. Downoload the stable channel from the [docker mac install page](https://docs.docker.com/docker-for-mac/install/#download-docker-for-mac). Docker for mac also requires MMU enable hardware. You should be safe if your laptop was build in 2010 or later.

For older distributions/hardware, you can still install Docker, the task is not always as smooth, but is [explained in detail here](https://docs.docker.com/toolbox/toolbox_install_mac/).

We recommend using a Jupyter notebook to run NIAK on OSX for a full featured user interface experience of NIAK (see bellow), but you can also run the following command in your favorite terminal to get an `octave` session with NIAK included.


```bash
bash
docker run -it --privileged --rm -v $HOME:$HOME \
       simexp/niak-cog:latest \
       /bin/bash -ic "cd $HOME; octave; /bin/bash"
```

Note that Macs often have tcsh terminal by default, the first line with `bash` forces your terminal to be in bash mode.

Note that one could access the octave gui by installing xquart on its mac, we do not officially support this feature but you can have a look [here](https://fredrikaverpil.github.io/2016/07/31/docker-for-mac-and-gui-applications/) for a procedure.

### Windows

If you have a Windows 10 Pro, the [docker installation](https://docs.docker.com/docker-for-windows/install/) is straight forward. Note that, as mention in the instruction, [virtualization must be enabled](https://docs.docker.com/docker-for-windows/troubleshoot/#virtualization-must-be-enabled)

For older distributions, the task is not always as smooth, but is [explained in detail here](https://docs.docker.com/toolbox/toolbox_install_windows/).


We recommend using a Jupyter notebook to run NIAK on windows for a full featured user interface experience of NIAK (see bellow), but you can also run the following command in your favorite terminal to get an `octave` session with NIAK included.


```bash
docker run -it --privileged --rm \
       simexp/niak-cog:latest \
       /bin/bash -ic "cd $HOME; octave; /bin/bash"
```


# NIAK in a Jupyter notebook

After a successful docker installation, niak can be controlled throught a Jupyter notebook. It is available with niak >= 0.18.0 image. You can run:

#### Linux & OSX variant
```bash
bash
docker run -it --rm  -v $PWD:/sandbox/home --user $UID \
       -p 8080:8080 simexp/niak-cog:latest niak_jupyter
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
You can now start your favorite browser and go to [http://localhost:8080](http://localhost:8080). Once the page is open, Jupyter will request a password, use NIAK. Then click New --> Octave. You now have access to all NIAK features! Note that the NIAK outputs will be in the directory where the `docker run` command has been executed.

You should then have access to the file present in the directory where `niak_jupyter` was started.

#### Windows variant
From the docker web site: _"If you are using Windows containers, keep in mind that there are some limitations with regard to networking [...] One thing you may encounter rather immediately is that published ports on Windows containers do not do loopback to the local host. Instead, container endpoints are only reachable from the host using the container’s IP and port."_

Hence, once you start Docker and spin off NIAK with the following command
```bash
docker run -it --rm  -v $PWD:"/sandbox/home"  -p 8080:8080 \
 simexp/niak-cog:latest niak_jupyter
```
> [<img src="docker_windows_niak.png" width="350px" />]

You will need to open your browser with the address provided to you by the docker virtual machine. The adress `192.168.99.100` is circled in red in the example above. You then open your favorite browser to the address appended by port `8080`: `192.168.99.100:8080`. Once the page is open, Jupyter will request a password, use NIAK.

> [<img src="jupyter_login.png" width="350px" />]

Then click New --> Octave. You now have access to all NIAK features! Note that the NIAK outputs will be in the directory where the `docker run` command has been executed.


# Pipeline manager

NIAK is using a pipeline system called [PSOM](http://psom.simexp-lab.org), a free open-source software (MIT license). With PSOM, it is possible to run computations in parallel on a laptop or a supercomputer, restart efficiently analysis or access detailed logs. In all pipelines, the options of psom are set using the field `opt.psom`. The most important parameter is the maximal number of processes that PSOM can run in parallel. More details about PSOM capabilities and configuration can be found in the dedicated [tutorial](http://psom.simexp-lab.org/psom_configuration.html).
```matlab
% Use up to four processes
opt.psom.max_queued = 4;
```
