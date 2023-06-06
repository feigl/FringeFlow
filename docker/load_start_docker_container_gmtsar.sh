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
cp $HOME/PAIRSmake.txt .
cp /opt/gmtsar/6.0/share/gmtsar/csh/config.tsx.txt .

# # 2021/01/10 siteinfo is no longer in repo
# if [[ -d $HOME/siteinfo ]]; then
#    cp -rfv $HOME/siteinfo .
# else
#    echo "ERROR: cannot find folder $HOME/siteinfo. Look on askja."
#    exit -1
# fi

echo '  '
echo "Starting image in container..."
echo "Once container starts, consider the following commands"
#echo 'tar -C $HOME -xzvf FringeFlow.tgz '
#echo 'source $HOME/FringeFlow/docker/setup_inside_container_gmtsar.sh'
#echo 'copy $HOME/FringeFlow/docker/setup_inside_container_gmtsar.sh'
# echo 'domagic.sh magic.tgz'
# echo 'export SITE_TABLE=$HOME/siteinfo/site_dims.txt'
echo '#test to see if that darned siteinfo is working'
echo '   get_site_dims.sh forge 1'
echo '  '
echo '  '
# set up for scripts 


 # should output
#-R-112.9852300488545/-112.7536042430101/38.4450885264283/38.59244067077842

# pull container from DockerHub
#docker pull docker.io/nbearson/isce_chtc2
docker pull docker.io/nbearson/gmtsar

# get the short (base) name of the current working directory
#export MYDIR=`basename $PWD`


## arrange permissions
# go directory above container
cd $dirname
#if [[ (( "$HOST" -eq "askja.ssec.wisc.edu") || ( "$HOST" -eq "maule.ssec.wisc.edu")) ]]; then
# if [[ (( "$HOST" == "askja.ssec.wisc.edu") || ( "$HOST" == "maule.ssec.wisc.edu")) ]]; then
#   podman unshare chown -R 1000:1000 $runname
# fi
# go into container
# cd $runname

echo "Once container starts, try: "
echo "cp -rv siteinfo /root"
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
docker run -it --rm -v "$PWD":"$PWD" -w $dirname docker.io/nbearson/gmtsar 
# if [[ -d /home/batzli/bin_htcondor ]] && [[ -d /s12/insar:/root/insar ]] ; then
#   docker run -it --rm -v "$PWD":"$PWD" \
#   -v ${HOME}/FringeFlow:/root/FringeFlow \
#   -v /home/batzli/bin_htcondor:/root/bin_htcondor \
#   -v /s12/insar:/root/insar \
#   -w $PWD docker.io/nbearson/gmtsar
# else
#   docker run -it --rm -v "$PWD":"$PWD" \
#   -w $dirname docker.io/nbearson/gmtsar
#   -v ${HOME}/FringeFlow:/root/FringeFlow \
# fi

# # change permissions back again
# cd ..

# # https://stackoverflow.com/questions/15973184/if-statement-to-check-hostname-in-shell-script/15973255
# if [[ $(hostname) == "askja.ssec.wisc.edu" ]] || [[ $(hostname) == "maule.ssec.wisc.edu" ]]; then
#     sudo chown -R ${USER}:'domain users' $runname 
# fi

