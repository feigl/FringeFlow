#!/bin/bash -veux
# set -v # verbose
# set -x # for debugging
# set -e # exit on error
# set -u # error on unset variables
# download ARIA products and run MINTPY
# 20221005 Kurt Feigl

# https://nbviewer.org/github/aria-tools/ARIA-tools-docs/blob/master/JupyterDocs/NISAR/L2_interseismic/mintpySF/smallbaselineApp_aria.ipynb
#conda activate ARIA-tools
# S1  20 FORGE 20200101  20200130
# S1 144 SANEM 20190301  20190401 1  
bname=`basename $0`

Help()
{
   # Display Help
    echo "$bname will get ARIA products and then run MintPy"
    echo "usage:   $bname [options]"
    echo '   -m mission e.g., S1 for Sentinel-1'
    echo '   -n name of site e.g., SANEM for San Emidio or FORGE'
    echo "   -1 first date YYYYMMDD"
    echo "   -2 last  date YYYYMMDD"
    #echo '   -c number of connections in stack'
    echo '   -t number of track'
    echo "examples:"
    echo "    $bname -n SANEM -m S1 -1 20220331 -2 20220506 -t 42"
    echo "    $bname -n FORGE -m S1 -1 20190101 -2 20220901 -t 20"
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
while getopts ":1:2:h:n:m:t:" option; do
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
   export TRACK=42
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

export WORKDIR=$PWD
echo WORKDIR is $WORKDIR

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


export TIMETAG=`date +"%Y%m%dT%H%M%S"`
echo TIMETAG is ${TIMETAG}

export RUNNAME="${SITEUC}_${MISSION}_${TRACK}_${YYYYMMDD1}_${YYYYMMDD2}"
echo RUNNAME is ${RUNNAME}

RUNDIR="$WORKDIR/$RUNNAME"
mkdir -p $RUNDIR
pushd $RUNDIR
pwd

export BBOX="$(get_site_dims.sh ${SITEUC} S) $(get_site_dims.sh ${SITEUC} N) $(get_site_dims.sh ${SITEUC} W) $(get_site_dims.sh ${SITEUC} E)"
echo BBOX is $BBOX


### Start ARIA
mkdir -p "$WORKDIR/$RUNNAME/ARIA"
pushd "$WORKDIR/$RUNNAME/ARIA"


do_download=1
if [[ do_download -eq 1 ]]; then
    # clean start
    # rm -rf unwrappedPhase connectedComponents coherence incidenceAngle azimuthAngle stack mask user_bbox.json productBoundingBox amplitude bParallel 
    # rm -rf DEM
    # rm -rf figures

    #\rm -rf products
    if [[ -d products ]]; then
        mkdir -p products
    fi

    # cd MetaData
    # curl "https://api.daac.asf.alaska.edu/services/search/param?intersectsWith=POLYGON((-119.4738%2040.3014,-119.3544%2040.2985,-119.3431%2040.45,-119.4695%2040.4486,-119.4738%2040.3014))&platform=SENTINEL-1&instrument=C-SAR&start=2014-06-14T05:00:00Z&end=2022-09-01T04:59:59Z&processinglevel=SLC&beamSwath=IW&maxResults=5000&output=CSV" > test2.csv
    # ariaAOIassist.py -f test2.csv --flag_partial_coverage --remove_incomplete_dates --lat_bounds '40.3480000000 40.4490000000' 

    # for anything
    #ariaDownload.py -v --bbox '40.3480000000 40.4490000000 -119.4600000000 -119.3750000000' --output url --start 20220331 --end 20220506 --track 42 -w ./products
    ariaDownload.py -v --bbox "${BBOX}" --output url --start ${YYYYMMDD1} --end ${YYYYMMDD2} --track ${TRACK} -w ./products
    #ariaDownload.py -v --bbox '40.3480000000 40.4490000000 -119.4600000000 -119.3750000000' --output Download --start 20220331 --end 20220506 --track 42 -w ./products
    #ariaDownload.py -v --bbox "${BBOX}" --output Download --start ${YYYYMMDD1} --end ${YYYYMMDD2} --track ${TRACK} -w ./products
    
    pushd products

    urllist=`ls -tr *.txt | tail -1`
    echo urllist is $urllist

    if [[ -f ${urllist} ]]; then
        get_urls.sh $urllist
    fi 

    popd
fi


# plot data
#ariaPlot.py -v -f "products/*.nc" -plotall  --figwidth=wide -nt 1
ariaPlot.py -v -f "products/*.nc" -plotbperpcoh  --figwidth=wide -nt 1

# Prepare ARIA products for time series processing.
#ariaTSsetup.py -f 'products/*.nc' --bbox '40.3480000000 40.4490000000 -119.4600000000 -119.3750000000' --mask Download --layers all -v -nt 1
ariaTSsetup.py -f "products/*.nc" --bbox "${BBOX}" --mask Download --layers all -v -nt 1

## get back to where you started from
cd $WORKDIR

touch tarlist.txt
ls -d $RUNNAME/ARIA >> tarlist.txt
tar_and_mv_to_staging.sh $RUNNAME /staging/groups/geoscience/insar/ARIA

#### Start MINTPY
mkdir -p "$WORKDIR/$RUNNAME/MINTPY"
pushd "$WORKDIR/$RUNNAME/MINTPY"


# set Lat,Lon coordinates of reference pixel 
case $SITEUC in
  SANEM)
    # NE corner
    # fails because NE corner is OUT of masked area
    # ValueError: input reference point is in masked OUT area defined by maskConnComp.h5!
    # REFLALO="$(get_site_dims.sh ${SITELC} N)","$(get_site_dims.sh ${SITELC} E)"
    # use GARL mean(T.x_latitude_deg_) 40.416526384799042
    # mean(T.x_longitude_deg_) -1.193554577197500e+02
    # REFLALO="40.416526384799042, -119.3554577197500"
    # get corner 10% in from NE
     export REFLALO=`grep -i $SITEUC $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%20.10f, %20.10f\n",$3+0.9*($4-$3), $1+0.9*($2-$1))}'`
     # reference date must be in list
    # if [[ $TRACK -eq 42 ]]; then
    #     REFDATE="20220312"
    # else
    #     REFDATE="auto"
    # fi
    export REFDATE="auto"
    ;;
  FORGE)
    # Should use GPS station named UTM2
    # instead use town of Milford Utah
    # 38.3969° N, 113.0108° W
    export REFLALO="38.3969, -1113.0108"
    export REFDATE="auto"
    ;;  
  *)
    # get corner 10% in from SW
    export REFLALO=`grep -i $SITEUC $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%20.10f, %20.10f\n",$3+0.1*($4-$3), $1+0.1*($2-$1))}'`
    export REFDATE="auto"
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

# start MintPy with updated config file
run_mintpy.sh smallbaselineApp.cfg
#smallbaselineApp.py

# make plots
plot_maps_mintpy.sh $SITEUC

echo "Storing results...."
# transfer output back to /staging/

# make a list of files to include in tarball
rm -f tarlist.txt
touch tarlist.txt
find . -type f -name "*.log" >> tarlist.txt
find . -type d -name MINTPY  >> tarlist.txt
find . -type f -name "*.png" >> tarlist.txt
find . -type f -name "*.eps" >> tarlist.txt
find . -type f -name "*.log" >> tarlist.txt

tar_and_mv_to_staging.sh $RUNNAME /staging/groups/geoscience/insar/MINTPY

pushd $WORKDIR

# exit cleanly
exit 0