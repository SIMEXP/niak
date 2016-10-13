FROM simexp/octave:4.0.2_ubuntu_12
MAINTAINER Pierre-Olivier Quirion <poq@criugm.qc.ca>


# Install NIAK from the tip of master
RUN apt-get install git -y --fix-missing


RUN mkdir /code  && cd /code \
   && git clone -b "bids-app" --depth 1 https://github.com/SIMEXP/niak.git


RUN cd /code/niak/extensions/ \
   && wget https://sites.google.com/site/bctnet/Home/functions/BCT.zip  \
   && unzip BCT.zip \
   && rm BCT.zip

RUN cd /code/niak/extensions/ \
   && git clone  --depth 1 https://github.com/SIMEXP/psom.git && cd /usr/local/bin \
   && ln -s  /code/niak/extensions/psom/psom_worker.py psom_worker.py && chmod 755 /code/niak/extensions/psom/psom_worker.py

# Build octave configure file

# Set minc tools

ENV MINC_TOOLKIT_VERSION="1.9.2-20140730"
ENV PATH=/opt/minc-itk4/bin:/opt/minc-itk4/pipeline:${PATH}
ENV PERL5LIB=/opt/minc-itk4/perl:/opt/minc-itk4/pipeline:${PERL5LIB}
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/minc-itk4/lib:/opt/minc-itk4/lib/InsightToolkit
ENV MNI_DATAPATH=/opt/minc-itk4/share
ENV MINC_FORCE_V2=1
ENV MINC_COMPRESS=4
ENV VOLUME_CACHE_THRESHOLD=-1
ENV TMPDIR=/outputs/tmp

# 3D visualisation tools
RUN apt-get install mricron -y \
     libcanberra-gtk-module \
     rsync

RUN mkdir /oasis
RUN mkdir /projects
RUN mkdir /scratch
RUN mkdir /local-scratch
ADD default_config.yaml /code/
ADD niak_cmd.py /code/run.py
ADD pyniak /code/pyniak
ADD pyyaml /code/
ADD psom_gb_vars_local.m /code/niak/psom_gb_vars_local.m
WORKDIR /outputs
ENTRYPOINT ["/code/run.py"]

RUN echo addpath\(genpath\(\"/code/niak/\"\)\)\; >> /etc/octave.conf
