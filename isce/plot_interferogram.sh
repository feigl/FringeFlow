#!/bin/bash 
# print an interferogram to jpg file

if [[ ("$#" -ne 2) ]]; then
    bname=`basename $0`
    echo "$bname will plot an interferogram to a JPEG file"
    echo "usage:   $bname SITE file.int"
    echo "example: $bname SANEM merged/interferograms/20220424_20220506/filt_fine.int "
    echo "example: $bname SANEM merged/interferograms/20220424_20220506/filt_fine.unw "
    exit -1
fi

echo "Starting script named $0"
echo PWD is ${PWD}
echo HOME is ${HOME} 

export sit=$1
export fname=$2

echo sit is $sit
echo fname is $fname

if [[ -f $fname ]]; then
    ## print wrapped phase 
    # mdx.py merged/interferograms/${t0}_${t1}/filt_fine.int -z -100 -wrap 6.28 -P 
    # convert out.ppm merged/interferograms/${t0}_${t1}/filt.fine.pha.jpg
    mdx.py $fname -z -100 -wrap 6.28 -P 
    convert out.ppm ${file}.mag.jpg
else
    echo ERROR cannot find int file named $fname
    exit -1
fi

# print amplitude (magnitude) 
if [[ -f $fname.vrt ]]; then
    export NSAMP=`grep rasterXSize ${fname}.vrt | awk '{print substr($2,13)}' | sed 's/"//g'`
    echo "Number of samples NSAMP is $NSAMP"
    #mdx -P merged/interferograms/${t0}_${t1}/filt_fine.int -c8mag -s $NSAMP
    mdx -P $fname -c8mag -s $NSAMP 
    convert out.ppm ${file}.mag.jpg
else
    echo ERROR cannot find vrt file named $fname.vrt
    exit -1
fi

ls -ltr ${fname}*

