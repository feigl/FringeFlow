#!/usr/bin/env bash
# 2022/08/04 Kurt Feigl 

# set -v # verbose
# set -x # for debugging
# set -e # exit on error
#set -u # error on unset variables
# S1  20 FORGE 20200101  20200130
# S1 144 SANEM 20190301  20190401 1  
# 

if [[ (( "$#" -ne 5 ) && ( "$#" -ne 6 )) ]]; then
    bname=`basename $0`
    echo "$bname will run ssara, isce, and eventually mintpy"
    echo "usage:   $bname SAT TRK SITE reference_YYYYMMDD secondary_YYYYMMDD nConnections"
    echo "usage:   $bname S1  20 FORGE_20200101_20200130 -all"
    echo "example: $bname S1 144 SANEM 20190110 20190122"
    echo "example: $bname S1 144 SANEM 20190110 20190122"
    echo "example: $bname S1 144 SANEM 20190110 20190122"
    echo "example: $bname S1 144 SANEM 20190110 20190122"
    echo "example: $bname S1 144 SANEM 20190110 20190122"
    echo "example: $bname S1 144 SANEM 20190110 20190122 -all "
    echo "example: $bname S1 144 SANEM 20190110 20190122 1"
    echo "example: $bname S1 144 SANEM 20190110 20190122 5"
    exit -1
fi


# NICKB: hardcoding some run_pairs_isce.sh bits for running interactive
# export sat=S1
# export trk=20
# export sit=FORGE
# export t0=20200101
# export t1=20200130

export sat=$1
export trk=$2
export sit=`echo $3 | awk '{print tolowers($1)}'`
export t0=$4
export t1=$5

# set number of connections for stackig
if [[ ( "$#" -eq 6 )  ]]; then
   export STACK_SENTINEL_NUM_CONNECTIONS=$6
else
   export STACK_SENTINEL_NUM_CONNECTIONS=1
fi

WORKDIR=$PWD
# set up time tags
export timetag=`date +"%Y%m%dT%H%M%S"`
echo timetag is ${timetag}
export runname="${sat}_${trk}_${sit}_${t0}_${t1}"
echo runname is ${runname}

## are we running under condor ?
if [[  -d /staging/groups/geoscience ]]; then
    export ISCONDOR=1
else
    export ISCONDOR=0 
fi
echo ISCONDOR is $ISCONDOR

# NICKB: this comes from run_pairs_isce.sh
# not currently necessary when using /staging/ or /groups/ for orbits and other input/output
#uncompress SSH keys ssh.tgz
#tar -C ${HOME} -xzvf ssh.tgz
#rm -vf ssh.tgz

# uncompress files for shell scripts 
#if [[ ISCONDOR -eq 1 ]]; then
if [[ $(hostname) == "brady.geology.wisc.edu" ]]; then 
    echo FringeFlow should be mounted
    ls -l /home/ops/FringeFlow
else
    tar -C ${HOME} -xzvf FringeFlow.tgz
fi

# set up paths and environment
# NICKB: does something in setup_inside_container_isce.sh require domagic.sh?
source $HOME/FringeFlow/docker/setup_inside_container_isce.sh

# NICKB: this does not appear to run in the run_pairs_isce.sh workflow; taken from docker/load_start_docker_container_isce.sh
# FIXME: domagic.sh cannot write $HOME/magic/model.cfg to the PyAPS install in /home/ops/PyAPS/pyaps3/model.cfg
$HOME/FringeFlow/docker/domagic.sh magic.tgz

# uncompress siteinfo
tar -C ${HOME} -xzvf siteinfo.tgz

# set up directory for this run
RUNDIR="$WORKDIR/$runname"
mkdir -p $RUNDIR
pushdir $RUNDIR
pwd

echo "Getting DEM ..."
mkdir -p DEM
pushd DEM
get_dem_isce.sh $sit
popd

echo "Retrieving AUX files  ..."
if [[ -f ../aux.tgz ]]; then
   tar -xzf ../aux.tgz
else
   echo ERROR cannot find ../aux.tgz
   exit -1
fi


echo "Downloading SLC files ..."
slcdir="SLC_${sat}_${sit}_${trk}_${t0}_${t1}"
if [[ -f /staging/groups/geoscience/isce/SLC/${slcdir}.tgz ]]; then
   cp -vf /staging/groups/geoscience/isce/SLC/${slcdir}.tgz .
   tar -xzvf ${slcdir}.tgz
else
    mkdir -p ${slcdir}
    pushd ${slcdir}
    echo PWD is now ${PWD}
    run_ssara.sh $sat $trk $sit $t0 $t1 download | tee -a ../slc.log
    tar -czf ${slcdir}.tgz slcdir
    if [[  -d /staging/groups/geoscience ]]; then
        mkdir -p "/staging/groups/geoscience/isce/SLC/"
        cp -fv ${slcdir}.tgz /staging/groups/geoscience/isce/SLC
    fi
    if [[ ! -d SLC ]]; then
       mkdir -p SLC
    fi
    mv $slcdir/*.zip SLC
fi
ls -ltr | tee -a ../slc.log
popd

echo "Handling orbits"
# mkdir -p ORBITS
# cd ORBITS
# get_orbits_from_askja.sh | tee -a ../orbits.log
# cd ..
# [chtc-nickb@bearson-9818685 ORBITS]$ get_orbits_from_askja.sh | tee -a ../orbits.log
# ssh: connect to host askja.ssec.wisc.edu port 22: Connection refused
# NICKB: FIXME: FIX WITH SSH or FIX WITH STAGING?
# above: leaning towards FIX WITH STAGING right now
# 2022/08/10 - ISCE can retrieve its own orbits
# if [[ $ISCONDOR -eq 1 ]]; then 
#     cp /staging/groups/geoscience/isce/input/orbits.tar.xz orbits.tar.xz
#     tar xf orbits.tar.xz
# else
#    if [[ ! -d ORBITS ]]; then
#    rsync -rav transfer.chtc.wisc.edu:/staging/groups/geoscience/isce/input/orbits.tar.xz .
#    tar xf orbits.tar.xz
#    fi
# fi


echo "Running ISCE"
mkdir -p ISCE
pushd ISCE
run_isce.sh ${sit} | tee -a ../isce.log
ls -ltr | tee -a ../isce.log

# check final output
find  baselines -type f -ls | tee baselines.lst
find  merged    -type f -ls | tee merged.lst
popd


# transfer output back to /staging/
cd $WORKDIR/$runname # I think we should already be there, but just in case
# I don't love using *.log here, as with `set -e` we will bail if there are no such log files
#tar czf "$runname.tgz" ISCE/merged ISCE/baselines ISCE/interferograms ISCE/JPGS.tgz ISCE/*.log *.log
# 2022/08/08 Kurt - add folders only

if [[  -d /staging/groups/geoscience ]]; then
    tar -czf "$runname.tgz" DEM ORBITS ISCE/reference ISCE/baselines ISCE/merged ISCE/geom_reference
    mkdir -p "/staging/groups/geoscience/isce/output/"
    cp -fv "$runname.tgz" "/staging/groups/geoscience/isce/output/$runname.tgz"
    # delete working dir contents to avoid transfering files back to /home/ on submit2
    rm -rf $WORKDIR/*
else
    echo keeping everything
fi

# exit cleanly
exit 0
