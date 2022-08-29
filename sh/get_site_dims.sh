#!/bin/bash
# script to give dimensions of interest based on site 
# Elena C Reinisch 20180327
# batzli update 20210304 made more universal with $user variable but requires each user have /siteinfo in their home directory as with /bin_htcondor
# 2021/03/18 Kurt and Sam, make "batzli" the user to hold the data base
# 2021/07/05 Kurt update to use local copy of file named site_dims.txt 
# 2021/07/07 Kurt update handle upper or lower case
# 2021/10/01 Kurt definitive version of siteinfo.tgz database lives on aska
#            definitive version of this script lives in FringeFlow/sh
# 2021/11/08 Kurt clarify error message for SITE_TABLE

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


if [[ -d ${HOME}/siteinfo ]]; then
    #export PATH=${HOME}/siteinfo:${PATH}
    export SITE_DIR=${HOME}/siteinfo  
elif [[ -d ${PWD}/siteinfo ]]; then 
    #export PATH=${PWD}/siteinfo:${PATH}
    export SITE_DIR=${PWD}/siteinfo
else
    echo "WARNING cannot find directory named siteinfo"
fi
#echo SITE_DIR is $SITE_DIR
export SITE_TABLE=${SITE_DIR}/site_dims.txt
#echo SITE_TABLE is $SITE_TABLE

if [[ ! -f $SITE_TABLE ]]; then
	echo "ERROR: $0 cannot find SITE_TABLE file named site_dims.txt (currently defined as: $SITE_TABLE)"
    echo "consider rsync -rav askja.ssec.wisc.edu:/s12/insar/siteinfo $HOME"
    echo "export SITE_TABLE=$HOME/siteinfo/site_dims.txt"  
    exit -1
fi


# get site ame
#site=$1
# 2021/07/08 make lower case
site=`echo ${1} | awk '{ print tolower($1) }'`
coord_id=${2}

# grab information for this site
grep -i $site $SITE_TABLE > t1.tmp
if [[ `wc -l t1.tmp | awk '{print $1}' ` -gt 0 ]]; then 
    case $coord_id in
        1 | 2 | 3)
            grep -i $site -A${coord_id} $SITE_TABLE | tail -1
            exit 0
        ;;
        W )
            # output W, 
            grep -i $site $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%.10f\n",$1)}' 
            exit 0
        ;;
        E)
            # output E, 
            grep -i $site $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%.10f\n",$2)}' 
            exit 0
        ;;
        S)
            # output S, 
            grep -i $site $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%.10f\n",$3)}' 
            exit 0
        ;;
        N)
            # output N, 
            grep -i $site $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%.10f\n",$4)}' 
            exit 0
        ;;
        -1 )
            # output W, E, S, N separately
            grep -i $site $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf(" W = %20.10f\n E = %20.10f\n S = %20.10f\n N = %20.10f\n",$1,$2,$3,$4)}' 
            exit 0
        ;;
        i) 
            # output integer bounds S, N, W, E
            # fails for negative longitude
            #grep -i $site $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%d %d %d %d\n",$3,$4+1,$1,$2+1)}' 
            # works for negative longitude, untested for negative latitude
            grep -i $site $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%d %d %d %d\n",$3-1,$4+1,$1-1,$2+1)}' 
            exit 0
            ;;
        b) 
            # output Bounding box S, N, W, E 
            grep -i $site $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("%20.10f %20.10f  %20.10f %20.10f\n",$3,$4,$1,$2)}' 
            # output Bounding box S, N, W, E with single quotes
            #https://unix.stackexchange.com/questions/222709/how-to-print-quote-character-in-awk/222717
            #grep -i $site $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("\047%20.10f %20.10f  %20.10f %20.10f\047\n",$3,$4,$1,$2)}' 
            # output Bounding box S, N, W, E with double quotes
            #grep -i $site $SITE_TABLE -A1 | tail -1 | sed 's/-R//' | awk -F'/' '{printf("\047\x22%.10f\x22 \x22%.10f\x22 \x22%.10f\x22 \x22%.10f\x22\047\n",$3,$4,$1,$2)}' 
            exit 0
            ;;
        -2 )
            grep -i $site $SITE_TABLE -A2 | tail -1 | sed 's/-R//' | awk -F'/' '{printf(" W = %12.3f\n E = %12.3f\n S = %12.3f\n N = %12.3f\n",$1,$2,$3,$4)}' 
            exit 0
            ;;
        *)
            echo "option not yet defined for this site."
            exit -1
            ;;
    esac
else 
    echo "site undefined."
    exit 1
fi

