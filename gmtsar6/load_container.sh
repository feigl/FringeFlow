#!/bin/bash -vex
#!/usr/bin/env -S bash -x
# 	switches in line above after "bash"
# 	-x  Print commands and their arguments as they are executed.
# 	-e  Exit immediately if a command exits with a non-zero status.
#
# reads a text file containing information on SAR images, forms pairs, writes submit files, and submits the jobs
# Elena C Reinisch, 20160808

# Usage: ~/bin_htcondor/run_pair_DAG_gmtsarv60.sh PAIRSmake.txt <value> ##second argument added for unwrap by batzli 20210308 
# Usage: [the second argument passes through run_pair_gmtsarv60.sh to pair2e.sh]

# edit 20161030 add variables to cut region, change names of output files to include satellite and track
# edit 20170407 add section to copy preproc and dem data from askja if doesn't exist on gluster
# edit 20170425 add check for duplicate preproc data, keep only the correct files based on site
# edit 20170605 add tarring of files and change transfer to home directory on output
# edit 20170616 add tarring of software and change to getting data onto gluster using transfer00
# edit 20170619 add orbits tar for ERS and ENVI
# edit 20170622 add time out allowance for copying from askja to gluster using transfer00; include ssh transfer material; remove file transfer on exit
# edit 20170710 now copy data during directly (no interaction with gluster); add concurrency_limits = SSEC_FTP to submit requirements and add check that cut version of DEM exists on askja
# edit 20171204 add line to require Linux 6 operating systems 
# edit 20180212 no longer require linux 6 OS (not needed)
# edit 20180319 save process.err and process.out for each file
# edit 20180406 update to pull from bin_htcondor repo
# edit 20180510 fix region commands for new get_site_dims.sh
# edit 20200107 port to submit-2:/home/groups/geoscience for sharing 
# edit 20200127 Kurt fix bug that stops run before geocoding
# edit 20200401 Kurt and Sam add switch to submit interactively
# edit 20201106 Sam changed shebang from #!/bin/bash to #!/urs/bin/env -S bash as recommended by TC
# edit 20201202 Sam and Kurt adapt for running on Askja
# edit 20210308 Sam added optional unwrap variable to pass through to pair2e.sh for editing config.tsx.txt file "threshold_snaphu = 0.12" if unset or empty (default = 0)
# edit 20210707 Kurt adapt for docker

if [ "$#" -eq 1 ]; then
	unwrap=0
elif [ "$#" -eq 2 ]; then
	unwrap=${2}
else
   echo "usage: this script expects a PAIRSmake.txt file and numerical value for threshold_snaphu"
   echo "$0 PAIRSmake.txt"
   echo "$0 PAIRSmake.txt 0.12"
   exit 0
fi

# set user
user=`echo $HOME | awk -F/ '{print $(NF)}'`

# set filter wavelength
filter_wv=`tail -1 $1 | awk '{print $19}'`

# set cut region in latitude and longitude
site=`tail -1 $1 | awk '{print $12}'`
xmin=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $1}'`
xmax=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $2}'`
ymin=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $3}'`
ymax=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $4}'`

## cut DEM
gmt grdcut /s12/insar/dem/${demf} -Gcut_${demf} -R${xmin}/${xmax}/${ymin}/${ymax}

### check variables
#I believe next will be: 
#~/bin_htcondor/run_pair_gmtsarv60.sh $sat $track $ref $sec $user $satparam $demf $filter_wv $xmin $xmax $ymin $ymax $site
# but some variables are missing: ($satparam) need to find source
echo "Currently defined Variables:"
echo "sat=$sat track=$track ref=$ref sec=$sec"
echo "user=$user" 
echo "satparam=$satparam"
echo "dem=$demf"
echo "filter_wv=$filter_wv"
echo "xmin=$xmin xmax=$xmax ymin=$ymin ymax=$ymax"
echo "site=$site"
echo "unwrap=${unwrap}"


#the following "while read" reads each line and all variables of the PAIRSmake.txt (not all present) to make the .sub file for each pair

# a         b         c      d      e                    f                    g    h    i    j       k          l      m       n      o      p      q    r                       s
# mast      slav      orb1   orb2   doy_mast             doy_slav             dt   nan  trk  orbdir  swath      site   wv      bpar   bperp  burst  sat  dem                     filter_wv   
# 20200415  20210505  54442  60287  105.054610604005006  124.054702444455998  385  NAN  T30  A       strip_004  forge  0.0311  -20.4  6.7    nan    TSX  forge_dem_3dep_10m.grd  80                      


while read -r a b c d e f g h i j k l m n o p q r s; do
# ignore commented lines
    [[ "$a" =~ ^#.*$ && "$a" != [[:blank:]]  ]] && continue
ref=$a
sec=$b
track=$i
filter_wv=$s #added by Kurt and Sam 2021/07/02
sat=$q
if [[ "$sat" == "TDX" ]]
then
  sat="TSX"
fi
satparam=$k
echo "ref=$ref"
echo "sec=$sec"
echo "track=$track"
echo "sat=$sat"
echo "satparam=$satparam"
echo "unwrap=${unwrap}"

# echo "we can manually hand-off to:"
# echo "now we are running: run_pair_gmtsarv60.sh $sat $track $ref $sec $user $satparam $demf $filter_wv $xmin $xmax $ymin $ymax $site ${unwrap}"
run_pair_gmtsarv60.sh $sat $track $ref $sec $user $satparam $demf $filter_wv $xmin $xmax $ymin $ymax $site ${unwrap}

echo "Now issue the following command:"
echo ./run_pair_gmtsarv60.sh ${sat} ${track} ${ref} ${sec} ${user} ${satparam} ${demf} ${filter_wv} ${xmin} ${xmax} ${ymin} ${ymax} ${site} ${unwrap}
done < $1

