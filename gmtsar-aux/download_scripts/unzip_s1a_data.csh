#!/bin/tcsh -f

#unzip and sort relative orbit of the raw data 

if ($#argv != 1) then
  echo ""
  echo "Usage: unzip_s1a_data.csh zip.list"
  echo ""
  exit 1
endif

set ziplist = $1

rm -f path.list
foreach  zipfile (`cat $ziplist`)
  echo "working on " $zipfile
  unzip -o $zipfile
  set pre = `basename $zipfile .zip`
  set flying = `grep pass  $pre".SAFE/annotation/"*".xml"|awk -F">" '{print $2 }' | awk -F"</" '{print $1}' | awk 'NR==1 {print $0}'|cut -c 1-3`
  echo "Flying Direction: " $flying
  set abs_orbit = `grep OrbitNumber $pre".SAFE/annotation/"*".xml"|awk -F">" '{print $2 }' | awk -F"</" '{print $1}' | awk 'NR==1 {print $0}'`
  echo "Absolution Orbit Number: " $abs_orbit
  set rel_orbit = `awk "BEGIN {print ($abs_orbit-73)%175 +1}"|awk '{ printf("%03d\n", $1) }'`
  echo "Relative Orbit Number: " $rel_orbit
  
  mkdir -p $flying"_"$rel_orbit

  echo $flying"_"$rel_orbit  >> path.list
  mv $pre".SAFE" $flying"_"$rel_orbit
end

uniq path.list > path.txt

set dir0 = `pwd`
#foreach insar_path (`cat path.txt`) 
#  cd $insar_path
#    make_s1a_frames.csh 
#  cd $dir0
#end

#rm -f  path.list path.txt


mkdir -p raw_all

mv S1A*.zip raw_all

