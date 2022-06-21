#!/bin/bash 
## 2021/04/08 Kurt Feigl
## 2022/07/09 Kurt Feigl get all orbits

# have to get the orbits we need

# download index file

#if [ ! -d ORBITS ]; then
#   mkdir ORBITS
#fi


#cd ORBITS

ls -la .netrc
ls -la $HOME/.netrc

rm -f index.html*
rm -f aux_poeorb* 
rm -f tmp.*
wget --user='feigl@wisc.edu' https://s1qc.asf.alaska.edu/aux_poeorb 


# for slcname in $(ls ../SLC/S1?_IW_SLC*.zip ); do
#    sat=`echo $slcname| awk '{print substr($1,8,3)}'` 
#    echo "sat is $sat" 
   
#    yyyymmdd=`echo $slcname| awk '{print substr($1,25,8)}'`
#    echo "yyyymmdd is $yyyymmdd"
#    #mkdir -p $yyyymmdd

#    #fnames=`grep "OPER_AUX_POEORB_OPOD" aux_poeorb  | grep $sat | grep ${yyyymmdd} | awk '{print substr($2,7,77)}'`
  

   #grep "OPER_AUX_POEORB_OPOD" aux_poeorb  | grep $sat | grep ${yyyymmdd} | awk '{print substr($2,7,77)}' > tmp.fnames
   grep "OPER_AUX_POEORB_OPOD" aux_poeorb  | grep S1[AB] | awk '{print substr($2,7,77)}' > tmp.fnames1


 
#    cat tmp.fnames1 | awk -F_ '{print $0,substr($7,2,8),substr($8,1,8)}' | awk -v YYYYMMDD=${yyyymmdd} 'YYYYMMDD >= $2 && YYYYMMDD <= $3 {print $1,$2,$3}' > tmp.fnames2
#    cat tmp.fnames2 | awk '{print $1}' > tmp.fnames3 
   fnames1=`cat tmp.fnames1`
   echo fnames1 is $fnames1

   for fname1 in ${fnames1}; do
      echo fname1 is $fname1
      wget --user='feigl@wisc.edu' -nc https://s1qc.asf.alaska.edu/aux_poeorb/$fname1
   done
   #mv -v $fname1 $yyyymmdd  
#done 

