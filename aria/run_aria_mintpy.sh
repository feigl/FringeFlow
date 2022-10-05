#!/bin/bash -vxe
# set -v # verbose
# set -x # for debugging
# set -e # exit on error
#set -u # error on unset variables
# download ARIA products and run MINTPY
# 20221005 Kurt Feigl

# https://nbviewer.org/github/aria-tools/ARIA-tools-docs/blob/master/JupyterDocs/NISAR/L2_interseismic/mintpySF/smallbaselineApp_aria.ipynb
#conda activate ARIA-tools
# S1  20 FORGE 20200101  20200130
# S1 144 SANEM 20190301  20190401 1  
# 
Help()
{
   # Display Help
    echo "$bname will get ARIA products and then run MintPy"
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

export WORKDIR=$PWD




# cd MetaData
# curl "https://api.daac.asf.alaska.edu/services/search/param?intersectsWith=POLYGON((-119.4738%2040.3014,-119.3544%2040.2985,-119.3431%2040.45,-119.4695%2040.4486,-119.4738%2040.3014))&platform=SENTINEL-1&instrument=C-SAR&start=2014-06-14T05:00:00Z&end=2022-09-01T04:59:59Z&processinglevel=SLC&beamSwath=IW&maxResults=5000&output=CSV" > test2.csv
# ariaAOIassist.py -f test2.csv --flag_partial_coverage --remove_incomplete_dates --lat_bounds '40.3480000000 40.4490000000' 

do_download=1
if [[ do_download -eq 1 ]]; then
    # clean start
    \rm -rf products

    # no data
    #ariaDownload.py --bbox "${bbox}" --output url --start 20200101 --end 20220630 --track 144

    # nice test case 
    #ariaDownload.py -v --bbox "${bbox}" --output url --start 20220401 --end 20220515 --track 42

    # for WHOLESCALE
    #ariaDownload.py -v --bbox "${bbox}" --output url --start 20190101 --end 20220902 --track 42

   # for anything
    ariaDownload.py -v --bbox "${bbox}" --output url --start ${YYYYMMDD1} --end ${YYYYMMDD2} --track ${TRACK}
    
    pushd products

    urllist=`ls -tr *.txt | tail -1`
    echo urllist is $urllist

    if [[ -f ${urllist} ]]; then
        get_urls.sh $urllist
    fi 

    popd
fi

# clean start
rm -rf unwrappedPhase connectedComponents coherence incidenceAngle azimuthAngle stack mask user_bbox.json productBoundingBox amplitude bParallel 
rm -rf DEM
rm -rf figures

# plot data
ariaPlot.py -v -f "products/*.nc" -plotall  --figwidth=wide -nt 1


# Prepare ARIA products for time series processing.
ariaTSsetup.py -f "products/*.nc" --bbox "${bbox}" --mask Download --layers all -v -nt 1

mkdir -p MINTPY
pushd MINTPY

cp $HOME/FringeFlow/mintpy/mintpy_aria.cfg .
run_mintpy.sh mintpy_aria.cfg 
