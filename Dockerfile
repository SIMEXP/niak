FROM simexp/octave:3.8.1
MAINTAINER Pierre-Olivier Quirion <poq@criugm.qc.ca>

# Install NIAK from the time of master
RUN cd /home/ \
	&& wget https://github.com/SIMEXP/niak/archive/v0.13.0.zip niak.zip\
	&& unzip niak.zip \
	&& rm niak.zip 

# Install PSOM
RUN cd /home/niak/extensions && wget http://www.nitrc.org/frs/download.php/7065/psom-1.0.2.zip && unzip psom-1.0.2.zip && rm psom-1.0.2.zip

# Install BCT
RUN cd /home/niak/extensions && wget https://sites.google.com/site/bctnet/Home/functions/BCT.zip && unzip BCT.zip && rm BCT.zip

# Build octave configure file
RUN echo addpath\(genpath\(\"/home/niak/\"\)\)\; >> /etc/octave.conf

# 3D visualisation tools
RUN apt-get install mricron -y \
     libcanberra-gtk-module

# Command to run octave as GUI
# docker run -i -t --privileged --rm -v /etc/group:/etc/group -v /etc/passwd:/etc/passwd   -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY -v $HOME:$HOME --user $UID poquirion/docker_build /bin/bash -c "cd $HOME/travail/simexp/software; source /opt/minc-itk4/minc-toolkit-config.sh; octave --force-gui --persist --eval 'addpath(genpath(pwd))'; /bin/bash"
