#!/bin/bash
# script to give dimensions of interest based on site 
# Elena C Reinisch 20180327
# batzli update 20210304 made more universal with $user variable but requires each user have /siteinfo in their home directory as with /bin_htcondor
# 2021/03/18 Kurt and Sam, make "batzli" the user to hold the data base
# 2021/07/05 Kurt update to use local copy of file named site_dims.txt 
# 2021/07/07 Kurt update handle upper or lower case

# SITE 5 LETTER CODE NAMES
#
# brady - Bradys Hot Springs, NV, USA
# maule - Laguna del Maule, Chile
# mcgin - McGinness Hills
# dcamp - Don Campell
# cosoc - Coso, CA
# tungs - Tungsen
# emesa - East Mesa
# fallo - Fallon, NV
# milfo - Milford, UT
# fawns - Fawnskin

if [[ $# -eq 0 ]]; then
  echo "script to give dimensions of interest based on site"
  echo "usage: get_site_dims.sh [site] [coordinate system index (1 for lat/lon, 2 for UTM, 3 for UTM zone)]"
  echo "e.g., get_site_dims.sh brady 1"
  exit 1
fi

if [[ $# -eq 1 ]]; then
 echo "must input coordinate system index"
 echo "1 for lat/lon"
 echo "2 for UTM"
 echo "3 for UTM zone"
 exit 1
fi

# get user name for location of text file 

if [[ -f $HOME/siteinfo/site_dims.txt ]]; then
    export SITE_TABLE=$HOME/siteinfo/site_dims.txt
elif [[ -f $HOME/FringeFlow/siteinfo/site_dims.txt ]]; then
    export SITE_TABLE=$HOME/FringeFlow/siteinfo/site_dims.txt
elif [[ -f $HOME/site_dims.txt ]]; then
    export SITE_TABLE=$HOME/site_dims.txt
else
    echo "ERROR: $0 cannot find SITE_TABLE file named site_dims.txt"
    echo "consider rsync -rav askja.ssec.wisc.edu:/home/batzli/siteinfo/site_dims.txt $HOME"
    exit -1
fi

#site=$1
# 2021/07/08 make lower case
site=`echo ${1} | awk '{ print tolower($1) }'`

coord_id=${2}

grep -i $site $SITE_TABLE > t1.tmp
if [[ `wc -l t1.tmp | awk '{print $1}' ` -gt 0 ]]; then 
    case $coord_id in
        1 | 2 | 3)
        grep -i $site -A${coord_id} $SITE_TABLE | tail -1
        exit 0
        ;;
        -1 )
        aline=`echo $coord_id | awk '{print sqrt($1*$1)}'`
        grep -i $site $SITE_TABLE -A${aline} | tail -1 | sed 's/-R//' | awk -F'/' '{printf(" W = %20.10f\n E = %20.10f\n S = %20.10f\n N = %20.10f\n",$1,$2,$3,$4)}' 
        exit 0
        ;;
        -2 )
        aline=`echo $coord_id | awk '{print sqrt($1*$1)}'`
        grep -i $site $SITE_TABLE -A${aline} | tail -1 | sed 's/-R//' | awk -F'/' '{printf(" W = %12.3f\n E = %12.3f\n S = %12.3f\n N = %12.3f\n",$1,$2,$3,$4)}' 
        exit 0
        ;;
        *)
        echo "option not yet defined for this site."
        exit 1
        ;;
    esac
else 
  echo "site undefined."
  exit 1
fi
