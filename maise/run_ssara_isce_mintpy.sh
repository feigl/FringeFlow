#!/bin/bash
# 2022/08/04 Kurt Feigl
# 2022/10/08 
# 2023/09/05 

set -v # verbose
set -x # for debugging
set -e # exit on error
set -u # error on unset variables
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
    echo '   -p number of processors for parallel [default 1, nproc]'
    echo '   -t number of track'
    echo "example:"
    echo "    $bname  -n SANEM -m S1 -1 20210331 -2 20210506 -c 1 -t 42"
    echo "    $bname  -n FORGE -m S1 -1 20200101 -2 20200130 -c 2"
    echo "    $bname  -n SANEM -m S1 -1 20220106 -2 20220623 -c 3 -t 144 "
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
while getopts ":1:2:c:h:n:m:t:p:" option; do
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
            export MISSION=$OPTARG
            ;;
        p) # number of processors
            export NPROC=$OPTARG
            ;;
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
    tar -C ${HOME} -xzvf FringeFlow.tgz

    # set up paths and environment
    # NICKB: does something in setup_inside_container_isce.sh require domagic.sh?
    source $HOME/FringeFlow/docker/setup_inside_container_maise.sh

    # NICKB: this does not appear to run in the run_pairs_isce.sh workflow; taken from docker/load_start_docker_container_isce.sh
    $HOME/FringeFlow/docker/domagic.sh magic.tgz

    # uncompress siteinfo
    #tar -C ${HOME} -xzvf siteinfo.tgz
    get_siteinfo.sh .
fi

# set some more environment variables
# get absolute path
export WORKDIR=${PWD}
echo WORKDIR is $WORKDIR

export TIMETAG=`date +"%Y%m%dT%H%M%S"`
echo TIMETAG is ${TIMETAG}

export RUNNAME="${SITEUC}_${MISSION}_${TRACK}_${YYYYMMDD1}_${YYYYMMDD2}"
echo RUNNAME is ${RUNNAME}

export SLCDIR="$WORKDIR/$RUNNAME/SLC"
export DEMDIR="$WORKDIR/$RUNNAME/DEM"
export ISCEDIR="$WORKDIR/$RUNNAME/ISCE"
export MINTPYDIR="$WORKDIR/$RUNNAME/MINTPY"

echo SLCDIR is $SLCDIR
echo DEMDIR is $DEMDIR
echo ISCEDIR is $ISCEDIR
echo MINTPYDIR is $MINTPYDIR


mkdir -p $RUNNAME
pushd $RUNNAME
pwd

echo "Getting DEM"
mkdir -p $DEMDIR
pushd $DEMDIR
get_dem_isce.sh $SITELC
cd $WORKDIR/

echo "Retrieving AUX files...."
if [[ -f ../../aux.tgz ]]; then
   tar -xzf ../../aux.tgz
elif [[ -f ../aux.tgz ]]; then
   tar -xzf ../aux.tgz
elif [[ -f aux.tgz ]]; then
   tar -xzf aux.tgz
else
   echo error cannot find aux.tgz
   exit -1
fi

### get SLC files
echo "Downloading SLC files...."
mkdir -p ${SLCDIR}
pushd ${SLCDIR}
echo PWD is now ${PWD}
#run_ssara.sh ${SITEUC} ${MISSION} ${TRACK} ${YYYYMMDD1} ${YYYYMMDD2} download | tee -a ../slc.log
download_asf.py -n ${SITEUC}  -t ${TRACK} -s ${YYYYMMDD1} -e ${YYYYMMDD2} -a download | tee -a ../slc.log
ls -ltr | tee -a ../slc.log



### now start ISCE
echo "Running ISCE...."
mkdir -p ${ISCEDIR}
pushd ${ISCEDIR}

#run_isce.sh SANEM S1 64 20210331 20210507
run_isce.sh $SITEUC $MISSION $TRACK $YYYYMMDD1 $YYYYMMDD2 | tee -a ../isce.log
# plot pairs in radar geometry
plot_interferograms.sh $SITEUC filt_fine.int | tee -a ../isce.log
plot_interferograms.sh $SITEUC filt_fine.unw  | tee -a ../isce.log
# geocode and plot pairs in geographic geometry 
geocode_interferograms.sh $SITEUC filt_fine.int | tee -a ../isce.log
geocode_interferograms.sh $SITEUC filt_fine.unw | tee -a ../isce.log
geocode_interferograms.sh $SITEUC filt_fine.cor
geocode_interferograms.sh $SITEUC filt_fine.unw.conncomp

### STORE RESULTS
echo "Storing results...."
pushd $WORKDIR 

# make a list of files to include in tarball
rm -f tarlist.txt
touch tarlist.txt
find . -type f -name "*.log" >> tarlist.txt
find . -type d -name ISCE    >> tarlist.txt
find . -type f -name "*.png" >> tarlist.txt
find . -type f -name "*.eps" >> tarlist.txt
find . -type f -name "*.log" >> tarlist.txt

tar_and_mv_to_staging.sh $RUNNAME /staging/groups/geoscience/insar/ISCE

#### NOW START MINTPY
echo "Running MINTPY..."
mkdir -p $MINTPYDIR
pushd $MINTPYDIR

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

echo REFLALO is $REFLALO

# make custom config file for Mintpy
if [[ -f $HOME/FringeFlow/mintpy/mintpy_isce_template_isce_era5.cfg ]]; then
  cp -vf $HOME/FringeFlow/mintpy/mintpy_isce_template_isce_era5.cfg mintpy.cfg
elif [[ -f ${WORKDIR}/FringeFlow/mintpy/mintpy_isce_template_isce_era5.cfg ]]; then
  cp -vf ${WORKDIR}//FringeFlow/mintpy/mintpy_isce_template_isce_era5.cfg mintpy.cfg
fi

cat mintpy_aria.cfg | grep -v mintpy.reference.lalo > tmp.cfg; echo "mintpy.reference.lalo = $REFLALO"            >> tmp.cfg; mv tmp.cfg mintpy.cfg
cat mintpy_aria.cfg | grep -v PROJECT_NAME          > tmp.cfg; echo "PROJECT_NAME          = ${SITEUC}_T{$TRACK}" >> tmp.cfg; mv tmp.cfg mintpy.cfg
cat mintpy_aria.cfg | grep -v mintpy.reference.date > tmp.cfg; echo "mintpy.reference.date = $REFDATE"            >> tmp.cfg; mv tmp.cfg mintpy.cfg
# update the standard config file with custom version 
smallbaselineApp.py -g mintpy.cfg
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

# make a list of files to include in tarball
rm -f tarlist.txt
touch tarlist.txt
find . -type f -name "*.log" >> tarlist.txt
find . -type d -name MINTPY  >> tarlist.txt
find . -type f -name "*.png" >> tarlist.txt
find . -type f -name "*.eps" >> tarlist.txt
find . -type f -name "*.log" >> tarlist.txt

tar_and_mv_to_staging.sh $RUNNAME /staging/groups/geoscience/insar/MINTPY


# restore environment variable
if [[ -n ${_CONDOR_SCRATCH_DIR+set} ]]; then      
        export HOME=${HOME1}
fi        
  
# exit cleanly
exit 0