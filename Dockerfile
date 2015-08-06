FROM simexp/octave:3.8.1
MAINTAINER Pierre-Olivier Quirion <poq@criugm.qc.ca>


ENV NIAK_VERSION v0.13.0
ENV NIAK_RELEASE_NAME niak-with-dependencies

# Install NIAK from the time of master
RUN cd /home/niak \
	&& wget https://github.com/SIMEXP/niak/releases/download/${NIAK_VERSION}/${NIAK_RELEASE_NAME}.zip niak.zip \
	&& unzip niak.zip \
	&& rm niak.zip 


# Build octave configure file
RUN echo addpath\(genpath\(\"/home/niak/\"\)\)\; >> /etc/octave.conf

# Source minc tools
RUN echo "source /opt/minc-itk4/minc-toolkit-config.sh" >> /etc/profile

# 3D visualisation tools
RUN apt-get install mricron -y \
     libcanberra-gtk-module

# Command to run octave as GUI
# docker run -i -t --privileged --rm -v /etc/group:/etc/group -v /etc/passwd:/etc/passwd   -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY -v $HOME:$HOME --user $UID poquirion/docker_build /bin/bash --login -c "cd $HOME/travail/simexp/software; octave --force-gui --persist --eval 'addpath(genpath(pwd))'; /bin/bash"
