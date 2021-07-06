#!/usr/bin/env python
#
# check a list of .SAFE files and see if they intersect with the area of interest
#
# by Kang Wang on 01/20/2017

import sys
import numpy as npy
import polygons_overlapping as shape

narg=len(sys.argv)-1

if (narg!=5):
   print ""
   print "Usage: check_s1a_data.py W E S N bounds.list"
   print "It generates a list called safe.found"
   print ""
   quit()

lon1 = float(sys.argv[1])
lon2 = float(sys.argv[2])
lat1 = float(sys.argv[3])
lat2 = float(sys.argv[4])

filelist = sys.argv[5]

if (lon1>lon2 or lat1>lat2 or lon1 <0 or lon2 > 360 or lat1 <-90 or lat2 >90 ):
   print "**Wrong input bounds"
   quit()

poly_in=npy.array([[lon1,lat1],[lon1,lat2],[lon2,lat2],[lon2,lat1],[lon1,lat1]])

bounds_list = sys.argv[5]
out_file='safe.found'

f_out=open(out_file,'w')

f=open(bounds_list);
lines=f.readlines()



for line_in in lines:
#   print line.strip('\n')
    line=line_in.strip('\n').split()
    str1=line[0].split(",")
    str2=line[1].split(",")
    str3=line[2].split(",")
    str4=line[3].split(",")
    filename=line[4]
   
    x1=float(str1[0])
    y1=float(str1[1])

    x2=float(str2[0])
    y2=float(str2[1])
    
    x3=float(str3[0])
    y3=float(str3[1])
 
    x4=float(str4[0])
    y4=float(str4[1])

#    print filename
#    print line[1]
    poly_data=npy.array([[x1,y1],[x2,y2],[x3,y3],[x4,y4],[x1,y1]])
    out=shape.pair_overlapping(poly_in,poly_data)
    if (out>0):
       print filename
       f_out.write('%s\n'%(filename))

f.close
f_out.close
