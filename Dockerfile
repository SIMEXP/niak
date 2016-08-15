FROM simexp/octave:4.0.0
MAINTAINER Pierre-Olivier Quirion <poq@criugm.qc.ca>

#ENV NIAK_VERSION dev-0.14.0
#ENV NIAK_RELEASE_NAME niak-with-dependencies

# Install NIAK from the tip of master
RUN apt-get install git -y --fix-missing


RUN cd /home \
   && git clone -b "bids-app" --depth 1 https://github.com/SIMEXP/niak.git


RUN cd /home/niak/extensions/ \
   && wget https://sites.google.com/site/bctnet/Home/functions/BCT.zip  \
   && unzip BCT.zip \
   && rm BCT.zip

RUN cd /home/niak/extensions/ \
   && git clone -b cbrain_integration --depth 1 https://github.com/SIMEXP/psom.git

# Build octave configure file
RUN echo addpath\(genpath\(\"/home/niak/\"\)\)\; >> /etc/octave.conf

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
COPY niak_cmd.py /code/run.py

ENTRYPOINT ["/code/run.py"]


# Command to run octave as GUI
# docker run -i -t --privileged --rm -v /etc/group:/etc/group -v /etc/passwd:/etc/passwd   -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY -v $HOME:$HOME --user $UID poquirion/docker_build /bin/bash --login -c "cd $HOME/travail/simexp/software; octave --force-gui --persist --eval 'addpath(genpath(pwd))'; /bin/bash"
