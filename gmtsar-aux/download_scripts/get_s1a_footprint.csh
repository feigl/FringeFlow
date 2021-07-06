#!/bin/tcsh
# by Kang Wang on 01/20/2017


if ($#argv != 1) then
  echo ""
  echo "Get the footprint of the S1A .SAFE files"
  echo ""
  echo "Usage: get_s1a_footprint.csh SAFE.list"
  echo ""
  exit 1
endif

set ziplist  = $1

set dir0 = `pwd`
rm -f $dir0/bound.dat

foreach safe (`cat $ziplist`)
   cd $dir0
#   root_name=`basename $zipfile ".zip"`
#   dir_root=$root_name".SAFE"
    set  dir_root = $safe
#    echo $dir_root"/preview"
   cd $dir_root"/preview"
   grep coordinates map-overlay.kml|awk -F">" '{print $2}'|awk -F"<" '{print $1}'  >> $dir0/bound.dat
end

cd $dir0

paste bound.dat $ziplist  > bounds.list

cat bound.dat|minmax -C|awk '{print $1}' >lon.dat
cat bound.dat|minmax -C|awk '{print $2}' >>lon.dat
cat bound.dat|minmax -C|awk '{print $5}' >>lon.dat
cat bound.dat|minmax -C|awk '{print $6}' >>lon.dat
cat bound.dat|minmax -C|awk '{print $9}' >>lon.dat
cat bound.dat|minmax -C|awk '{print $10}' >>lon.dat
cat bound.dat|minmax -C|awk '{print $13}' >>lon.dat
cat bound.dat|minmax -C|awk '{print $14}' >>lon.dat

cat bound.dat|minmax -C|awk '{print $3}' >lat.dat
cat bound.dat|minmax -C|awk '{print $4}' >>lat.dat
cat bound.dat|minmax -C|awk '{print $7}' >>lat.dat
cat bound.dat|minmax -C|awk '{print $8}' >>lat.dat
cat bound.dat|minmax -C|awk '{print $11}' >>lat.dat
cat bound.dat|minmax -C|awk '{print $12}' >>lat.dat
cat bound.dat|minmax -C|awk '{print $15}' >>lat.dat
cat bound.dat|minmax -C|awk '{print $16}' >>lat.dat

rm -f lonlat.dat
paste lon.dat lat.dat > lonlat.dat

set xmin_tmp = `minmax  lonlat.dat -C|awk '{print $1}'`
set xmax_tmp = `minmax  lonlat.dat -C|awk '{print $2}'`

set ymin_tmp = `minmax  lonlat.dat -C|awk '{print $3}'`
set ymax_tmp = `minmax  lonlat.dat -C|awk '{print $4}'`

set xmin = `echo "$xmin_tmp-0.3"|bc|awk '{printf "%.1f",$1}'`
set xmax = `echo "$xmax_tmp+0.3"|bc|awk '{printf "%.1f",$1}'` 

set ymin = `echo "$ymin_tmp-0.3"|bc|awk '{printf "%.1f",$1}'`
set ymax = `echo "$ymax_tmp+0.3"|bc|awk '{printf "%.1f",$1}'`

echo "For Image Display:        -R$xmin_tmp/$xmax_tmp/$ymin_tmp/$ymax_tmp"  > bounding.txt
echo "For DEM Preparation:      -R$xmin/$xmax/$ymin/$ymax"  >>bounding.txt
echo "For DEM Preparation:      -R$xmin/$xmax/$ymin/$ymax"  

rm -f lon.dat lat.dat lonlat.dat 
