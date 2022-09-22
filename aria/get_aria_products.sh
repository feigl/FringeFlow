#!/bin/bash -vxe


# attempt to download ARIA products and 
# 20220810 Kurt Feigl

# https://nbviewer.org/github/aria-tools/ARIA-tools-docs/blob/master/JupyterDocs/NISAR/L2_interseismic/mintpySF/smallbaselineApp_aria.ipynb
#conda activate ARIA-tools

# example of bounding box
#ariaDownload.py --bbox "36.75 37.225 -76.655 -75.928"

# get small bounding box - study area only
# site="sanem"
# bbox="$(get_site_dims.sh ${site} S) $(get_site_dims.sh ${site} N) $(get_site_dims.sh ${site} W) $(get_site_dims.sh ${site} E)"
# echo bbox is $bbox
#bbox is 40.3480000000 40.4490000000 -119.4600000000 -119.3750000000

# get bounding box from SSARA covering whole scene
#run_ssara.sh sanem S1 144 20190110  20190122 download
#grep LineString ssara_search_20220828200348.kml
#<LineString><tessellate>1</tessellate><coordinates>-120.004097,40.137749,0 -119.664558,41.756149,0 -116.649643,41.361141,0 -117.064262,39.741959,0 -120.004097,40.137749,0 </coordinates></LineString>
bbox="40.137749 41.756149 -120.004097 -116.649643"
# narrow the longitude
#bbox="40.137749 41.756149 -119.4600000000 -119.3750000000" # cuts off two much

# https://github.com/aria-tools/ARIA-tools/issues/187
# medium size 
# bbox="40.2 40.6 -119.7 -119.3"
# bbox="40.2 40.5 -119.7 -119.3"

#  curl "https://api.daac.asf.alaska.edu/services/search/param?intersectsWith=POLYGON((-119.4738%2040.3014,-119.3544%2040.2985,-119.3431%2040.45,-119.4695%2040.4486,-119.4738%2040.3014))&platform=SENTINEL-1&instrument=C-SAR&maxResults=5000&output=CSV" > test.csv

# curl "https://api.daac.asf.alaska.edu/services/search/param?intersectsWith=POLYGON((-119.4738%2040.3014,-119.3544%2040.2985,-119.3431%2040.45,-119.4695%2040.4486,-119.4738%2040.3014))&platform=SENTINEL-1&instrument=C-SAR&start=2014-06-14T05:00:00Z&end=2022-09-01T04:59:59Z&processinglevel=SLC&beamSwath=IW&maxResults=5000&output=CSV" > test2.csv
#  ariaAOIassist.py -f test.csv -w work
do_download=0
if [[ do_download -eq 1 ]]; then
    # clean start
    \rm -rf products
    #ariaDownload.py --bbox "${bbox}" --output url --start 20210401 --end 20210515 --track 144
    ariaDownload.py -v --bbox "${bbox}" --output url --start 20190101 --end 20190401 --track 144 
    #ariaDownload.py -v --bbox "${bbox}" --output url --start 20200101 --end 2020601 --track 144 --version="2_0_4"
    #ariaDownload.py --bbox "${bbox}" --output url --start 20140101 --end 20220601 --track 144 -v
    #ariaDownload.py --bbox "${bbox}" --output url --start 20140101 --end 20220630 --track 137
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

ariaPlot.py -v -f "products/*.nc" -plotall  --figwidth=wide -nt 1
mv -vf figures figures_all

# study area only
#bbox="40.3480000000 40.4490000000 -119.4600000000 -119.3750000000"
#ariaPlot.py -v -f "products/*.nc" --bbox "${bbox}"  -plotall --figwidth=wide -nt 1

#ariaPlot.py -v -f "products/*v2_0_2.nc" --bbox "${bbox}"  -plotall -croptounion
# ariaPlot.py -f "products/*v2_0_4.nc" --bbox "${bbox}" # 0 valid pairs
# ariaPlot.py -f "products/*v2_0_5.nc" --bbox "${bbox}"


# Prepare ARIA products for time series processing.
ariaTSsetup.py -f "products/*.nc" --bbox "${bbox}" --mask Download --layers all -v 



#ariaTSsetup.py -f "products/*.nc" --mask Download --layers all -v --croptounion




# I have downloaded 773 ARIA products with ariaDownload.py. But when I use smallbaselineApp
# ariaDownload.py --bbox "40.2 40.6 -119.7 -119.3" --output url --start 20140101 --end 20220601 --track 144

# (base) mambauser@25443de73af5:/System/Volumes/Data/mnt/t31/insar/SANEM/ARIA/T144/MINTPY$ ls ../products/*.nc | wc
#     773     773   69570

# But I only 99 interferograms load.

# WARNING: 672 out of 773 GUNW products rejected for not meeting users bbox spatial criteria

# echo "conda deactivate "
mkdir -p MINTPY
pushd MINTPY

cp $HOME/FringeFlow/mintpy/mintpy_aria.cfg .
run_mintpy.sh mintpy_aria.cfg 
# Warning 1: Invalid band number. Got 1050, expected 1015. Ignoring provided one, and using 1015 instead
# Warning 1: Invalid band number. Got 1051, expected 1016. Ignoring provided one, and using 1016 instead
# More than 1000 errors or warnings have been reported. No more will be reported from now.
