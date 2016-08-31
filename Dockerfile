FROM simexp/octave:4.0.2_ubuntu_12
MAINTAINER Pierre-Olivier Quirion <poq@criugm.qc.ca>


ENV NIAK_VERSION v0.16.0
ENV NIAK_RELEASE_NAME niak-with-dependencies
ENV PSOM_VERSION v2.0.2

# Install NIAK from the tip of master
RUN mkdir /home/niak \ 
   && cd /home/niak \
   && wget https://github.com/SIMEXP/niak/releases/download/${NIAK_VERSION}/${NIAK_RELEASE_NAME}.zip \
   && unzip ${NIAK_RELEASE_NAME}.zip \
   && rm ${NIAK_RELEASE_NAME}.zip 

# niak dependency ship with psom, but one may want buit the image with a newer version
WORKDIR /home/niak/extensions
RUN rm -rf psom* && wget https://github.com/SIMEXP/psom/archive/${PSOM_VERSION}.zip \ 
    && unzip ${PSOM_VERSION}.zip \
    && rm ${PSOM_VERSION}.zip



# Build octave configure file
RUN echo addpath\(genpath\(\"/home/niak/\"\)\)\; >> /etc/octave.conf


# 3D visualisation tools
RUN apt-get install mricron -y \
     libcanberra-gtk-module

# Command to run octave as GUI
# docker run -i -t --privileged --rm -v /etc/group:/etc/group -v /etc/passwd:/etc/passwd   -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY -v $HOME:$HOME --user $UID poquirion/docker_build /bin/bash --login -c "cd $HOME/travail/simexp/software; octave --force-gui --persist --eval 'addpath(genpath(pwd))'; /bin/bash"
