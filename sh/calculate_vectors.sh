#!/bin/bash -vx

# calculate unit vectors pointing from target to sat 
# 2024/07/17 Kurt Feigl and Sam Batzli

# first make a text file with lat, lon coordinates of every pixel in DEM
if [[ ! -f dem_llt.txt ]]; then
	gmt gmtset FORMAT_FLOAT_OUT "%.12f"
	gmt grd2xyz -W ./PAIRS/In20230501_20230523/dem.grd > dem_llt.txt
fi


# Make list of epochs with directories
pushd PAIRS
find In* -type f -name "*.LED" > file_list.txt
echo "file_list.txt made"
# Calculate unit vectors
echo "calculating unit vectors..."
while read -r filepath; do
	dirpath=$(dirname "$filepath")
	filename=$(basename "$filepath")
	allvectors="${filename%.*}_unit_vectors.txt"
	meanvector="${filename%.*}_unit_vector_mean.txt"
	if [ ! -f $allvectors ]; then
	   pushd ${dirpath}
	   echo "now in ${dirpath}"
	   ln -s /s12/batzli/forge_2024/dem_llt.txt dem_llt.txt
	   SAT_look "${filename%.*}.PRM" < dem_llt.txt > $allvectors
	   unlink dem_llt.txt

	   # take the mean over all pixels
	   awk -f ../../mean.awk $allvectors > $meanvector
	   popd
	fi
done < file_list.txt

# now compile all the means into a single file - we did this manually
popd
# This makes a file with 3 lines per orbit
head -1 `find PAIRS/In* -name "*_unit_vector_mean.txt"` > temp2.txt
# join lines 1 and 2, ignore line 3
# https://stackoverflow.com/questions/9605232/how-to-merge-every-two-lines-into-one-from-the-command-line
awk 'NR%3{printf "%s ",$0;next;}1' temp2.txt | awk '{print $2,$7,$8,$9}' > mean_unit_vectors.txt