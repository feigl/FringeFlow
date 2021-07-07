#!/bin/bash

# copy standard error and standard out to screen only
#./run.sh >& run.log 

# clean up afterwards
### find . -type f  ! -name '*.png'  ! -name '*LED*' ! -name '*PRM' ! -name '*.tif' ! -name '*.tiff' ! -name '*.cpt' ! -name '*corr*.grd'  !  -name '*.kml' ! -name 'display_amp*.grd' ! -name 'phase*.grd' ! -name 'unwrap*.grd' ! -name 'trans.dat'  -delete
# remove links
#find . -type l -delete

# move results out of single intf directory (named by DOY) into current In${ref}_${sec} directory 
if [[ -d intf ]]; then
	if [ $(find . -name "phasefilt_ll.grd") ]; then
  #	if [ -f intf/phasefilt_ll.grd ]; then  #this will always fail because file will be in /intf/$DOY/ --SAB 6/30/2021
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

#if [[ ${ref} != 20170324 || ${sec} != 20170313 ]] ; then
if [ $pair_status != 0 ]; then
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
#else
#	pair_status=0
fi

echo "pair_status is now ${pair_status}"
cd ..
# remove echoes when satisfied 
#tar -czvf In${ref}_${sec}.tgz In${ref}_${sec}
# follow the links
#tar -chzvf In${ref}_${sec}.tgz In${ref}_${sec}
#echo rm -rvf RAW

# transfer pair to askja under ${HOME}/insar/[sat][trk]/site
# htcondor version
# ssh $askja "mkdir -p ${HOME}/insar/$sat/$trk/$site"
#rsync -av --remove-source-files In${ref}_${sec}.tgz $askja:${HOME}/insar/$sat/$trk/$site/
#rsync -av In${ref}_${sec}.tgz $askja:${HOME}/insar/$sat/$trk/$site/

# clean up after pair is transferred
# rm -fv In${ref}_${sec}.tgz 

#exit 0

echo "done with pair In${ref}_${sec}"