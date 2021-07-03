#!/usr/bin/env -S bash
# Run GMTSAR6 under docker
# 2021/07/02 Kurt Feigl and Sam Batzli

# pull container from DockerHub
#docker pull nbearson/isce_mintpy:latest
docker pull gitlab.ssec.wisc.edu:5555/nickb/docker-gmtsar

# check to see about images
docker images

# get the short (base) name of the current working directory
#export MYDIR=`basename $PWD`

export workdir=$PWD

# arrange permissions
export runname="docker_test"
mkdir -p $runname

# copy things we need into folder for container
cp run_one_pair.sh $runname

# script things
cd /home/batzli
tar -czvf $workdir/$runname/bin_htcondor.tgz bin_htcondor
tar -czvf $workdir/$runname/gmtsar-aux.tgz gmtsar-aux
cd $workdir

cp PAIRSmake.txt $runname
cp setup_docker.sh $runname
cp run_pair_inside_docker.sh $runname


# arrange permissions
podman unshare chown -R 1000:1000 $runname


# go into fully loaded folder for container
cd $runname


# start interactive shell in container
docker run -it --rm -v "$PWD":"$PWD" -w "$PWD" gitlab.ssec.wisc.edu:5555/nickb/docker-gmtsar

### inside the container
    # 2  cd In20200807_20210326
    # 3  ls
    # 4  more run.sh
    # 5  ./run.sh

# run script in container
# try passing argument to script
#docker run --rm -v "$PWD":"$PWD" -w "$PWD" gitlab.ssec.wisc.edu:5555/nickb/docker-gmtsar run_one_pair.sh In20200807_20210326
#docker run --rm -v "$PWD":"$PWD" -w "$PWD" gitlab.ssec.wisc.edu:5555/nickb/docker-gmtsar ./run_one_pair.sh

# change permissions back again
cd ..
sudo chown -R feigl:'domain users' $runname

