#!/bin/bash -vex
# 2022/12/16 Kurt Feigl

# set -v # verbose
# set -x # for debugging
# set -e # exit on error
# set -u # error on unset variables


bname=`basename $0`

Help()
{
   # Display Help
    echo "$bname will run some combination of Mintpy Aria Isce Ssara Efficiently"
    echo "example:"
    echo "    $bname  -n SANEM -m S1 -t 64 -1 20210331 -2 20210506 -c 1"
    echo 'condor_submit executable="run_ssara_isce_mintpy.sh" arguments="-n SANEM -m S1 -t 64 -1 20220326 -2 20220501 -c 2" run_maise.sub'
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


## are we running under condor ?
if [[  -d /staging/groups/geoscience ]]; then
    export ISCONDOR=1
else
    export ISCONDOR=0 
fi
echo ISCONDOR is $ISCONDOR

# uncompress files for shell scripts 
if [[ ISCONDOR -eq 1 ]]; then
#TODO need to define HOME
#   Interesting thought! I'm not sure if that variable is available in a submit file. These two quick tests were unsuccessful:
#    Using:
#       environment = "HOME=$_CONDOR_SCRATCH_DIR"
#    gives me:
#       I have no name!@bearson-10155730:/var/lib/condor/execute/slot1/dir_2266535$ echo $HOME
#       $_CONDOR_SCRATCH_DIR
# and:
#     environment = "HOME=$(_CONDOR_SCRATCH_DIR)"
#      gives me:
#    I have no name!@bearson-10155732:/var/lib/condor/execute/slot2/dir_579990$ echo $HOME
#    /
    
    echo '$HOME' is $HOME
    #echo '$(_CONDOR_SCRATCH_DIR)' is $(_CONDOR_SCRATCH_DIR)
    # try exporting
    #export HOME=$(_CONDOR_SCRATCH_DIR)
    #export HOME=$PWD
    echo '$HOME' is $HOME

    # next line fails for lack of permissions
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
pushd $RUNDIR
pwd

# set folder for SLC zip files
# if [[ -n ${SLCDIR+set} ]]; then
#    echo SLCDIR is $SLCDIR
# else
#    export SLCDIR="${RUNDIR}/SLC_${SITEUC}_${MISSION}_${TRACK}_${YYYYMMDD1}_${YYYYMMDD2}"
# fi
# echo SLCDIR is ${SLCDIR}

# # test case
# cd ISCE
# stackSentinel.py -w ./ -d demLat_N39_N41_Lon_W120_W118.dem.wgs84 \
# -s /s12/insar/SANEM/S1/T64/SANEM_S1_64_20210331_20210506/SLC -a ../AUX/ -o ../ORBITS/ -c 1 --filter_strength 0 --azimuth_looks 5 --range_looks 20 --num_proc 1 --num_process4topo 1 \
# -C geometry -b '40.3480000000 40.4490000000 -119.4600000000 -119.3750000000' --start 2021-03-31 --stop 2021-05-07 -W interferogram 

# 20210331
# orbit was not found in the /s12/insar/SANEM/S1/T64/SANEM_S1_64_20210331_20210506/ORBITS
# downloading precise or restituted orbits ...
# restituted or precise orbit already exists.
# Traceback (most recent call last):
#   File "/tools/isce2/src/isce2/contrib/stack/topsStack/stackSentinel.py", line 1003, in <module>
#     main(sys.argv[1:])
#   File "/tools/isce2/src/isce2/contrib/stack/topsStack/stackSentinel.py", line 968, in main
#     acquisitionDates, stackReferenceDate, secondaryDates, safe_dict, updateStack = checkCurrentStatus(inps)
#   File "/tools/isce2/src/isce2/contrib/stack/topsStack/stackSentinel.py", line 861, in checkCurrentStatus
#     acquisitionDates, stackReferenceDate, secondaryDates, safe_dict = get_dates(inps)
#   File "/tools/isce2/src/isce2/contrib/stack/topsStack/stackSentinel.py", line 301, in get_dates
#     pnts = safeObj.getkmlQUAD(safe)
#   File "/tools/isce2/src/isce2/contrib/stack/topsStack/Stack.py", line 1646, in getkmlQUAD
#     import cv2
# ImportError: libGL.so.1: cannot open shared object file: No such file or directory

echo "Storing results...."
# transfer output back to /staging/
pushd $WORKDIR/$RUNNAME # I think we should already be there, but just in case
# I don't love using *.log here, as with `set -e` we will bail if there are no such log files
#tar czf "$RUNNAME.tgz" ISCE/merged ISCE/baselines ISCE/interferograms ISCE/JPGS.tgz ISCE/*.log *.log
# 2022/08/08 Kurt - add folders only

if [[  -d /staging/groups/geoscience ]]; then
    tar -czf "$RUNNAME.tgz" DEM ORBITS ISCE/reference ISCE/baselines ISCE/merged ISCE/geom_reference MINTPY _condor_stdout _condor_stderr
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