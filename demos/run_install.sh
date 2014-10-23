#!/usr/bin/env bash

# Make this into a working system first
sudo apt-get update 

# Install dependencies
echo Installing dependencies
sudo apt-get install build-essential g++ cmake cmake-curses-gui bison flex \
 freeglut3 freeglut3-dev libxi6 libxi-dev libxmu6 libxmu-dev \
 libxmu-headers imagemagick libjpeg62 -y 

# Add the backports
check=`cat /etc/apt/sources.list | grep 'deb http://http.debian.net/debian wheezy-backports main'`
if [ -z "${check}" ]
  then
  echo Adding the Backports because they were not there yet
  sudo apt-get install python-software-properties
  sudo add-apt-repository "deb http://http.debian.net/debian wheezy-backports main"
fi
sudo apt-get update 

# Install Octave
echo Install Octave
sudo apt-get -t wheezy-backports install "octave" -y 
# Install additional dependecies
echo Install additional Octave dependencies
sudo apt-get -t wheezy-backports install "liboctave-dev" -y
sudo octave --eval "pkg install -auto -global -forge control general signal image io statistics"

# Download niak
nversion=niak-boss-0.12.17
ndir=/home/${usr}/$nversion
if [ ! -d "${ndir}" ]
then
	echo Download niak
	sudo apt-get install unzip
	wget http://www.nitrc.org/frs/download.php/7149/${nversion}.zip -P /home/${usr}
	unzip /home/${usr}/${nversion}.zip 
	rm /home/${usr}/${nversion}.zip 
fi

# Edit .octaverc
octconf=/home/${usr}/.octaverc
check=`cat ${octconf} | grep "addpath(genpath(\"${ndir}\"))";`
if [ -z "$check" ]
  then
  echo "(possibly create) and edit the .octaverc"
  touch ${octconf}
  echo \% Verbose in real time >> ${octconf}
  echo more off >> ${octconf}
  echo \% Use the same .mat files as Matlab >> ${octconf}
  echo save_default_options\(\'-7\'\)\; >> ${octconf}
  echo \% Add NIAK to the Octave path >> ${octconf}
  echo addpath\(genpath\(\"${ndir}\"\)\)\; >> ${octconf}
fi

# Download Minc Toolkit and install
mncurl=http://packages.bic.mni.mcgill.ca/minc-toolkit/Debian/
mnc=minc-toolkit-1.0.01-20131211-Debian_7.1-x86_64.deb
wget ${mncurl}${mnc} -P /home/${usr}/Downloads
sudo dpkg -i /home/${usr}/Downloads/${mnc}
check=`cat /home/${usr}/.bashrc | grep '/opt/minc/minc-toolkit-config.sh'`
if [ -z "${check}" ]
  then
  echo Adding the minc-toolkit to .bashrc
  echo source /opt/minc/minc-toolkit-config.sh >> /home/${usr}/.bashrc
fi

echo All Done. Happy Niak!
