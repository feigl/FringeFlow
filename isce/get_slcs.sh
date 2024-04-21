#!/bin/bash -vxe
# attempt to download SLC products
# 20240420 Kurt Feigl

bname=`basename $0`

Help()
{
   # Display Help
    echo "$bname downloads SLC files"
    echo "usage:   $bname SITE MISSION "
    echo "example: $bname SANEM        
    exit -1
  }

if [[  ( "$#" -ne 1) ]]; then
    Help()
else

site=$1

# # get small bounding box - study area only
# #site="sanem"
# site="forge"
# bbox="$(get_site_dims.sh ${site} S) $(get_site_dims.sh ${site} N) $(get_site_dims.sh ${site} W) $(get_site_dims.sh ${site} E)"
# echo bbox is $bbox


if [[ ( "$site" -eq "forge" )]]; then


# FORGE
 FORGE
# get_site_dims.sh forge 1
# -R-112.9852300488545/-112.7536042430101/38.4450885264283/38.59244067077842
curl "https://api.daac.asf.alaska.edu/services/search/param?intersectsWith=POLYGON((-112.985%2038.4450,-112.753%2038.4450,-112.753%2038.5924,-112.985%2038.5924,-112.985%2038.4450))&platform=SENTINEL-1&instrument=C-SAR&start=2014-06-14T05:00:00Z&end=2022-09-01T04:59:59Z&processinglevel=SLC&beamSwath=IW&maxResults=5000&output=CSV" > test.csv
#ariaAOIassist.py -f test.csv --flag_partial_coverage --remove_incomplete_dates --lat_bounds '38. 39.' 

else
    exit -1
fi


do_download=1
if [[ do_download -eq 1 ]]; then
    
    pushd products

    urllist=`ls -tr *.txt | tail -1`
    echo urllist is $urllist

    if [[ -f ${urllist} ]]; then
        get_urls.sh $urllist
    fi 

    popd
fi

fi


