#!/usr/bin/env bash
# 2022/08/04 Kurt Feigl 

# set -v # verbose
# set -x # for debugging
# set -e # exit on error
#set -u # error on unset variables
# S1  20 FORGE 20200101  20200130
# S1 144 SANEM 20190301  20190401 1  
# 
Help()
{
   # Display Help
    echo "$bname will run ssara, isce, and eventually mintpy"
    echo "usage:   $bname [options]"
    echo "   -1 first date YYYYMMDD"
    echo "   -2 last  date YYYYMMDD"
    echo '   -c number of connections in stack'
    echo '   -m mission e.g., S1 for Sentinel-1'
    echo '   -n name of site e.g., SANEM for San Emidio or FORGE'
    echo "example:"
    echo "    $bname  -n SANEM -m S1 -1 20220331 -2 20220506 -c 1"
    exit -1
  }

############################################################
############################################################
# Main program                                             #
############################################################
############################################################
if [[  ( "$#" -eq 0)  ]]; then
    Help
fi

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":1:2:c:h:n:m:t:" option; do
    case $option in
        1) # start date YYYYMMDD
            export YYYYMMDD1=$OPTARG
            ;;
        2) # end date YYYYMMDD
            export YYYYMMDD2=$OPTARG
            ;;
        c) # number of connections
            export STACK_SENTINEL_NUM_CONNECTIONS=$OPTARG
            ;;
        h) # display Help
            Help
            exit;;
        n) # Enter a site name
            export SITELC=`echo ${OPTARG} | awk '{ print tolower($1) }'`         
            export SITEUC=`echo ${SITELC} | awk '{ print toupper($1) }'`
            ;;
        m) # Enter a satellite mission
            export MISSION=$OPTARG;;
        t) # Enter a track
            TRACK=$OPTARG
            ;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done

# test existence of variables
#https://unix.stackexchange.com/questions/212183/how-do-i-check-if-a-variable-exists-in-an-if-statement
if [[ -n ${SITELC+set} ]]; then
   echo SITELC is $SITELC
else
   export SITELC="sanem"
fi
if [[ -n ${SITEUC+set} ]]; then
   echo SITEUC is $SITEUC
else
   export SITEUC="SANEM"
fi
if [[ -n ${MISSION+set} ]]; then
   echo MISSION is $MISSION
else
   export MISSION="S1"
fi
if [[ -n ${TRACK+set} ]]; then
   echo TRACK is $TRACK
else
   export TRACK=144
fi
if [[ -n ${YYYYMMDD1+set} ]]; then
    echo YYYYMMDD1 is $YYYYMMDD1
else
    export YYYYMMDD1="20140403" # start of Sentinel-1A 
fi
if [[ -n ${YYYYMMDD2+set} ]]; then
    echo YYYYMMDD2 is $YYYYMMDD2
else
    export YYYYMMDD2="20240101" # 
fi
if [[ -n ${STACK_SENTINEL_NUM_CONNECTIONS} ]]; then
   echo STACK_SENTINEL_NUM_CONNECTIONS  is $STACK_SENTINEL_NUM_CONNECTIONS
else
   export STACK_SENTINEL_NUM_CONNECTIONS=1
fi

export WORKDIR=$PWD

# set folder for SLC zip files
if [[ -n ${SLCDIR+set} ]]; then
   echo SLCDIR is $SLCDIR
else
   export SLCDIR="SLC_${SITEUC}_${MISSION}_${TRACK}_${YYYYMMDD1}_${YYYYMMDD2}"
fi
echo SLCDIR is ${SLCDIR}


## are we running under condor ?
if [[  -d /staging/groups/geoscience ]]; then
    export ISCONDOR=1
else
    export ISCONDOR=0 
fi
echo ISCONDOR is $ISCONDOR

# uncompress files for shell scripts 
if [[ ISCONDOR -eq 1 ]]; then
    tar -C ${HOME} -xzvf FringeFlow.tgz

    # set up paths and environment
    # NICKB: does something in setup_inside_container_isce.sh require domagic.sh?
    source $HOME/FringeFlow/docker/setup_inside_container_isce.sh

    # NICKB: this does not appear to run in the run_pairs_isce.sh workflow; taken from docker/load_start_docker_container_isce.sh
    $HOME/FringeFlow/docker/domagic.sh magic.tgz

    # uncompress siteinfo
    #tar -C ${HOME} -xzvf siteinfo.tgz
    get_siteinfo.sh .
fi


export TIMETAG=`date +"%Y%m%dT%H%M%S"`
echo TIMETAG is ${TIMETAG}

export RUNNAME="${SITEUC}_${MISSION}_${TRACK}_${YYYYMMDD1}_${YYYYMMDD2}"
echo RUNNAME is ${RUNNAME}

RUNDIR="$WORKDIR/$RUNNAME"
mkdir -p $RUNDIR
cd $RUNDIR
pwd

echo "Getting DEM"
mkdir -p DEM
pushd DEM
get_dem_isce.sh $SITELC
popd


echo "Retrieving AUX files...."
if [[ -f ../aux.tgz ]]; then
   tar -xzf ../aux.tgz
else
   echo error cannot find ../aux.tgz
fi

echo "Downloading SLC files...."
mkdir -p ${SLCDIR}
pushd ${SLCDIR}
echo PWD is now ${PWD}
run_ssara.sh ${SITEUC} ${MISSION} ${TRACK} ${YYYYMMDD1} ${YYYYMMDD2} download | tee -a ../slc.log
ls -ltr | tee -a ../slc.log
popd


#echo "Handling orbits"
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


echo "Running ISCE...."
mkdir -p ISCE
pushd ISCE
run_isce.sh $SITEUC $MISSION $TRACK $YYYYMMDD1 $YYYYMMDD2 | tee -a ../isce.log
popd

echo "Running MINTPY..."
mkdir -p MINTPY
pushd MINTPY
cp $HOME/FringeFlow/mintpy/mintpy_template.cfg .
run_mintpy.sh mintpy_template.cfg  | tee -a ../mintpy.log
popd

echo "Storing results...."
# transfer output back to /staging/
pushd $WORKDIR/$RUNNAME # I think we should already be there, but just in case
# I don't love using *.log here, as with `set -e` we will bail if there are no such log files
#tar czf "$RUNNAME.tgz" ISCE/merged ISCE/baselines ISCE/interferograms ISCE/JPGS.tgz ISCE/*.log *.log
# 2022/08/08 Kurt - add folders only

if [[  -d /staging/groups/geoscience ]]; then
    tar -czf "$RUNNAME.tgz" DEM ORBITS ISCE/reference ISCE/baselines ISCE/merged ISCE/geom_reference MINTPY
    mkdir -p "/staging/groups/geoscience/isce/output/"
    cp -fv "$RUNNAME.tgz" "/staging/groups/geoscience/isce/output/$RUNNAME.tgz"
    # delete working dir contents to avoid transfering files back to /home/ on submit2
    rm -rf $WORKDIR/*
else
    echo keeping everything
fi
popd

# exit cleanly
exit 0