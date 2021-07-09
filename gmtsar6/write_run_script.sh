#!/bin/bash 
#!/usr/bin/env -S bash -x 
# 	options: -ex
# 	-x  Print commands and their arguments as they are executed.
# 	-e  Exit immediately if a command exits with a non-zero status.
#
# Usage: pair2.sh ERS 12345 67890 /scratch/feigl/dems/bhs.grd [conf.ers.txt]
# TSX Usage: pair2e.sh "$sat" "$ref" "$sec" $satparam dem/${demf} $filter_wv $site $xmin $xmax $ymin $ymax $unwrap
#
# # modifications 
# 20160804 Kurt adapt for CHTC
# 20160806 Elena correct relative path name for DEM
# update ECR 20171114 add variable for site so that p2p_TSX_SLC_airbus.csh is called for tungs and dcamp
# update ECR 20180116 add variable for site so that p2p_TSX_SLC_airbus.csh is called for dixie (as well as tungs and dcamp)
# udpate ECR 20180605 add S1B
# 20200127 KLF try to fix enviroment variables $maule
# 20201130 Sam and Kurt noting necessary changes for migration to 6.0 and Askja
# 20201209 Sam modified for ref/sec and paths for dem and config.tsx.txt
# 20210308 Sam added ${12} unwrap value "0.12" or empty (passed in from run_pair_gmtsarv60.sh) 
# 20210318 Kurt and Sam added self-documentation.
# 20210707 Kurt and Sam adapt for docker. "region_cut" must be empty
if [ ! "$#" -eq 12 ]; then
	echo "$0 needs 12 arguments. Found only $#"
   	exit 1
fi

sat=${1}
ref=${2}
sec=${3}
satparam=${4}
demgrd=${5}
filter_wv=${6}
site=${7}
xmin=${8}
xmax=${9}
ymin=${10}
ymax=${11}
unwrap=${12}

if [[ "$sat" == "ERS2" || "$sat" == "ERS1" ]] ; then
	sat=ERS
fi

#region_cut=0 # temporary variable to default to no cutting (for development only)
#orb1=$5
#orb2=$6
orb1a=`expr $ref - 1`
orb1b=`expr $ref + 1`
orb2a=`expr $ref - 1`
orb2b=`expr $ref + 1`
homedir=`pwd`
echo "Working directory homedir is $homedir"

# if [ $# -lt 3 ] ; then
# 	echo " Usage: pair2.sh ERS 12345 67890 dem/dem.grd [conf.ers.txt]"
# 	echo "missing arguments"
# 	exit 1
# fi

if [ $# -gt 3 ] ; then
  case "$sat" in 
  TSX)
    # should already be in container
	if [[ -f /opt/gmtsar/6.0/share/gmtsar/csh/config.tsx.txt ]]; then
       cp -v /opt/gmtsar/6.0/share/gmtsar/csh/config.tsx.txt .
	fi
    cnf=$homedir/config.tsx.txt
    ;;
   *)
    echo "unknown sat $sat"
    exit 1
    ;;
  esac
else
  #cnf=$5
    cnf=$homedir/gmtsar/config/config.s1a.txt
    cp $homedir/gmtsar/config/config.s1a.txt .
    cnf=$homedir/config.s1a.txt
fi

echo "Config file cnf is $cnf"


