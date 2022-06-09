#!/bin/bash -vx 

# build directories for running gmtsar6. 
# based on /home/batzli/bin_htcondor/run_pair_DAG_gmtsarv60.sh

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
# edit 20211028 Kurt and Sam improve error reporting
# edit 20220302 Sam added dt=$g and others (trk already defined) to capture that variable from the PAIRSmake.txt and pass it to build_pair.sh->write_run_script.sh->post_process_pair.sh->plot_pair7.sh
# edit 20220203 Kurt and Sam pass variables needed for ploting down the line


if [ "$#" -eq 1 ]; then
	unwrap=0
elif [ "$#" -eq 2 ]; then
	unwrap=${2}
else
   echo "usage: this script expects a PAIRSmake.txt file and, optionally, a numerical value for threshold_snaphu"
   echo "$0 PAIRSmake.txt 0"
   echo "$0 PAIRSmake.txt 0.12"
   echo "Note that last line of file must be blank or a comment."
   exit 0
fi

# set user
user=`echo $HOME | awk -F/ '{print $(NF)}'`

# set remote user on chtc
if [[ ${user} = "batzli" ]]; then
   ruser="sabatzli"
else
   ruser=${user}
fi


# set data directory
if [[ $(hostname) = "askja.ssec.wisc.edu" ]]; then
    export DATADIR=/s12
else
    export DATADIR=${HOME}
fi
echo "DATADIR is $DATADIR"

# set filter wavelength
filter_wv=`tail -1 $1 | awk '{print $19}'`


### set DEM and make sure cut version of DEM exists on askja
# get DEM from input file
demf=`grep dem $1 | tail -1 | awk '{print $18}'`
#echo "demf is $demf"

### check variables
#I believe next will be: 
#~/bin_htcondor/run_pair_gmtsarv60.sh $sat $trk $ref $sec $user $satparam $demf $filter_wv $xmin $xmax $ymin $ymax $site
# but some variables are missing: ($satparam) need to find source
# echo "Currently defined Variables:"
# echo "sat=$sat trk=$trk ref=$ref sec=$sec"
# echo "user=$user" 
# echo "satparam=$satparam"
# echo "dem=$demf"
# echo "filter_wv=$filter_wv"
# echo "xmin=$xmin xmax=$xmax ymin=$ymin ymax=$ymax"
# echo "site=$site"
# echo "unwrap=${unwrap}"
# echo "missing some so lets keep going..."

# use this syntax
# https://www.cyberciti.biz/faq/bash-check-if-string-starts-with-character-such-as/

#the following "while read" reads each line and all variables of the PAIRSmake.txt (not all present) to make the .sub file for each pair

# 1         2         3      4      5                    6                    7    8    9   10       11        12      13     14      15     16     17   18                     19
# a         b         c      d      e                    f                    g    h    i    j       k          l      m       n      o      p      q    r                       s
# mast      slav      orb1   orb2   doy_mast             doy_slav             dt   nan  trk  orbdir  swath      site   wv      bpar   bperp  burst  sat  dem                     filter_wv   
# 20200415  20210505  54442  60287  105.054610604005006  124.054702444455998  385  NAN  T30  A       strip_004  forge  0.0311  -20.4  6.7    nan    TSX  forge_dem_3dep_10m.grd  80                      

# ignore commented lines
#  [[ "$a" =~ ^#.*$ && "$a" != [[:blank:]]  ]] && continue

# start list of jobs
echo "#!/bin/bash" > submit_all.sh
# initialize counters
kount=0
ngood=0
# loop over lines in make file
while read -r a b c d e f g h i j k l m n o p q r s ; do
let "kount+=1"
#echo On line $i  a is $a
  # syntax must be exactly as on follwing line. No quotes around special characters. No "if" statement. 
  # Next line of code will try to process a blank line
  # [[ $a =~ ^#.* ]] && continue
  # Next line of code will skip over blank lines
   [[ "$a" =~ ^#.*$ && "$a" != [[:blank:]]  ]] && continue
   let "ngood+=1"  
   ref=$a
   sec=$b
   dt=$g

   if [ -z ${ref+x} ]; then 
      echo "variable ref is NOT set"; 
   else 
      echo "variable ref is set to $ref"; 
   fi

   if [ -z ${sec+x} ]; then 
      echo "variable sec is NOT set"; 
   else 
      echo "variable sec is set to $sec"; 
   fi

   trk=$i
   sat=$q
   if [[ "$sat" == "TDX" ]]; then
      sat="TSX"
   fi
   satparam=$k
   # remove underscore
   swath=`echo $satparam | sed 's/_//'`
   #echo "swath is $swath"
   bperp=$o
   demf=$r
   filter_wv=$s #added by Kurt and Sam 2021/07/02

   # set cut region in latitude and longitude
   site=$l
   xmin=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $1}'`
   xmax=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $2}'`
   ymin=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $3}'`
   ymax=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $4}'`

   SITE=`echo ${site} | awk '{ print toupper($1) }'`

   # make a directory for this pair
   pairdir=${SITE}_${sat}_${trk}_${swath}_${ref}_${sec}

   # get time difference in days
   dt=$g

   ## TODO - add DT to this
   echo ""
   echo ""
   echo "LAUNCHING PAIR ${ngood} on ${pairdir}"
   echo "build_pair.sh $sat $trk $ref $sec $user $satparam $demf $filter_wv $xmin $xmax $ymin $ymax $site $unwrap $dt $bperp"
   build_pair.sh ${sat} ${trk} ${ref} ${sec} ${user} ${satparam} ${demf} ${filter_wv} ${xmin} ${xmax} ${ymin} ${ymax} ${site} ${unwrap} ${dt} ${bperp} | tee ${pairdir}.log 
done < "$1"   # end of "while read" loop from above
echo ""
echo ""
echo "Processed $ngood good lines of $kount lines total in file $1"
echo "Normal end of $0"



