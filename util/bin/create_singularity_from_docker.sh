#!/usr/bin/env bash

# This script takes an *EXISTING* docker image and create a singularity container with it
# the image has the env vars present in the docker container are put in /docker_environment
# It also has a couple of directory that will be mount at crunch time: 
#                   Guillimin : /gs, /localscratch, /sf1
#                   Briaree   : /alloc, /RQusagers, /RQexec, /lscratch
#                   CRIUGM    : /data /mnt/ data_k6  data_k7  data_kr  data_pr  data_sq  data_t8   home_ex  home_je  home_sq
#                   scinet    : /sgfs1

usage (){

echo 
echo "usage: $0 <docker_image> [singularity_image]"
echo 
echo "   -p        Pull the docker image before creating"
echo "               the singularity image"  
echo "   -s        Size of the image default in Mo"
 
}

pull_docker_image (){

docker pull $D_IMAGE
}


img_size=2000

while getopts "ps:" opt; do
  case $opt in
    p)
      pull_docker=1
      ;;
    s)
      img_size=$OPTARG  
      ;;
   \?)
      usage
      exit 1
      ;;
  esac
done


shift $(expr $OPTIND - 1 )
if [[ $# < 1 || $# > 2 ]] ; then

  usage
  exit 1
fi 

#  Docker image
D_IMAGE=$1
# singularity image
S_IMAGE=$(echo ${2:-$D_IMAGE} | tr "/:"  "_-")
#Make sure there is only one trailing .img
S_IMAGE=${S_IMAGE%.img}.img
TMPDIR=/tmp


# size in MB
rm -f $S_IMAGE
sudo singularity create -s $img_size $S_IMAGE

CONTAINER_ID=$(docker create $D_IMAGE)

docker export $CONTAINER_ID | sudo singularity import $S_IMAGE

#singularity import ${S_IMAGE} docker://${D_IMAGE}

# TODO add created dir that as options -d
sudo singularity shell -w $S_IMAGE -c "mkdir -p /scratch /data /localscratch /gs /alloc /RQusagers /RQexec /lscratch /sgfs1 /mnt/data_k6  /mnt/data_k7  /mnt/data_kr  /mnt/data_pr  /mnt/data_sq  /mnt/data_t8   /mnt/home_ex  /mnt/home_je  /mnt/home_sq"

# export env vars
docker run --rm --entrypoint="/usr/bin/env" $D_IMAGE > $TMPDIR/docker_environment
# don't include HOME and HOSTNAME - they mess with local config
sed -i '/^HOME/d' $TMPDIR/docker_environment
sed -i '/^HOSTNAME/d' $TMPDIR/docker_environment
sed -i 's/^/export /' $TMPDIR/docker_environment
#sudo singularity shell -B /home --pwd $PWD -w $S_IMAGE -c "cp -r singularity.d /.singularity.d "
sudo singularity shell -B /mnt  -B /home -w --pwd $PWD $S_IMAGE -c "cp -r singularity.d /.singularity.d && cat $TMPDIR/docker_environment >> /.singularity.d/env/10-docker.sh && cd /  && ln -s /.singularity.d/action/shell ./shell && ln -s /.singularity.d/action/exec .exec && ln -s /.singularity.d/action/run .run  && ln -s  /.singularity.d/action/test .test"
rm -rf $TMPDIR/docker_environment

# Force bash to be defaulT
#sudo singularity shell --writable --contain $S_IMAGE -c "cd /bin; rm sh; ln -s bash sh  "
sudo chown $USER ${S_IMAGE}
sudo chgrp $USER ${S_IMAGE}
sudo chmod 644 ${S_IMAGE}

function finish {
docker rm $CONTAINER_ID > /dev/null 2>&1
}
trap finish EXIT
