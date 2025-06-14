#!/bin/bash 

# Load a docker container and then start it
# 2021/07/05 Kurt Feigl
# 2021/11/29 Kurt Feigl 
# 2022/08/04 Kurt Feigl
# 2022/09/12 Kurt Feigl and Nick Bearson
# 2023/09/10 Kurt Feigl - when on askja, do not mount
# 2024/08/09

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
elif [[ $(hostname) == "askja.ssec.wisc.edu" ]]; then 
  echo NOT tarring FringeFlow
else
  if [[ -d $HOME/FringeFlow ]]; then
    pushd $HOME/FringeFlow
    git pull 
    popd 

    pushd $HOME
    tar --exclude FringeFlow/.git -czf $HOME/FringeFlow.tgz FringeFlow
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

# # copy aux files
# if [[ -f $HOME/aux.tgz ]]; then
#    \cp -rfv $HOME/aux.tgz .
# else
#    echo error could not find $HOME/aux.tgz 
#    echo see https://github.com/isce-framework/isce2/blob/main/contrib/stack/topsStack/README.md
#    echo consider wget https://qc.sentinel1.groupcls.com/product/S1A/AUX_CAL/2014/09/08/S1A_AUX_CAL_V20140908T000000_G20190626T100201.SAFE.TGZ
# fi

# 2021/01/10 siteinfo is no longer in repo
if [[ -d $HOME/siteinfo ]]; then
   #tar -C $HOME -czvf siteinfo.tgz siteinfo
   # exclude extra attributes on mac https://stackoverflow.com/questions/51655657/tar-ignoring-unknown-extended-header-keyword-libarchive-xattr-security-selinux
   tar -C $HOME --no-xattrs --exclude=".*" -czf siteinfo.tgz siteinfo
   # 2022/01/24 copy into run folder
   echo Copying $HOME/siteinfo.tgz to $PWD
   cp -rf $HOME/siteinfo.tgz $PWD
elif [[ -f $HOME/siteinfo.tgz ]]; then
   #cp -rfv $HOME/siteinfo .
   # 2022/01/24 copy into run folder
   echo Copying $HOME/siteinfo.tgz to $PWD
   cp -rf $HOME/siteinfo.tgz $PWD
   #tar -xzvf siteinfo.tgz
else
   echo "ERROR: cannot find folder $HOME/siteinfo. Look on askja."
   exit -1
fi

dockertag="docker.io/isce/isce2:latest"

# pull container from DockerHub
docker pull $dockertag

echo '  '
echo "Starting Docker image in container..."
echo "Once container starts, consider the following commands"
if [[ $(hostname) == "brady.geology.wisc.edu" ]]; then 
   echo Using personal FringeFlow
# elif [[ $(hostname) == "askja.ssec.wisc.edu" ]]; then 
#    echo Using personal FringeFlow
else
   echo 'tar -C $HOME -xzf FringeFlow.tgz '
fi
echo 'tar -C $HOME -xzf siteinfo.tgz '
echo 'source $HOME/FringeFlow/docker/setup_inside_container_isce.sh'
echo 'domagic.sh magic.tgz'
# echo 'get_siteinfo.sh .'
echo '  '
echo '  '

## arrange permissions
# go directory above container
cd $dirname
if [[ $(hostname) == "askja.ssec.wisc.edu" || $(hostname) == "maule.ssec.wisc.edu" ]]; then
  echo "unsharing"
  podman unshare chown -R 1000:1000 $runname
else
  echo "not unsharing"
fi

# go into container
cd $runname

# run script in container
#docker run --name $runname -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/.." -w $PWD nbearson/isce_mintpy ./bin/run_pair.sh 20190110  20190122


if [[ $(hostname) == "brady.geology.wisc.edu" ]]; then
    # mount FringeFlow instead of copying it 
    docker run -it --rm -v "$PWD":"$PWD" -v "${HOME}/FringeFlow":/root/FringeFlow -w $PWD $dockertag
# elif [[ $(hostname) == "askja.ssec.wisc.edu" ]]; then
#     # mount FringeFlow instead of copying it 
#     docker run -it --rm -v "$PWD":"$PWD" -v "${HOME}/FringeFlow":/root/FringeFlow -w $PWD $dockertag
elif [[ $(hostname) == "porotomo.geology.wisc.edu" ]]; then 
    docker run -it --rm -v "$PWD":"$PWD" -w $PWD --network=host $dockertag
else 
  docker run -it --rm -v "$PWD":"$PWD" -w $PWD $dockertag
fi


# change permissions back again
cd ..
# https://stackoverflow.com/questions/15973184/if-statement-to-check-hostname-in-shell-script/15973255
if [[ $(hostname) == "askja.ssec.wisc.edu" ]] || [[ $(hostname) == "maule.ssec.wisc.edu" ]]; then
    echo consider following command
    echo sudo chown -R ${USER}:"'"domain users"'" $runname 
fi

#podman unshare chown -R feigl:'domain users' $PWD
