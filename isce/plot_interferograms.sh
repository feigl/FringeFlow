#!/bin/bash -vx
# plot interferograms

# configure environment 
source /opt/isce2/isce_env.sh
export PATH=/opt/isce2/src/isce2/contrib/stack/topsStack:$PATH

# graphics output
#mdx.py interferograms/20181006_20181018/IW3/fine_01.int -z -100 -wrap 6.28 -P
#mdx.py interferograms/20200105_20200117/IW3/fine_01.int -z -100 -wrap 6.28 -P
for fname in interferograms/*/IW?/fine_01.int ; do
    dname=`dirname $fname`
    echo dname is $dname
    mdx.py $fname -z -100 -wrap 6.28 -P
    convert out.ppm $dname/fine_01.jpg
    #convert out.ppm $dname/fine_01.pdf
    # PDF is 2X bigger than JPG
    # -rw-r--r--  1 feigl  15   57084823 Apr 17 07:37 fine_01.jpg
    # -rw-r--r--  1 feigl  15  104249944 Apr 17 07:37 fine_01.pdf
done


find . -name "*.jpg" -ls
tar -czvf JPGS.tgz `find . -name "*.jpg"`
