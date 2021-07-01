#!/bin/bash -x
## 2021/06/08 Kurt Feigl

# have to get the orbits we need from askja.ssec.wisc.edu

# clean start
rm -f tmp.*

# download index file
ssh askja.ssec.wisc.edu 'ls /s12/insar/SANEM/SENTINEL/ORBITS' > tmp.fnames0

for slcname in $(ls ../SLC/S1?_IW_SLC*.zip ); do
   sat=`echo $slcname| awk '{print substr($1,8,3)}'` 
   echo "sat is $sat" 
   
   # get acquistion date of SLC
   yyyymmdd=`echo $slcname| awk '{print substr($1,25,8)}'`
   echo "yyyymmdd is $yyyymmdd"
   
   # get names of orbit files
   grep "ORB_OPOD" tmp.fnames0  | grep $sat  > tmp.fnames1

   # make sure that acquistion date of SLC is in time interval of validity
   cat tmp.fnames1 | awk -F_ '{print $0,substr($7,2,8),substr($8,1,8)}' | awk -v YYYYMMDD=${yyyymmdd} 'YYYYMMDD >= $2 && YYYYMMDD <= $3 {print $1,$2,$3}' > tmp.fnames2
   cat tmp.fnames2 | awk '{print $1}' > tmp.fnames3 
   fnames3=`cat tmp.fnames3`
   echo fnames3 is $fnames3

   for fname1 in ${fnames3}; do
      echo fname1 is $fname1
      rsync -rav askja.ssec.wisc.edu:/s12/insar/SANEM/SENTINEL/ORBITS/${fname1} .
   done
   #mv -v $fname1 $yyyymmdd  
done 

