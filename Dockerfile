FROM simexp/octave:4.0.0
MAINTAINER Pierre-Olivier Quirion <poq@criugm.qc.ca>

#ENV NIAK_VERSION dev-0.14.0
#ENV NIAK_RELEASE_NAME niak-with-dependencies

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

# Source minc tools
RUN echo "source /opt/minc-itk4/minc-toolkit-config.sh" >> /etc/profile \
    && echo "source /opt/minc-itk4/minc-toolkit-config.sh" >> /etc/bash.bashrc

# 3D visualisation tools
RUN apt-get install mricron -y \
     libcanberra-gtk-module

RUN mkdir /oasis
RUN mkdir /projects
RUN mkdir /scratch
RUN mkdir /local-scratch
ADD niak_cmd.py /code/run.py
ADD pyniak /code/pyniak
ADD psom_gb_vars_local.m /code/niak/psom_gb_vars_local.m

ENTRYPOINT ["/code/run.py"]

RUN echo addpath\(genpath\(\"/code/niak/\"\)\)\; >> /etc/octave.conf
