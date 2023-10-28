#!/bin/bash 
# 2023/10/25

# set -v # verbose
# set -x # for debugging
# set -e # exit on error
# set -u # error on unset variables

bname=`basename $0`

Help()
{
   # Display Help
    echo "$bname cut grids made by GMTSAR to prepare them for use in mintpy"
    echo "usage:   $bname [options]"
    echo "$bname   '../In*'"
     exit -1
  }

############################################################
############################################################
# Main program                                             #
############################################################
############################################################
if [[  ( "$#" -ne 1)  ]]; then
    Help
fi

export INDIR=$1

# loop over pairs
for pairdir in $INDIR ; do
    echo pairdir is $pairdir

    # handle older directory structure 
    if [[ -f $pairdir/../../topo/dem_ll.grd ]]; then
        cp -v $pairdir/../../topo/dem_ll.grd $pairdir
    fi

    if [[ -f $pairdir/unwrap_ll.grd ]] && [[ -f $pairdir/corr_ll.grd ]] && [[ -f $pairdir/dem_ll.grd ]]; then

        if [[ -f $pairdir/../topo/dem_ll.grd ]]; then
            cp -v $pairdir/../topo/dem_ll.grd $pairdir
        fi

        echo $pairdir
        basename $pairdir

        # name of parameter PRM file for first acquisition in pair
        prm1=`basename $pairdir | awk '{print substr($1,3,8)".PRM"}'`
        echo prm1 is $prm1
        # name of parameter PRM file for second acquisition in pair
        prm2=`basename $pairdir | awk '{print substr($1,12,8)".PRM"}'`
        echo prm2 is $prm2


        if [[ -f $pairdir/$prm1 ]] && [[ -f $pairdir/$prm2 ]]; then
            pushd $pairdir

            SAT_baseline $prm1 $prm2 > baseline.txt

            
            
            # get increments from unwrap_ll.grd
            inclon=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C unwrap_ll.grd | awk '{print $8"d"}'`
            inclat=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C unwrap_ll.grd | awk '{print $9"d"}'`
            numlon=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C unwrap_ll.grd | awk '{print $10}'`
            numlat=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C unwrap_ll.grd | awk '{print $11}'`
            echo "Filename                       inclon             inclat             numlon numlat"
            echo "xxxxxxxxxxxxx.grd              $inclon $inclat    $numlon    $numlat"

            # create grid of incidence angles, resample, and edit metadata (degrees from vertical)
            gmt grd2xyz dem_ll.grd | SAT_look $prm1 | awk '{print $1,$2,180.0*atan2(sqrt($4*$4 + $5*$5),$6)/atan2(0,-1)}' | gmt xyz2grd -Rdem_ll.grd -Gincidence_ll.grd 
            gmt grd2xyz incidence_ll.grd | gmt surface -Runwrap_ll.grd  -I$inclon/$inclat  -Gincidence_ll_cut.grd
            gmt grdedit -D+xlongitude+ylatitude incidence_ll_cut.grd -Gincidence_ll_cut_edit.grd

            # create grid of azimuth angles, resample and edit metadata (degrees clockwise from North) 
            gmt grd2xyz dem_ll.grd | SAT_look $prm1 | awk '{print $1,$2,180. - 180.0*atan2($5,$4)/atan2(0,-1)}' | gmt xyz2grd -Rdem_ll.grd -Gazimuth_ll.grd 
            gmt grd2xyz azimuth_ll.grd | gmt surface -Runwrap_ll.grd  -I$inclon/$inclat  -Gazimuth_ll_cut.grd
            gmt grdedit -D+xlongitude+ylatitude azimuth_ll_cut.grd -Gazimuth_ll_cut_edit.grd
        
            # resample correlation to be same size as unwrapped grid
            #gmt grdinfo -C unwrap_ll.grd corr_ll.grd dem_ll.grd        
            #gmt grdsample -nc+c corr_ll.grd -Runwrap_ll.grd -G$corr_ll_cut.grd
            gmt grd2xyz corr_ll.grd | gmt surface -Runwrap_ll.grd  -I$inclon/$inclat -Gcorr_ll_cut.grd
            gmt grdedit -D+xlongitude+ylatitude corr_ll_cut.grd -Gcorr_ll_cut_edit.grd

        
            # resample DEM to be same size as unwrapped gird
            gmt grd2xyz dem_ll.grd | gmt surface -Runwrap_ll.grd  -I$inclon/$inclat  -Gdem_ll_cut.grd
            gmt grdedit -D+xlongitude+ylatitude dem_ll_cut.grd -Gdem_ll_cut_edit.grd

            # check that all have the same size
            gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C unwrap_ll.grd corr_ll_cut.grd dem_ll_cut_edit.grd incidence_ll_cut_edit.grd azimuth_ll_cut_edit.grd | awk '{printf("%30s %.12gd %.12gd %6d %6d\n",$1,$8,$9,$10,$11)}'
            popd
        fi

    fi
done
