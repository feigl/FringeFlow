#!/bin/bash -f
# retrieve pairs
# 2021/07/09 Kurt Feigl
# 2021/11/04 edit batzli Added some comments and commented-out line 101 for making UTMs since that is already done on submit-2. Changed mast-->ref and slav-->sec on line 56.
# 2021/11/05 Kurt and Sam UTM files are already in tar ball, no need to make them here. Save plotting for later. 
#   Retrieve, but do not delete tarball from /staging
# 2021/11/08 Make plots, too.
# 2021/12/17 UTMs and plots are made here back on SSEC server (e.g. Ajska)
# 2022/01/28 Try cleaning up /staging 
if [ "$#" -eq 2 ]; then
	pairlist=${1}
    site=`echo ${2} | awk '{print tolower($1)}'`
else
    echo "retrieve pairs from CHTC. Run in desired destination directory."
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



#the following "while read" reads each line and all variables of the PAIRSmake.txt (not all present) to make the .sub file for each pair
# a         b         c      d      e                    f                    g    h    i    j       k          l      m       n      o      p      q    r                       s
# ref       sec       orb1   orb2   doy_mast             doy_slav             dt   nan  trk  orbdir  swath      site   wv      bpar   bperp  burst  sat  dem                     filter_wv   
# 20200415  20210505  54442  60287  105.054610604005006  124.054702444455998  385  NAN  T30  A       strip_004  forge  0.0311  -20.4  6.7    nan    TSX  forge_dem_3dep_10m.grd  80                      

echo 'ref       sec       orb1   orb2   doy_ref             doy_sec             dt   nan  trk  orbdir  swath      site   wv      bpar   bperp  burst  sat  dem                     filter_wv' > goodpairs.txt 

# syntax must be exactly as on follwing line. No quotes around special characters. No "if" statement. 
# ignore commented lines
while read -r a b c d e f g h i j k l m n o p q r s; do
   [[ "$a" =~ ^#.*$ && "$a" != [[:blank:]]  ]] && continue
    ref=$a
    sec=$b
    dt=$g
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
    demf=$r
    filter_wv=$s

    echo $sat $track $ref $sec $user $satparam $demf $filter_wv $xmin $xmax $ymin $ymax $site ${unwrap}
    # set name of tarball
    tgz1="In${ref}_${sec}.tgz"
    echo "tgz1 is now ${tgz1}"

    # find out what is there
    ssh ${ruser}@transfer.chtc.wisc.edu "ls -l /staging/groups/geoscience/insar/${tgz1}"

    # copy tarball 
    rsync -rav ${ruser}@transfer.chtc.wisc.edu:/staging/groups/geoscience/insar/${tgz1} . 
    # copy tarball and delete
    #rsync --remove-source-files -rav ${ruser}@transfer.chtc.wisc.edu:/staging/groups/geoscience/insar/${tgz1} . 

    if [[ ! -f "${tgz1}" ]]; then
        echo "extracting files from tarball named ${tgz1}"
        tar -xzf ${tgz1}
    
        # make plots -- Yes, if UTMs are correctly made on submit-2, then this should work.
        if [[ -d In${ref}_${sec} ]]; then
            echo "entering directory In${ref}_${sec}"
            cd In${ref}_${sec}

            # name of input directory for this pair
            pairdir=${site}_${sat}_${trk}_${swath}_${ref}_${sec}
            echo "pairdir is now set to $pairdir"

            # get the log files by names - next step is to delete
            rsync -rav ${ruser}@submit-2.chtc.wisc.edu:"${pairdir}*.log" .
            rsync -rav ${ruser}@submit-2.chtc.wisc.edu:"${pairdir}*.out" .
            rsync -rav ${ruser}@submit-2.chtc.wisc.edu:"${pairdir}*.err" .

            if [[ -f phasefilt_mask_utm.grd ]]; then   
                # make plot
                # plot_pair6.sh TSX T30 forge forge_TSX_T30_strip004_20200324_20210311 phasefilt_mask_utm.grd phasefilt_mask_utm.ps 15.5 97.6 feigl 80 999. "dem" $PWD
                # echo "plot_pair.sh $sat $trk $site $pair $pair/${pha1}.grd ${pair}_${pha1}.ps $mmperfringe $bperp $user $filter_wv $dt $demf"
                # plot_pair.sh $sat $trk $site $pair $pair/${pha1}.grd ${pair}_${pha1}.ps $mmperfringe $bperp $user $filter_wv $dt $demf
                #plot_pair6.sh  TSX T30 forge "title" phasefilt_mask_utm.grd phase_filt_mask.ps 15.5 63.2 $USER 80 999 In20181115_20190418
                plot_pair6.sh  $sat $trk $site $pairdir phasefilt_mask_utm.grd phasefilt_mask_utm.ps $mmperfringe $bperp $user $filter_wv $dt $demf
                
                # make an exceptionally well documented CSV file;-)
                gmt grdinfo phasefilt_mask_utm.grd     | awk '{print "#",$0}' > phasefilt_mask_utm.csv
                gmt grd2xyz -s -fo phasefilt_mask_utm.grd   | awk '{printf("%.0f,%.0f,%.3f\n",$1,$2,$3)}' >> phasefilt_mask_utm.csv

                echo $a $b $c $d $e $f $g $h $i $j $k $l $m $n $o $p $q $r $s >> ../goodpairs.txt 
            else
                echo "could not find UTM file named phasefilt_mask_utm.grd"
            fi
            echo "Completed In${ref}_${sec}"
            cd ..
            echo "now in directory ${PWD}"
        else
            echo "Did not find directory In${ref}_${sec}"
        fi
    else
        echo "Did not find an ouput tar file named: ${tgz1}, for making In${ref}_${sec}"
    fi
done < ${pairlist}   # end of "while read" loop from above
