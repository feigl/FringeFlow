#!/bin/bash -vx
# run ISCE inside container

# configure environment 
source /opt/isce2/isce_env.sh
export PATH=/opt/isce2/src/isce2/contrib/stack/topsStack:$PATH

# very clean start
#rm -rf orbits ORBITS isce.log baselines configs merged stack run_files interferograms coreg_secondarys secondarys geom_reference reference
# clean start
rm -rf isce.log baselines configs merged stack run_files interferograms coreg_secondarys secondarys geom_reference reference run_files

# forge:
# -R-112.9852300488545/-112.7536042430101/38.4450885264283/38.59244067077842
# -R326752.87/347279.72/4256656.73/4273419.68
# 12

dem="demLat_N38_N39_Lon_W114_W111.dem.wgs84"

# -W interferogram 

stackSentinel.py -w ./ -s ../SLC2021/ -a aux/ -o ../ORBITS \
-z 2 -r 6 -c all -C geometry  \
-b '38.4450885264283 38.59244067077842 -112.9852300488545 -112.7536042430101' \
-d $dem 

#--start ${YYYYMMDD1} --stop ${YYYYMMDD2}

# set up a script to run all the scripts
ls -1 run_files/* | grep -v job | awk '{printf("echo\n echo\n echo STARTING %s\nbash %s\n",$1,$1)}' > run_isce_jobs.sh 
chmod a+x run_isce_jobs.sh

#run the script
./run_isce_jobs.sh | tee run_isce_jobs.log 

# quality control
grep -i error isce.log
grep -i warning isce.log
 
# graphics output
# mdx.py interferograms/20181006_20181018/IW3/fine_01.int -z -100 -wrap 6.28 -P
# convert out.ppm out.pdf
# convert out.ppm out.jpg
# ls -l out.*
#display out.jpg

# geocode
#geocodeIsce.py -f merged/interferograms/20190110_20190122/filt_fine.int -d demLat_N40_N41_Lon_W120_W119.dem.wgs84 -m ./reference -s ./secondarys/20190122/ -a 2 -r 6 -b '40.348 40.449 -119.46 -119.375' 
#convert out.ppm merged/interferograms/20190110_20190122/filt_fine.dem.crop.jpg
# https://stackoverflow.com/questions/20796200/how-to-loop-over-files-in-directory-and-change-path-and-add-suffix-to-filename
# for file in Data/*.txt
# do
#     for ((i = 0; i < 3; i++))
#     do
#         name=${file##*/}
#         base=${name%.txt}
#         ./MyProgram.exe "$file" Logs/"${base}_Log$i.txt"
#     done
# done

# for filename in Data/*.txt; do
#     [ -e "$filename" ] || continue
#     # ... rest of the loop body
# done



for filename in ./merged/interferograms/????????_????????/filt_fine.int ; do
    [ -e "$filename" ] || continue
        pair=`echo $filename | awk -F'/' '{print $3}'`
        ref=`echo $pair | awk -F_ '{print $1}'`
        sec=`echo $pair | awk -F_ '{print $2}'`
        geocodeIsce.py -f merged/interferograms/${ref}_${sec}/filt_fine.int -d $dem -m ./reference -s ./secondarys/${sec}/ -a 2 -r 6 -b '38.4450885264283 38.59244067077842 -112.9852300488545 -112.7536042430101'  
        mdx.py dem.crop -z -100 -wrap 6.28 -P
        convert out.ppm merged/interferograms/${ref}_${sec}/filt_fine_geo_crop.png
done

# timing
head -1 isce.log
tail -1 isce.log
#2021-03-13 00:53:09,018 - isce.zerodop.topozero - WARNING - Default Peg heading set to: -2.90493584856863
#2021-03-13 02:24:23,944 - isce.mroipac.correlation - INFO - Calculating Correlation
# less than 2 hours for 7 aquisitions
#2021-03-18 18:06:31,974 - isce.zerodop.topozero - WARNING - Default Peg heading set to: -2.90493584856863
#2021-03-18 18:17:52,645 - isce.mroipac.correlation - INFO - Calculating Correlation
# less than 7 minutes for 2 SLCs