if [ $# -ge 5 ] ; then
	sed -i "/filter_wavelength/c\filter_wavelength = $filter_wv" $cnf
	sed -i "/proc_stage/c\proc_stage = 1" $cnf
fi

# Edit configuration file for unwrapping (default if not edited is "0" meaning "no")
# this test checks to see if the variable is set as an expression that evaluates to nothing if unwrap is unset
echo "the unwrap variable is ${unwrap}"
echo "the config file is ${cnf}"
if [[ ${unwrap} != 0 ]]; then
#if [ -z ${unwrap+x} ]; then 
	sed -i "/threshold_snaphu/c\threshold_snaphu = ${unwrap}" $cnf
	echo "setting the threshold_snaphu to ${unwrap}"
fi
	
# construct path to RAW data
#RAWdir=`pwd`/raw
# make relative path name
RAWdir=../../RAW
# should this be ../RAW? probably not
#RAWdir=../RAW

# construct name for In directory
inpairdir=In${ref}_${sec}
if [ -d $inpairdir ]; then
	echo "removing existing inpairdir named $inpairdir"
   	rm -rf $inpairdir
fi
mkdir $inpairdir
cd $inpairdir
cp $cnf .
cnf=`basename $cnf`
echo "Configuration filename cnf is $cnf"

# This may or may not have changed in v6.0
mkdir raw intf SLC topo

# can use relative path name
# is this broken?
cd topo
#ln -s ../$demgrd dem.grd #attempted fix for below broke the processing.  Needs to be fixed in the move.
#ln -s ../../$demgrd dem.grd #this broke when moving files up and out $DOY directory -- SAB 06/30/21
cp -v ../../$demgrd dem.grd # copy, do not link
cd ..

# set up links to RAW 
cd raw
# ls $RAWdir/*$2*
# ls $RAWdir/*$3*

if [ "$sat" == "TSX" ] ; then
    # copy the files we want to keep in the tar file
	# cp -v $RAWdir/${ref}.PRM .
	# cp -v $RAWdir/${sec}.PRM .
	# cp -v $RAWdir/${ref}.LED .
	# cp -v $RAWdir/${sec}.LED .
    # # make links for some files
	# ln -s $RAWdir/${ref}.LED ${ref}.LED
	# ln -s $RAWdir/${sec}.LED ${sec}.LED

    # these get deleted in step 1, but they must be there
	#ln -s $RAWdir/${ref}.SLC ${ref}.SLC
	#ln -s $RAWdir/${sec}.SLC ${sec}.SLC
	touch ${ref}.SLC
	touch ${sec}.SLC
	touch ${ref}.PRM
	touch ${sec}.PRM
	touch ${ref}.LED
	touch ${sec}.LED

	#longdirname1=`grep ${site} ${DATADIR}/insar/TSX/TSX_OrderList.txt | grep ${ref} | sed 's%/s12/%/root/%' | awk '{print $12}'`
    longdirname1=`grep -i ${site} ${DATADIR}/insar/TSX/TSX_OrderList.txt | grep ${ref}  | awk '{print $12}'`
	echo "longdirname1 is $longdirname1"
	longbasename1=`basename $longdirname1`
	echo "longbasename is $longbasename1"
	#longdirname2=`grep ${site} ${DATDIR}/insar/TSX/TSX_OrderList.txt | grep ${sec} | sed 's%/s12/%/root/%' | awk '{print $12}'`
	longdirname2=`grep -i ${site} ${DATADIR}/insar/TSX/TSX_OrderList.txt | grep ${sec}  | awk '{print $12}'`
	echo "longdirname2 is $longdirname2"
	longbasename2=`basename $longdirname2`
	echo "longbasename2 is $longbasename2"

	# # copy the whole thing
	# cp -r $RAWdir/$longbasename1 .
	# cp -r $RAWdir/$longbasename2 .


	# links for $ref and $sec .cos and .xml with date names for rsynced earlier run_pair_gmtsarv60.sh
	#XMLref=`find $RAWdir/TDX1_SM_091_strip_005_20201023014507 -name "*.xml" | grep -v ANNOTATION | grep -v iif`
	XMLref=`find $RAWdir/$longbasename1 -name "*.xml" | grep -v ANNOTATION | grep -v iif`
	#XMLref=`find $longbasename1 -name "*.xml" | grep -v ANNOTATION | grep -v iif`
	ln -s $XMLref ${ref}.xml
	#cp -v $XMLref ${ref}.xml
	#COSref=`find $RAWdir/TDX1_SM_091_strip_005_20201023014507 -name "*.cos"`
	COSref=`find $RAWdir/$longbasename1 -name "*.cos"`
	#COSref=`find $longbasename1 -name "*.cos"`
	ln -s $COSref ${ref}.cos
	#cp -v $COSref ${ref}.cos
	#XMLsec=`find $RAWdir/TDX1_SM_091_strip_005_20201114014508 -name "*.xml" | grep -v ANNOTATION | grep -v iif`
	XMLsec=`find $RAWdir/$longbasename2 -name "*.xml" | grep -v ANNOTATION | grep -v iif`
	#XMLsec=`find $longbasename2 -name "*.xml" | grep -v ANNOTATION | grep -v iif`
	ln -s $XMLsec ${sec}.xml
    #cp -v $XMLsec ${sec}.xml
	#COSsec=`find $RAWdir/TDX1_SM_091_strip_005_20201114014508 -name "*.cos"`
	COSsec=`find $RAWdir/$longbasename2 -name "*.cos"`
	#COSsec=`find $longbasename2 -name "*.cos"`
	ln -s $COSsec ${sec}.cos
    #cp -v $COSsec ${sec}.cos

else
	echo "unknown sat $sat"
	exit 1
fi
cd ..



# start to write the commands for the run script with sebang
echo '#!/bin/bash -vx' > run.sh

echo SAT = $sat

# build the command [p2p_processing.csh now handles TSX and other sats that don't have their own scripts, but order of args has probably changed]
if [[ "$sat" == "TSX" ]] ; then
	if [[ "$site" == "dcamp" || "$site" == "tungs" || "$site" == "dixie" || "$site" == "tusca" ]] ; then #special case for Airbus not urgent
		echo '# USING AIRBUS VERSION OF P2P FOR TSX' >> run.sh
		echo "p2p_TSX_SLC_airbus.csh $ref $sec $cnf" >> run.sh
  	else
		#this script is now p2p_processing.csh  
		#echo p2p_TSX_SLC.csh $ref $sec $cnf >> run.sh
		# standard out of the box version
		echo "p2p_processing.csh ${sat} ${ref} ${sec} ${cnf}" >> run.sh
		# Kurt's modified version
     	#echo p2p_processingKF.csh ${sat} $ref $sec $cnf >> run.sh
	fi
else
    echo "unknown sat $sat"
fi

# handle post-processing
echo "post_process_pair.sh ${site} ${ref} ${sec}" >> run.sh

# make run.sh executable 
chmod +x run.sh

exit 0
