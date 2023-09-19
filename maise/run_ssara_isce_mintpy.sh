#!/bin/bash
# 2022/08/04 Kurt Feigl
# 2022/10/08 
# 2023/09/05 

set -v # verbose
set -x # for debugging
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
    echo '   -t number of track'
    echo "example:"
    echo "    $bname  -n SANEM -m S1 -1 20210331 -2 20210506 -c 1 -t 42"
    echo "    $bname  -n FORGE -m S1 -1 20200101 -2 20200130 -c 2"
    echo "    $bname  -n SANEM -m S1 -1 20220331 -2 20220506 -c 3 -t 42"
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
if [[ -n ${STACK_SENTINEL_NUM_CONNECTIONS+set} ]]; then
   echo STACK_SENTINEL_NUM_CONNECTIONS  is $STACK_SENTINEL_NUM_CONNECTIONS
else
   export STACK_SENTINEL_NUM_CONNECTIONS=1
fi

## are we running under condor ?
if [[  -d /staging/groups/geoscience ]]; then
    export ISCONDOR=1
else
    export ISCONDOR=0 
fi
echo ISCONDOR is $ISCONDOR

# uncompress files for shell scripts 
if [[ ISCONDOR -eq 1 ]]; then
    # set up paths and environment
    if [[ -n ${_CONDOR_SCRATCH_DIR+set} ]]; then
        tar -C ${_CONDOR_SCRATCH_DIR} -xzf siteinfo.tgz 
        tar -C ${_CONDOR_SCRATCH_DIR} -xzvf FringeFlow.tgz
        source  ${_CONDOR_SCRATCH_DIR}/FringeFlow/docker/setup_inside_container_maise.sh
        # magic files must be in $HOME
        export HOME1=${HOME} 
        export HOME=${_CONDOR_SCRATCH_DIR}
        ${_CONDOR_SCRATCH_DIR}/FringeFlow/docker/domagic.sh magic.tgz
        export HOME=${HOME1}
    else
        tar -C ${HOME} -xzf siteinfo.tgz 
        tar -C ${HOME} -xzvf FringeFlow.tgz 
        source ${HOME}/FringeFlow/docker/setup_inside_container_maise.sh 
        $HOME/FringeFlow/docker/domagic.sh magic.tgz
    fi
fi

# set some more environment variables
# get absolute path
export WORKDIR=$PWD

export TIMETAG=`date +"%Y%m%dT%H%M%S"`
echo TIMETAG is ${TIMETAG}

export RUNNAME="${SITEUC}_${MISSION}_${TRACK}_${YYYYMMDD1}_${YYYYMMDD2}"
echo RUNNAME is ${RUNNAME}

RUNDIR=${WORKDIR}/${RUNNAME}
mkdir -p $RUNDIR
pushd $RUNDIR
pwd

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
export SLCDIR=${WORKDIR}/SLC
mkdir -p ${SLCDIR}
pushd ${SLCDIR}
echo PWD is now ${PWD}
run_ssara.sh ${SITEUC} ${MISSION} ${TRACK} ${YYYYMMDD1} ${YYYYMMDD2} download | tee -a ../slc.log
ls -ltr | tee -a ../slc.log
popd

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
if [[ -f $HOME/FringeFlow/mintpy/mintpy_template.cfg ]]; then
  cp -vf $HOME/FringeFlow/mintpy/mintpy_template.cfg .
elif [[ -f ${_CONDOR_SCRATCH_DIR}/FringeFlow/mintpy/mintpy_template.cfg ]]; then
  cp -vf ${_CONDOR_SCRATCH_DIR}/FringeFlow/mintpy/mintpy_template.cfg .
fi

# set Lat,Lon coordinates of reference pixel 
case $SITEUC in
  SANEM)
    # get corner 10% in from NE
    REFLALO=`grep -i $SITEUC $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%20.10f, %20.10f\n",$3+0.9*($4-$3), $1+0.9*($2-$1))}'`
    REFDATE="auto"
    ;;
  FORGE)
    # Should use GPS station named UTM2
    # instead use town of Milford Utah
    # 38.3969° N, 113.0108° W
    REFLALO="38.3969, -1113.0108"
    REFDATE="auto"
    ;;  
  *)
    # get corner 10% in from SW
    REFLALO=`grep -i $SITEUC $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%20.10f, %20.10f\n",$3+0.1*($4-$3), $1+0.1*($2-$1))}'`
    REFDATE="auto"
    ;;   
esac

# make custom config file for Mintpy
echo REFLALO is $REFLALO
cat $HOME/FringeFlow/mintpy/mintpy_aria.cfg  > mintpy_aria.cfg
cat mintpy_aria.cfg | grep -v mintpy.reference.lalo > tmp.cfg; echo "mintpy.reference.lalo = $REFLALO"            >> tmp.cfg; mv tmp.cfg mintpy_aria.cfg
cat mintpy_aria.cfg | grep -v PROJECT_NAME          > tmp.cfg; echo "PROJECT_NAME          = ${SITEUC}_T{$TRACK}" >> tmp.cfg; mv tmp.cfg mintpy_aria.cfg
cat mintpy_aria.cfg | grep -v mintpy.reference.date > tmp.cfg; echo "mintpy.reference.date = $REFDATE"            >> tmp.cfg; mv tmp.cfg mintpy_aria.cfg 
# update the standard config file with custom version 
smallbaselineApp.py -g mintpy_aria.cfg
run_mintpy.sh mintpy_template.cfg  | tee -a ../mintpy.log

if [[ -d geo ]]; then
    pushd geo
    plot_maps_mintpy.sh $SITEUC
    popd
fi
popd

### STORE RESULTS
echo "Storing results...."

pushd $WORKDIR 

# keep standard output
if [[ $ISCONDOR -eq 1 ]]; then
    cp -vf _condor_stdout $RUNNAME
    cp -vf _condor_stderr $RUNNAME
fi

# remove intermediate steps
if [[ -f ${WORKDIR}/${RUNNAME}/MINTPY/geo/geo_velocity.h5 ]]; then
    rm -vrf ${WORKDIR}/${RUNNAME}/SLC
    rm -vrf ${WORKDIR}/${RUNNAME}/ISCE/interferograms
    rm -vrf ${WORKDIR}/${RUNNAME}/ISCE/reference
fi

# keep everything

tar -czf ${RUNNAME}.tgz $RUNNAME

if [[  -d /staging/groups/geoscience ]]; then
    mkdir -p "/staging/groups/geoscience/maise/"
    mv -fv $RUNNAME.tgz /staging/groups/geoscience/maise/
    # delete working dir contents to avoid transfering files back to /home/ on submit2
    #rm -rf $RUNNAME
else
    echo keeping everything
fi
popd

# restore environment variable
if [[ -n ${_CONDOR_SCRATCH_DIR+set} ]]; then      
        export HOME=${HOME1}
fi        
  
# exit cleanly
exit 0