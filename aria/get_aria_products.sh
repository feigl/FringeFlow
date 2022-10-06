#!/bin/bash -vxe


# attempt to download ARIA products and 
# 20220810 Kurt Feigl

# https://nbviewer.org/github/aria-tools/ARIA-tools-docs/blob/master/JupyterDocs/NISAR/L2_interseismic/mintpySF/smallbaselineApp_aria.ipynb
#conda activate ARIA-tools

# example of bounding box
#ariaDownload.py --bbox "36.75 37.225 -76.655 -75.928"

# get small bounding box - study area only
site="sanem"
bbox="$(get_site_dims.sh ${site} S) $(get_site_dims.sh ${site} N) $(get_site_dims.sh ${site} W) $(get_site_dims.sh ${site} E)"
echo bbox is $bbox
#bbox is 40.3480000000 40.4490000000 -119.4600000000 -119.3750000000

# get bounding box from SSARA covering whole scene
#run_ssara.sh sanem S1 144 20190110  20190122 download
#grep LineString ssara_search_20220828200348.kml
#<LineString><tessellate>1</tessellate><coordinates>-120.004097,40.137749,0 -119.664558,41.756149,0 -116.649643,41.361141,0 -117.064262,39.741959,0 -120.004097,40.137749,0 </coordinates></LineString>
#bbox="40.137749 41.756149 -120.004097 -116.649643"
# narrow the longitude
#bbox="40.137749 41.756149 -119.4600000000 -119.3750000000" # cuts off two much

# https://github.com/aria-tools/ARIA-tools/issues/187
# medium size 
# bbox="40.2 40.6 -119.7 -119.3"
#bbox="40.2 40.5 -119.7 -119.3"

#  curl "https://api.daac.asf.alaska.edu/services/search/param?intersectsWith=POLYGON((-119.4738%2040.3014,-119.3544%2040.2985,-119.3431%2040.45,-119.4695%2040.4486,-119.4738%2040.3014))&platform=SENTINEL-1&instrument=C-SAR&maxResults=5000&output=CSV" > test.csv
# SANEM
# cd MetaData
# curl "https://api.daac.asf.alaska.edu/services/search/param?intersectsWith=POLYGON((-119.4738%2040.3014,-119.3544%2040.2985,-119.3431%2040.45,-119.4695%2040.4486,-119.4738%2040.3014))&platform=SENTINEL-1&instrument=C-SAR&start=2014-06-14T05:00:00Z&end=2022-09-01T04:59:59Z&processinglevel=SLC&beamSwath=IW&maxResults=5000&output=CSV" > test2.csv
# ariaAOIassist.py -f test2.csv --flag_partial_coverage --remove_incomplete_dates --lat_bounds '40.3480000000 40.4490000000' 
# ARIA-tools) brady:MetaData feigl$ wc *epochs.txt
#      284     284    2556 A137_epochs.txt
#      261     261    2349 A64_epochs.txt
#      207     207    1863 D144_epochs.txt
#      200     200    1800 D42_epochs.txt
#      952     952    8568 total


# FORGE
# get_site_dims.sh forge 1
# -R-112.9852300488545/-112.7536042430101/38.4450885264283/38.59244067077842
#curl "https://api.daac.asf.alaska.edu/services/search/param?intersectsWith=POLYGON((-112.985%2038.4450,-112.753%2038.4450,-112.753%2038.5924,-112.985%2038.5924,-112.985%2038.4450))&platform=SENTINEL-1&instrument=C-SAR&start=2014-06-14T05:00:00Z&end=2022-09-01T04:59:59Z&processinglevel=SLC&beamSwath=IW&maxResults=5000&output=CSV" > test.csv
#ariaAOIassist.py -f test.csv --flag_partial_coverage --remove_incomplete_dates --lat_bounds '38. 39.' 



do_download=1
if [[ do_download -eq 1 ]]; then
    # clean start
    \rm -rf products

    # no data
    #ariaDownload.py --bbox "${bbox}" --output url --start 20200101 --end 20220630 --track 144

    # nice test case 
    #ariaDownload.py -v --bbox "${bbox}" --output url --start 20220401 --end 20220515 --track 42

    # for WHOLESCALE
    ariaDownload.py -v --bbox "${bbox}" --output url --start 20190101 --end 20220902 --track 42
    
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
