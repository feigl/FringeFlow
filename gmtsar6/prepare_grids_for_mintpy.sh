#!/bin/bash 
# 2024/04/27 Kurt Feigl set dimensions to match ONE DEM
# 2024/07/27 make work for different sites

bname=`basename $0`

Help()
{
   # Display Help
    echo "$bname cut grids made by GMTSAR to prepare them for use in mintpy"
    echo "usage:   $bname [options]"
    echo "         $bname dem_ll.grd '../PAIRS/In*'"
    echo "         NB: single quotes around second argument are required"
    exit -1
  }

############################################################
############################################################
# Main program                                             #
############################################################
############################################################


if [[  ( "$#" -ne 2)  ]]; then
    Help
fi

set -v # verbose
set -x # for debugging
# set -e # exit on error
# set -u # error on unset variables


export DEM=$1
export INDIR=$2

  
# get dimensions from dem.grd
inclon=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C $DEM | awk '{print $8"d"}'`
inclat=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C $DEM | awk '{print $9"d"}'`
minlon=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C $DEM | awk '{printf("%+#013.8f\n",$2)}'`
maxlon=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C $DEM | awk '{printf("%+#013.8f\n",$3)}'`
minlat=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C $DEM | awk '{printf("%+#013.8f\n",$4)}'`
maxlat=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C $DEM | awk '{printf("%+#013.8f\n",$5)}'`
numlon=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C $DEM | awk '{print $10}'`
numlat=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C $DEM | awk '{print $11}'`
numlat=`gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C $DEM | awk '{print $11}'`


ranges="$minlon/$maxlon/$minlat/$maxlat"

# for FORGE
# surface [WARNING]: Your grid dimensions are mutually prime.  Convergence is very unlikely.
# surface [INFORMATION]: Hint: Choosing -R-112.99/-112.75/38.44/38.59 [n_columns = 2560, n_rows = 1600] might cut run time by a factor of 910.88468
# ranges="-112.99/-112.75/38.44/38.60"

echo ranges is $ranges

\rm -f gmt.conf
\rm -f $HOME/gmt.conf

gmt gmtset FORMAT_FLOAT_OUT="%.12lg"

# loop over pairs
for pairdir in $INDIR ; do
    echo pairdir is $pairdir

    
    if [[ -f $pairdir/unwrap_ll.grd ]] && [[ -f $pairdir/corr_ll.grd ]] && [[ -f $pairdir/dem_ll.grd ]]; then

        cp -v $DEM $pairdir/dem_ll_STANDARD.grd

 
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

            # next line requires GMTSAR
            SAT_baseline $prm1 $prm2 > baseline.txt


            # # create grid of incidence angles, resample, and edit metadata (degrees from vertical)
            gmt grd2xyz dem_ll.grd | SAT_look $prm1 | awk '{print $1,$2,180.0*atan2(sqrt($4*$4 + $5*$5),$6)/atan2(0,-1)}' | gmt xyz2grd -Rdem_ll.grd -Gincidence_ll.grd 
            gmt grd2xyz incidence_ll.grd | gmt surface -R$ranges -I$inclon/$inclat  -Gincidence_ll_cut.grd
            gmt grdedit -D+xlongitude+ylatitude incidence_ll_cut.grd -Gincidence_ll_cut_edit.grd

            # # create grid of azimuth angles, resample and edit metadata (degrees clockwise from North) 
            gmt grd2xyz dem_ll.grd | SAT_look $prm1 | awk '{print $1,$2,180. - 180.0*atan2($5,$4)/atan2(0,-1)}' | gmt xyz2grd -Rdem_ll.grd -Gazimuth_ll.grd 
            gmt grd2xyz azimuth_ll.grd | gmt surface -R$ranges -I$inclon/$inclat  -Gazimuth_ll_cut.grd
            gmt grdedit -D+xlongitude+ylatitude azimuth_ll_cut.grd -Gazimuth_ll_cut_edit.grd
        

            # resample unwrap_ll.grd to be same size as DEM
            gmt grd2xyz unwrap_ll.grd  | gmt surface -R$ranges -I$inclon/$inclat -Gunwrap_ll_cut.grd
            gmt grdedit -D+xlongitude+ylatitude unwrap_ll_cut.grd -Gunwrap_ll_cut_edit.grd

           # resample correlation to be same size as DEM
            gmt grd2xyz corr_ll.grd | gmt surface -R$ranges -I$inclon/$inclat -Gcorr_ll_cut.grd
            gmt grdedit -D+xlongitude+ylatitude corr_ll_cut.grd -Gcorr_ll_cut_edit.grd

        
            # resample DEM to be same size as unwrapped gird
            gmt grd2xyz dem_ll.grd | gmt surface -R$ranges -I$inclon/$inclat  -Gdem_ll_cut.grd
            gmt grdedit -D+xlongitude+ylatitude dem_ll_cut.grd -Gdem_ll_cut_edit.grd

            # check that all have the same size
            #gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C unwrap_ll.grd corr_ll_cut.grd dem_ll_cut_edit.grd incidence_ll_cut_edit.grd azimuth_ll_cut_edit.grd | awk '{printf("%30s %.12gd %.12gd %6d %6d\n",$1,$8,$9,$10,$11)}'
            gmt grdinfo --FORMAT_FLOAT_OUT="%.12lg" -C unwrap_ll_cut_edit.grd corr_ll_cut_edit.grd dem_ll_cut_edit.grd  incidence_ll_cut_edit.grd azimuth_ll_cut_edit.grd | awk '{printf("%30s %.12gd %.12gd %6d %6d\n",$1,$8,$9,$10,$11)}'
            popd
        fi

    fi
done
