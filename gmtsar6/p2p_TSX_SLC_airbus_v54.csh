#!/bin/csh -f
#       $Id$
#
#  Xiaopeng Tong, Jan 14, 2014
#
# process generic L1.1 data
# Automatically process a single frame of interferogram.
# see instruction.txt for details.
#
# Elena Reinisch 20160909 change default filter wavelength to 50 m from 100 m
# ECR 20170102 - add section to cut to subregion before interferogram formation
# ECR 20170130 - udpate for circular stats 
# ECR 20170522 - update to add exception to resetting $region_cut (i.e., also don't define if $min_ra==$max_ra, az)
# ECR 20170724 - update to selecting region_cut2: add -g option to sort to account for negative values

alias rm 'rm -f'
unset noclobber
#
  if ($#argv != 3) then
    echo ""
    echo "Usage: p2p_SAT_SLC.csh master_image slave_image configuration_file "
    echo ""
    echo "Example: p2p_SAT_SLC.csh TSX_20110608 TSX_20110619 config.tsx.slc.txt"
    echo ""
    echo "         Place the L1.1 data in a directory called raw and a dem.grd file in "
    echo "         a parallel directory called topo.  Execute this command at the directory"
    echo "         location above raw and topo.  The file dem.grd"
    echo "         is a dem that completely covers the SAR frame - larger is OK."
    echo "         If the dem is omitted then an interferogram will still be created"
    echo "         but there will not be geocoded output."
    echo "         A custom dem.grd can be made at the web site http://topex.ucsd.edu/gmtsar"
    echo ""
    echo ""
    exit 1
  endif

# start 

#
#   make sure the files exist
#
 if((! -f raw/$1.PRM) || (! -f raw/$1.LED) || (! -f raw/$1.SLC)) then
   echo " missing input files  raw/"$1
   exit
 endif
 if((! -f raw/$2.PRM) || (! -f raw/$2.LED) || (! -f raw/$2.SLC)) then
   echo " missing input files  raw/"$2
   exit
 endif
  if(! -f $3 ) then
    echo " no configure file: "$3
    exit
  endif
# 
# read parameters from configuration file
# 
  set stage = `grep proc_stage $3 | awk '{print $3}'`
  set earth_radius = `grep earth_radius $3 | awk '{print $3}'`
  if ((! $?earth_radius) || ($earth_radius == "")) then
    set earth_radius = 0
  endif
  set topo_phase = `grep topo_phase $3 | awk '{print $3}'`
  set shift_topo = `grep shift_topo $3 | awk '{print $3}'`
  set switch_master = `grep switch_master $3 | awk '{print $3}'`
#
# if filter wavelength is not set then use a default of 50m
#
  set filter = `grep filter_wavelength $3 | awk '{print $3}'`
  if ( "x$filter" == "x" ) then
  set filter = 200
  echo " "
  echo "WARNING filter wavelength was not set in config.txt file"
  echo "        please specify wavelength (e.g., filter_wavelength = 200)"
  echo "        remove filter1 = gauss_alos_200m"
  endif
  echo $filter
  set dec = `grep dec_factor $3 | awk '{print $3}'` 
  set threshold_snaphu = `grep threshold_snaphu $3 | awk '{print $3}'`
  set threshold_geocode = `grep threshold_geocode $3 | awk '{print $3}'`
  set region_cut = `grep "\bregion_cut\b" $3 | awk '{print $3}'`
  set switch_land = `grep switch_land $3 | awk '{print $3}'`
  set defomax = `grep defomax $3 | awk '{print $3}'`
  set region_cut2 = `grep region_cut2 $3 | awk '{print $3}'` 
#
# read file names of raw data
#
  set master = $1 
  set slave = $2 

  if ($switch_master == 0) then
    set ref = $master
    set rep = $slave
  else if ($switch_master == 1) then
    set ref = $slave
    set rep = $master
  else
    echo "Wrong paramter: switch_master "$switch_master
  endif
#
# make working directories
#  
  mkdir -p intf/ SLC/

#############################
# 1 - start from preprocess #
#############################

  if ($stage == 1) then
# 
# preprocess the raw data
#
    echo " "
    echo "PREPROCESS - START"
    cd raw
#
# preprocess the raw data make the raw data and copy the PRM to PRM00
# in case the script is run a second time
#
#   make_raw.com
#
    if(-e $master.PRM00) then
       cp $master.PRM00 $master.PRM
       cp $slave.PRM00 $slave.PRM
    else
       cp $master.PRM $master.PRM00
       cp $slave.PRM $slave.PRM00
    endif
#
# set the num_lines to be the min of the master and slave
#
    @ m_lines  = `grep num_lines ../raw/$master.PRM | awk '{printf("%d",int($3))}' `
    @ s_lines  = `grep num_lines ../raw/$slave.PRM | awk '{printf("%d",int($3))}' `
# add test case for dcamp T144
    if($s_lines <  $m_lines) then
      update_PRM.csh $master.PRM num_lines $s_lines
      update_PRM.csh $master.PRM num_valid_az $s_lines
      update_PRM.csh $master.PRM nrows $s_lines
    else
      update_PRM.csh $slave.PRM num_lines $m_lines
      update_PRM.csh $slave.PRM num_valid_az $m_lines
      update_PRM.csh $slave.PRM nrows $m_lines
    endif
#
#   calculate SC_vel and SC_height
#   set the Doppler to be zero
#
    cp $master.PRM $master.PRM0
    calc_dop_orb $master.PRM0 $master.log $earth_radius 0
    cat $master.PRM0 $master.log > $master.PRM
    echo "fdd1                    = 0" >> $master.PRM
    echo "fddd1                   = 0" >> $master.PRM
#
    cp $slave.PRM $slave.PRM0
    calc_dop_orb $slave.PRM0 $slave.log $earth_radius 0
    cat $slave.PRM0 $slave.log > $slave.PRM
    echo "fdd1                    = 0" >> $slave.PRM
    echo "fddd1                   = 0" >> $slave.PRM
    rm *.log
    rm *.PRM0

    cd ..
    echo "PREPROCESS.CSH - END"
  endif

#############################################
# 2 - start from focus and align SLC images #
#############################################
  
  if ($stage <= 2) then
# 
# clean up 
#
    cleanup.csh SLC
#
# align SLC images 
# 
    echo " "
    echo "ALIGN - START"
    cd SLC
    cp ../raw/*.PRM .
    ln -s ../raw/$master.SLC . 
    ln -s ../raw/$slave.SLC . 
    ln -s ../raw/$master.LED . 
    ln -s ../raw/$slave.LED .
    
    cp $slave.PRM $slave.PRM0
    SAT_baseline $master.PRM $slave.PRM0 >> $slave.PRM
    xcorr $master.PRM $slave.PRM -xsearch 128 -ysearch 128
    fitoffset.csh 2 2 freq_xcorr.dat >> $slave.PRM
    resamp $master.PRM $slave.PRM $slave.PRMresamp $slave.SLCresamp 4
    rm $slave.SLC
    mv $slave.SLCresamp $slave.SLC
    cp $slave.PRMresamp $slave.PRM
        
    cd ..
    echo "ALIGN - END"
  endif

##################################
# 3 - start from make topo_ra    #
##################################

  if ($stage <= 3) then
#
# clean up
#
    cleanup.csh topo
#
# make topo_ra if there is dem.grd
#
    if ($topo_phase == 1) then 
      echo " "
      echo "DEM2TOPO_RA.CSH - START"
      echo "USER SHOULD PROVIDE DEM FILE"
      cd topo
      cp ../SLC/$master.PRM master.PRM 
      ln -s ../raw/$master.LED . 
      if (-f dem.grd) then 
        dem2topo_ra.csh master.PRM dem.grd 
      else 
        echo "no DEM file found: " dem.grd 
        exit 1
      endif
      cd .. 
      echo "DEM2TOPO_RA.CSH - END"
# 
# shift topo_ra
# 
      if ($shift_topo == 1) then 
        echo " "
        echo "OFFSET_TOPO - START"
#
#  make sure the range increment of the amplitude image matches the topo_ra.grd
#
        set rng = `gmt grdinfo topo/topo_ra.grd | grep x_inc | awk '{print $7}'`
        cd SLC 
        echo " range decimation is:  " $rng
        slc2amp.csh $master.PRM $rng amp-$master.grd
        cd ..
        cd topo
        ln -s ../SLC/amp-$master.grd . 
        offset_topo amp-$master.grd topo_ra.grd 0 0 7 topo_shift.grd 
        cd ..
        echo "OFFSET_TOPO - END"
      else if ($shift_topo == 0) then 
        echo "NO TOPO_RA SHIFT "
      else 
        echo "Wrong paramter: shift_topo "$shift_topo
        exit 1
      endif

      else if ($topo_phase == 0) then 
      echo "NO TOPO_RA IS SUBSTRACTED"
    else 
      echo "Wrong paramter: topo_phase "$topo_phase
      exit 1
    endif
  endif

##################################################
# 4 - start from make and filter interferograms  #
##################################################

  if ($stage <= 4) then
#
# clean up
#
    cleanup.csh intf

# make and filter interferograms
# 
    echo " "
    echo "INTF.CSH, FILTER.CSH - START"
    cd intf/
    set ref_id  = `grep SC_clock_start ../raw/$master.PRM | awk '{printf("%d",int($3))}' `
    set rep_id  = `grep SC_clock_start ../raw/$slave.PRM | awk '{printf("%d",int($3))}' `
    mkdir $ref_id"_"$rep_id
    cd $ref_id"_"$rep_id
    ln -s ../../raw/$ref.LED . 
    ln -s ../../raw/$rep.LED .
    ln -s ../../SLC/$ref.SLC . 
    ln -s ../../SLC/$rep.SLC .
    cp ../../SLC/$ref.PRM . 
    cp ../../SLC/$rep.PRM .

# ECR > 
## for later when streamlining cutting process (not dependent on pre-defined regions of interest)
# trim regions
# if subregion undefined, form entire interferogram
    echo "REGION_CUT2 = $region_cut2"
    if ((! $?region_cut2) || ($region_cut2 == "")) then
      echo "SUBREGION UNDEFINED. FORMING  FUL L INTERFEROGRAM"
      if($topo_phase == 1) then
        if ($shift_topo == 1) then
          set region_cut2 = `gmt grdinfo ../../topo/topo_shift.grd -I- | cut -c3-20`
        else
          set region_cut2 = `gmt grdinfo ../../topo/topo_ra.grd -I- | cut -c3-20`
        endif
      endif
    endif

# define region for cutting
    gmt gmtconvert ../../topo/trans.dat -bi5d > testtable
    set subminx = `echo $region_cut2 | sed -e 's/\// /g' | awk '{print $1}'`
    set subminy = `echo $region_cut2 | sed -e 's/\// /g' | awk '{print $3}'`
    set submaxx = `echo $region_cut2 | sed -e 's/\// /g' | awk '{print $2}'`
    set submaxy = `echo $region_cut2 | sed -e 's/\// /g' | awk '{print $4}'`

    # get region from lat/lon and then take min/max for range and azimuth
    set min_r = `awk -v var="$submaxx" '$(NF-1) <= var' testtable | awk -v var="$subminx" '$(NF-1) >= var' | awk -v var="$subminy" '$(NF) >= var' | awk -v var="$submaxy" '$(NF) <= var' | sort -g -k1 | head -1 | awk '{printf("%.0f\n",$1)}'`
    set max_r = `awk -v var="$submaxx" '$(NF-1) <= var' testtable | awk -v var="$subminx" '$(NF-1) >= var' | awk -v var="$subminy" '$(NF) >= var' | awk -v var="$submaxy" '$(NF) <= var' | sort -g -k1 | tail -1 | awk '{printf("%.0f\n", $1)}'`
    set min_a = `awk -v var="$submaxx" '$(NF-1) <= var' testtable | awk -v var="$subminx" '$(NF-1) >= var' | awk -v var="$subminy" '$(NF) >= var' | awk -v var="$submaxy" '$(NF) <= var' | sort -g -k2 | head -1 | awk '{printf("%.0f\n", $2)}'`
    set max_a = `awk -v var="$submaxx" '$(NF-1) <= var' testtable | awk -v var="$subminx" '$(NF-1) >= var' | awk -v var="$subminy" '$(NF) >= var' | awk -v var="$submaxy" '$(NF) <= var' | sort -g -k2 | tail -1 | awk '{printf("%.0f\n", $2)}'`
    echo "$min_r"
    echo "$min_a"
    echo "$max_r"
    echo "$max_a"
    if (( "$min_r/$min_a" != "") && ( "$max_r/$max_a" != "") && ( "$min_r/$min_a" != "$max_r/$max_a" ) && ( "$min_r" != "$max_r" ) && ( "$min_a" != "$max_a" )) then
      #if($topo_phase == 1) then
      #  #echo "$min_ra/$max_ra"
      #  echo "ECR GRDCUT TEST INIT PASS"
      #  if ($shift_topo == 1) then
      #    echo "ECR GRDCUT TOPO_SHIFT.GRD"
      #    gmt grdcut ../../topo/topo_shift.grd -R$min_r/$max_r/$min_a/$max_a -G../../topo/topo_shift.grd
      #  else
      #    echo "ECR GRDCUT TOPO_RA.GRD"
      #    gmt grdcut ../../topo/topo_ra.grd -R$min_r/$max_r/$min_a/$max_a -G../../topo/topo_ra.grd
      #  endif
      # endif
      echo "SET REGION_CUT TO RESULTS OF REGION_CUT2"
      set region_cut = "$min_r/$max_r/$min_a/$max_a"
      echo $region_cut
    endif
  #  echo "SET REGION_CUT TO NULL"
    set region_cut =

# < ECR 20170102

    if($topo_phase == 1) then
      if ($shift_topo == 1) then
        ln -s ../../topo/topo_shift.grd .
        intf.csh $ref.PRM $rep.PRM -topo topo_shift.grd  
        filter.csh $ref.PRM $rep.PRM $filter $dec 
      else 
        ln -s ../../topo/topo_ra.grd . 
        intf.csh $ref.PRM $rep.PRM -topo topo_ra.grd 
        filter.csh $ref.PRM $rep.PRM $filter $dec 
      endif
    else
      intf.csh $ref.PRM $rep.PRM
      filter.csh $ref.PRM $rep.PRM $filter $dec 
    endif 
    #cd ../..
    #echo "INTF.CSH, FILTER.CSH - END"
  #endif

# ECR >
# initial check to see if interferogram has decent circular mean deviation. Should eventually be added to filter.csh
# calculate circular standard deviation
 gmt grdmath phase.grd COS MEAN SQR = mcos2.grd
 gmt grdmath phase.grd SIN MEAN SQR = msin2.grd
 gmt grdmath mcos2.grd msin2.grd ADD SQRT = rlength.grd
 gmt grdmath rlength.grd LOG -2 MUL SQRT = cstd.grd
 set pha_std = `grdinfo -L2 cstd.grd | grep mean | awk '{print $3}'`
 echo "pha_std = $pha_std"
 # test to see if phase std is less than 1/2*pi (1/4 of a cycle).  If not, kill job  
# if (`echo 1.6 $pha_std | awk '{print ( $1 <= $2 ) ? "true" : "false"}'` == "true" ) then 
 # echo "PHA_STD FAIL, PHA_STD > 1.6"
 #  echo "res_mean = nan"
 #  echo "res_std = nan"
 #  echo "res_nu = nan"
 #  echo "abs_t_obs = nan"
 #  echo "abs_t_crit = nan" 
 # exit 1
# endif
   
# check to see if difference between filtered and unfiltered follow ~N(0, sigma)using 1-sample student's T test
 gmt grdmath phasefilt.grd phase.grd SUB WRAP = reswrap.grd
 # calculate mean, std, and df of reswrap.grd
 # circular mean deviation
 gmt grdmath reswrap.grd COS MEAN SQR = mcos2.grd
 gmt grdmath reswrap.grd SIN MEAN SQR = msin2.grd
 gmt grdmath reswrap.grd msin2.grd ADD SQRT = rlength.grd
 gmt grdmath reswrap.grd LOG -2 MUL SQRT = cstd.grd
 set res_std = `gmt grdinfo -M -L2 cstd.grd | grep mean | awk '{print $3}'`
 # mean direction
 gmt grdmath reswrap.grd COS MEAN = mcos.grd
 gmt grdmath reswrap.grd SIN MEAN = msin.grd
 gmt grdmath msin.grd mcos.grd ATAN2 = cmean.grd
 set res_mean = `gmt grdinfo -M -L2 cmean.grd | grep stdev | awk '{print $3}'`
 # find degrees of freedom
 set res_nu = `gmt grdinfo -C reswrap.grd | awk '{prod = ($10 * $11) - 1; print prod}'` 
 # calculate observed t value
 set t_obs = `echo "$res_mean $res_std $res_nu" | awk '{ t_val = ($1) / ($2 / (($3 + 1) ** (1/2)) ); print sqrt ( t_val ** 2) }'`
 # calculate critical t value at alpha = 0.05 
 gmt grdmath 0.05 $res_nu TCRIT -R0/1/0/1 -I1 = tcrit.grd
 set t_crit = `gmt grdinfo -L2 tcrit.grd | grep mean | awk '{print sqrt( $3 ** 2 )}'`
 echo "res_mean = $res_mean"
 echo "res_std = $res_std"
 echo "res_nu = $res_nu"
 echo "abs_t_obs = $t_obs"
 echo "abs_t_crit = $t_crit"
 # test to see if abs_t_crit < abs_t_obs.  If so, reject and skip unwrapping.
 #if ( `echo $t_crit $t_obs | awk '{ print ($1 < $2) ? "true" : "false" }'` == "true" ) then
 #  echo "T TEST FAIL, NO UNWRAPPING"
 #  set threshold_snaphu = "0"
 # #set stage = "8" 
 #endif
# < ECR 20170111; ECR 20170130 update for circ stats 

    cd ../..
    echo "INTF.CSH, FILTER.CSH - END"
  endif


################################
# 5 - start from unwrap phase  #
################################

  if ($stage <= 5 ) then
    if ($threshold_snaphu != 0 ) then
      echo "region_cut = $region_cut"
      cd intf
      set ref_id  = `grep SC_clock_start ../SLC/$master.PRM | awk '{printf("%d",int($3))}' `
      set rep_id  = `grep SC_clock_start ../SLC/$slave.PRM | awk '{printf("%d",int($3))}' `

      cd $ref_id"_"$rep_id
      if ((! $?region_cut) || ($region_cut == "")) then
        set region_cut = `gmt grdinfo phase.grd -I- | cut -c3-20`
      endif

#
# landmask
#
      if ($switch_land == 1) then
        cd ../../topo
        if (! -f landmask_ra.grd) then
          landmask.csh $region_cut
        endif
        cd ../intf
        cd $ref_id"_"$rep_id
        ln -s ../../topo/landmask_ra.grd .
      endif

      echo " "
      echo "SNAPHU.CSH - START"
      echo "threshold_snaphu: $threshold_snaphu"
      
      snaphu.csh $threshold_snaphu $defomax $region_cut

      echo "SNAPHU.CSH - END"
      cd ../..
    else 
      echo ""
      echo "SKIP UNWRAP PHASE"
    endif
  endif

###########################
# 6 - start from geocode  #
###########################

  if ($stage <= 6) then
    cd intf
    set ref_id  = `grep SC_clock_start ../SLC/$master.PRM | awk '{printf("%d",int($3))}' `
    set rep_id  = `grep SC_clock_start ../SLC/$slave.PRM | awk '{printf("%d",int($3))}' `
    cd $ref_id"_"$rep_id
    echo " "
    echo "GEOCODE.CSH - START"
    rm raln.grd ralt.grd
    if ($topo_phase == 1) then
      rm trans.dat
      ln -s  ../../topo/trans.dat . 
      echo "threshold_geocode: $threshold_geocode"
      geocode.csh $threshold_geocode
    else 
      echo "topo_ra is needed to geocode"
      exit 1
    endif
    echo "GEOCODE.CSH - END"
    cd ../..
  endif

# end

