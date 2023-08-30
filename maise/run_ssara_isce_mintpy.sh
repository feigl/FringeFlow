#!/bin/bash -vex
# 2022/08/04 Kurt Feigl
# 2022/10/08 

# set -v # verbose
# set -x # for debugging
# set -e # exit on error
# set -u # error on unset variables
# S1  20 FORGE 20200101  20200130
# S1 144 SANEM 20190301  20190401 1  

bname=`basename $0`

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
    echo "    $bname  -n SANEM -m S1 -1 20210331 -2 20210506 -c 1"
    echo "    $bname  -n FORGE -m S1 -1 20200101 -2 20200130 -c 2"
    echo "    $bname  -n SANEM -m S1 -1 20220331 -2 20220506 -c 3"
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

    
    # next line fails for lack of permissions
    tar -C ${HOME} -xzvf FringeFlow.tgz  

    # set up paths and environment
    # NICKB: does something in setup_inside_container_isce.sh require domagic.sh?
    #source $HOME/FringeFlow/docker/setup_inside_container_isce.sh
    # 
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


echo "Getting DEM"
mkdir -p DEM
pushd DEM
get_dem_isce.sh $SITELC
popd


echo "Retrieving AUX files...."
if [[ -f ../aux.tgz ]]; then
   tar -xzf ../aux.tgz
elif [[ -f aux.tgz ]]; then
   tar -xzf aux.tgz
else
   echo error cannot find aux.tgz
   exit -1
fi

echo "Downloading SLC files...."
export SLCDIR=${PWD}/SLC
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
#run_isce.sh SANEM S1 64 20210331 20210507
run_isce.sh $SITEUC $MISSION $TRACK $YYYYMMDD1 $YYYYMMDD2 | tee -a ../isce.log
# plot pairs in radar geometry
plot_interferograms.sh $SITEUC filt_fine.int | tee -a ../isce.log
plot_interferograms.sh $SITEUC filt_fine.unw  | tee -a ../isce.log
# geocode and plot pairs in geographic geometry 
geocode_interferograms.sh $SITEUC filt_fine.int | tee -a ../isce.log
geocode_interferograms.sh $SITEUC filt_fine.unw | tee -a ../isce.log
popd

echo "Running MINTPY..."
mkdir -p MINTPY
pushd MINTPY
\cp $HOME/FringeFlow/mintpy/mintpy_template.cfg .
run_mintpy.sh mintpy_template.cfg  | tee -a ../mintpy.log

# FAILS with template
# timeseries2velocity.py /s12/insar/SANEM/S1/T144/SANEM_S1_144_20220331_20220506/MINTPY/inputs/ERA5.h5 -t /s12/insar/SANEM/S1/T144/SANEM_S1_144_20220331_20220506/MINTPY/smallbaselineApp.cfg -o /s12/insar/SANEM/S1/T144/SANEM_S1_144_20220331_20220506/MINTPY/velocityERA5.h5 --update --ref-date 20220331 --ref-yx 739 535
# read options from template file: smallbaselineApp.cfg
# update mode: ON
# 1) output file /s12/insar/SANEM/S1/T144/SANEM_S1_144_20220331_20220506/MINTPY/velocityERA5.h5 NOT found.
# run or skip: run.
# open timeseries file: ERA5.h5
#     sys.exit(load_entry_point('mintpy==1.4.1', 'console_scripts', 'smallbaselineApp.py')())
#   File "/opt/conda/lib/python3.8/site-packages/mintpy-1.4.1-py3.8.egg/mintpy/smallbaselineApp.py", line 1291, in main
#     app.run(steps=inps.runSteps)
#   File "/opt/conda/lib/python3.8/site-packages/mintpy-1.4.1-py3.8.egg/mintpy/smallbaselineApp.py", line 1086, in run
#     self.run_timeseries2velocity(sname)
#   File "/opt/conda/lib/python3.8/site-packages/mintpy-1.4.1-py3.8.egg/mintpy/smallbaselineApp.py", line 925, in run_timeseries2velocity
#     mintpy.timeseries2velocity.main(iargs)
#   File "/opt/conda/lib/python3.8/site-packages/mintpy-1.4.1-py3.8.egg/mintpy/timeseries2velocity.py", line 794, in main
#     run_timeseries2time_func(inps)
#   File "/opt/conda/lib/python3.8/site-packages/mintpy-1.4.1-py3.8.egg/mintpy/timeseries2velocity.py", line 330, in run_timeseries2time_func
#     inps = read_date_info(inps)
#   File "/opt/conda/lib/python3.8/site-packages/mintpy-1.4.1-py3.8.egg/mintpy/timeseries2velocity.py", line 285, in read_date_info
#     ts_obj.open()
#   File "/opt/conda/lib/python3.8/site-packages/mintpy-1.4.1-py3.8.egg/mintpy/objects/stack.py", line 171, in open
#     self.get_metadata()
#   File "/opt/conda/lib/python3.8/site-packages/mintpy-1.4.1-py3.8.egg/mintpy/objects/stack.py", line 213, in get_metadata
#     self.metadata['REF_DATE'] = dateList[0]
# IndexError: list index out of range
# Dumping dates
# HDF5 "inputs/ifgramStack.h5" {
# DATASET "date" {
#    DATATYPE  H5T_STRING {
#       STRSIZE 8;
#       STRPAD H5T_STR_NULLPAD;
#       CSET H5T_CSET_ASCII;
#       CTYPE H5T_C_S1;
#    }

if [[ -d geo ]]; then
    pushd geo
    plot_maps_mintpy.sh $SITEUC
    popd
fi
popd

echo "Storing results...."
# transfer output back to /staging/
pushd $WORKDIR/$RUNNAME # I think we should already be there, but just in case
# I don't love using *.log here, as with `set -e` we will bail if there are no such log files
#tar czf "$RUNNAME.tgz" ISCE/merged ISCE/baselines ISCE/interferograms ISCE/JPGS.tgz ISCE/*.log *.log
# 2022/08/08 Kurt - add folders only

if [[  -d /staging/groups/geoscience ]]; then
    cp -vf ../_condor_stdout .
    cp -vf ../_condor_stderr .
    tar -czf "$RUNNAME.tgz" DEM ORBITS ISCE/reference ISCE/baselines ISCE/merged ISCE/geom_reference MINTPY ../_condor_stdout ../_condor_stderr
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