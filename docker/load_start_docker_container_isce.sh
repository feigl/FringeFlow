#!/bin/bash 

# Load a docker container and then start it
# 2021/07/05 Kurt Feigl
# 2021/11/29 Kurt Feigl 

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
if [[ "$#" -eq 5 ]]; then
  echo "Arguments are $1 $2 $3 $4 $5"
  export sat=$1
  export trk=$2
  export sit=$3
  export t0=$4
  export t1=$5
elif [[ "$#" -eq 3 ]]; then
  echo "Arguments are $1 $2 $3"
  export sat=$1
  export trk=$2
  export sit=$3
  export t0='';
  export t1='';
else
  export dirname=$1
  export runname=$dirname
fi

if [[ (( "$#" -eq 3) || ( "$#" -eq 5 )) ]]; then
  echo sat is $sat
  echo trk is $trk
  echo sit is $sit
  echo t0 is $t0
  echo t1 is $t1
  export runname="${sat}_${trk}_${sit}_${t0}_${t1}"

  case $HOSTNAME in
      askja.ssec.wisc.edu)
      dirname=/s12/insar/$sit/$sat
      ;;
      maule.ssec.wisc.edu)
      dirname=/s22/insar/$sit/$sat
      ;;
      *)
      dirname=/System/Volumes/Data/mnt/t31/insar/$sit/$sat
      ;;
  esac
fi

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

## copy keys here
# cp -v $HOME/.netrc . 
# cp -v $HOME/.model.cfg .
# cp -v $HOME/SSARA-master/password_config.py .
# cp -v $HOME/site_dims.txt .
cp -v $HOME/magic.tgz .
cp -v $HOME/.ssh/id_rsa .

# 2021/01/10 siteinfo is no longer in repo
if [[ -d $HOME/siteinfo ]]; then
   cp -r $HOME/siteinfo .
else
   echo "ERROR: cannot find folder $HOME/siteinfo. Look on askja."
   exit -1
fi

# copy input files
#cp /s12/insar/SANEM/Maps/SanEmidioWells2/San_Emidio_Wells_2019WithLatLon.csv .
#cp -r ../TEMPLATE/* .
#rsync -rav feigl@askja.ssec.wisc.edu:/s12/insar/$sit/S1/ISCE/"dem*" ISCE
# make a copy of executable scripts
#cp -vr /s12/insar/SANEM/SENTINEL/bin .

# ## pull scripts and make a tar file
cd $HOME
# cd FringeFlow
# git pull 
# cd ..
tar --exclude FringeFlow/.git -chzvf FringeFlow.tgz FringeFlow
cp -rfv FringeFlow.tgz $runname

# 2021/01/10 siteinfo is no longer in repo
if [[ -d $HOME/siteinfo ]]; then
   cp -rfv $HOME/siteinfo .
else
   echo "ERROR: cannot find folder $HOME/siteinfo. Look on askja."
   exit -1
fi

# make a tar file
#tar -czvf ../${runname}.tgz .


# pull container from DockerHub
#docker pull docker.io/nbearson/isce_chtc2
docker pull docker.io/nbearson/isce_mintpy:20211110

# get the short (base) name of the current working directory
#export MYDIR=`basename $PWD`

echo '  '
echo "Starting image in container..."
echo "Once container starts, consider the following commands"
echo 'tar -C $HOME -xzvf FringeFlow.tgz '
echo 'source $HOME/FringeFlow/docker/setup_inside_container_isce.sh'
echo 'domagic.sh magic.tgz'
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
docker run -it --rm -v "$PWD":"$PWD" -w $PWD docker.io/nbearson/isce_mintpy:20211110



# change permissions back again
cd ..
# https://stackoverflow.com/questions/15973184/if-statement-to-check-hostname-in-shell-script/15973255
if [[ $(hostname) == "askja.ssec.wisc.edu" ]] || [[ $(hostname) == "maule.ssec.wisc.edu" ]]; then
    sudo chown -R ${USER}:'domain users' $runname 
fi

#podman unshare chown -R feigl:'domain users' $PWD
