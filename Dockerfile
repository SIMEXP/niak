FROM simexp/octave:4.0.2_ubuntu_12
MAINTAINER Pierre-Olivier Quirion <poq@criugm.qc.ca>

ENV PSOM_VERSION 2.1.0
ENV NIAK_ROOT /usr/local/niak

# Install NIAK  

RUN mkdir ${NIAK_ROOT}
ADD bricks/ ${NIAK_ROOT}/bricks/
ADD commands/ ${NIAK_ROOT}/commands/
ADD demos/ ${NIAK_ROOT}/demos/
ADD util/  ${NIAK_ROOT}/util/
ADD reports/ ${NIAK_ROOT}/reports/
ADD pipeline/ ${NIAK_ROOT}/pipeline/
ADD template/ ${NIAK_ROOT}/template/
ADD extensions/ ${NIAK_ROOT}/extensions/
WORKDIR  ${NIAK_ROOT}/extensions
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
# "
# niak will run here
RUN mkdir -p /niak_sandbox
WORKDIR /niak_sandbox

# jupyter install
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py
RUN pip install notebook
# octave_kernel install
RUN pip install octave_kernel
RUN python -m octave_kernel.install
RUN pip install ipywidgets
ADD util/bin/niak_jupyter /usr/local/bin/niak_jupyter
ADD util/lib/psom_gb_vars_local.jupyter /usr/local/lib/psom_gb_vars_local.jupyter
RUN chmod 777 /usr/local/bin/niak_jupyter
EXPOSE 80 



# 3D visualisation tools
RUN apt-get install mricron -y \
     libcanberra-gtk-module

# Command to run octave as GUI
# docker run -it --privileged --rm -v /etc/group:/etc/group -v /etc/passwd:/etc/passwd   -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY -v $HOME:$HOME --user $UID simexp/niak-boss /bin/bash -lic "cd $HOME/software; octave --force-gui ; /bin/bash"
