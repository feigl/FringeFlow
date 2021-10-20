#!/bin/bash 

# Load a docker container and then start it
# 2021/07/05 Kurt Feigl
# 2021/01/10 siteinfo is no longer in repo

if [[ ( "$#" -ne 1 ) ]]; then
    bname=`basename $0`
    echo "$bname will add ingredients to a folder and then start docker for GMTSAR v6"
    echo "usage:   $bname folder"
     echo "example: $bname /s22/insar/FORGE/S1"
    exit -1
fi

echo "Starting script named $0"
echo PWD is ${PWD}
echo HOME is ${HOME} 

export dirname=$1
export runname=$dirname

echo "directory name dirname is $dirname"
mkdir -p $dirname
cd $dirname
#runname=`basename $dirname`

# if [ -d $runname ]; then
#     rm -rf $runname
# fi
echo runname is $runname
mkdir -p $runname
cd $runname

# get important files
cp $HOME/PAIRSmake.txt .
cp /opt/gmtsar/6.0/share/gmtsar/csh/config.tsx.txt .

# 2021/01/10 siteinfo is no longer in repo
if [[ -d $HOME/siteinfo ]]; then
   cp -rfv $HOME/siteinfo .
else
   echo "ERROR: cannot find folder $HOME/siteinfo. Look on askja."
   exit -1
fi

# pull container from DockerHub
#docker pull docker.io/nbearson/isce_chtc2
docker pull docker.io/nbearson/gmtsar

# get the short (base) name of the current working directory
#export MYDIR=`basename $PWD`


## arrange permissions
# go directory above container
cd $dirname
#if [[ (( "$HOST" -eq "askja.ssec.wisc.edu") || ( "$HOST" -eq "maule.ssec.wisc.edu")) ]]; then
if [[ (( "$HOST" == "askja.ssec.wisc.edu") || ( "$HOST" == "maule.ssec.wisc.edu")) ]]; then
  podman unshare chown -R 1000:1000 $runname
fi
# go into container
cd $runname


echo "Once container starts, try: "
echo "source /root/FringeFlow/docker/setup_inside_container_gmtsar.sh"
echo "Starting container...."

# run script in container
#docker run --name $runname -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/.." -w $PWD nbearson/isce_mintpy ./bin/run_pair.sh 20190110  20190122

# start interactive shell in container 
#docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/.." -v "$PWD/../..":"$PWD/../.."  -w $PWD nbearson/isce_mintpy 
#docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/../ISCE":"$PWD/../ISCE" -w $PWD nbearson/isce_mintpy 
#docker run -it --rm -v "$PWD":"$PWD" -w $PWD nbearson/isce_mintpy:latest 
#docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/../" -w $PWD isce/isce2:latest
#docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/../" -w $PWD benjym/insar  # does not include icse
#docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/../" -w $PWD docker.io/nbearson/isce_chtc2
#docker run -it --rm -v "$PWD":"$PWD" -v "${HOME}/FringeFlow":/root/FringeFlow -w $PWD docker.io/nbearson/isce_chtc2
docker run -it --rm -v "$PWD":"$PWD" \
-v ${HOME}/FringeFlow:/root/FringeFlow \
-v /home/batzli/bin_htcondor:/root/bin_htcondor \
-v /s12/insar:/root/insar \
-w $PWD docker.io/nbearson/gmtsar

# change permissions back again
cd ..

# https://stackoverflow.com/questions/15973184/if-statement-to-check-hostname-in-shell-script/15973255
if [[ $(hostname) = "askja.ssec.wisc.edu" ]] || [[ $(hostname) = "maule.ssec.wisc.edu" ]]; then
    sudo chown -R ${USER}:'domain users' $runname 
fi

