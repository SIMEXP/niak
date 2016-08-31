FROM simexp/octave:4.0.2_ubuntu12
MAINTAINER Pierre-Olivier Quirion <poq@criugm.qc.ca>


<<<<<<< HEAD
ENV NIAK_VERSION v0.13.5
=======
ENV NIAK_VERSION v0.16.0
>>>>>>> _TMP_RELEASE_BRANCH_
ENV NIAK_RELEASE_NAME niak-with-dependencies

# Install NIAK from the tip of master
RUN mkdir /home/niak \ 
   && cd /home/niak \
   && wget https://github.com/SIMEXP/niak/releases/download/${NIAK_VERSION}/${NIAK_RELEASE_NAME}.zip \
   && unzip ${NIAK_RELEASE_NAME}.zip \
   && rm ${NIAK_RELEASE_NAME}.zip 


# Build octave configure file
RUN echo addpath\(genpath\(\"/home/niak/\"\)\)\; >> /etc/octave.conf


# 3D visualisation tools
RUN apt-get install mricron -y \
     libcanberra-gtk-module

# Command to run octave as GUI
# docker run -i -t --privileged --rm -v /etc/group:/etc/group -v /etc/passwd:/etc/passwd   -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY -v $HOME:$HOME --user $UID poquirion/docker_build /bin/bash --login -c "cd $HOME/travail/simexp/software; octave --force-gui --persist --eval 'addpath(genpath(pwd))'; /bin/bash"
