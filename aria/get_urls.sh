#!/bin/bash -ex
# 2022/08/09 Kurt Feigl handle cookies

## get data from URLs

if [ "$#" -eq 1 ]; then
    icol=1
elif [ "$#" -eq 2 ]; then
    icol=$2
else
    bname=`basename $0`
    echo "$bname will retrieve data from a set of URLs listed in a CSV file "
    echo "usage:   $bname file"
    echo "example: $bname file column"
    echo "example: $bname aria.csv 11"
    exit -1
fi

cat $1 | grep http  | awk -F, -vICOL=$icol '{print $ICOL}' > tmp.txt
filename="tmp.txt"
while read -r line; do
    echo getting $line
    curl -b ~/.urs_cookies -c ~/.urs_cookies -L -n -f -Og $line && echo || echo "Command failed with error on $line . Please retrieve the data manually."
done < $filename
rm tmp.txt

echo "$0 ended normally"
exit 0


