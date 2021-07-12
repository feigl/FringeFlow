#!/bin/bash 
# retrieve pairs
# 2021/07/09 Kurt Feigl

if [ "$#" -eq 2 ]; then
	pairlist=${1}
    site=`echo ${2} | awk '{print tolower($1)}'`
else
    echo "retrieve pairs from CHTC"
    echo "$0 PAIRSmake.txt site"
    echo "$0 PAIRSmake.txt forge"
    exit -1
fi

echo "site is $site"
echo "pairlist is $pairlist"
SITE=`echo ${site} | awk '{ print toupper($1) }'`

# set user
user=`echo $HOME | awk -F/ '{print $(NF)}'`
echo "local user is $user"

# set remote user on chtc
if [[ ${user} = "batzli" ]]; then
   ruser="sabatzli"
else
   ruser=${user}
fi
echo "remote user ruser is $user"

# set data directory
if [[ $(hostname) = "askja.ssec.wisc.edu" ]]; then
    export DATADIR=/s12
else
    export DATADIR=${HOME}
fi
echo "DATADIR is $DATADIR"

# get the output files
rsync --remove-source-files -rav ${ruser}@transfer.chtc.wisc.edu:/staging/groups/geoscience/insar/"In*" .

# get the log files. It would be better to pull these by names
rsync --remove-source-files -rav ${ruser}@submit-2.chtc.wisc.edu:"${SITE}*.log" .
rsync --remove-source-files -rav ${ruser}@submit-2.chtc.wisc.edu:"${SITE}*.out" .
rsync --remove-source-files -rav ${ruser}@submit-2.chtc.wisc.edu:"${SITE}*.err" .
 

#the following "while read" reads each line and all variables of the PAIRSmake.txt (not all present) to make the .sub file for each pair

# a         b         c      d      e                    f                    g    h    i    j       k          l      m       n      o      p      q    r                       s
# mast      slav      orb1   orb2   doy_mast             doy_slav             dt   nan  trk  orbdir  swath      site   wv      bpar   bperp  burst  sat  dem                     filter_wv   
# 20200415  20210505  54442  60287  105.054610604005006  124.054702444455998  385  NAN  T30  A       strip_004  forge  0.0311  -20.4  6.7    nan    TSX  forge_dem_3dep_10m.grd  80                      


while read -r a b c d e f g h i j k l m n o p q r s; do
# ignore commented lines
  [[ "$a" =~ ^#.*$ && "$a" != [[:blank:]]  ]] && continue
    ref=$a
    sec=$b
    dt=$gd
    trk=$i
    bperp=$n
    sat=$q
    if [[ "$sat" == "TDX" ]]; then
        sat="TSX"
    fi
    wv=$m
    mmperfringe=`echo $wv | awk '{printf("%2.1f\n", $1/2 * 1000)}'`
    satparam=$k
    swath=`echo $satparam | sed 's/_//'`

    # directory for this pair
    pairdir=${site}_${sat}_${trk}_${swath}_${ref}_${sec}
    echo "pairdir is $pairdir"

    #echo $sat $track $ref $sec $user $satparam $demf $filter_wv $xmin $xmax $ymin $ymax $site ${unwrap}
    #rsync --remove-source-files -rav ${ruser}@transfer.chtc.wisc.edu:/staging/groups/geoscience/insar/"In${ref}_${sec}*.tgz" .

    #ssh ${ruser}@transfer.chtc.wisc.edu 'ls -l /staging/groups/geoscience/insar/In*.tgz'
    #ssh ${ruser}@transfer.chtc.wisc.edu "ls -l /staging/groups/geoscience/insar/In${ref}_${sec}.tgz"

    # extract contents from tar files
    tgzs=`find . -name "In${ref}_${sec}*.tgz"`
    if [[ ${#tgzs} -gt 0 ]]; then
        echo "output tar file tgzs is $tgzs"
        for tgz1 in $tgzs; do
            if [[ ! -d "In${ref}_${sec}" ]]; then
                tar -xzvf $tgz1
            fi
        done
    else
        echo "Did not find an ouput tar file for In${ref}_${sec}"
    fi

    # make UTM grids
    prepare_grids_for_gipht6.sh $site

    # make 
      # echo "plot_pair.sh $sat $trk $site $pair $pair/${pha1}.grd ${pair}_${pha1}.ps $mmperfringe $bperp $user $filter_wv $dt $demf"
      # plot_pair.sh $sat $trk $site $pair $pair/${pha1}.grd ${pair}_${pha1}.ps $mmperfringe $bperp $user $filter_wv $dt $demf
      #plot_pair6.sh  TSX T30 forge "title" phasefilt_mask_utm.grd phase_filt_mask.ps 15.5 63.2 $USER 80 999 In20181115_20190418
    plot_pair6.sh  $sat $trk $site $pairdir phasefilt_mask_utm.grd phase_filt_mask.ps $mmperfringe $bperp $user $filter_wv $dt $demf

done < ${pairlist}   # end of "while read" loop from above





