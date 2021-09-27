#!/bin/bash 
# dump the attributes of an HDF5 file

## 2021/00/27 Kurt Feigl

# Run epochs for MINTPY
bname=`basename $0`
if [[  ( "$#" -eq 1)  ]]; then
   h5=$1
else
    echo "$bname will dump the attributes of an HDF5 file"
    echo "usage:   $bname file.h5"
    echo "example: $bname geo_velocity.h5"
    echo "example: $bname geo_velocity.h5 | grep DATE12"
    echo "example: $bname geo_velocity.h5 | grep OG_FILE_PATH"
fi

# dump the attributes and join pairs of lines
# trick for joining lines: https://stackoverflow.com/questions/8545538/how-do-i-join-pairs-of-consecutive-lines-in-a-large-file-1-million-lines-using
h5dump -A $h5 | grep -e ATTRIBUTE -e '(0)' | sed -rn 'N;s/\n/ /;p' | sed 's/(0)://' | sed 's/{//g'

exit 0
