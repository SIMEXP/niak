FROM simexp/octave:4.0.2_ubuntu_12
MAINTAINER Pierre-Olivier Quirion <poq@criugm.qc.ca>


ENV PSOM_VERSION v2.0.2

# Install NIAK  

RUN mkdir /usr/local/niak
ADD bricks commands demos util reports pipeline template extensions /usr/local/niak/
WORKDIR  /usr/local/niak/extensions
RUN wget https://sites.google.com/site/bctnet/Home/functions/BCT.zip \
    && unzip BCT.zip \
    && rm BCT.zip \
    && wget https://github.com/SIMEXP/psom/archive/${PSOM_VERSION}.zip \ 
    && unzip ${PSOM_VERSION}.zip \
    && rm ${PSOM_VERSION}.zip \
    && cd /usr/local/bin \
    && ln -s ../niak/extention/psom_worker.py psom_worker.py \
    && ln -s ../niak/util/bin/niak_cmd.py niak_cmd.py



# Build octave configure file
RUN echo addpath\(genpath\(\"/usr/local/niak/\"\)\)\; >> /etc/octave.conf


# 3D visualisation tools
RUN apt-get install mricron -y \
     libcanberra-gtk-module

# Command to run octave as GUI
# docker run -it --privileged --rm -v /etc/group:/etc/group -v /etc/passwd:/etc/passwd   -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY -v $HOME:$HOME --user $UID simexp/niak-boss /bin/bash -lic "cd $HOME/software; octave --force-gui ; /bin/bash"
