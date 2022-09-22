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

# pull scripts and make a tar file
if [[ $(hostname) == "brady.geology.wisc.edu" ]]; then 
  echo NOT tarring FringeFlow
else
  if [[ -d $HOME/FringeFlow ]]; then
    pushd $HOME/FringeFlow
    git pull 
    popd 

    pushd $HOME
    tar --exclude FringeFlow/.git -cvzf $HOME/FringeFlow.tgz FringeFlow
    popd
  else
    echo Could not find $HOME/FringeFlow 
    exit -1
  fi
fi

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

# copy code
if [[ $(hostname) == "brady.geology.wisc.edu" ]]; then 
  echo NOT copying FringeFlow
else
  echo Copying $HOME/FringeFlow.tgz to $PWD
  \cp -rfv $HOME/FringeFlow.tgz .
fi

# copy aux files
if [[ -f $HOME/aux.tgz ]]; then
   \cp -rfv $HOME/aux.tgz .
else
   echo error could not find $HOME/aux.tgz 
   echo see https://github.com/isce-framework/isce2/blob/main/contrib/stack/topsStack/README.md
   echo consider wget https://qc.sentinel1.groupcls.com/product/S1A/AUX_CAL/2014/09/08/S1A_AUX_CAL_V20140908T000000_G20190626T100201.SAFE.TGZ
fi

# 2021/01/10 siteinfo is no longer in repo
if [[ -f $HOME/siteinfo.tgz ]]; then
   #cp -rfv $HOME/siteinfo .
   # 2022/01/24 copy into run folder
   echo Copying $HOME/siteinfo.tgz to $PWD
   cp -rf $HOME/siteinfo.tgz $PWD
   #tar -xzvf siteinfo.tgz
else
   echo "ERROR: cannot find folder $HOME/siteinfo. Look on askja."
   exit -1
fi

# pull container from DockerHub
#docker pull docker.io/nbearson/isce_chtc2
#docker pull docker.io/nbearson/isce_mintpy:20211110
#docker pull docker.io/nbearson/isce_mintpy:20211110
#docker pull docker.io/nbearson/isce_chtc:20220204
#docker pull docker.io/nbearson/isce_chtc:latest

# get the short (base) name of the current working directory
#export MYDIR=`basename $PWD`

echo '  '
echo "Starting Docker image in container..."
echo "Once container starts, consider the following commands"
if [[ $(hostname) == "brady.geology.wisc.edu" ]]; then 
   echo Using personal FringeFlow
else
    echo 'tar -C $HOME -xzf FringeFlow.tgz '
fi
echo 'tar -C $HOME -xzf siteinfo.tgz '
echo 'source $HOME/FringeFlow/docker/setup_inside_container_maise.sh'
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
# inherit ssh keys with proper permissions
#https://nickjanetakis.com/blog/docker-tip-56-volume-mounting-ssh-keys-into-a-docker-container
#docker run --rm -it -v ~/.ssh:/root/.ssh:ro
#docker run -it --rm -v "$PWD":"$PWD" -v "${HOME}/FringeFlow":/root/FringeFlow -v "${HOME}/.ssh":"/home/ops/.ssh:ro" -w $PWD docker.io/nbearson/isce_chtc2
#docker run -it --rm -v "$PWD":"$PWD" -w $PWD docker.io/nbearson/isce_mintpy:20211110
#docker run -it --rm -v "$PWD":"$PWD" -w $PWD docker.io/nbearson/isce_mintpy:latest
# mount FringeFlow instead of copying it
if [[ $(hostname) == "brady.geology.wisc.edu" ]]; then 
   #docker run -it --rm -v "$PWD":"$PWD" -v "${HOME}/FringeFlow":/home/ops/FringeFlow -w $PWD docker.io/nbearson/isce_chtc:20220204 
   #docker run -it --rm -v "$PWD":"$PWD" -v "${HOME}/FringeFlow":/root/FringeFlow -w $PWD docker.io/nbearson/maise:20220915
   docker run -it --rm -v "$PWD":"$PWD" -v "${HOME}/FringeFlow":/root/FringeFlow -w $PWD docker.io/nbearson/maise:20220919
elif [[ $(hostname) == "porotomo.geology.wisc.edu" ]]; then 
   #https://github.com/containers/podman/blob/main/troubleshooting.md#34-passed-in-devices-or-files-cant-be-accessed-in-rootless-container-uidgid-mapping-problem
  #uid=`id -u`
  #gid=`id -g`
  #--uidmap "$uid":1000 --gidmap "$gid":1000 
  # above does not work
  #docker run -it --rm -v "$PWD":"$PWD" --user 1000:1000 -w $PWD docker.io/nbearson/isce_chtc:20220204 
  docker run -it --rm -v "$PWD":"$PWD" --user 1000:1000 -w $PWD docker.io/nbearson/maise:20220919
else 
  #docker run -it --rm -v "$PWD":"$PWD" -w $PWD docker.io/nbearson/isce_chtc:20220204
  docker run -it --rm -v "$PWD":"$PWD" -w $PWD docker.io/nbearson/maise:20220919
fi


# change permissions back again
cd ..
# https://stackoverflow.com/questions/15973184/if-statement-to-check-hostname-in-shell-script/15973255
if [[ $(hostname) == "askja.ssec.wisc.edu" ]] || [[ $(hostname) == "maule.ssec.wisc.edu" ]]; then
    echo consider following command
    echo sudo chown -R ${USER}:"'"domain users"'" $runname 
fi

#podman unshare chown -R feigl:'domain users' $PWD
