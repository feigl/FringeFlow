#!/bin/bash
# for file in $(find 2021/In*  -type f -name "*.PRM"); do 
# 	echo $file | sort -nu >> unique_list.txt 
# done
for file in $(find 2021/In*  -type f -name tmp.footer ); do 
    dname=`dirname $file`
	echo working on $file in $dname
	cat $file | cut -f3- --delimiter=' '  | sed  's%/var/lib/condor/execute/slot1/%%g' | tr '\n' ',' > $dname/title.txt
done
