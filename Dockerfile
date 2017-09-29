FROM simexp/octave:4.2.1_cross_u16
MAINTAINER Pierre-Olivier Quirion <poq@criugm.qc.ca>

ENV PSOM_VERSION 2.3.1
ENV NIAK_ROOT /home/poquirion/simexp/niak
ENV NIAK_CONFIG_PATH /local_config
ENV NIAK_SANDBOX_ROOT /sandbox
ENV NIAK_SANDBOX ${NIAK_SANDBOX_ROOT}/home
ENV HOME ${NIAK_SANDBOX}
ENV TERM xterm-256color

# Install NIAK  

#RUN mkdir ${NIAK_ROOT}
#ADD bricks/ ${NIAK_ROOT}/bricks/
#ADD commands/ ${NIAK_ROOT}/commands/
#ADD demos/ ${NIAK_ROOT}/demos/
#ADD reports/ ${NIAK_ROOT}/reports/
#ADD pipeline/ ${NIAK_ROOT}/pipeline/
#ADD template/ ${NIAK_ROOT}/template/
#ADD extensions/ ${NIAK_ROOT}/extensions/
#WORKDIR  ${NIAK_ROOT}/extensions
#RUN wget https://sites.google.com/site/bctnet/Home/functions/BCT.zip \
#    && unzip BCT.zip \
#    && rm BCT.zip \
#    && wget https://github.com/SIMEXP/psom/archive/v${PSOM_VERSION}.zip \
#    && unzip v${PSOM_VERSION}.zip \
#    && rm v${PSOM_VERSION}.zip \
#    && cd /usr/local/bin \
WORKDIR /usr/local/bin
RUN     ln -s /home/poquirion/simexp/psom/psom_worker.py psom_worker.py \
    && ln -s /home/poquirion/simexp/psom/container/psom_image_exec_redirection.sh psom_image_exec_redirection.sh \
    && ln -s /home/poquirion/simexp/niak/util/bin/niak_cmd.py niak_cmd.py \
    && mkdir /scratch
# Build octave configure file
RUN mkdir ${NIAK_CONFIG_PATH} && chmod 777 ${NIAK_CONFIG_PATH} \
    && echo addpath\(genpath\(\'/home/poquirion/simexp/niak\'\)\)\; >> /etc/octave.conf \
    && echo addpath\(genpath\(\'/home/poquirion/simexp/psom\'\)\)\; >> /etc/octave.conf \
    && echo addpath\(genpath\(\'/home/poquirion/simexp/BCT\'\)\)\; >> /etc/octave.conf

# niak will run here
RUN mkdir -p ${NIAK_SANDBOX} && chmod -R 777 ${NIAK_SANDBOX_ROOT}
WORKDIR ${NIAK_SANDBOX}


# To run with jupyter
# docker run -it --rm  -v /niak_sandbox:$PWD --user $UID -p 8080:6666 simexp/niak-cog niak_jupyter


# Command to run octave as GUI
# docker run -it --privileged --rm -v /etc/group:/etc/group -v /etc/passwd:/etc/passwd   -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY -v $HOME:$HOME --user $UID simexp/niak-boss /bin/bash -lic "cd $HOME/software; octave --force-gui ; /bin/bash"

# Bids app setup
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py
RUN pip install pyyaml
ENV PYTHONPATH=/home/poquirion/simexp/niak/util
RUN ln -s $NIAK_ROOT /code
ENV TMPDIR=/outputs/tmp

ENV NIAK_CONFIG_PATH /outputs/tmp/local_config
RUN mkdir /oasis /projects  /local-scratch
WORKDIR /outputs
ENTRYPOINT ["/code/util/bin/bids_app.py"]
CMD ["--help"]
ADD util/  ${NIAK_ROOT}/util/
