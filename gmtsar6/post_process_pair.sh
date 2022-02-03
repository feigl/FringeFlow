#!/bin/bash -vx
# 2021/10/25 Sam and Kurt uncommented line 96 to create UTM grid files.
# 2022/01/31 make the plots in the ht_condor job in the slot

timetag=`date +"%Y%m%dT%H%M%S"`
echo timetag is ${timetag}

# move output from DOY_DOY folder into InYYYYMMDD_YYYYMMDD

if [[ ! $# -eq 3 ]] ; then
    bname=`basename ${0}`
    echo "${bname} will move GMTSAR output from DOY_DOY folder into InYYYYMMDD_YYYYMMDD"
    echo "Usage: $bname site5 ref sec"
    echo "$bname forge 20200415 20210505"
    exit -1
 else
    site=${1}
    ref=${2}
    sec=${3}
    SITE=`echo $site | awk '{ print toupper($1) }'`

    # clean up afterwards
    ### find . -type f  ! -name '*.png'  ! -name '*LED*' ! -name '*PRM' ! -name '*.tif' ! -name '*.tiff' ! -name '*.cpt' ! -name '*corr*.grd'  !  -name '*.kml' ! -name 'display_amp*.grd' ! -name 'phase*.grd' ! -name 'unwrap*.grd' ! -name 'trans.dat'  -delete
    
    # remove links
    find . -type l -delete

    # move results out of single intf directory (named by DOY) into current directory named In${ref}_${sec} 
    if [[ -d intf ]]; then
    #	if [ -f intf/phasefilt_ll.grd ]; then  #this will always fail because file will be in /intf/$DOY/ --SAB 6/30/2021
       if [[ $(find . -name "phasefilt_ll.grd") ]]; then
            pair_status=1
            pwd
            mv -v intf/*/* .
            mv -v topo/* .
            mv -v ../config.*.txt .
            mv -v raw/*LED* raw/*PRM .
            # delete folders and any remaining content or broken sym links
            rm -vf topo_ra.grd trans.dat *.SLC
            rm -rvf intf raw SLC topo
        else
            pair_status=0
        fi
    else
        pair_status=0	
    fi

    echo "pair_status is ${pair_status}"
    parent=$(dirname ${PWD})
    export SITE_TABLE="$parent/siteinfo/site_dims.txt"
    echo "trying to set SITE_TABLE to $SITE_TABLE again this time in post_processing.sh"
    if [ $pair_status != 0 ]; then

        xmin=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $1}'`
        xmax=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $2}'`
        ymin=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $3}'`
        ymax=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $4}'`

        if [[ -e "phase_ll.grd"  ]] ; then
            gmt grdcut phase_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gphase_ll.grd
        fi
        if [[ -e "phasefilt_ll.grd"  ]] ; then
            gmt grdcut phasefilt_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gphasefilt_ll.grd
        fi
        if [[ -e "phasefilt_mask_ll.grd" ]] ; then
            gmt grdcut phasefilt_mask_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gphasefilt_mask_ll.grd
        fi
        if [[ -e "unwrap_ll.grd" ]] ; then
            gmt grdcut unwrap_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gunwrap_ll.grd
        fi
        if [[ -e "unwrap_mask_ll.grd" ]] ; then
            gmt grdcut unwrap_mask_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gunwrap_mask_ll.grd
        fi
    fi

    # print completion status and compute arc if necessary
    if [[ -e "phase_ll.grd" && -e "phasefilt_ll.grd" && -e "unwrap_mask_ll.grd" ]] ; then
        pair_status=1
        gmt grdmath phase_ll.grd phasefilt_ll.grd ARC = arc.grd
        # calculate mean, std, and rms of arc; print to txt file
        arc_mean=`gmt grdinfo -M -L2 arc.grd | grep mean | awk '{print $3}'`
        arc_std=`gmt grdinfo -M -L2 arc.grd | grep mean | awk '{print $5}'`
        arc_rms=`gmt grdinfo -M -L2 arc.grd | grep mean | awk '{print $7}'`
        echo "arc_mean = ${arc_mean}"
        echo "arc_std = ${arc_std}"
        echo "arc_rms = ${arc_rms}"
        rm arc.grd
    elif [[ -e "phasefilt_ll.grd" ]]; then
        pair_status=1
        arc_mean='NaN'
        arc_std="NaN"
        arc_rms="NaN"
    else
    	pair_status=0
    fi

    echo "pair_status is now ${pair_status}"

    # prepare cut grd files for gipht 
    prepare_grids_for_gipht6.sh $site

    # make plots (depends on having makefile)
    # make -f plotting.make plot_pha_utm

    # 2022/01/31 make the plots in the ht_condor job in the slot
    # here is the old example
#       plot_pair6.sh  $sat $trk $site $pairdir phasefilt_mask_utm.grd phasefilt_mask_utm.ps $mmperfringe $bperp $user $filter_wv $dt $demf
#      plot_pair7.sh  TSX T91 sanem $PWD phasefilt_mask_utm.grd phasefilt_mask_utm.ps "_" ../dem/sanem_dem_3dep_10m.grd 
#      inside this script, we do not know much. Leave T
       #2022/02/03 remove ploting to its own line in run.sh (written by write_run_script)
       #plot_pair7.sh  TSX T91 $site $PWD phasefilt_mask_utm.grd phasefilt_mask_utm.ps "mmperfringe" "bperp" "user" "filter_wv" "dt" "UTM"
    cd ..
    
    # make a tar file
    #tgzfile=In${ref}_${sec}_${timetag}.tgz
    tgzfile=In${ref}_${sec}.tgz
    # remove echoes when satisfied 
    #tar -czvf $tgzfile In${ref}_${sec}
    # follow the links
    tar -chzvf ${tgzfile} In${ref}_${sec}
    
 
    # transfer pair to askja under ${HOME}/insar/[sat][trk]/site
    # htcondor version
    # ssh $askja "mkdir -p ${HOME}/insar/$sat/$trk/$site"
    #rsync -av --remove-source-files $tgzfile $askja:${HOME}/insar/$sat/$trk/$site/
    #rsync -av $tgzfile $askja:${HOME}/insar/$sat/$trk/$site/  
    #exit 0
    
    # test string for equality
    #if [[ "$hostname" == "askja.ssec.wisc.edu" ]]; then

   
    if [[ -d /s12/insar ]]; then
        # assume we are on askja
        mkdir -p /s12/insar/${SITE}/TSX
        cp -v  $tgzfile /s12/insar/${SITE}/TSX
        # clean up after pair is transferred
        #rm -fv $tgzfile
        #rm -rfv In${ref}_${sec}
    elif [[ -d /staging/groups/geoscience/insar ]]; then
        # assume we are on submit-2 
        mkdir -p /staging/groups/geoscience/insar
        cp -v  $tgzfile /staging/groups/geoscience/insar
        # clean up after pair is transferred
        rm -fv $tgzfile
        rm -rfv In${ref}_${sec}
        rm -rfv *.tgz FringeFlow bin_htcondor 
    else
        # trouble
        echo "Cannot find a place to transfer tar file named $tgzfile"
        # clean up 
        # rm -rf In${ref}_${sec}
    fi

    echo "done with pair In${ref}_${sec}"
    exit 0
fi
