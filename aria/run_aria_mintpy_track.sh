#!/bin/bash 

# run ARIA then MINTPY
# assumes that we have a virtual environment set up for each
#
# 2023/11/27 Kurt Feigl


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
    echo '   -m mission e.g., S1 for Sentinel-1'
    echo '   -n threads [default will use all processors]'
    echo '   -s name of site e.g., SANEM for San Emidio or FORGE'
    echo '   -t number of track'
    echo "example:"
    echo "    $bname  -s SANEM -m S1 -1 20210331 -2 20210506 -t 42"
    echo "    $bname  -s FORGE -m S1 -1 20200101 -2 20200130 "
    echo "    $bname  -s SANEM -m S1 -1 20220106 -2 20220623 -t 144 "
    echo "    $bname  -s SANEM -m S1 -t 137 "
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
while getopts ":1:2:h:n:m:s:t:" option; do
    case $option in
        1) # start date YYYYMMDD
            export YYYYMMDD1=$OPTARG
            ;;
        2) # end date YYYYMMDD
            export YYYYMMDD2=$OPTARG
            ;;
        h) # display Help
            Help
            exit;;
        m) # Enter a satellite mission
            export MISSION=$OPTARG
            ;;
        n) # number of processors
            export NPROC=$OPTARG
            ;;
        t) # Enter a track
            export TRACK=$OPTARG
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
if [[ -n ${NPROC+set} ]]; then
    echo NPROC is $NPROC
else
    export NPROC=`nproc`
fi

## are we running under condor ?
if [[  -d /staging/groups/geoscience ]]; then
    export ISCONDOR=1
else
    export ISCONDOR=0 
fi
echo ISCONDOR is $ISCONDOR

# set Lat,Lon coordinates of reference pixel 
# set Bounding Box
case $SITEUC in
  SANEM)
    # NE corner
    # fails because NE corner is OUT of masked area
    # ValueError: input reference point is in masked OUT area defined by maskConnComp.h5!
    # REFLALO="$(get_site_dims.sh ${SITELC} N)","$(get_site_dims.sh ${SITELC} E)"
    # use GARL mean(T.x_latitude_deg_) 40.416526384799042
    # mean(T.x_longitude_deg_) -1.193554577197500e+02
    export REFLALO="40.416526384799042, -119.3554577197500"
    # get corner 10% in from NE
    # export REFLALO=`grep -i $SITEUC $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%20.10f, %20.10f\n",$3+0.9*($4-$3), $1+0.9*($2-$1))}'`
     # reference date must be in list
    # if [[ $TRACK -eq 42 ]]; then
    #     REFDATE="20220312"
    # else
    #     REFDATE="auto"
    # fi
    export REFDATE="auto"
    # change eastern  boundary to include 
    # GARL
    # Latitude: 40.417 degrees
    # Longitude: -119.355 degrees
    # Height: 1640.227 meters
    export BBOX='40.3480000000 40.4490000000 -119.4600000000 -119.350'
    ;;
  FORGE)
    # Should use GPS station named UTM2
    # instead use town of Milford Utah
    # 38.3969° N, 113.0108° W
    export REFLALO="38.3969, -1113.0108"
    export REFDATE="auto"
    export BBOX="$(get_site_dims.sh ${SITEUC} S) $(get_site_dims.sh ${SITEUC} N) $(get_site_dims.sh ${SITEUC} W) $(get_site_dims.sh ${SITEUC} E)"
    ;;  
  *)
    # get corner 10% in from SW
    export REFLALO=`grep -i $SITEUC $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%20.10f, %20.10f\n",$3+0.1*($4-$3), $1+0.1*($2-$1))}'`
    export REFDATE="auto"
    export BBOX="$(get_site_dims.sh ${SITEUC} S) $(get_site_dims.sh ${SITEUC} N) $(get_site_dims.sh ${SITEUC} W) $(get_site_dims.sh ${SITEUC} E)"
    ;;   
esac

echo REFDATE is $REFDATE
echo REFLALO is $REFLALO
echo BBOX is $BBOX



############################################
### starting aria                     ######
############################################
echo starting ARIA
mkdir -p ARIA
pushd ARIA

# ariaDownload.py -v --bbox '40.3480000000 40.4490000000 -119.4600000000 -119.350' --output Download --start 20160101 --end 20230901 --track 42 -w ./products
#ariaDownload.py -v --bbox "$BBOX" --output Download --start $YYYYMMDD1 --end $YYYYMMDD2 --track $TRACK -nt $NPROC -w ./products

ariaPlot.py -v -f "products/*.nc" -plotall  --figwidth=wide -nt $NPROC
ariaTSsetup.py -f 'products/*.nc' --bbox "$BBOX" --mask Download --layers all -v -nt $NPROC

popd

############################################
### starting MintPy using height_correlation              
############################################
echo starting mintpy 
mamba activate mintpy

mkdir -p MINTPY_hcorr
pushd MINTPY_hcorr
rm -rf inputs *.h5 pic
rm -f rms_timeseriesResidual_ramp.txt 
rm -f coherenceSpatialAvg.txt ls
rm -f reference_date.txt 

cp $HOME/FringeFlow/mintpy/aria_hcorr.cfg .
smallbaselineApp.py aria_hcorr.cfg
mamba deactivate

popd

############################################
### starting MintPy using pyaps          
############################################

mamba activate mintpy
mkdir -p MINTPY_pyaps
pushd MINTPY_pyaps
rm -rf inputs *.h5 pic
rm -f rms_timeseriesResidual_ramp.txt 
rm -f coherenceSpatialAvg.txt ls
rm -f reference_date.txt 

cp -v $HOME/FringeFlow/mintpy/aria_pyaps.cfg .
smallbaselineApp.py aria_pyaps.cfg

popd



