#!/bin/tcsh -f

if ($#argv < 3) then
   echo ""
   echo "Usage: get_s1a_data.csh Rw/e/s/n yyyymmdd yyyymmdd [relative_orbit] [download(Y/N)]"
   echo "Example: get_s1a_data.csh R85/88/27/28 20150512 20150830 85" 
   echo ""
   exit 1
   
endif



set region = $1
set t1 = $2
set t2 = $3


set flag_arg1 = `echo $1 | cut -c 1`
if ($flag_arg1 != "R") then
   echo "***Bad bounds input!"
   echo "***Type the command without arguments to see the usage!"
   exit 1
endif

set west = `echo $region | awk -F"/" '{sub(/R/,"");print $1 }'`
set east = `echo $region | awk -F"/" '{sub(/R/,"");print $2 }'`
set south = `echo $region | awk -F"/" '{sub(/R/,"");print $3 }'`
set north = `echo $region | awk -F"/" '{sub(/R/,"");print $4 }'`

set R_ok1 = `echo $east $west | awk '{if($1>$2){print "good"}else {print "bad"}}' `
set R_ok2 = `echo $north $south | awk '{if($1>$2){print "good"}else {print "bad"}}' `
if ($R_ok1 == "bad" || $R_ok2 == "bad") then
   echo "***Bad bounds input!"
   exit 1
endif


set R_ok3 = `echo $east | awk '{if ($1>=-180.0 && $1<=180.0){print "good"}else {print "bad"} }'`
set R_ok4 = `echo $west | awk '{if ($1>=-180.0 && $1<=180.0){print "good"}else {print "bad"} }'`
set R_ok5 = `echo $south | awk '{if ($1>=-90.0 && $1<=90.0){print "good"}else {print "bad"} }'`
set R_ok6 = `echo $north | awk '{if ($1>=-90.0 && $1<=90.0){print "good"}else {print "bad"} }'`
if ($R_ok3 == "bad" || $R_ok4 == "bad" || $R_ok5 == "bad" || $R_ok6 == "bad") then
   echo "***Bad bounds input!"
   exit 1
endif


set region_com = "--intersectsWith='POLYGON(( $west $south , $west $north , $east $north , $east $south , $west $south ))'"
set platform_com = "--platform=Sentinel-1A"

set yr1 = `echo $t1|cut -c 1-4`
set m1  = `echo $t1|cut -c 5-6`
set d1 = `echo $t1|cut -c 7-8`

set yr2 = `echo $t2|cut -c 1-4`
set m2  = `echo $t2|cut -c 5-6`
set d2 = `echo $t2|cut -c 7-8`

set t1_com = "-s $yr1-$m1-$d1"
set t2_com = "-e $yr2-$m2-$d2"

if ($#argv > 3) then
   set orbit = $4
   set orbit_com = "-r $orbit "
else
   set orbit_com =
endif

set download = "N"

if ($#argv > 4) then
  set download = $5
endif

set processing_Level = "--processingLevel=SLC"
echo "ssara_federated_query.py" $platform_com $region_com $t1_com $t2_com $orbit_com $processing_Level  --kml > ssara.com
echo "ssara_federated_query.py" $platform_com $region_com $t1_com $t2_com $orbit_com $processing_Level  --kml 

bash ssara.com 

grep "Download URL" winsar_search.kml | awk -F"/" '{print $NF}'|rev |cut -c 5- |rev  > data.list


if ($download == "Y") then

   get_s1a_from_asf.csh data.list
endif

