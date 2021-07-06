#!/bin/bash
# extract_warm_ground_polys.sh: takes polys from Warm\ Grounds.kml and writes them to separate text files by ID in a format that GMT can read (for use with plot_pair_deployment.sh
# Elena C Reinisch 20180125

# prepare text files
grep "Placemark id=" Warm\ Grounds.kml | awk -F\" '{print $2}' > warm_ground_polys_id.txt # get poly id
grep "<coordinates>" -A1 Warm\ Grounds.kml  > warm_ground_polys.tmp # get poly info
cat warm_ground_polys.tmp | sed $'s/,0/\\\n/g' > warm_ground_polys.txt # clean up formatting (remove ,0 and replace with new line)

# initialize count
count=0

# cycle through poly file 
while read line; do
    if [[ $line == *"coordinates"* ]]; then
        let "count+=1"
        echo COUNT = $count
        sceneid=$(sed "${count}q;d" warm_ground_polys_id.txt)
        echo SCENEID = $sceneid
        fout=$(echo $sceneid | awk '{printf("brady_poly_%s.txt", $1)}')
        echo FOUT = ${fout}
    elif [[ $line == *"119"* ]]; then
        echo $line >> ${fout}     
    fi
done < warm_ground_polys.txt

