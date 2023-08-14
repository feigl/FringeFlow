#!/bin/bash 

# Load a docker container and then start it
# 2021/07/05 Kurt Feigl
# 2021/11/29 Kurt Feigl 
# 2022/08/04 Kurt Feigl
# 2022/09/12 Kurt Feigl and Nick Bearson

if [[ (( "$#" -ne 1 ) && ( "$#" -ne 5 ) && ("$#" -ne 3)) ]]; then
    bname=`basename $0`
    echo "$bname will add ingredients to a folder and then start docker"
    echo "usage:   $bname SAT TRK SITE reference_YYYYMMDD secondary_YYYYMMDD"
    echo "example: $bname S1 144 SANEM 20190110 20190122"
    echo "example: $bname S1 144 SANEM 20190110 20190122"
    echo "example: $bname S1 144 SANEM 20190110 20190122"
    echo "example: $bname /s22/insar/FORGE/S1"
    exit -1
fi


echo "Starting script named $0"
echo PWD is ${PWD}
echo HOME is ${HOME} 

# export sat='S1'
# export site='SANEM'
# export trk=144
# export t0=20190110
# export t1=20190122
if [[ "$#" -eq 1 ]]; then
  export dirname=$1
  export runname=$dirname
else
  echo ERROR need target directory
  exit -1
fi

pushd $dirname

# make directory
echo "directory name dirname is $dirname"
mkdir -p $dirname
pushd $dirname

## copy keys here
# cp -v $HOME/.netrc . 
# cp -v $HOME/.model.cfg .
# cp -v $HOME/SSARA-master/password_config.py .
# cp -v $HOME/site_dims.txt .
cp -v $HOME/magic.tgz .

# 2021/01/10 siteinfo is no longer in repo
if [[ -d $HOME/siteinfo ]]; then
   cp -rfv $HOME/siteinfo .
else
   echo "ERROR: cannot find folder $HOME/siteinfo. Look on askja."
   exit -1
fi

# pull container from DockerHub
docker pull ghcr.io/insarlab/mintpy:latest

# get the short (base) name of the current working directory
#export MYDIR=`basename $PWD`

echo '  '
echo "Starting Docker image in container..."
echo "Once container starts, consider the following commands"
echo 'source $HOME/FringeFlow/docker/setup_inside_container_mintpy.sh'
echo 'domagic.sh magic.tgz'
# echo 'get_siteinfo.sh .'
echo '  '
echo '  '

## arrange permissions
# go directory above container
cd $dirname
if [[ $(hostname) == "askja.ssec.wisc.edu" || $(hostname) == "maule.ssec.wisc.edu" ]]; then
  #echo "unsharing"
  podman unshare chown -R 1000:1000 $runname
else
  echo "not unsharing"
fi
# go into container
cd $runname

# start interactive shell in container 
# mount FringeFlow instead of copying it
if [[ $(hostname) == "brady.geology.wisc.edu" ]]; then 
   docker run -it --rm -v "$PWD":"$PWD" -v "${HOME}/FringeFlow":/root/FringeFlow -w $PWD ghcr.io/insarlab/mintpy:latest
elif [[ $(hostname) == "porotomo.geology.wisc.edu" ]]; then 
  docker run -it --rm -v "$PWD":"$PWD" -w $PWD ghcr.io/insarlab/mintpy:latest
else 
  docker run -it --rm -v "$PWD":"$PWD" -w $PWD ghcr.io/insarlab/mintpy:latest
fi


# change permissions back again
cd ..
# https://stackoverflow.com/questions/15973184/if-statement-to-check-hostname-in-shell-script/15973255
if [[ $(hostname) == "askja.ssec.wisc.edu" ]] || [[ $(hostname) == "maule.ssec.wisc.edu" ]]; then
    echo consider following command
    echo sudo chown -R ${USER}:"'"domain users"'" $runname 
fi

#podman unshare chown -R feigl:'domain users' $PWD
