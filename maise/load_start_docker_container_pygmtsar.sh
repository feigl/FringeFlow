#!/bin/bash 

# Load a docker container and then start it
# 2021/07/05 Kurt Feigl
# 2021/01/10 siteinfo is no longer in repo
# 2023/06/06 make as close as possible to running on CHTC

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

dirname=$1
timetag=`date -Iseconds`
runname=${dirname}_${timetag}

echo "directory name dirname is $dirname"
if [[ ! -d $dirname ]]; then
  mkdir -p $dirname
fi

cd $dirname
#runname=`basename $dirname`

# if [ -d $runname ]; then
#     rm -rf $runname
# fi
echo runname is $runname
# mkdir -p $runname
# cd $runname

# get important files
# 

# # original
# docker run --hostname=6b29bd5d12a7 --user=1000 \
# --mac-address=02:42:ac:11:00:02 \
# --env=PATH=/usr/local/GMTSAR/bin:/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
# --env=DEBIAN_FRONTEND=noninteractive 
# --env=CONDA_DIR=/opt/conda \
# --env=SHELL=/bin/bash --env=NB_USER=jovyan --env=NB_UID=1000 --env=NB_GID=100 \
# --env=LC_ALL=en_US.UTF-8 --env=LANG=en_US.UTF-8 --env=LANGUAGE=en_US.UTF-8 
# --env=HOME=/home/jovyan 
# --env=JUPYTER_PORT=8888 
# --env=XDG_CACHE_HOME=/home/jovyan/.cache/ 
# --volume=/Users/feigl/pygmtsar:/Users/feigl/pygmtsar 
# --workdir=/home/jovyan -p 8888:8888 
# --restart=no --label='maintainer=Jupyter Project <jupyter@googlegroups.com>' \
# --label='org.opencontainers.image.ref.name=ubuntu' 
# --label='org.opencontainers.image.version=22.04' --runtime=runc 
# -d docker.io/mobigroup/pygmtsar

# modified
docker run --hostname=6b29bd5d12a7 --user=1000 \
--mac-address=02:42:ac:11:00:02 \
--env=PATH=/usr/local/GMTSAR/bin:/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
--env=DEBIAN_FRONTEND=noninteractive \
--env=CONDA_DIR=/opt/conda \
--env=SHELL=/bin/bash --env=NB_USER=jovyan --env=NB_UID=1000 --env=NB_GID=100 \
--env=LC_ALL=en_US.UTF-8 --env=LANG=en_US.UTF-8 --env=LANGUAGE=en_US.UTF-8 \
--env=HOME=/home/jovyan \
--env=JUPYTER_PORT=8888 \
--env=XDG_CACHE_HOME=/home/jovyan/.cache/ \
--volume=/Users/feigl/pygmtsar:/Users/feigl/pygmtsar \
--workdir=$PWD \
-p 8888:8888 \
--restart=no --label='maintainer=Jupyter Project <jupyter@googlegroups.com>' \
--label='org.opencontainers.image.ref.name=ubuntu' \
--label='org.opencontainers.image.version=22.04' --runtime=runc \
-d docker.io/mobigroup/pygmtsar

docker run -it --rm --volume="$PWD":"$PWD"  docker.io/mobigroup/pygmtsar 


# # change permissions back again
# cd ..

# # https://stackoverflow.com/questions/15973184/if-statement-to-check-hostname-in-shell-script/15973255
# if [[ $(hostname) == "askja.ssec.wisc.edu" ]] || [[ $(hostname) == "maule.ssec.wisc.edu" ]]; then
#     sudo chown -R ${USER}:'domain users' $runname 
# fi

