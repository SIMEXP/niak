FROM simexp/octave:4.0.2_ubuntu_12
MAINTAINER Pierre-Olivier Quirion <poq@criugm.qc.ca>

ENV PSOM_VERSION 2.3.1

# Install NIAK  

RUN mkdir /usr/local/niak
ADD bricks/ /usr/local/niak/bricks/
ADD commands/ /usr/local/niak/commands/
ADD demos/ /usr/local/niak/demos/
ADD util/  /usr/local/niak/util/
ADD reports/ /usr/local/niak/reports/
ADD pipeline/ /usr/local/niak/pipeline/
ADD template/ /usr/local/niak/template/
ADD extensions/ /usr/local/niak/extensions/
WORKDIR  /usr/local/niak/extensions
RUN wget https://sites.google.com/site/bctnet/Home/functions/BCT.zip \
    && unzip BCT.zip \
    && rm BCT.zip \
    && wget https://github.com/SIMEXP/psom/archive/v${PSOM_VERSION}.zip \ 
    && unzip v${PSOM_VERSION}.zip \
    && rm v${PSOM_VERSION}.zip \
    && cd /usr/local/bin \
    && ln -s ../niak/extensions/psom-${PSOM_VERSION}/psom_worker.py psom_worker.py \
    && ln -s ../niak/util/bin/niak_cmd.py niak_cmd.py

# Build octave configure file
RUN mkdir /local_config && chmod 777 /local_config \
    && echo addpath\(genpath\(\"/usr/local/niak/\"\)\)\; >> /etc/octave.conf \
    && echo addpath\(genpath\(\"/local_config/\"\)\)\; >> /etc/octave.conf


# 3D visualisation tools
RUN apt-get install mricron -y \
     libcanberra-gtk-module

# Command to run octave as GUI
# docker run -it --privileged --rm -v /etc/group:/etc/group -v /etc/passwd:/etc/passwd   -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY -v $HOME:$HOME --user $UID simexp/niak-boss /bin/bash -lic "cd $HOME/software; octave --force-gui ; /bin/bash"
