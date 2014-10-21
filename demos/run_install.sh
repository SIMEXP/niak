#!/usr/bin/env bash

# Make this into a working system first
apt-get update > /dev/null
apt-get install sudo vim git -y > /dev/null
# Only works if there is just one user
usr=`ls /home`
adduser ${usr} sudo > /dev/null
mkdir -p /home/${usr}/Downloads

# Install dependencies
echo Installing dependencies
apt-get install build-essential g++ cmake cmake-curses-gui bison flex \
 freeglut3 freeglut3-dev libxi6 libxi-dev libxmu6 libxmu-dev \
 libxmu-headers imagemagick libjpeg62 -y > /dev/null

# Add the backports
check=`cat /etc/apt/sources.list | grep 'deb http://http.debian.net/debian wheezy-backports main'`
if [ -z "${check}" ]
  then
  echo Adding the Backports because they were not there yet
  echo deb http://http.debian.net/debian wheezy-backports main >> /etc/apt/sources.list
fi
apt-get update > /dev/null

# Install Octave
echo Install Octave
apt-get -t wheezy-backports install "octave" -y > /dev/null
# Install additional dependecies
echo Install additional Octave dependencies
apt-get -t wheezy-backports install "liboctave-dev" -y > /dev/null
octave --silent --eval "pkg install -auto -global -forge control general signal image io statistics"

# Download niak
ndir=/home/${usr}/niak
nversion=v0.12.17.tar.gz
if [ ! -d "${ndir}" ]
then
	echo Download niak
	mkdir -pv ${ndir}
	wget -q https://github.com/SIMEXP/niak/archive/${nversion} -P /home/${usr}/Downloads
	# Unpack niak
	tar -xzf /home/${usr}/Downloads/${nversion} -C ${ndir}
	nname=`ls /home/${usr}/niak`
	mv ${ndir}/${nname}/* ${ndir}
	rm -rf ${ndir}/${nname}
fi

# Download psom
pdir=/home/${usr}/psom
pversion=v1.0.2.tar.gz
if [ ! -d "${pdir}" ]; then
	echo Download psom
	# Add Psom directory
	mkdir -pv ${pdir}
	wget -q https://github.com/SIMEXP/psom/archive/${pversion} -P /home/${usr}/Downloads
	# Unpack psom
	tar -xzf /home/${usr}/Downloads/${pversion} -C ${pdir}
	pname=`ls /home/${usr}/psom`
	mv ${pdir}/${pname}/* ${pdir}
	rm -rf ${pdir}/${pname}
fi

# Edit .octaverc
ocpath=/home/${usr}/.octaverc
if [ ! -e "${ocpath}" ]
  then
  echo Create and edit the .octaverc
  touch ${ocpath}
  echo \% Verbose in real time >> ${ocpath}
  echo more off >> ${ocpath}
  echo \% Use the same .mat files as Matlab >> ${ocpath}
  echo save_default_options\(\'-7\'\)\; >> ${ocpath}
  echo addpath\(genpath\(\'/home/${usr}/niak\'\)\)\; >> ${ocpath}
  echo addpath\(genpath\(\'/home/${usr}/psom\'\)\)\; >> ${ocpath}
  echo \% Verbose in real time >> ${ocpath}
  echo \% Use the same .mat files as Matlab >> ${ocpath}
fi

# Download Minc Toolkit and install
mncurl=http://packages.bic.mni.mcgill.ca/minc-toolkit/Debian/
mnc=minc-toolkit-1.0.01-20131211-Debian_7.1-x86_64.deb
wget -q ${mncurl}${mnc} -P /home/${usr}/Downloads
dpkg -i /home/${usr}/Downloads/${mnc}
check=`cat /home/${usr}/.bashrc | grep '/opt/minc/minc-toolkit-config.sh'`
if [ -z "${check}" ]
  then
  echo Adding the Backports because they were not there yet
  echo source /opt/minc/minc-toolkit-config.sh >> /home/${usr}/.bashrc
fi

chown -R ${usr}:${usr} /home/${usr}/

echo All Done. Happy Niak!
